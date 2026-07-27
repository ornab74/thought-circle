import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/reflection.dart';
import '../models/thought.dart';
import '../services/gemma_service.dart';
import '../services/thought_repository.dart';
import '../services/vault_service.dart';

final class AppController extends ChangeNotifier {
  AppController({ThoughtVault? vault, GemmaService? gemma})
    : vault = vault ?? ThoughtVault.instance,
      gemma = gemma ?? GemmaService() {
    repository = ThoughtRepository(this.vault);
  }

  final ThoughtVault vault;
  final GemmaService gemma;
  late final ThoughtRepository repository;
  final Uuid _uuid = Uuid();
  Future<void>? _modelInitialization;

  VaultAccess vaultAccess = VaultAccess.locked;
  List<Thought> thoughts = const <Thought>[];
  List<JournalEntry> journalEntries = const <JournalEntry>[];
  List<ChatTurn> guideTurns = const <ChatTurn>[];
  List<MoodColorEntry> moodColors = const <MoodColorEntry>[];
  bool onboardingComplete = false;
  bool busy = false;
  bool journalBusy = false;
  bool guideBusy = false;
  String guideStreamingText = '';
  bool modelInitialized = false;
  String? message;
  Map<String, Object?>? localModelMetadata;

  List<Thought> get activeThoughts => thoughts
      .where((thought) => thought.state == ThoughtState.active)
      .toList(growable: false);

  int get completedSteps => thoughts
      .expand((thought) => thought.plan?.steps ?? const <ThoughtStep>[])
      .where((step) => step.done)
      .length;

  int get totalSteps => thoughts
      .expand((thought) => thought.plan?.steps ?? const <ThoughtStep>[])
      .length;

  List<JournalEntry> get todayJournalEntries {
    final now = DateTime.now();
    return journalEntries
        .where(
          (entry) =>
              entry.createdAt.year == now.year &&
              entry.createdAt.month == now.month &&
              entry.createdAt.day == now.day,
        )
        .toList(growable: false);
  }

  int get guideContextTokens => gemma.lastChatInputTokens;

  Future<void> initialize() async {
    final inspection = await vault.inspect();
    vaultAccess = inspection.access;
    notifyListeners();
  }

  Future<void> initializeModel() async {
    if (modelInitialized) return;
    final active = _modelInitialization;
    if (active != null) return active;
    final operation = () async {
      await gemma.initialize();
      modelInitialized = true;
      notifyListeners();
    }();
    _modelInitialization = operation;
    try {
      await operation;
    } finally {
      _modelInitialization = null;
    }
  }

  Future<void> createVault(String password) async {
    await _run(() async {
      await vault.create(password);
      vaultAccess = VaultAccess.unlocked;
      thoughts = _demoThoughts();
      await repository.save(thoughts);
      journalEntries = const <JournalEntry>[];
      guideTurns = const <ChatTurn>[];
      moodColors = const <MoodColorEntry>[];
      onboardingComplete = false;
      await repository.saveJournal(journalEntries);
      await repository.saveChat(guideTurns);
      await repository.saveMoodColors(moodColors);
      await repository.saveOnboardingComplete(false);
    }, success: 'Your circle is ready.');
  }

  Future<void> unlock(String password) async {
    await _run(() async {
      await vault.unlock(password);
      vaultAccess = VaultAccess.unlocked;
      thoughts = await repository.load();
      if (thoughts.isEmpty) {
        thoughts = _demoThoughts();
        await repository.save(thoughts);
      }
      journalEntries = await repository.loadJournal();
      guideTurns = await repository.loadChat();
      moodColors = await repository.loadMoodColors();
      localModelMetadata = await repository.loadModelMetadata();
      onboardingComplete = await repository.loadOnboardingComplete();
    });
  }

  Future<void> lock() async {
    await _run(() async {
      await vault.lock();
      vaultAccess = VaultAccess.locked;
      thoughts = const <Thought>[];
      journalEntries = const <JournalEntry>[];
      guideTurns = const <ChatTurn>[];
      moodColors = const <MoodColorEntry>[];
      onboardingComplete = false;
    });
  }

  Future<void> changePassword(String password) async {
    await _run(
      () => vault.changePassword(password),
      success: 'Startup password changed.',
    );
  }

  Future<void> finishOnboarding() async {
    onboardingComplete = true;
    await repository.saveOnboardingComplete(true);
    notifyListeners();
  }

  Future<void> restartOnboarding() async {
    onboardingComplete = false;
    await repository.saveOnboardingComplete(false);
    notifyListeners();
  }

  Future<Thought> addThought({
    required String title,
    required String detail,
    required ThoughtKind kind,
  }) async {
    final now = DateTime.now();
    final thought = Thought(
      id: _uuid.v4(),
      title: title.trim(),
      detail: detail.trim(),
      kind: kind,
      state: ThoughtState.active,
      createdAt: now,
      updatedAt: now,
      plan: null,
    );
    thoughts = <Thought>[thought, ...thoughts];
    await repository.save(thoughts);
    notifyListeners();
    return thought;
  }

  Future<void> updateThought(Thought updated) async {
    thoughts = <Thought>[
      for (final thought in thoughts)
        if (thought.id == updated.id) updated else thought,
    ];
    await repository.save(thoughts);
    notifyListeners();
  }

  Future<void> deleteThought(String id) async {
    thoughts = thoughts.where((thought) => thought.id != id).toList();
    await repository.save(thoughts);
    notifyListeners();
  }

  Thought? findThought(String id) {
    for (final thought in thoughts) {
      if (thought.id == id) return thought;
    }
    return null;
  }

  Future<void> makeStarterPlan(String id) async {
    final thought = findThought(id);
    if (thought == null) return;
    await updateThought(thought.copyWith(plan: starterPlanFor(thought)));
  }

  Future<void> makeAiPlan(String id) async {
    final thought = findThought(id);
    if (thought == null) return;
    await _run(() async {
      final plan = await gemma.makePlan(thought, moodColors: moodColors);
      await updateThought(thought.copyWith(plan: plan));
    }, success: 'Your new plan is ready.');
  }

  Future<JournalEntry> addJournalEntry({
    required String note,
    required JournalMood mood,
    String? linkedThoughtId,
  }) async {
    final cleaned = note.trim();
    if (cleaned.isEmpty) {
      throw ArgumentError('Write a few words first.');
    }
    journalBusy = true;
    notifyListeners();
    try {
      JournalAiResult result;
      if (gemma.isReady) {
        result = await gemma.shapeJournal(
          note: cleaned,
          mood: mood,
          circle: thoughts,
          moodColors: moodColors,
        );
      } else {
        result = JournalAiResult(
          title: _journalTitle(cleaned),
          transcript: cleaned,
          summary: cleaned.length <= 260
              ? cleaned
              : '${cleaned.substring(0, 257).trimRight()}…',
          highlights: const <String>[],
          circleMatch: '',
        );
      }
      final entry = _saveJournalResult(
        result,
        mood: mood,
        source: JournalSource.typed,
        linkedThoughtId: linkedThoughtId,
      );
      await repository.saveJournal(journalEntries);
      return entry;
    } finally {
      journalBusy = false;
      notifyListeners();
    }
  }

  Future<JournalEntry> addVoiceJournal({
    required Uint8List audioBytes,
    required JournalMood mood,
    String note = '',
    String? linkedThoughtId,
  }) async {
    if (!gemma.isReady) {
      throw StateError('Start Gemma before shaping a voice note.');
    }
    journalBusy = true;
    notifyListeners();
    try {
      final result = await gemma.shapeJournal(
        note: note,
        mood: mood,
        circle: thoughts,
        moodColors: moodColors,
        audioBytes: audioBytes,
      );
      final entry = _saveJournalResult(
        result,
        mood: mood,
        source: JournalSource.voice,
        linkedThoughtId: linkedThoughtId,
      );
      await repository.saveJournal(journalEntries);
      return entry;
    } finally {
      journalBusy = false;
      notifyListeners();
    }
  }

  Future<JournalEntry> makeDailyReview() async {
    final source = todayJournalEntries
        .where((entry) => entry.source != JournalSource.dailyReview)
        .toList(growable: false);
    if (source.isEmpty) {
      throw StateError('Add a note before making today’s review.');
    }
    if (!gemma.isReady) {
      throw StateError('Start Gemma before making a daily review.');
    }
    final note = source
        .map((entry) => '${entry.title}: ${entry.summary}')
        .join('\n');
    journalBusy = true;
    notifyListeners();
    try {
      final result = await gemma.shapeJournal(
        note: 'Create a concise daily review from these notes:\n$note',
        mood: source.last.mood,
        circle: thoughts,
        moodColors: moodColors,
      );
      final entry = _saveJournalResult(
        result,
        mood: source.last.mood,
        source: JournalSource.dailyReview,
      );
      await repository.saveJournal(journalEntries);
      return entry;
    } finally {
      journalBusy = false;
      notifyListeners();
    }
  }

  Future<void> deleteJournalEntry(String id) async {
    journalEntries = journalEntries
        .where((entry) => entry.id != id)
        .toList(growable: false);
    await repository.saveJournal(journalEntries);
    notifyListeners();
  }

  Future<MoodColorEntry> addMoodColor({
    required int colorValue,
    required String label,
    required double energy,
    String note = '',
  }) async {
    final entry = MoodColorEntry(
      id: _uuid.v4(),
      colorValue: colorValue,
      label: label.trim().isEmpty ? 'Mixed' : label.trim(),
      energy: energy.clamp(0.0, 1.0).toDouble(),
      createdAt: DateTime.now(),
      note: note.trim(),
    );
    moodColors = <MoodColorEntry>[entry, ...moodColors];
    await repository.saveMoodColors(moodColors);
    notifyListeners();
    return entry;
  }

  Future<void> deleteMoodColor(String id) async {
    moodColors = moodColors
        .where((entry) => entry.id != id)
        .toList(growable: false);
    await repository.saveMoodColors(moodColors);
    notifyListeners();
  }

  Future<void> sendGuideMessage(String text, GuideMode mode) async {
    final input = text.trim();
    if (input.isEmpty || guideBusy) return;
    final userTurn = ChatTurn(
      id: _uuid.v4(),
      role: ChatRole.user,
      text: input,
      createdAt: DateTime.now(),
    );
    guideTurns = <ChatTurn>[...guideTurns, userTurn];
    await repository.saveChat(guideTurns);
    guideBusy = true;
    guideStreamingText = '';
    message = null;
    notifyListeners();
    try {
      if (!gemma.isReady) {
        throw StateError('Start Gemma before opening the guide.');
      }
      final reply = await gemma.replyToGuide(
        history: guideTurns.length > 1
            ? guideTurns.sublist(0, guideTurns.length - 1)
            : const <ChatTurn>[],
        message: userTurn.text,
        mode: mode,
        circle: thoughts,
        moodColors: moodColors,
        onToken: (token) {
          guideStreamingText += token;
          notifyListeners();
        },
      );
      guideTurns = <ChatTurn>[
        ...guideTurns,
        ChatTurn(
          id: _uuid.v4(),
          role: ChatRole.guide,
          text: reply.text,
          createdAt: DateTime.now(),
        ),
      ];
      await repository.saveChat(guideTurns);
    } catch (exception) {
      message = _friendlyError(exception);
      rethrow;
    } finally {
      guideBusy = false;
      guideStreamingText = '';
      notifyListeners();
    }
  }

  Future<void> clearGuideChat() async {
    guideTurns = const <ChatTurn>[];
    await repository.saveChat(guideTurns);
    notifyListeners();
  }

  Future<void> stopGuideChat() async {
    if (!guideBusy) return;
    await gemma.cancelCurrentGeneration();
    guideBusy = false;
    message = null;
    notifyListeners();
  }

  Future<void> toggleStep(String thoughtId, String stepId) async {
    final thought = findThought(thoughtId);
    final plan = thought?.plan;
    if (thought == null || plan == null) return;
    final updatedPlan = ThoughtPlan(
      understanding: plan.understanding,
      support: plan.support,
      steps: <ThoughtStep>[
        for (final step in plan.steps)
          if (step.id == stepId) step.copyWith(done: !step.done) else step,
      ],
      helpfulActions: plan.helpfulActions,
      createdAt: plan.createdAt,
    );
    await updateThought(thought.copyWith(plan: updatedPlan));
  }

  Future<void> settleThought(String id) async {
    final thought = findThought(id);
    if (thought == null) return;
    await updateThought(thought.copyWith(state: ThoughtState.settled));
  }

  Future<void> restoreThought(String id) async {
    final thought = findThought(id);
    if (thought == null) return;
    await updateThought(thought.copyWith(state: ThoughtState.active));
  }

  Future<void> chooseAndInstallModel() async {
    await initializeModel();
    const group = XTypeGroup(
      label: 'Gemma LiteRT-LM model',
      extensions: <String>['litertlm'],
    );
    final file = await openFile(acceptedTypeGroups: const <XTypeGroup>[group]);
    if (file == null) return;
    await _run(
      () => gemma.installFromFile(file.path),
      success: 'The local AI model was added.',
    );
  }

  Future<void> downloadModel() async {
    await initializeModel();
    if (gemma.state == LocalAiState.readyToLoad || gemma.isReady) {
      message = 'Gemma is already downloaded.';
      notifyListeners();
      return;
    }
    busy = true;
    message = null;
    notifyListeners();
    try {
      await gemma.downloadAndInstall(onProgress: notifyListeners);
      if (gemma.state != LocalAiState.paused) {
        message = 'Gemma is downloaded.';
        final path = await gemma.installedModelPath;
        localModelMetadata = <String, Object?>{
          'path': path,
          'sha256': GemmaService.modelSha256,
          'verifiedAt': DateTime.now().toUtc().toIso8601String(),
        };
        await repository.saveModelMetadata(
          path: path,
          sha256: GemmaService.modelSha256,
        );
      }
    } catch (exception) {
      message = _friendlyError(exception);
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void pauseModelDownload() {
    gemma.pauseDownload(onProgress: notifyListeners);
  }

  Future<void> loadModel() async {
    await initializeModel();
    await _run(gemma.load, success: 'Local AI is ready.');
  }

  Future<void> closeModel() async {
    await initializeModel();
    await _run(gemma.close, success: 'Local AI was closed.');
  }

  void clearMessage() {
    message = null;
  }

  Future<void> _run(
    Future<void> Function() operation, {
    String? success,
  }) async {
    busy = true;
    message = null;
    notifyListeners();
    try {
      await operation();
      message = success;
    } catch (exception) {
      message = _friendlyError(exception);
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  String _friendlyError(Object exception) {
    if (exception is VaultException) return exception.message;
    final text = exception.toString();
    if (text.contains('SecretBoxAuthenticationError')) {
      return 'That password did not unlock your private data.';
    }
    return text
        .replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '')
        .replaceFirst(RegExp(r'^Bad state:\s*'), '');
  }

  JournalEntry _saveJournalResult(
    JournalAiResult result, {
    required JournalMood mood,
    required JournalSource source,
    String? linkedThoughtId,
  }) {
    var thoughtId = linkedThoughtId;
    if ((thoughtId == null || thoughtId.isEmpty) &&
        result.circleMatch.isNotEmpty) {
      final match = thoughts.where(
        (thought) =>
            thought.title.toLowerCase() == result.circleMatch.toLowerCase(),
      );
      if (match.isNotEmpty) thoughtId = match.first.id;
    }
    final now = DateTime.now();
    final entry = JournalEntry(
      id: _uuid.v4(),
      title: result.title.isEmpty ? 'Daily note' : result.title,
      body: result.transcript,
      summary: result.summary,
      highlights: result.highlights,
      source: source,
      mood: mood,
      createdAt: now,
      updatedAt: now,
      linkedThoughtId: thoughtId,
    );
    journalEntries = <JournalEntry>[entry, ...journalEntries];
    return entry;
  }

  String _journalTitle(String note) {
    final firstLine = note.split(RegExp(r'[\n.!?]')).first.trim();
    if (firstLine.isEmpty) return 'Daily note';
    if (firstLine.length <= 48) return firstLine;
    return '${firstLine.substring(0, 45).trimRight()}…';
  }

  List<Thought> _demoThoughts() {
    final now = DateTime.now();
    Thought thought(String title, String detail, ThoughtKind kind, int offset) {
      return Thought(
        id: _uuid.v4(),
        title: title,
        detail: detail,
        kind: kind,
        state: ThoughtState.active,
        createdAt: now.subtract(Duration(minutes: offset)),
        updatedAt: now.subtract(Duration(minutes: offset)),
      );
    }

    return <Thought>[
      thought('I’m hungry', 'I keep thinking about food.', ThoughtKind.body, 1),
      thought(
        'I need to organize my room',
        'It feels messy and overwhelming.',
        ThoughtKind.home,
        2,
      ),
      thought(
        'I can’t stop overthinking',
        'My mind keeps going over the same things.',
        ThoughtKind.worry,
        3,
      ),
      thought(
        'What will people think of me?',
        'I keep worrying about being judged.',
        ThoughtKind.people,
        4,
      ),
      thought(
        'I’m behind on work',
        'I feel like I should be doing more.',
        ThoughtKind.work,
        5,
      ),
    ];
  }
}
