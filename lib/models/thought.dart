import 'dart:convert';

import 'package:flutter/material.dart';

enum ThoughtKind { body, home, worry, work, people, other }

enum ThoughtState { active, settled, archived }

final class ThoughtStep {
  final String id;
  final String title;
  final String detail;
  final bool done;

  const ThoughtStep({
    required this.id,
    required this.title,
    required this.detail,
    this.done = false,
  });

  ThoughtStep copyWith({bool? done}) {
    return ThoughtStep(
      id: id,
      title: title,
      detail: detail,
      done: done ?? this.done,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'title': title,
    'detail': detail,
    'done': done,
  };

  factory ThoughtStep.fromJson(Map<String, Object?> json) {
    return ThoughtStep(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      detail: json['detail']?.toString() ?? '',
      done: json['done'] == true,
    );
  }
}

final class ThoughtPlan {
  final String understanding;
  final String support;
  final List<ThoughtStep> steps;
  final List<String> helpfulActions;
  final DateTime createdAt;

  const ThoughtPlan({
    required this.understanding,
    required this.support,
    required this.steps,
    required this.helpfulActions,
    required this.createdAt,
  });

  Map<String, Object?> toJson() => <String, Object?>{
    'understanding': understanding,
    'support': support,
    'steps': steps.map((step) => step.toJson()).toList(growable: false),
    'helpfulActions': helpfulActions,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  factory ThoughtPlan.fromJson(Map<String, Object?> json) {
    final rawSteps = json['steps'];
    final rawActions = json['helpfulActions'];
    return ThoughtPlan(
      understanding: json['understanding']?.toString() ?? '',
      support: json['support']?.toString() ?? '',
      steps: rawSteps is List
          ? rawSteps
                .whereType<Map>()
                .map(
                  (item) =>
                      ThoughtStep.fromJson(Map<String, Object?>.from(item)),
                )
                .toList(growable: false)
          : const <ThoughtStep>[],
      helpfulActions: rawActions is List
          ? rawActions.map((item) => item.toString()).toList(growable: false)
          : const <String>[],
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

final class Thought {
  final String id;
  final String title;
  final String detail;
  final ThoughtKind kind;
  final ThoughtState state;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ThoughtPlan? plan;

  const Thought({
    required this.id,
    required this.title,
    required this.detail,
    required this.kind,
    required this.state,
    required this.createdAt,
    required this.updatedAt,
    this.plan,
  });

  Thought copyWith({
    String? title,
    String? detail,
    ThoughtKind? kind,
    ThoughtState? state,
    DateTime? updatedAt,
    ThoughtPlan? plan,
    bool clearPlan = false,
  }) {
    return Thought(
      id: id,
      title: title ?? this.title,
      detail: detail ?? this.detail,
      kind: kind ?? this.kind,
      state: state ?? this.state,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      plan: clearPlan ? null : (plan ?? this.plan),
    );
  }

  Color get color => switch (kind) {
    ThoughtKind.body => const Color(0xFFFF8A4C),
    ThoughtKind.home => const Color(0xFFF25CB0),
    ThoughtKind.worry => const Color(0xFF6C63FF),
    ThoughtKind.work => const Color(0xFF7B61FF),
    ThoughtKind.people => const Color(0xFF8367D8),
    ThoughtKind.other => const Color(0xFF4F7DF3),
  };

  IconData get icon => switch (kind) {
    ThoughtKind.body => Icons.restaurant_rounded,
    ThoughtKind.home => Icons.weekend_rounded,
    ThoughtKind.worry => Icons.nights_stay_rounded,
    ThoughtKind.work => Icons.schedule_rounded,
    ThoughtKind.people => Icons.groups_rounded,
    ThoughtKind.other => Icons.lightbulb_rounded,
  };

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'title': title,
    'detail': detail,
    'kind': kind.name,
    'state': state.name,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'plan': plan?.toJson(),
  };

  factory Thought.fromJson(Map<String, Object?> json) {
    final rawPlan = json['plan'];
    return Thought(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      detail: json['detail']?.toString() ?? '',
      kind: ThoughtKind.values.firstWhere(
        (item) => item.name == json['kind']?.toString(),
        orElse: () => ThoughtKind.other,
      ),
      state: ThoughtState.values.firstWhere(
        (item) => item.name == json['state']?.toString(),
        orElse: () => ThoughtState.active,
      ),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      plan: rawPlan is Map
          ? ThoughtPlan.fromJson(Map<String, Object?>.from(rawPlan))
          : null,
    );
  }

  static String encodeList(List<Thought> thoughts) {
    return jsonEncode(thoughts.map((item) => item.toJson()).toList());
  }

  static List<Thought> decodeList(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! List) return const <Thought>[];
    return decoded
        .whereType<Map>()
        .map((item) => Thought.fromJson(Map<String, Object?>.from(item)))
        .where((item) => item.id.isNotEmpty && item.title.isNotEmpty)
        .toList(growable: false);
  }
}
