import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:thought_circle/services/vault_service.dart';

void main() {
  test('vault encrypts, locks, and unlocks records', () async {
    final directory = await Directory.systemTemp.createTemp(
      'thought-circle-vault-',
    );
    addTearDown(() async => directory.delete(recursive: true));
    final vault = ThoughtVault.forTesting(directory);

    await vault.create('correct horse battery staple');
    await vault.writeJson('thoughts', 'active', <String, Object?>{
      'title': 'I need to organize my room',
    });

    expect(await vault.readJson('thoughts', 'active'), <String, Object?>{
      'title': 'I need to organize my room',
    });

    await vault.lock();
    expect(vault.isUnlocked, isFalse);

    await expectLater(
      vault.unlock('this password is incorrect'),
      throwsA(isA<VaultException>()),
    );

    await vault.unlock('correct horse battery staple');
    expect(await vault.readJson('thoughts', 'active'), <String, Object?>{
      'title': 'I need to organize my room',
    });
  });

  test('changing the password preserves encrypted records', () async {
    final directory = await Directory.systemTemp.createTemp(
      'thought-circle-rekey-',
    );
    addTearDown(() async => directory.delete(recursive: true));
    final vault = ThoughtVault.forTesting(directory);

    await vault.create('first password is long enough');
    await vault.writeJson('thoughts', 'one', <String>['small next step']);
    await vault.changePassword('second password is also long enough');
    await vault.lock();

    await expectLater(
      vault.unlock('first password is long enough'),
      throwsA(isA<VaultException>()),
    );
    await vault.unlock('second password is also long enough');
    expect(await vault.readJson('thoughts', 'one'), <String>[
      'small next step',
    ]);
  });

  test('changed ciphertext is rejected', () async {
    final directory = await Directory.systemTemp.createTemp(
      'thought-circle-tamper-',
    );
    addTearDown(() async => directory.delete(recursive: true));
    final vault = ThoughtVault.forTesting(directory);

    await vault.create('tamper test password is long enough');
    await vault.writeJson('thoughts', 'private', <String, Object?>{
      'title': 'This should never be visible in plaintext',
    });
    await vault.lock();

    final database = sqlite.sqlite3.open(
      '${directory.path}/thought_circle_vault.sqlite3',
    );
    database.execute(
      'UPDATE vault_records SET cipher_text = zeroblob(length(cipher_text))',
    );
    database.close();

    await expectLater(
      vault.unlock('tamper test password is long enough'),
      throwsA(isA<VaultException>()),
    );
  });
}
