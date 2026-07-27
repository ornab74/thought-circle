import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:path_provider/path_provider.dart';

import '../models/reflection.dart';
import '../models/thought.dart';

enum LocalAiState {
  unavailable,
  downloading,
  paused,
  readyToLoad,
  loading,
  ready,
  working,
  error,
}

final class GemmaService {
  static const String modelFileName = 'gemma-4-E2B-it.litertlm';
  static const String modelDownloadUrl =
      'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/7fa1d78473894f7e736a21d920c3aa80f950c0db/gemma-4-E2B-it.litertlm';
  static const String modelSha256 =
      'ab7838cdfc8f77e54d8ca45eadceb20452d9f01e4bfade03e5dce27911b27e42';
  static const int contextTokens = 2100;
  static const int _downloadChunkBytes = 8 * 1024 * 1024;
  static const int _maximumModelBytes = 6 * 1024 * 1024 * 1024;

  InferenceModel? _model;
  InferenceChat? _activeChat;
  bool _cancelRequested = false;
  HttpClient? _activeDownloadClient;
  bool _pauseRequested = false;
  LocalAiState state = LocalAiState.unavailable;
  String status = 'Add Gemma when you want the local guide.';
  String? error;
  double? installProgress;
  int downloadedBytes = 0;
  int totalDownloadBytes = 0;
  int lastChatInputTokens = 0;

  bool get isReady => state == LocalAiState.ready;
  bool get hasLoadedModel =>
      _model != null ||
      state == LocalAiState.ready ||
      state == LocalAiState.working;
  bool get isBusy =>
      state == LocalAiState.downloading ||
      state == LocalAiState.loading ||
      state == LocalAiState.working;
  bool get canPause => state == LocalAiState.downloading;
  bool get canResume => state == LocalAiState.paused || downloadedBytes > 0;

  String get downloadLabel {
    if (downloadedBytes <= 0) return '';
    final received = _formatBytes(downloadedBytes);
    if (totalDownloadBytes <= 0) return received;
    return '$received of ${_formatBytes(totalDownloadBytes)}';
  }

  Future<String> get installedModelPath async {
    final directory = await getApplicationSupportDirectory();
    return '${directory.path}/models/$modelFileName';
  }

  Future<void> initialize() async {
    try {
      await FlutterGemma.initialize(inferenceEngines: [LiteRtLmEngine()]);
      final installed = await FlutterGemma.listInstalledModels();
      if (installed.isNotEmpty) {
        state = LocalAiState.readyToLoad;
        status = 'Gemma is ready to start.';
      } else {
        await _restorePartialDownload();
      }
    } catch (exception) {
      state = LocalAiState.error;
      error = exception.toString();
      status = 'Gemma could not start here.';
    }
  }

  Future<void> installFromFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw FileSystemException('The selected model file was not found.', path);
    }
    if (!path.toLowerCase().endsWith('.litertlm')) {
      throw const FormatException('Choose a .litertlm Gemma model file.');
    }

    state = LocalAiState.loading;
    status = 'Checking the model file…';
    installProgress = null;
    error = null;

    final digest = await crypto.sha256.bind(file.openRead()).first;
    if (digest.toString().toLowerCase() != modelSha256) {
      state = LocalAiState.error;
      status = 'That model file did not pass the safety check.';
      throw const FormatException(
        'The selected file does not match the expected Gemma 4 E2B model.',
      );
    }

    try {
      status = 'Adding the local AI model…';
      await FlutterGemma.installModel(
        modelType: ModelType.gemma4,
        fileType: ModelFileType.litertlm,
      ).fromFile(path).install();
      state = LocalAiState.readyToLoad;
      installProgress = null;
      status = 'Local AI is installed and ready to load.';
    } catch (exception) {
      state = LocalAiState.error;
      error = exception.toString();
      status = 'The model could not be added.';
      rethrow;
    }
  }

  Future<void> downloadAndInstall({void Function()? onProgress}) async {
    final files = await _downloadFiles();
    _pauseRequested = false;
    error = null;
    state = LocalAiState.downloading;
    downloadedBytes = await files.partial.exists()
        ? await files.partial.length()
        : 0;
    status = downloadedBytes > 0 ? 'Resuming Gemma…' : 'Downloading Gemma…';
    installProgress = totalDownloadBytes > 0
        ? downloadedBytes / totalDownloadBytes
        : 0;
    onProgress?.call();

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 30)
      ..idleTimeout = const Duration(seconds: 45)
      ..userAgent = 'ThoughtCircle/0.2';
    _activeDownloadClient = client;
    try {
      while (totalDownloadBytes <= 0 || downloadedBytes < totalDownloadBytes) {
        if (_pauseRequested) {
          _markDownloadPaused(onProgress);
          return;
        }

        final end = downloadedBytes + _downloadChunkBytes - 1;
        final request = await client.getUrl(Uri.parse(modelDownloadUrl));
        request.followRedirects = true;
        request.maxRedirects = 8;
        request.headers.set(
          HttpHeaders.rangeHeader,
          'bytes=$downloadedBytes-$end',
        );
        final response = await request.close().timeout(
          const Duration(seconds: 90),
          onTimeout: () => throw TimeoutException(
            'The model server took too long to respond.',
          ),
        );

        if (response.statusCode == HttpStatus.requestedRangeNotSatisfiable &&
            totalDownloadBytes > 0 &&
            downloadedBytes >= totalDownloadBytes) {
          break;
        }
        if (response.statusCode != HttpStatus.partialContent &&
            response.statusCode != HttpStatus.ok) {
          throw HttpException(
            'The Gemma download returned ${response.statusCode}.',
            uri: Uri.parse(modelDownloadUrl),
          );
        }
        if (response.statusCode == HttpStatus.ok && downloadedBytes > 0) {
          await files.partial.writeAsBytes(const <int>[], flush: true);
          downloadedBytes = 0;
        }

        final serverSentFullFile = response.statusCode == HttpStatus.ok;
        totalDownloadBytes = _totalBytesFrom(response, downloadedBytes);
        if (totalDownloadBytes > _maximumModelBytes) {
          throw FileSystemException(
            'The Gemma download is unexpectedly large.',
            files.partial.path,
          );
        }

        final output = files.partial.openWrite(mode: FileMode.append);
        try {
          await for (final chunk in response.timeout(
            const Duration(seconds: 90),
            onTimeout: (sink) =>
                sink.addError(TimeoutException('The model download stalled.')),
          )) {
            if (_pauseRequested) break;
            output.add(chunk);
            downloadedBytes += chunk.length;
            installProgress = totalDownloadBytes > 0
                ? (downloadedBytes / totalDownloadBytes)
                      .clamp(0.0, 1.0)
                      .toDouble()
                : null;
            onProgress?.call();
          }
        } finally {
          await output.flush();
          await output.close();
        }
        await _saveDownloadState(files.stateFile);

        // Some mirrors ignore Range and return the complete file with 200.
        // It is already fully written, so do not request another range and
        // repeatedly truncate the partial file.
        if (serverSentFullFile) {
          totalDownloadBytes = downloadedBytes;
          installProgress = 1;
          onProgress?.call();
          break;
        }
      }

      if (_pauseRequested) {
        _markDownloadPaused(onProgress);
        return;
      }

      status = 'Checking Gemma…';
      installProgress = null;
      onProgress?.call();
      final digest = await crypto.sha256.bind(files.partial.openRead()).first;
      if (digest.toString().toLowerCase() != modelSha256) {
        await files.partial.delete();
        if (await files.stateFile.exists()) await files.stateFile.delete();
        downloadedBytes = 0;
        totalDownloadBytes = 0;
        throw const FormatException(
          'The Gemma file did not pass its file check. Download it again.',
        );
      }

      if (await files.complete.exists()) await files.complete.delete();
      await files.partial.rename(files.complete.path);
      if (await files.stateFile.exists()) await files.stateFile.delete();
      status = 'Finishing Gemma setup…';
      onProgress?.call();
      await FlutterGemma.installModel(
        modelType: ModelType.gemma4,
        fileType: ModelFileType.litertlm,
      ).fromFile(files.complete.path).install();
      state = LocalAiState.readyToLoad;
      installProgress = null;
      status = 'Gemma is ready to start.';
      onProgress?.call();
    } catch (exception) {
      if (_pauseRequested) {
        await _saveDownloadState(files.stateFile);
        _markDownloadPaused(onProgress);
        return;
      }
      await _saveDownloadState(files.stateFile);
      state = LocalAiState.error;
      error = exception.toString();
      status = downloadedBytes > 0
          ? 'Download stopped. Your progress is saved.'
          : 'Gemma could not be downloaded.';
      onProgress?.call();
      rethrow;
    } finally {
      client.close(force: true);
      if (identical(_activeDownloadClient, client)) {
        _activeDownloadClient = null;
      }
    }
  }

  void pauseDownload({void Function()? onProgress}) {
    if (state != LocalAiState.downloading) return;
    _pauseRequested = true;
    state = LocalAiState.paused;
    status = 'Download paused. Progress is saved.';
    _activeDownloadClient?.close(force: true);
    onProgress?.call();
  }

  Future<_DownloadFiles> _downloadFiles() async {
    final directory = Directory(
      '${(await getApplicationSupportDirectory()).path}/models',
    );
    await directory.create(recursive: true);
    final complete = File('${directory.path}/$modelFileName');
    return _DownloadFiles(
      complete: complete,
      partial: File('${complete.path}.part'),
      stateFile: File('${complete.path}.download.json'),
    );
  }

  Future<void> _restorePartialDownload() async {
    final files = await _downloadFiles();
    if (!await files.partial.exists()) return;
    downloadedBytes = await files.partial.length();
    if (await files.stateFile.exists()) {
      try {
        final raw = jsonDecode(await files.stateFile.readAsString());
        if (raw is Map) {
          totalDownloadBytes =
              int.tryParse(raw['total']?.toString() ?? '') ?? 0;
        }
      } catch (_) {
        totalDownloadBytes = 0;
      }
    }
    if (downloadedBytes > 0) {
      state = LocalAiState.paused;
      installProgress = totalDownloadBytes > 0
          ? (downloadedBytes / totalDownloadBytes).clamp(0.0, 1.0).toDouble()
          : null;
      status = 'Gemma download ready to resume.';
    }
  }

  Future<void> _saveDownloadState(File stateFile) async {
    if (downloadedBytes <= 0) return;
    await stateFile.writeAsString(
      jsonEncode(<String, Object?>{
        'url': modelDownloadUrl,
        'bytes': downloadedBytes,
        'total': totalDownloadBytes,
        'chunkBytes': _downloadChunkBytes,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      }),
      flush: true,
    );
  }

  int _totalBytesFrom(HttpClientResponse response, int offset) {
    final contentRange = response.headers.value(HttpHeaders.contentRangeHeader);
    if (contentRange != null) {
      final match = RegExp(r'/([0-9]+)$').firstMatch(contentRange);
      final total = int.tryParse(match?.group(1) ?? '');
      if (total != null) return total;
    }
    if (response.contentLength > 0) return offset + response.contentLength;
    return totalDownloadBytes;
  }

  void _markDownloadPaused(void Function()? onProgress) {
    state = LocalAiState.paused;
    status = 'Download paused. Progress is saved.';
    installProgress = totalDownloadBytes > 0
        ? (downloadedBytes / totalDownloadBytes).clamp(0.0, 1.0).toDouble()
        : null;
    onProgress?.call();
  }

  Future<void> load() async {
    if (_model != null) {
      state = LocalAiState.ready;
      status = 'Local AI is ready.';
      return;
    }
    state = LocalAiState.loading;
    status = 'Starting local AI…';
    error = null;
    try {
      final backend = Platform.isWindows || Platform.isLinux
          ? PreferredBackend.cpu
          : PreferredBackend.gpu;
      _model = await FlutterGemma.getActiveModel(
        maxTokens: contextTokens,
        preferredBackend: backend,
        maxConcurrentSessions: 2,
      );
      state = LocalAiState.ready;
      status = 'Local AI is ready.';
    } catch (firstError) {
      if (!Platform.isWindows) {
        try {
          _model = await FlutterGemma.getActiveModel(
            maxTokens: contextTokens,
            preferredBackend: PreferredBackend.cpu,
            maxConcurrentSessions: 2,
          );
          state = LocalAiState.ready;
          status = 'Local AI is ready.';
          return;
        } catch (_) {
          // Report the original error because it normally has the best context.
        }
      }
      state = LocalAiState.error;
      error = firstError.toString();
      status = 'Local AI could not load on this device.';
      rethrow;
    }
  }

  Future<ThoughtPlan> makePlan(
    Thought thought, {
    required List<MoodColorEntry> moodColors,
  }) async {
    final model = _model;
    if (model == null || !isReady) {
      throw StateError('Load local AI before asking it to make a plan.');
    }

    state = LocalAiState.working;
    status = 'Making a calm, practical plan…';
    error = null;
    InferenceChat? chat;
    try {
      chat = await model.openChat(
        modelType: ModelType.gemma4,
        systemInstruction: _systemInstruction,
        maxOutputTokens: 460,
        temperature: 0.25,
        topK: 20,
        topP: 0.9,
        randomSeed: 7,
        isThinking: false,
      );
      await chat.addQueryChunk(
        Message.text(text: _promptFor(thought, moodColors), isUser: true),
      );

      final output = StringBuffer();
      await for (final response in chat.generateChatResponseAsync()) {
        if (response is TextResponse) output.write(response.token);
      }
      final plan = _parsePlan(output.toString(), thought);
      state = LocalAiState.ready;
      status = 'Local AI is ready.';
      return plan;
    } catch (exception) {
      _recoverAfterInferenceError(
        exception,
        'A plan could not be made this time.',
      );
      rethrow;
    } finally {
      await chat?.close();
    }
  }

  Future<JournalAiResult> shapeJournal({
    required String note,
    required JournalMood mood,
    required List<Thought> circle,
    required List<MoodColorEntry> moodColors,
    Uint8List? audioBytes,
  }) async {
    final model = _requireModel();
    state = LocalAiState.working;
    status = audioBytes == null ? 'Shaping your note…' : 'Listening…';
    error = null;
    InferenceChat? chat;
    try {
      chat = await model.openChat(
        modelType: ModelType.gemma4,
        systemInstruction: _journalSystemInstruction,
        maxOutputTokens: 440,
        temperature: 0.2,
        topK: 18,
        topP: 0.9,
        randomSeed: 11,
        isThinking: false,
      );
      final prompt = _journalPrompt(
        note,
        mood,
        circle,
        moodColors,
        audioBytes != null,
      );
      await chat.addQueryChunk(
        audioBytes == null
            ? Message.text(text: prompt, isUser: true)
            : Message.withAudio(
                text: prompt,
                audioBytes: audioBytes,
                isUser: true,
              ),
      );
      final raw = await _collect(chat);
      final result = _parseJournal(raw, note);
      state = LocalAiState.ready;
      status = 'Gemma is ready.';
      return result;
    } catch (exception) {
      _recoverAfterInferenceError(
        exception,
        'The note could not be shaped this time.',
      );
      rethrow;
    } finally {
      await chat?.close();
    }
  }

  Future<GuideReply> replyToGuide({
    required List<ChatTurn> history,
    required String message,
    required GuideMode mode,
    required List<Thought> circle,
    required List<MoodColorEntry> moodColors,
    void Function(String token)? onToken,
  }) async {
    final model = _requireModel();
    state = LocalAiState.working;
    status = 'Thinking with you…';
    error = null;
    InferenceChat? chat;
    try {
      _cancelRequested = false;
      final prompt = _rollingGuidePrompt(
        history,
        message,
        mode,
        circle,
        moodColors,
      );
      lastChatInputTokens = _estimateTokens(
        '$_guideSystemInstruction\n$prompt',
      );
      chat = await model.openChat(
        modelType: ModelType.gemma4,
        systemInstruction: _guideSystemInstruction,
        maxOutputTokens: 340,
        temperature: 0.35,
        topK: 24,
        topP: 0.9,
        randomSeed: 19,
        isThinking: false,
      );
      _activeChat = chat;
      await chat.addQueryChunk(Message.text(text: prompt, isUser: true));
      final raw = await _collect(chat, onToken: onToken);
      if (_cancelRequested) {
        throw const _GenerationCancelled();
      }
      final text = _clean(raw, 1300);
      state = LocalAiState.ready;
      status = 'Gemma is ready.';
      return GuideReply(
        text: text.isEmpty
            ? 'I’m here. What feels most important in this moment?'
            : text,
        inputTokens: lastChatInputTokens,
      );
    } catch (exception) {
      _recoverAfterInferenceError(
        exception,
        'The guide could not reply this time.',
      );
      rethrow;
    } finally {
      if (identical(_activeChat, chat)) _activeChat = null;
      await chat?.close();
    }
  }

  Future<void> cancelCurrentGeneration() async {
    _cancelRequested = true;
    final chat = _activeChat;
    _activeChat = null;
    await chat?.close();
  }

  Future<void> close() async {
    await _model?.close();
    _model = null;
    state = LocalAiState.readyToLoad;
    status = 'Gemma is ready to start.';
  }

  InferenceModel _requireModel() {
    final model = _model;
    if (model == null || !isReady) {
      throw StateError('Start Gemma before using the local guide.');
    }
    return model;
  }

  Future<String> _collect(
    InferenceChat chat, {
    void Function(String token)? onToken,
  }) async {
    final output = StringBuffer();
    await for (final response in chat.generateChatResponseAsync()) {
      if (response is TextResponse) {
        output.write(response.token);
        onToken?.call(response.token);
      }
    }
    return output.toString();
  }

  String _journalPrompt(
    String note,
    JournalMood mood,
    List<Thought> circle,
    List<MoodColorEntry> moodColors,
    bool hasAudio,
  ) {
    final loops = circle
        .where((item) => item.state == ThoughtState.active)
        .take(5)
        .map((item) => _clean(item.title, 80))
        .join(' | ');
    return '''
${hasAudio ? 'Transcribe the attached voice note first.' : 'Shape this written note.'}
Mood: ${mood.name}
Recent mood colors: ${_moodColorContext(moodColors)}
Active circle: ${loops.isEmpty ? 'none' : loops}
Note: ${_clean(note, 1800)}

Return JSON only:
{
  "title": "2-6 words",
  "transcript": "clean transcript or original note",
  "summary": "one warm, useful paragraph under 70 words",
  "highlights": ["short point", "short point", "short point"],
  "circleMatch": "exact active circle title or empty"
}

''';
  }

  JournalAiResult _parseJournal(String raw, String fallbackBody) {
    final map = _jsonMap(raw);
    final transcript = _clean(
      map?['transcript']?.toString() ?? fallbackBody,
      5000,
    );
    final rawHighlights = map?['highlights'];
    final highlights = rawHighlights is List
        ? rawHighlights
              .map((item) => _clean(item.toString(), 130))
              .where((item) => item.isNotEmpty)
              .take(4)
              .toList(growable: false)
        : const <String>[];
    final fallbackSummary = transcript.isEmpty
        ? 'A moment saved for later reflection.'
        : _clean(transcript, 320);
    return JournalAiResult(
      title: _clean(map?['title']?.toString() ?? 'Daily note', 80),
      transcript: transcript,
      summary: _clean(map?['summary']?.toString() ?? fallbackSummary, 520),
      highlights: highlights,
      circleMatch: _clean(map?['circleMatch']?.toString() ?? '', 120),
    );
  }

  String _rollingGuidePrompt(
    List<ChatTurn> history,
    String message,
    GuideMode mode,
    List<Thought> circle,
    List<MoodColorEntry> moodColors,
  ) {
    const promptBudget = 1450;
    final modeInstruction = switch (mode) {
      GuideMode.reflect =>
        'Reflect what matters, ask at most one gentle question, and stay concise.',
      GuideMode.circle =>
        'Help connect this message to the active circle without diagnosing.',
      GuideMode.nextStep =>
        'End with one realistic action that takes under five minutes.',
    };
    final loops = circle
        .where((item) => item.state == ThoughtState.active)
        .take(5)
        .map((item) => _clean(item.title, 70))
        .join(' | ');
    final current = _clean(message, 1400);
    final header =
        '''
Mode: ${mode.name}
Direction: $modeInstruction
Active circle: ${loops.isEmpty ? 'none' : loops}
Recent mood colors: ${_moodColorContext(moodColors)}
Recent conversation:
''';
    const footerPrefix = '\nCurrent message: ';
    var used = _estimateTokens('$header$footerPrefix$current');
    final selected = <String>[];
    for (final turn in history.reversed.take(16)) {
      final line =
          '${turn.role == ChatRole.user ? 'Person' : 'Guide'}: '
          '${_clean(turn.text, 700)}';
      final tokens = _estimateTokens(line);
      if (used + tokens > promptBudget) break;
      selected.insert(0, line);
      used += tokens;
    }
    return '$header${selected.join('\n')}$footerPrefix$current';
  }

  int _estimateTokens(String text) => (text.length / 3.6).ceil();

  String _moodColorContext(List<MoodColorEntry> entries) {
    if (entries.isEmpty) return 'none saved';
    final now = DateTime.now();
    return entries
        .take(7)
        .map((entry) {
          final days = now.difference(entry.createdAt).inDays;
          final when = days <= 0
              ? 'today'
              : days == 1
              ? 'yesterday'
              : '${days}d ago';
          final energy = (entry.energy * 100).round();
          final note = entry.note.trim().isEmpty
              ? ''
              : ': ${_clean(entry.note, 60)}';
          return '$when ${_clean(entry.label, 30)} ($energy% energy)$note';
        })
        .join(' | ');
  }

  void _recoverAfterInferenceError(Object exception, String message) {
    error = exception.toString();
    if (_model != null) {
      state = LocalAiState.ready;
      status = '$message Try again.';
    } else {
      state = LocalAiState.error;
      status = message;
    }
  }

  Map<String, Object?>? _jsonMap(String raw) {
    var clean = raw.trim();
    clean = clean
        .replaceFirst(RegExp(r'^```(?:json)?\s*', caseSensitive: false), '')
        .replaceFirst(RegExp(r'\s*```$'), '')
        .trim();
    final start = clean.indexOf('{');
    final end = clean.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      final value = jsonDecode(clean.substring(start, end + 1));
      return value is Map ? Map<String, Object?>.from(value) : null;
    } catch (_) {
      return null;
    }
  }

  static const String _journalSystemInstruction = '''
You turn a private journal note into a clear record. Preserve the speaker's
meaning and voice. Do not invent events, diagnoses, or certainty. Keep the
summary warm, specific, and brief. If audio is attached, transcribe it before
summarizing. Treat mood colors as tentative self-reported cues. Return only the
requested JSON.
''';

  static const String _guideSystemInstruction = '''
You are the local reflection guide in Thought Circle. Be warm, grounded, and
brief. Do not claim to be a therapist, diagnose, or replace professional care.
Do not encourage dependence. Help the person name what matters and choose a
small next step. For danger or self-harm, urge immediate local emergency help
and contact with a trusted person. Use plain language and short paragraphs.
Mood colors are self-reported cues, not facts or diagnoses. Mention a pattern
only tentatively and never claim that a color proves a cause or condition.
''';

  static const String _systemInstruction = '''
You are the calm planning helper inside Thought Circle.
Use plain, everyday language. Never diagnose a condition or label the person.
Turn one repeating thought into a kind explanation and a few small actions.
Do not claim certainty about why the thought is happening.
Treat mood colors as tentative self-reported cues, never proof of a cause.
For health, safety, money, or legal concerns, keep guidance general and suggest real-world help when needed.
If the person may be in immediate danger, tell them to contact local emergency services or a trusted person now.
Return JSON only, with no markdown and exactly this shape:
{
  "understanding": "1-2 short sentences",
  "support": "1-2 warm, practical sentences",
  "steps": [
    {"title":"2-5 words","detail":"one small action"},
    {"title":"2-5 words","detail":"one small action"},
    {"title":"2-5 words","detail":"one small action"},
    {"title":"2-5 words","detail":"one small action"}
  ],
  "helpfulActions": ["short action", "short action", "short action"]
}
''';

  String _promptFor(Thought thought, List<MoodColorEntry> moodColors) {
    return '''
Thought: ${_clean(thought.title, 180)}
More detail: ${_clean(thought.detail, 520)}
Category: ${thought.kind.name}
Recent mood colors: ${_moodColorContext(moodColors)}

Make a gentle plan that can be started in under five minutes. Avoid fancy terms.
''';
  }

  ThoughtPlan _parsePlan(String raw, Thought thought) {
    var clean = raw.trim();
    clean = clean
        .replaceFirst(RegExp(r'^```(?:json)?\s*', caseSensitive: false), '')
        .replaceFirst(RegExp(r'\s*```$'), '')
        .trim();
    final start = clean.indexOf('{');
    final end = clean.lastIndexOf('}');
    if (start < 0 || end <= start) return starterPlanFor(thought);

    try {
      final decoded = jsonDecode(clean.substring(start, end + 1));
      if (decoded is! Map) return starterPlanFor(thought);
      final map = Map<String, Object?>.from(decoded);
      final rawSteps = map['steps'];
      final rawActions = map['helpfulActions'];
      final steps = <ThoughtStep>[];
      if (rawSteps is List) {
        for (var index = 0; index < rawSteps.length && index < 5; index++) {
          final item = rawSteps[index];
          if (item is! Map) continue;
          final step = Map<String, Object?>.from(item);
          final title = _clean(step['title']?.toString() ?? '', 80);
          final detail = _clean(step['detail']?.toString() ?? '', 220);
          if (title.isEmpty || detail.isEmpty) continue;
          steps.add(
            ThoughtStep(
              id: '${thought.id}-ai-${DateTime.now().microsecondsSinceEpoch}-$index',
              title: title,
              detail: detail,
            ),
          );
        }
      }
      if (steps.length < 2) return starterPlanFor(thought);
      final actions = rawActions is List
          ? rawActions
                .map((item) => _clean(item.toString(), 120))
                .where((item) => item.isNotEmpty)
                .take(4)
                .toList(growable: false)
          : const <String>[];
      return ThoughtPlan(
        understanding: _clean(
          map['understanding']?.toString() ??
              'This thought may be asking for your attention.',
          420,
        ),
        support: _clean(
          map['support']?.toString() ??
              'You do not need to solve everything at once.',
          420,
        ),
        steps: steps,
        helpfulActions: actions,
        createdAt: DateTime.now(),
      );
    } catch (_) {
      return starterPlanFor(thought);
    }
  }

  static String _clean(String value, int maxLength) {
    final text = value
        .replaceAll(RegExp(r'[\u0000-\u001F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength).trimRight()}…';
  }

  static String _formatBytes(int bytes) {
    const gib = 1024 * 1024 * 1024;
    const mib = 1024 * 1024;
    if (bytes >= gib) return '${(bytes / gib).toStringAsFixed(2)} GB';
    return '${(bytes / mib).toStringAsFixed(0)} MB';
  }
}

final class JournalAiResult {
  const JournalAiResult({
    required this.title,
    required this.transcript,
    required this.summary,
    required this.highlights,
    required this.circleMatch,
  });

  final String title;
  final String transcript;
  final String summary;
  final List<String> highlights;
  final String circleMatch;
}

final class GuideReply {
  const GuideReply({required this.text, required this.inputTokens});

  final String text;
  final int inputTokens;
}

final class _DownloadFiles {
  const _DownloadFiles({
    required this.complete,
    required this.partial,
    required this.stateFile,
  });

  final File complete;
  final File partial;
  final File stateFile;
}

ThoughtPlan starterPlanFor(Thought thought) {
  final steps = switch (thought.kind) {
    ThoughtKind.body => const <(String, String)>[
      ('Pause and check in', 'Notice whether you need food, water, or rest.'),
      (
        'Choose one thing',
        'Pick the smallest helpful choice you can make now.',
      ),
      ('Take care of your body', 'Have a simple snack, drink water, or rest.'),
      ('Check again', 'See how the thought feels in ten minutes.'),
    ],
    ThoughtKind.home => const <(String, String)>[
      ('Pick one tiny area', 'Choose one shelf, corner, or small surface.'),
      (
        'Set five minutes',
        'Stop when the timer ends, even if it is not perfect.',
      ),
      ('Sort three ways', 'Use keep, move, and throw away piles.'),
      ('Notice the win', 'Take a breath and look at what changed.'),
    ],
    ThoughtKind.work => const <(String, String)>[
      (
        'Name the next task',
        'Write one action that takes less than ten minutes.',
      ),
      ('Hide the rest', 'Close extra tabs and put the longer list aside.'),
      (
        'Work for five minutes',
        'Start before deciding whether you feel ready.',
      ),
      ('Choose what follows', 'Continue, pause, or ask someone for help.'),
    ],
    ThoughtKind.people => const <(String, String)>[
      ('Name the fear', 'Write what you are worried someone may think.'),
      (
        'Check what is known',
        'Separate facts from guesses about their reaction.',
      ),
      (
        'Choose your value',
        'Decide how you want to act regardless of judgment.',
      ),
      (
        'Take one honest step',
        'Send, say, or do the smallest respectful action.',
      ),
    ],
    ThoughtKind.worry || ThoughtKind.other => const <(String, String)>[
      (
        'Slow the moment',
        'Take three steady breaths and relax your shoulders.',
      ),
      ('Write the thought', 'Put the exact worry into one short sentence.'),
      ('Circle what you control', 'Choose one part you can affect today.'),
      (
        'Take one small step',
        'Do the easiest useful action, then check in again.',
      ),
    ],
  };
  return ThoughtPlan(
    understanding:
        'This thought is taking up attention because something feels unfinished, uncertain, or important.',
    support:
        'You do not have to solve the whole thing right now. A small next step is enough.',
    steps: <ThoughtStep>[
      for (var index = 0; index < steps.length; index++)
        ThoughtStep(
          id: '${thought.id}-starter-$index',
          title: steps[index].$1,
          detail: steps[index].$2,
        ),
    ],
    helpfulActions: const <String>[
      'Drink a glass of water',
      'Set a five-minute timer',
      'Write one sentence',
    ],
    createdAt: DateTime.now(),
  );
}

final class _GenerationCancelled implements Exception {
  const _GenerationCancelled();
}
