import 'package:flutter_test/flutter_test.dart';
import 'package:thought_circle/models/thought.dart';
import 'package:thought_circle/services/gemma_service.dart';

void main() {
  test('thought data survives a JSON round trip', () {
    final now = DateTime.utc(2026, 7, 26, 12);
    final thought = Thought(
      id: 'thought-1',
      title: 'I need to organize my room',
      detail: 'It feels messy and overwhelming.',
      kind: ThoughtKind.home,
      state: ThoughtState.active,
      createdAt: now,
      updatedAt: now,
      plan: ThoughtPlan(
        understanding: 'The room feels bigger than the first step.',
        support: 'Start with one small surface.',
        steps: const <ThoughtStep>[
          ThoughtStep(
            id: 'step-1',
            title: 'Pick one area',
            detail: 'Choose one shelf.',
            done: true,
          ),
        ],
        helpfulActions: const <String>['Set a five-minute timer'],
        createdAt: now,
      ),
    );

    final restored = Thought.fromJson(thought.toJson());

    expect(restored.title, thought.title);
    expect(restored.kind, ThoughtKind.home);
    expect(restored.plan?.steps.single.done, isTrue);
  });

  test('starter plan always returns small actions', () {
    final thought = Thought(
      id: 'thought-2',
      title: 'I’m hungry',
      detail: 'I keep thinking about food.',
      kind: ThoughtKind.body,
      state: ThoughtState.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final plan = starterPlanFor(thought);

    expect(plan.steps, hasLength(4));
    expect(plan.steps.every((step) => step.title.isNotEmpty), isTrue);
    expect(plan.helpfulActions, isNotEmpty);
  });
}
