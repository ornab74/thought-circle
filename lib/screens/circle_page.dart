import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/thought.dart';
import '../state/app_controller.dart';
import '../widgets/soft_card.dart';
import '../widgets/thought_orbit.dart';
import 'add_thought_sheet.dart';
import 'thought_detail_screen.dart';

class CirclePage extends StatelessWidget {
  const CirclePage({
    super.key,
    required this.controller,
    required this.onOpenGuide,
    required this.onOpenJournal,
  });

  final AppController controller;
  final VoidCallback onOpenGuide;
  final VoidCallback onOpenJournal;

  void _openThought(BuildContext context, Thought thought) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            ThoughtDetailScreen(controller: controller, thoughtId: thought.id),
      ),
    );
  }

  Future<void> _addThought(BuildContext context) async {
    final thought = await showAddThoughtSheet(context, controller);
    if (thought != null && context.mounted) _openThought(context, thought);
  }

  @override
  Widget build(BuildContext context) {
    final active = controller.activeThoughts;
    return PageGlow(
      child: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            floating: true,
            titleSpacing: 20,
            title: const Row(
              children: <Widget>[
                ThoughtCircleMark(size: 34),
                SizedBox(width: 11),
                Text('Your Circle'),
              ],
            ),
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: IconButton.filledTonal(
                  tooltip: 'Add a loop',
                  onPressed: () => _addThought(context),
                  icon: const Icon(Icons.add_rounded),
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 34),
            sliver: SliverList.list(
              children: <Widget>[
                Text(
                  'Make space.',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                if (active.isEmpty) ...<Widget>[
                  const SizedBox(height: 5),
                  Text(
                    'Your circle is clear.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: ThoughtCircleColors.muted,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: active.isEmpty
                        ? _EmptyCircle(onAdd: () => _addThought(context))
                        : ThoughtOrbit(
                            thoughts: active,
                            onThoughtTap: (thought) =>
                                _openThought(context, thought),
                          ),
                  ),
                ),
                GradientAction(
                  title: 'Talk it out',
                  subtitle: 'One clear next step',
                  icon: Icons.auto_awesome_rounded,
                  onTap: onOpenGuide,
                ),
                const SizedBox(height: 25),
                SectionLabel(
                  'Daily reflection',
                  trailing: TextButton(
                    onPressed: onOpenJournal,
                    child: const Text('View all'),
                  ),
                ),
                const SizedBox(height: 8),
                SoftCard(
                  onTap: onOpenJournal,
                  padding: const EdgeInsets.all(17),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: ThoughtCircleColors.lavender,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.edit_note_rounded,
                          color: ThoughtCircleColors.purple,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              controller.todayJournalEntries.isEmpty
                                  ? 'How did today feel?'
                                  : '${controller.todayJournalEntries.length} notes today',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              controller.completedSteps == 0
                                  ? 'Save one clear moment.'
                                  : '${controller.completedSteps} small steps complete.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCircle extends StatelessWidget {
  const _EmptyCircle({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 350,
      child: Center(
        child: SoftCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const ThoughtCircleMark(size: 56),
              const SizedBox(height: 16),
              Text(
                'A quiet circle',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Add what keeps returning.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add a loop'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
