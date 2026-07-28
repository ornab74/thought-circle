import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/thought.dart';
import '../state/app_controller.dart';

Future<Thought?> showAddThoughtSheet(
  BuildContext context,
  AppController controller,
) {
  return showModalBottomSheet<Thought>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) => _AddThoughtSheet(controller: controller),
  );
}

class _AddThoughtSheet extends StatefulWidget {
  const _AddThoughtSheet({required this.controller});

  final AppController controller;

  @override
  State<_AddThoughtSheet> createState() => _AddThoughtSheetState();
}

class _AddThoughtSheetState extends State<_AddThoughtSheet> {
  final _title = TextEditingController();
  final _detail = TextEditingController();
  ThoughtKind _kind = ThoughtKind.other;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _detail.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final thought = await widget.controller.addThought(
        title: _title.text,
        detail: _detail.text,
        kind: _kind,
      );
      if (mounted) Navigator.pop(context, thought);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ThoughtCircleColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        12,
        22,
        22 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: ThoughtCircleColors.line,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'What keeps coming back?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _title,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 120,
              decoration: const InputDecoration(
                labelText: 'Thought',
                hintText: 'AI is not useful >>> I may be prompting poorly >>> AI is not useful',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tip: use >>> between thoughts to map the full loop.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ThoughtCircleColors.muted,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _detail,
              textCapitalization: TextCapitalization.sentences,
              minLines: 2,
              maxLines: 4,
              maxLength: 420,
              decoration: const InputDecoration(
                labelText: 'More (optional)',
                hintText: 'Add facts, context, or what keeps linking the thoughts together.',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 6),
            Text('Theme', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: <Widget>[
                for (final kind in ThoughtKind.values)
                  ChoiceChip(
                    selected: _kind == kind,
                    onSelected: (_) => setState(() => _kind = kind),
                    avatar: Icon(_iconFor(kind), size: 17),
                    label: Text(_labelFor(kind)),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add loop'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _labelFor(ThoughtKind kind) => switch (kind) {
    ThoughtKind.body => 'Body',
    ThoughtKind.home => 'Home',
    ThoughtKind.worry => 'Worry',
    ThoughtKind.work => 'Work',
    ThoughtKind.people => 'People',
    ThoughtKind.other => 'Something else',
  };

  IconData _iconFor(ThoughtKind kind) => switch (kind) {
    ThoughtKind.body => Icons.restaurant_rounded,
    ThoughtKind.home => Icons.home_rounded,
    ThoughtKind.worry => Icons.nights_stay_rounded,
    ThoughtKind.work => Icons.schedule_rounded,
    ThoughtKind.people => Icons.groups_rounded,
    ThoughtKind.other => Icons.lightbulb_rounded,
  };
}
