import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thought_circle/models/thought.dart';
import 'package:thought_circle/widgets/thought_orbit.dart';

void main() {
  Thought thought(String id, String title, ThoughtKind kind) {
    final now = DateTime(2026, 7, 29);
    return Thought(
      id: id,
      title: title,
      detail: 'A useful detail',
      kind: kind,
      state: ThoughtState.active,
      createdAt: now,
      updatedAt: now,
    );
  }

  testWidgets('renders count and supports orbital drag', (tester) async {
    final thoughts = <Thought>[
      thought('one', 'First loop', ThoughtKind.worry),
      thought('two', 'Second loop', ThoughtKind.work),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            child: ThoughtOrbit(
              thoughts: thoughts,
              onThoughtTap: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('2'), findsOneWidget);
    expect(find.text('active loops'), findsOneWidget);

    await tester.drag(find.byType(ThoughtOrbit), const Offset(90, 24));
    await tester.pump(const Duration(milliseconds: 120));

    expect(tester.takeException(), isNull);
  });

  testWidgets('honors reduced motion', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 420,
              child: ThoughtOrbit(
                thoughts: <Thought>[
                  thought('one', 'First loop', ThoughtKind.people),
                ],
                onThoughtTap: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('1'), findsOneWidget);
    expect(find.text('active loop'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
