import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/reflection.dart';
import '../models/thought.dart';
import '../state/app_controller.dart';
import '../widgets/soft_card.dart';
import 'thought_detail_screen.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final settled = controller.thoughts
        .where((thought) => thought.state == ThoughtState.settled)
        .toList(growable: false);
    final ratio = controller.totalSteps == 0
        ? 0.0
        : controller.completedSteps / controller.totalSteps;
    return PageGlow(
      child: CustomScrollView(
        slivers: <Widget>[
          const SliverAppBar(title: Text('Insights')),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 5, 18, 34),
            sliver: SliverList.list(
              children: <Widget>[
                Text(
                  'See what shifted.',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 5),
                Text(
                  'Small movement still counts.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _StatCard(
                        value: '${controller.activeThoughts.length}',
                        label: 'Active',
                        color: ThoughtCircleColors.purple,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _StatCard(
                        value: '${settled.length}',
                        label: 'Moved',
                        color: ThoughtCircleColors.orange,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _StatCard(
                        value: '${controller.journalEntries.length}',
                        label: 'Notes',
                        color: ThoughtCircleColors.pink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SoftCard(
                  color: const Color(0xFFFFFBF7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'Small steps',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          Text(
                            '${controller.completedSteps}/${controller.totalSteps}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: ThoughtCircleColors.purple),
                          ),
                        ],
                      ),
                      const SizedBox(height: 17),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          minHeight: 10,
                          value: ratio,
                          backgroundColor: ThoughtCircleColors.line,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            ThoughtCircleColors.orange,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        controller.totalSteps == 0
                            ? 'Open a loop to begin.'
                            : 'Keep the pace kind.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (controller.journalEntries.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 24),
                  const SectionLabel('Recent mood'),
                  const SizedBox(height: 9),
                  SoftCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        for (final entry in controller.journalEntries.take(7))
                          _MoodMark(mood: entry.mood),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                const SectionLabel('Moved through'),
                const SizedBox(height: 9),
                if (settled.isEmpty)
                  SoftCard(
                    child: Text(
                      'Completed loops will collect here.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                else
                  for (final thought in settled) ...<Widget>[
                    SoftCard(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ThoughtDetailScreen(
                            controller: controller,
                            thoughtId: thought.id,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        children: <Widget>[
                          CircleAvatar(
                            backgroundColor: thought.color.withValues(
                              alpha: 0.12,
                            ),
                            foregroundColor: thought.color,
                            child: Icon(thought.icon),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Text(
                              thought.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                    const SizedBox(height: 9),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ThoughtCircleColors.line),
      ),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _MoodMark extends StatelessWidget {
  const _MoodMark({required this.mood});

  final JournalMood mood;

  @override
  Widget build(BuildContext context) {
    final color = switch (mood) {
      JournalMood.steady => ThoughtCircleColors.purple,
      JournalMood.hopeful => ThoughtCircleColors.pink,
      JournalMood.light => ThoughtCircleColors.orange,
      JournalMood.restless => const Color(0xFF4F7DF3),
      JournalMood.heavy => ThoughtCircleColors.ink,
    };
    return Container(
      width: 18,
      height: 42,
      alignment: Alignment.bottomCenter,
      child: Container(
        width: 9,
        height: 12 + mood.index * 5,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
