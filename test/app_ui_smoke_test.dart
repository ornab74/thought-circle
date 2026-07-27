import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thought_circle/app/theme.dart';
import 'package:thought_circle/models/reflection.dart';
import 'package:thought_circle/models/thought.dart';
import 'package:thought_circle/screens/guide_page.dart';
import 'package:thought_circle/screens/home_screen.dart';
import 'package:thought_circle/screens/onboarding_screen.dart';
import 'package:thought_circle/services/gemma_service.dart';
import 'package:thought_circle/state/app_controller.dart';

void main() {
  testWidgets('onboarding fits a phone viewport', (tester) async {
    await _phoneViewport(tester);
    final controller = _controller();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildThoughtCircleTheme(),
        home: OnboardingScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Break the loop.\nBuild clarity.'), findsOneWidget);

    for (var page = 1; page < 4; page++) {
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Add your\nlocal guide.'), findsOneWidget);
  });

  testWidgets('circle and all five tabs fit a phone viewport', (tester) async {
    await _phoneViewport(tester);
    final controller = _controller();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildThoughtCircleTheme(),
        home: HomeScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Make space.'), findsOneWidget);

    for (final label in <String>['Mood colors', 'Journal', 'Guide', 'You']) {
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      if (label == 'Mood colors') {
        expect(find.text('Color the moment.'), findsOneWidget);
      }
    }
  });

  testWidgets('guide keeps its composer while a Markdown reply is working', (
    tester,
  ) async {
    await _phoneViewport(tester);
    final controller = _controller()
      ..guideBusy = true
      ..guideTurns = <ChatTurn>[
        ChatTurn(
          id: 'reply',
          role: ChatRole.guide,
          text: '## A small step\n\n- **Pause**\n- Breathe',
          createdAt: DateTime(2026, 7, 26),
        ),
      ];
    controller.gemma.state = LocalAiState.working;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildThoughtCircleTheme(),
        home: GuidePage(controller: controller),
      ),
    );
    await tester.pump();

    expect(find.byType(MarkdownBody), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('main shell fits a desktop viewport', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildThoughtCircleTheme(),
        home: HomeScreen(controller: _controller()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Make space.'), findsOneWidget);
  });
}

Future<void> _phoneViewport(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

AppController _controller() {
  final now = DateTime(2026, 7, 26, 12);
  final controller = AppController()
    ..onboardingComplete = true
    ..moodColors = <MoodColorEntry>[
      MoodColorEntry(
        id: 'mood-2',
        colorValue: 0xFFFFA14F,
        label: 'Amber',
        energy: 0.72,
        createdAt: now,
      ),
      MoodColorEntry(
        id: 'mood-1',
        colorValue: 0xFF7357FF,
        label: 'Violet',
        energy: 0.42,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ]
    ..thoughts = <Thought>[
      Thought(
        id: 'one',
        title: 'Overthinking',
        detail: 'What if it all goes wrong?',
        kind: ThoughtKind.worry,
        state: ThoughtState.active,
        createdAt: now,
        updatedAt: now,
      ),
      Thought(
        id: 'two',
        title: 'I’m hungry',
        detail: 'I keep thinking about food.',
        kind: ThoughtKind.body,
        state: ThoughtState.active,
        createdAt: now,
        updatedAt: now,
      ),
      Thought(
        id: 'three',
        title: 'My room',
        detail: 'It feels messy.',
        kind: ThoughtKind.home,
        state: ThoughtState.active,
        createdAt: now,
        updatedAt: now,
      ),
      Thought(
        id: 'four',
        title: 'Work tomorrow',
        detail: 'I feel behind.',
        kind: ThoughtKind.work,
        state: ThoughtState.active,
        createdAt: now,
        updatedAt: now,
      ),
      Thought(
        id: 'five',
        title: 'What will people think?',
        detail: 'I worry about judgment.',
        kind: ThoughtKind.people,
        state: ThoughtState.active,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  return controller;
}
