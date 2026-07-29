import 'dart:ui';

import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/orbital_workspace.dart';
import '../models/thought.dart';

class OrbitalWorkspacePanel extends StatelessWidget {
  const OrbitalWorkspacePanel({
    super.key,
    required this.thoughts,
    required this.workspace,
    required this.onMoveThought,
    required this.onAddMoon,
    required this.onToggleMoon,
  });

  final List<Thought> thoughts;
  final OrbitalWorkspace workspace;
  final void Function(Thought thought, int ringIndex) onMoveThought;
  final ValueChanged<Thought> onAddMoon;
  final ValueChanged<OrbitalMoon> onToggleMoon;

  static const _ringNames = <String>['Near', 'Middle', 'Outer'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Orbital workspace',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              '${workspace.moons.length} moons',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Place each loop on a ring, then add small moons for questions, evidence, actions, constraints, or experiments.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 14),
        for (var ringIndex = 0; ringIndex < 3; ringIndex++) ...<Widget>[
          _RingLane(
            name: _ringNames[ringIndex],
            ringIndex: ringIndex,
            thoughts: thoughts
                .where(
                  (thought) =>
                      workspace.ringFor(thought.id, fallback: 0) == ringIndex,
                )
                .toList(growable: false),
            workspace: workspace,
            onMoveThought: onMoveThought,
            onAddMoon: onAddMoon,
            onToggleMoon: onToggleMoon,
          ),
          if (ringIndex != 2) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _RingLane extends StatelessWidget {
  const _RingLane({
    required this.name,
    required this.ringIndex,
    required this.thoughts,
    required this.workspace,
    required this.onMoveThought,
    required this.onAddMoon,
    required this.onToggleMoon,
  });

  final String name;
  final int ringIndex;
  final List<Thought> thoughts;
  final OrbitalWorkspace workspace;
  final void Function(Thought thought, int ringIndex) onMoveThought;
  final ValueChanged<Thought> onAddMoon;
  final ValueChanged<OrbitalMoon> onToggleMoon;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x147357FF),
                blurRadius: 26,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: <Color>[
                          ThoughtCircleColors.orange,
                          ThoughtCircleColors.pink,
                          ThoughtCircleColors.purple,
                        ],
                      ),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(color: Color(0x447357FF), blurRadius: 10),
                      ],
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text('$name ring', style: Theme.of(context).textTheme.labelLarge),
                  const Spacer(),
                  Text(
                    '${thoughts.length} loops',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (thoughts.isEmpty)
                Text(
                  'No loops on this ring yet.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                for (final thought in thoughts) ...<Widget>[
                  _ThoughtRow(
                    thought: thought,
                    ringIndex: ringIndex,
                    moons: workspace.moonsFor(thought.id),
                    onMoveThought: onMoveThought,
                    onAddMoon: onAddMoon,
                    onToggleMoon: onToggleMoon,
                  ),
                  if (thought != thoughts.last) const SizedBox(height: 9),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ThoughtRow extends StatelessWidget {
  const _ThoughtRow({
    required this.thought,
    required this.ringIndex,
    required this.moons,
    required this.onMoveThought,
    required this.onAddMoon,
    required this.onToggleMoon,
  });

  final Thought thought;
  final int ringIndex;
  final List<OrbitalMoon> moons;
  final void Function(Thought thought, int ringIndex) onMoveThought;
  final ValueChanged<Thought> onAddMoon;
  final ValueChanged<OrbitalMoon> onToggleMoon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: thought.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 16,
                backgroundColor: thought.color.withValues(alpha: 0.14),
                child: Icon(thought.icon, size: 16, color: thought.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  thought.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              IconButton(
                tooltip: 'Add moon',
                onPressed: () => onAddMoon(thought),
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
              PopupMenuButton<int>(
                tooltip: 'Move to another ring',
                onSelected: (value) => onMoveThought(thought, value),
                itemBuilder: (context) => <PopupMenuEntry<int>>[
                  for (var index = 0; index < 3; index++)
                    PopupMenuItem<int>(
                      value: index,
                      enabled: index != ringIndex,
                      child: Text('Move to ${OrbitalWorkspacePanel._ringNames[index]}'),
                    ),
                ],
              ),
            ],
          ),
          if (moons.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: <Widget>[
                for (final moon in moons)
                  FilterChip(
                    selected: moon.completed,
                    onSelected: (_) => onToggleMoon(moon),
                    avatar: Icon(_iconFor(moon.kind), size: 15),
                    label: Text(moon.label),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconFor(OrbitalMoonKind kind) => switch (kind) {
        OrbitalMoonKind.note => Icons.notes_rounded,
        OrbitalMoonKind.question => Icons.help_outline_rounded,
        OrbitalMoonKind.evidence => Icons.fact_check_outlined,
        OrbitalMoonKind.action => Icons.task_alt_rounded,
        OrbitalMoonKind.constraint => Icons.lock_outline_rounded,
        OrbitalMoonKind.experiment => Icons.science_outlined,
      };
}
