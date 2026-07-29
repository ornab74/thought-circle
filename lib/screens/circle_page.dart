import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../app/theme.dart';
import '../models/orbital_workspace.dart';
import '../models/thought.dart';
import '../state/app_controller.dart';
import '../widgets/orbital_workspace_panel.dart';
import '../widgets/soft_card.dart';
import '../widgets/thought_orbit.dart';
import 'add_thought_sheet.dart';
import 'thought_detail_screen.dart';

class CirclePage extends StatefulWidget {
  const CirclePage({
    super.key,
    required this.controller,
    required this.onOpenGuide,
    required this.onOpenJournal,
  });

  final AppController controller;
  final VoidCallback onOpenGuide;
  final VoidCallback onOpenJournal;

  @override
  State<CirclePage> createState() => _CirclePageState();
}

class _CirclePageState extends State<CirclePage> {
  final Uuid _uuid = const Uuid();
  OrbitalWorkspace _workspace = const OrbitalWorkspace();
  bool _workspaceLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadWorkspace();
  }

  Future<void> _loadWorkspace() async {
    final loaded = await widget.controller.repository.loadOrbitalWorkspace();
    final normalized = loaded.normalizedFor(
      widget.controller.thoughts.map((thought) => thought.id),
    );
    if (!mounted) return;
    setState(() {
      _workspace = normalized;
      _workspaceLoaded = true;
    });
    if (loaded.toJson().toString() != normalized.toJson().toString()) {
      await widget.controller.repository.saveOrbitalWorkspace(normalized);
    }
  }

  void _openThought(BuildContext context, Thought thought) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ThoughtDetailScreen(
          controller: widget.controller,
          thoughtId: thought.id,
        ),
      ),
    );
  }

  Future<void> _addThought(BuildContext context) async {
    final thought = await showAddThoughtSheet(context, widget.controller);
    if (thought == null || !context.mounted) return;
    final next = _workspace.assignRing(thought.id, 0);
    await _saveWorkspace(next);
    if (context.mounted) _openThought(context, thought);
  }

  Future<void> _saveWorkspace(OrbitalWorkspace next) async {
    setState(() => _workspace = next);
    await widget.controller.repository.saveOrbitalWorkspace(next);
  }

  Future<void> _moveThought(Thought thought, int ringIndex) async {
    await _saveWorkspace(_workspace.assignRing(thought.id, ringIndex));
  }

  Future<void> _toggleMoon(OrbitalMoon moon) async {
    await _saveWorkspace(
      _workspace.updateMoon(moon.copyWith(completed: !moon.completed)),
    );
  }

  Future<void> _showAddMoon(Thought thought) async {
    final labelController = TextEditingController();
    var selectedKind = OrbitalMoonKind.note;
    final result = await showModalBottomSheet<OrbitalMoon>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Add a moon',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          thought.title,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: labelController,
                          autofocus: true,
                          maxLength: 80,
                          decoration: const InputDecoration(
                            labelText: 'What does this moon hold?',
                            hintText: 'A question, fact, next step, or constraint',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            for (final kind in OrbitalMoonKind.values)
                              ChoiceChip(
                                selected: selectedKind == kind,
                                onSelected: (_) =>
                                    setSheetState(() => selectedKind = kind),
                                label: Text(_moonKindLabel(kind)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              final label = labelController.text.trim();
                              if (label.isEmpty) return;
                              Navigator.of(context).pop(
                                OrbitalMoon(
                                  id: _uuid.v4(),
                                  thoughtId: thought.id,
                                  label: label,
                                  kind: selectedKind,
                                  createdAt: DateTime.now(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            label: const Text('Place moon on ring'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    labelController.dispose();
    if (result != null) await _saveWorkspace(_workspace.addMoon(result));
  }

  String _moonKindLabel(OrbitalMoonKind kind) => switch (kind) {
        OrbitalMoonKind.note => 'Note',
        OrbitalMoonKind.question => 'Question',
        OrbitalMoonKind.evidence => 'Evidence',
        OrbitalMoonKind.action => 'Action',
        OrbitalMoonKind.constraint => 'Constraint',
        OrbitalMoonKind.experiment => 'Experiment',
      };

  @override
  Widget build(BuildContext context) {
    final active = widget.controller.activeThoughts;
    final visibleWorkspace = _workspace.normalizedFor(
      widget.controller.thoughts.map((thought) => thought.id),
    );
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
                if (active.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: !_workspaceLoaded
                        ? const Center(child: CircularProgressIndicator())
                        : OrbitalWorkspacePanel(
                            key: ValueKey<int>(visibleWorkspace.moons.length),
                            thoughts: active,
                            workspace: visibleWorkspace,
                            onMoveThought: _moveThought,
                            onAddMoon: _showAddMoon,
                            onToggleMoon: _toggleMoon,
                          ),
                  ),
                  const SizedBox(height: 20),
                ],
                GradientAction(
                  title: 'Talk it out',
                  subtitle: 'One clear next step',
                  icon: Icons.auto_awesome_rounded,
                  onTap: widget.onOpenGuide,
                ),
                const SizedBox(height: 25),
                SectionLabel(
                  'Daily reflection',
                  trailing: TextButton(
                    onPressed: widget.onOpenJournal,
                    child: const Text('View all'),
                  ),
                ),
                const SizedBox(height: 8),
                SoftCard(
                  onTap: widget.onOpenJournal,
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
                              widget.controller.todayJournalEntries.isEmpty
                                  ? 'How did today feel?'
                                  : '${widget.controller.todayJournalEntries.length} notes today',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.controller.completedSteps == 0
                                  ? 'Save one clear moment.'
                                  : '${widget.controller.completedSteps} small steps complete.',
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
