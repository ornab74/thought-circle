import 'dart:convert';

enum OrbitalMoonKind {
  note,
  question,
  evidence,
  action,
  constraint,
  experiment,
}

final class OrbitalMoon {
  const OrbitalMoon({
    required this.id,
    required this.thoughtId,
    required this.label,
    required this.kind,
    required this.createdAt,
    this.completed = false,
  });

  final String id;
  final String thoughtId;
  final String label;
  final OrbitalMoonKind kind;
  final DateTime createdAt;
  final bool completed;

  OrbitalMoon copyWith({
    String? label,
    OrbitalMoonKind? kind,
    bool? completed,
  }) {
    return OrbitalMoon(
      id: id,
      thoughtId: thoughtId,
      label: label ?? this.label,
      kind: kind ?? this.kind,
      createdAt: createdAt,
      completed: completed ?? this.completed,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'thoughtId': thoughtId,
        'label': label,
        'kind': kind.name,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'completed': completed,
      };

  factory OrbitalMoon.fromJson(Map<String, Object?> json) {
    return OrbitalMoon(
      id: json['id']?.toString() ?? '',
      thoughtId: json['thoughtId']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      kind: OrbitalMoonKind.values.firstWhere(
        (item) => item.name == json['kind']?.toString(),
        orElse: () => OrbitalMoonKind.note,
      ),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      completed: json['completed'] == true,
    );
  }
}

final class OrbitalWorkspace {
  const OrbitalWorkspace({
    this.schemaVersion = 1,
    this.ringByThoughtId = const <String, int>{},
    this.moons = const <OrbitalMoon>[],
  });

  final int schemaVersion;
  final Map<String, int> ringByThoughtId;
  final List<OrbitalMoon> moons;

  int ringFor(String thoughtId, {int fallback = 0}) {
    return (ringByThoughtId[thoughtId] ?? fallback).clamp(0, 2);
  }

  List<OrbitalMoon> moonsFor(String thoughtId) {
    return moons
        .where((moon) => moon.thoughtId == thoughtId)
        .toList(growable: false);
  }

  OrbitalWorkspace assignRing(String thoughtId, int ringIndex) {
    return OrbitalWorkspace(
      schemaVersion: schemaVersion,
      ringByThoughtId: <String, int>{
        ...ringByThoughtId,
        thoughtId: ringIndex.clamp(0, 2),
      },
      moons: moons,
    );
  }

  OrbitalWorkspace addMoon(OrbitalMoon moon) {
    return OrbitalWorkspace(
      schemaVersion: schemaVersion,
      ringByThoughtId: ringByThoughtId,
      moons: <OrbitalMoon>[...moons, moon],
    );
  }

  OrbitalWorkspace updateMoon(OrbitalMoon updated) {
    return OrbitalWorkspace(
      schemaVersion: schemaVersion,
      ringByThoughtId: ringByThoughtId,
      moons: <OrbitalMoon>[
        for (final moon in moons)
          if (moon.id == updated.id) updated else moon,
      ],
    );
  }

  OrbitalWorkspace removeThought(String thoughtId) {
    final nextRings = Map<String, int>.from(ringByThoughtId)..remove(thoughtId);
    return OrbitalWorkspace(
      schemaVersion: schemaVersion,
      ringByThoughtId: nextRings,
      moons: moons
          .where((moon) => moon.thoughtId != thoughtId)
          .toList(growable: false),
    );
  }

  OrbitalWorkspace normalizedFor(Iterable<String> thoughtIds) {
    final validIds = thoughtIds.toSet();
    final nextRings = <String, int>{};
    var fallback = 0;
    for (final id in validIds) {
      nextRings[id] = ringFor(id, fallback: fallback % 3);
      fallback += 1;
    }
    return OrbitalWorkspace(
      schemaVersion: schemaVersion,
      ringByThoughtId: nextRings,
      moons: moons
          .where((moon) => validIds.contains(moon.thoughtId))
          .toList(growable: false),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': schemaVersion,
        'ringByThoughtId': ringByThoughtId,
        'moons': moons.map((moon) => moon.toJson()).toList(growable: false),
      };

  factory OrbitalWorkspace.fromJson(Map<String, Object?> json) {
    final rawRings = json['ringByThoughtId'];
    final rawMoons = json['moons'];
    return OrbitalWorkspace(
      schemaVersion: int.tryParse(json['schemaVersion']?.toString() ?? '') ?? 1,
      ringByThoughtId: rawRings is Map
          ? <String, int>{
              for (final entry in rawRings.entries)
                entry.key.toString():
                    (int.tryParse(entry.value.toString()) ?? 0).clamp(0, 2),
            }
          : const <String, int>{},
      moons: rawMoons is List
          ? rawMoons
              .whereType<Map>()
              .map(
                (item) =>
                    OrbitalMoon.fromJson(Map<String, Object?>.from(item)),
              )
              .where(
                (moon) =>
                    moon.id.isNotEmpty &&
                    moon.thoughtId.isNotEmpty &&
                    moon.label.isNotEmpty,
              )
              .toList(growable: false)
          : const <OrbitalMoon>[],
    );
  }

  static String encode(OrbitalWorkspace workspace) {
    return jsonEncode(workspace.toJson());
  }

  static OrbitalWorkspace decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) return const OrbitalWorkspace();
    return OrbitalWorkspace.fromJson(Map<String, Object?>.from(decoded));
  }
}
