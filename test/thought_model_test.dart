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
      verdict: ThoughtVerdict.partlyValid,
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
        loopNodes: const <String>[
          'The room is too messy',
          'I do not know where to start',
          'The room is too messy',
        ],
        validSignal: 'The room does need some attention.',
        uncertainty: 'The whole room may not need to be solved at once.',
        constructiveCycle: const <String>[
          'Name one area',
          'Run a five-minute test',
          'Choose or close',
        ],
        experiment: 'Clear one shelf for five minutes.',
        closureRule: 'Stop after the timer and decide once.',
        helpfulActions: const <String>['Set a five-minute timer'],
        createdAt: now,
      ),
    );

    final restored = Thought.fromJson(thought.toJson());

    expect(restored.title, thought.title);
    expect(restored.kind, ThoughtKind.home);
    expect(restored.verdict, ThoughtVerdict.partlyValid);
    expect(restored.plan?.steps.single.done, isTrue);
    expect(restored.plan?.loopNodes, hasLength(3));
    expect(restored.plan?.validSignal, contains('attention'));
    expect(restored.plan?.closureRule, contains('Stop'));
  });

  test('older saved plans load with safe cycle defaults', () {
    final restored = Thought.fromJson(<String, Object?>{
      'id': 'legacy-thought',
      'title': 'A legacy loop',
      'detail': 'Saved before the supportive-cycle update.',
      'kind': 'other',
      'state': 'active',
      'createdAt': '2026-07-01T12:00:00.000Z',
      'updatedAt': '2026-07-01T12:00:00.000Z',
      'plan': <String, Object?>{
        'understanding': 'Legacy understanding',
        'support': 'Legacy support',
        'steps': <Object?>[],
        'helpfulActions': <Object?>['Pause once'],
        'createdAt': '2026-07-01T12:00:00.000Z',
      },
    });

    expect(restored.verdict, ThoughtVerdict.unreviewed);
    expect(restored.plan?.loopNodes, isEmpty);
    expect(restored.plan?.constructiveCycle, isEmpty);
    expect(restored.plan?.support, 'Legacy support');
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
  test('starter plan maps an explicit linked thought chain', () {
    final thought = Thought(
      id: 'thought-chain',
      title:
          'AI is not useful >>> I may be prompting poorly >>> I do not see use cases >>> AI is not useful',
      detail: 'I want a concrete way to test this.',
      kind: ThoughtKind.work,
      state: ThoughtState.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final plan = starterPlanFor(thought);

    expect(plan.loopNodes, hasLength(4));
    expect(plan.loopNodes.first, 'AI is not useful');
    expect(plan.validSignal, isNotEmpty);
    expect(plan.uncertainty, isNotEmpty);
    expect(plan.constructiveCycle, hasLength(5));
    expect(plan.experiment, contains('prototype'));
    expect(plan.closureRule, isNotEmpty);
  });

}
