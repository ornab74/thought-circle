import '../models/orbital_workspace.dart';
import '../models/reflection.dart';
import '../models/thought.dart';
import 'vault_service.dart';

final class ThoughtRepository {
  ThoughtRepository(this._vault);

  final ThoughtVault _vault;

  static const String _namespace = 'thought-circle';
  static const String _thoughtsKey = 'thoughts';
  static const String _journalKey = 'journal';
  static const String _chatKey = 'guide-chat';
  static const String _moodColorsKey = 'mood-colors';
  static const String _onboardingKey = 'onboarding-complete';
  static const String _modelKey = 'local-guide-model';
  static const String _orbitalWorkspaceKey = 'orbital-workspace-v1';

  Future<Map<String, Object?>?> loadModelMetadata() async {
    final raw = await _vault.readJson(_namespace, _modelKey);
    return raw is Map ? Map<String, Object?>.from(raw) : null;
  }

  Future<void> saveModelMetadata({
    required String path,
    required String sha256,
  }) {
    return _vault.writeJson(_namespace, _modelKey, <String, Object?>{
      'path': path,
      'sha256': sha256,
      'verifiedAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<List<Thought>> load() async {
    final raw = await _vault.readJson(_namespace, _thoughtsKey);
    if (raw is! List) return const <Thought>[];
    return raw
        .whereType<Map>()
        .map((item) => Thought.fromJson(Map<String, Object?>.from(item)))
        .where((item) => item.id.isNotEmpty && item.title.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> save(List<Thought> thoughts) {
    return _vault.writeJson(
      _namespace,
      _thoughtsKey,
      thoughts.map((item) => item.toJson()).toList(growable: false),
    );
  }

  Future<OrbitalWorkspace> loadOrbitalWorkspace() async {
    final raw = await _vault.readJson(_namespace, _orbitalWorkspaceKey);
    if (raw is! Map) return const OrbitalWorkspace();
    return OrbitalWorkspace.fromJson(Map<String, Object?>.from(raw));
  }

  Future<void> saveOrbitalWorkspace(OrbitalWorkspace workspace) {
    return _vault.writeJson(
      _namespace,
      _orbitalWorkspaceKey,
      workspace.toJson(),
    );
  }

  Future<List<JournalEntry>> loadJournal() async {
    final raw = await _vault.readJson(_namespace, _journalKey);
    if (raw is! List) return const <JournalEntry>[];
    return raw
        .whereType<Map>()
        .map((item) => JournalEntry.fromJson(Map<String, Object?>.from(item)))
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> saveJournal(List<JournalEntry> entries) {
    return _vault.writeJson(
      _namespace,
      _journalKey,
      entries.map((item) => item.toJson()).toList(growable: false),
    );
  }

  Future<List<ChatTurn>> loadChat() async {
    final raw = await _vault.readJson(_namespace, _chatKey);
    if (raw is! List) return const <ChatTurn>[];
    return raw
        .whereType<Map>()
        .map((item) => ChatTurn.fromJson(Map<String, Object?>.from(item)))
        .where((item) => item.id.isNotEmpty && item.text.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> saveChat(List<ChatTurn> turns) {
    return _vault.writeJson(
      _namespace,
      _chatKey,
      turns.take(40).map((item) => item.toJson()).toList(growable: false),
    );
  }

  Future<List<MoodColorEntry>> loadMoodColors() async {
    final raw = await _vault.readJson(_namespace, _moodColorsKey);
    if (raw is! List) return const <MoodColorEntry>[];
    return raw
        .whereType<Map>()
        .map((item) => MoodColorEntry.fromJson(Map<String, Object?>.from(item)))
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> saveMoodColors(List<MoodColorEntry> entries) {
    return _vault.writeJson(
      _namespace,
      _moodColorsKey,
      entries.take(365).map((item) => item.toJson()).toList(growable: false),
    );
  }

  Future<bool> loadOnboardingComplete() async {
    return await _vault.readJson(_namespace, _onboardingKey) == true;
  }

  Future<void> saveOnboardingComplete(bool value) {
    return _vault.writeJson(_namespace, _onboardingKey, value);
  }
}
