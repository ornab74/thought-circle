import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart' show DartArgon2id;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

const _format = 'thought-circle-vault-v1';
const _databaseName = 'thought_circle_vault.sqlite3';
const _headerName = 'thought_circle_vault.header.json';
const _sentinelNamespace = '_system';
const _sentinelKey = 'sentinel';
const _maxHeaderBytes = 1024 * 1024;

enum VaultAccess { setupRequired, locked, unlocked }

final class VaultInspection {
  final VaultAccess access;

  const VaultInspection(this.access);
}

final class VaultException implements Exception {
  final String code;
  final String message;
  final Object? cause;

  const VaultException(this.code, this.message, [this.cause]);

  @override
  String toString() => 'VaultException($code): $message';
}

/// An encrypted record store designed for private app state.
///
/// The SQLite schema, row count, ciphertext sizes, and update times remain
/// visible to someone who can read the database file. Record names and values
/// are not stored in plaintext.
final class ThoughtVault {
  ThoughtVault._({Future<Directory> Function()? directoryProvider})
    : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  static final ThoughtVault instance = ThoughtVault._();

  factory ThoughtVault.forTesting(Directory directory) {
    return ThoughtVault._(directoryProvider: () async => directory);
  }

  final Future<Directory> Function() _directoryProvider;
  final AesGcm _aes = AesGcm.with256bits();
  final Hmac _hmac = Hmac.sha256();
  final Hkdf _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  Future<void> _tail = Future<void>.value();
  sqlite.Database? _database;
  Map<String, Object?>? _header;
  Uint8List? _masterKey;
  Uint8List? _indexKey;

  bool get isUnlocked => _database != null && _masterKey != null;

  Future<VaultInspection> inspect() {
    return _enqueue(() async {
      if (isUnlocked) return const VaultInspection(VaultAccess.unlocked);
      final header = await _headerFile();
      return VaultInspection(
        await header.exists() ? VaultAccess.locked : VaultAccess.setupRequired,
      );
    });
  }

  Future<void> create(String password) {
    return _enqueue(() => _createNow(password));
  }

  Future<void> unlock(String password) {
    return _enqueue(() => _unlockNow(password));
  }

  Future<void> lock() {
    return _enqueue(_lockNow);
  }

  Future<Object?> readJson(String namespace, String key) {
    _validateRecordName(namespace, key);
    return _enqueue(() => _readJsonNow(namespace, key));
  }

  Future<void> writeJson(String namespace, String key, Object? value) {
    _validateRecordName(namespace, key);
    return _enqueue(() => _writeJsonNow(namespace, key, value));
  }

  Future<void> delete(String namespace, String key) {
    _validateRecordName(namespace, key);
    return _enqueue(() async {
      final recordId = await _recordId(namespace, key);
      _requireDatabase().execute(
        'DELETE FROM vault_records WHERE record_id = ?',
        <Object?>[recordId],
      );
    });
  }

  Future<void> changePassword(String password) {
    return _enqueue(() async {
      _validateNewPassword(password);
      final header = Map<String, Object?>.from(_requireHeader());
      final master = _requireMasterKey();
      final salt = _randomBytes(16);
      Uint8List? passwordKey;
      try {
        passwordKey = await _derivePasswordKey(
          password: password,
          salt: salt,
          memoryKiB: 64 * 1024,
          iterations: 3,
          parallelism: 1,
        );
        header['kdf'] = <String, Object?>{
          'algorithm': 'Argon2id-1.3',
          'salt': base64Encode(salt),
          'memoryKiB': 64 * 1024,
          'iterations': 3,
          'parallelism': 1,
        };
        header['wrappedMasterKey'] = await _seal(
          master,
          passwordKey,
          _masterKeyAad(header),
        );
        header['updatedAt'] = DateTime.now().toUtc().toIso8601String();
        await _writeHeader(await _headerFile(), header);
        _header = header;
      } finally {
        _zero(passwordKey);
        _zero(salt);
      }
    });
  }

  Future<void> _createNow(String password) async {
    await _lockNow();
    _validateNewPassword(password);
    final headerFile = await _headerFile();
    if (await headerFile.exists()) {
      throw const VaultException(
        'already_exists',
        'A private vault already exists on this device.',
      );
    }

    final vaultId = _base64UrlNoPadding(_randomBytes(18));
    final salt = _randomBytes(16);
    final master = _randomBytes(32);
    Uint8List? passwordKey;
    Uint8List? indexKey;
    try {
      passwordKey = await _derivePasswordKey(
        password: password,
        salt: salt,
        memoryKiB: 64 * 1024,
        iterations: 3,
        parallelism: 1,
      );
      final header = <String, Object?>{
        'format': _format,
        'version': 1,
        'vaultId': vaultId,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
        'kdf': <String, Object?>{
          'algorithm': 'Argon2id-1.3',
          'salt': base64Encode(salt),
          'memoryKiB': 64 * 1024,
          'iterations': 3,
          'parallelism': 1,
        },
      };
      header['wrappedMasterKey'] = await _seal(
        master,
        passwordKey,
        _masterKeyAad(header),
      );
      await _writeHeader(headerFile, header);

      final database = sqlite.sqlite3.open((await _databaseFile()).path);
      _configureDatabase(database);
      indexKey = await _deriveIndexKey(master, vaultId);
      _database = database;
      _header = header;
      _masterKey = Uint8List.fromList(master);
      _indexKey = indexKey;

      await _writeJsonNow(_sentinelNamespace, _sentinelKey, <String, Object?>{
        'format': _format,
        'vaultId': vaultId,
        'ok': true,
      });
    } catch (_) {
      await _lockNow();
      rethrow;
    } finally {
      _zero(passwordKey);
      _zero(salt);
      _zero(master);
    }
  }

  Future<void> _unlockNow(String password) async {
    await _lockNow();
    _validatePasswordInput(password);
    final header = await _readHeader(await _headerFile());
    final kdf = header['kdf'];
    if (kdf is! Map || kdf['algorithm'] != 'Argon2id-1.3') {
      throw const VaultException(
        'bad_header',
        'The vault settings are invalid.',
      );
    }

    Uint8List? passwordKey;
    Uint8List? master;
    Uint8List? indexKey;
    sqlite.Database? database;
    try {
      passwordKey = await _derivePasswordKey(
        password: password,
        salt: Uint8List.fromList(base64Decode(kdf['salt'].toString())),
        memoryKiB: _asInt(kdf['memoryKiB']),
        iterations: _asInt(kdf['iterations']),
        parallelism: _asInt(kdf['parallelism']),
      );
      final envelope = header['wrappedMasterKey'];
      if (envelope is! Map) {
        throw const VaultException('bad_header', 'The vault key is missing.');
      }
      master = await _open(
        Map<String, Object?>.from(envelope),
        passwordKey,
        _masterKeyAad(header),
      );
      if (master.length != 32) {
        throw const VaultException('bad_key', 'The vault key is invalid.');
      }
      indexKey = await _deriveIndexKey(master, header['vaultId'].toString());
      database = sqlite.sqlite3.open((await _databaseFile()).path);
      _configureDatabase(database);
      _database = database;
      _header = header;
      _masterKey = Uint8List.fromList(master);
      _indexKey = indexKey;
      database = null;
      indexKey = null;

      final sentinel = await _readJsonNow(_sentinelNamespace, _sentinelKey);
      if (sentinel is! Map || sentinel['ok'] != true) {
        throw const VaultException(
          'authentication',
          'The password is incorrect or the private vault was changed.',
        );
      }
    } on SecretBoxAuthenticationError catch (error) {
      await _lockNow();
      throw VaultException(
        'authentication',
        'The password is incorrect or the private vault was changed.',
        error,
      );
    } catch (_) {
      await _lockNow();
      rethrow;
    } finally {
      database?.close();
      _zero(passwordKey);
      _zero(master);
      _zero(indexKey);
    }
  }

  Future<Object?> _readJsonNow(String namespace, String key) async {
    final recordId = await _recordId(namespace, key);
    final rows = _requireDatabase().select(
      'SELECT nonce, cipher_text, mac FROM vault_records WHERE record_id = ?',
      <Object?>[recordId],
    );
    if (rows.isEmpty) return null;
    final row = rows.single;
    Uint8List? recordKey;
    Uint8List? clear;
    try {
      recordKey = await _deriveRecordKey(recordId);
      clear = Uint8List.fromList(
        await _aes.decrypt(
          SecretBox(
            List<int>.from(row['cipher_text'] as Uint8List),
            nonce: List<int>.from(row['nonce'] as Uint8List),
            mac: Mac(List<int>.from(row['mac'] as Uint8List)),
          ),
          secretKey: SecretKey(recordKey),
          aad: _recordAad(recordId),
        ),
      );
      return jsonDecode(utf8.decode(clear));
    } on SecretBoxAuthenticationError catch (error) {
      throw VaultException(
        'record_authentication',
        'One private record could not be verified.',
        error,
      );
    } finally {
      _zero(recordKey);
      _zero(clear);
    }
  }

  Future<void> _writeJsonNow(
    String namespace,
    String key,
    Object? value,
  ) async {
    final recordId = await _recordId(namespace, key);
    final clear = Uint8List.fromList(utf8.encode(jsonEncode(value)));
    Uint8List? recordKey;
    try {
      recordKey = await _deriveRecordKey(recordId);
      final box = await _aes.encrypt(
        clear,
        secretKey: SecretKey(recordKey),
        aad: _recordAad(recordId),
      );
      _requireDatabase().execute(
        '''
INSERT INTO vault_records(record_id, nonce, cipher_text, mac, updated_at)
VALUES(?, ?, ?, ?, ?)
ON CONFLICT(record_id) DO UPDATE SET
  nonce=excluded.nonce,
  cipher_text=excluded.cipher_text,
  mac=excluded.mac,
  updated_at=excluded.updated_at
''',
        <Object?>[
          recordId,
          Uint8List.fromList(box.nonce),
          Uint8List.fromList(box.cipherText),
          Uint8List.fromList(box.mac.bytes),
          DateTime.now().toUtc().millisecondsSinceEpoch,
        ],
      );
    } finally {
      _zero(recordKey);
      _zero(clear);
    }
  }

  Future<Uint8List> _recordId(String namespace, String key) async {
    final indexKey = _indexKey;
    if (indexKey == null) {
      throw const VaultException('locked', 'The private vault is locked.');
    }
    final mac = await _hmac.calculateMac(
      utf8.encode('$_format\u001f$namespace\u001f$key'),
      secretKey: SecretKey(indexKey),
    );
    return Uint8List.fromList(mac.bytes);
  }

  Future<Uint8List> _deriveIndexKey(List<int> master, String vaultId) async {
    final key = await _hkdf.deriveKey(
      secretKey: SecretKey(master),
      nonce: utf8.encode(vaultId),
      info: utf8.encode('$_format/index-key'),
    );
    return Uint8List.fromList(await key.extractBytes());
  }

  Future<Uint8List> _deriveRecordKey(Uint8List recordId) async {
    final key = await _hkdf.deriveKey(
      secretKey: SecretKey(_requireMasterKey()),
      nonce: recordId,
      info: utf8.encode('$_format/record-key'),
    );
    return Uint8List.fromList(await key.extractBytes());
  }

  Future<Map<String, Object?>> _seal(
    List<int> clear,
    List<int> key,
    List<int> aad,
  ) async {
    final box = await _aes.encrypt(clear, secretKey: SecretKey(key), aad: aad);
    return <String, Object?>{
      'cipher': 'AES-256-GCM',
      'nonce': base64Encode(box.nonce),
      'cipherText': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    };
  }

  Future<Uint8List> _open(
    Map<String, Object?> envelope,
    List<int> key,
    List<int> aad,
  ) async {
    if (envelope['cipher'] != 'AES-256-GCM') {
      throw const VaultException(
        'bad_cipher',
        'The vault cipher is unsupported.',
      );
    }
    final clear = await _aes.decrypt(
      SecretBox(
        base64Decode(envelope['cipherText'].toString()),
        nonce: base64Decode(envelope['nonce'].toString()),
        mac: Mac(base64Decode(envelope['mac'].toString())),
      ),
      secretKey: SecretKey(key),
      aad: aad,
    );
    return Uint8List.fromList(clear);
  }

  List<int> _masterKeyAad(Map<String, Object?> header) {
    final kdf = header['kdf'];
    return utf8.encode(
      jsonEncode(<String, Object?>{
        'format': _format,
        'version': header['version'],
        'vaultId': header['vaultId'],
        'kdf': kdf is Map ? Map<String, Object?>.from(kdf) : null,
      }),
    );
  }

  List<int> _recordAad(Uint8List recordId) {
    return utf8.encode('$_format/record/${base64UrlEncode(recordId)}');
  }

  Future<Map<String, Object?>> _readHeader(File file) async {
    if (!await file.exists()) {
      throw const VaultException('missing', 'No private vault exists yet.');
    }
    final stat = await file.stat();
    if (stat.size <= 0 || stat.size > _maxHeaderBytes) {
      throw const VaultException('bad_header', 'The vault header is invalid.');
    }
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map) {
      throw const VaultException('bad_header', 'The vault header is invalid.');
    }
    final header = Map<String, Object?>.from(decoded);
    if (header['format'] != _format || header['version'] != 1) {
      throw const VaultException(
        'bad_header',
        'The vault version is unsupported.',
      );
    }
    final vaultId = header['vaultId']?.toString() ?? '';
    if (!RegExp(r'^[A-Za-z0-9_-]{16,64}$').hasMatch(vaultId)) {
      throw const VaultException(
        'bad_header',
        'The vault identifier is invalid.',
      );
    }
    return header;
  }

  Future<void> _writeHeader(File file, Map<String, Object?> header) async {
    await file.parent.create(recursive: true);
    final temporary = File('${file.path}.new');
    if (await temporary.exists()) await temporary.delete();
    await temporary.writeAsString(
      const JsonEncoder.withIndent('  ').convert(header),
      flush: true,
    );
    await _harden(temporary);
    if (Platform.isWindows && await file.exists()) await file.delete();
    await temporary.rename(file.path);
    await _harden(file);
    await _readHeader(file);
  }

  void _configureDatabase(sqlite.Database database) {
    database.execute('PRAGMA trusted_schema=OFF');
    database.execute('PRAGMA foreign_keys=ON');
    database.execute('PRAGMA secure_delete=ON');
    database.execute('PRAGMA journal_mode=WAL');
    database.execute('PRAGMA synchronous=FULL');
    database.execute('PRAGMA busy_timeout=5000');
    database.execute('''
CREATE TABLE IF NOT EXISTS vault_records(
  record_id BLOB PRIMARY KEY NOT NULL,
  nonce BLOB NOT NULL CHECK(length(nonce) = 12),
  cipher_text BLOB NOT NULL,
  mac BLOB NOT NULL CHECK(length(mac) = 16),
  updated_at INTEGER NOT NULL
) WITHOUT ROWID;
''');
    database.userVersion = 1;
  }

  Future<void> _lockNow() async {
    final database = _database;
    _database = null;
    if (database != null) {
      try {
        database.execute('PRAGMA wal_checkpoint(TRUNCATE)');
      } catch (_) {}
      database.close();
    }
    _header = null;
    _zero(_masterKey);
    _zero(_indexKey);
    _masterKey = null;
    _indexKey = null;
  }

  sqlite.Database _requireDatabase() {
    final database = _database;
    if (database == null) {
      throw const VaultException('locked', 'The private vault is locked.');
    }
    return database;
  }

  Map<String, Object?> _requireHeader() {
    final header = _header;
    if (header == null) {
      throw const VaultException('locked', 'The private vault is locked.');
    }
    return header;
  }

  Uint8List _requireMasterKey() {
    final key = _masterKey;
    if (key == null) {
      throw const VaultException('locked', 'The private vault is locked.');
    }
    return key;
  }

  Future<File> _databaseFile() async {
    final directory = await _directoryProvider();
    return File('${directory.path}/$_databaseName');
  }

  Future<File> _headerFile() async {
    final directory = await _directoryProvider();
    return File('${directory.path}/$_headerName');
  }

  void _validateRecordName(String namespace, String key) {
    for (final value in <String>[namespace, key]) {
      if (value.isEmpty || value.length > 200 || value.contains('\u0000')) {
        throw ArgumentError.value(
          value,
          'record',
          'Invalid private record name.',
        );
      }
    }
    if (namespace == _sentinelNamespace) {
      throw ArgumentError.value(namespace, 'namespace', 'Reserved namespace.');
    }
  }

  void _validateNewPassword(String password) {
    final length = password.runes.length;
    if (length != 0 && length < 12) {
      throw const VaultException(
        'weak_password',
        'Use at least 12 characters for the app password.',
      );
    }
    _validatePasswordInput(password);
  }

  void _validatePasswordInput(String password) {
    final length = password.runes.length;
    if (length < 1 || length > 1024) {
      throw const VaultException('bad_password', 'The password is invalid.');
    }
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final next = _tail.then((_) => operation());
    _tail = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  Uint8List _randomBytes(int length) {
    final random = math.Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }

  String _base64UrlNoPadding(List<int> bytes) {
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? -1;
  }

  void _zero(List<int>? bytes) {
    if (bytes == null) return;
    for (var index = 0; index < bytes.length; index++) {
      bytes[index] = 0;
    }
  }

  Future<void> _harden(File file) async {
    if (Platform.isWindows || !await file.exists()) return;
    try {
      await Process.run('chmod', <String>['600', file.path]);
    } catch (_) {}
  }
}

Future<Uint8List> _derivePasswordKey({
  required String password,
  required Uint8List salt,
  required int memoryKiB,
  required int iterations,
  required int parallelism,
}) async {
  if (salt.length < 16 ||
      memoryKiB < 64 ||
      memoryKiB > 256 * 1024 ||
      iterations < 1 ||
      iterations > 10 ||
      parallelism < 1 ||
      parallelism > 16) {
    throw const VaultException('unsafe_kdf', 'The vault settings are unsafe.');
  }

  final passwordBytes = Uint8List.fromList(utf8.encode(password));
  try {
    final bytes = await Isolate.run<List<int>>(() async {
      final algorithm = DartArgon2id(
        parallelism: parallelism,
        memory: memoryKiB,
        iterations: iterations,
        hashLength: 32,
        maxIsolates: 0,
        blocksPerProcessingChunk: -1,
      );
      final key = await algorithm.deriveKey(
        secretKey: SecretKey(passwordBytes),
        nonce: salt,
      );
      return key.extractBytes();
    });
    return Uint8List.fromList(bytes);
  } finally {
    for (var index = 0; index < passwordBytes.length; index++) {
      passwordBytes[index] = 0;
    }
  }
}
