enum JournalSource { typed, voice, circle, dailyReview }

enum JournalMood { steady, hopeful, light, restless, heavy }

final class MoodColorEntry {
  const MoodColorEntry({
    required this.id,
    required this.colorValue,
    required this.label,
    required this.energy,
    required this.createdAt,
    this.note = '',
  });

  final String id;
  final int colorValue;
  final String label;
  final double energy;
  final DateTime createdAt;
  final String note;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'colorValue': colorValue,
    'label': label,
    'energy': energy,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'note': note,
  };

  factory MoodColorEntry.fromJson(Map<String, Object?> json) {
    final energy = double.tryParse(json['energy']?.toString() ?? '') ?? 0.5;
    return MoodColorEntry(
      id: json['id']?.toString() ?? '',
      colorValue:
          int.tryParse(json['colorValue']?.toString() ?? '') ?? 0xFF7357FF,
      label: json['label']?.toString() ?? 'Mixed',
      energy: energy.clamp(0.0, 1.0).toDouble(),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      note: json['note']?.toString() ?? '',
    );
  }
}

final class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.title,
    required this.body,
    required this.summary,
    required this.highlights,
    required this.source,
    required this.mood,
    required this.createdAt,
    required this.updatedAt,
    this.linkedThoughtId,
  });

  final String id;
  final String title;
  final String body;
  final String summary;
  final List<String> highlights;
  final JournalSource source;
  final JournalMood mood;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? linkedThoughtId;

  String get shareText {
    final points = highlights.isEmpty
        ? ''
        : '\n\n${highlights.map((item) => '• $item').join('\n')}';
    return '$title\n\n$summary$points';
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'title': title,
    'body': body,
    'summary': summary,
    'highlights': highlights,
    'source': source.name,
    'mood': mood.name,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'linkedThoughtId': linkedThoughtId,
  };

  factory JournalEntry.fromJson(Map<String, Object?> json) {
    final rawHighlights = json['highlights'];
    return JournalEntry(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Daily note',
      body: json['body']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      highlights: rawHighlights is List
          ? rawHighlights
                .map((item) => item.toString())
                .where((item) => item.trim().isNotEmpty)
                .take(5)
                .toList(growable: false)
          : const <String>[],
      source: JournalSource.values.firstWhere(
        (item) => item.name == json['source']?.toString(),
        orElse: () => JournalSource.typed,
      ),
      mood: JournalMood.values.firstWhere(
        (item) => item.name == json['mood']?.toString(),
        orElse: () => JournalMood.steady,
      ),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      linkedThoughtId: json['linkedThoughtId']?.toString(),
    );
  }
}

enum ChatRole { user, guide }

enum GuideMode { reflect, circle, nextStep }

final class ChatTurn {
  const ChatTurn({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final ChatRole role;
  final String text;
  final DateTime createdAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'role': role.name,
    'text': text,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  factory ChatTurn.fromJson(Map<String, Object?> json) {
    return ChatTurn(
      id: json['id']?.toString() ?? '',
      role: ChatRole.values.firstWhere(
        (item) => item.name == json['role']?.toString(),
        orElse: () => ChatRole.user,
      ),
      text: json['text']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
