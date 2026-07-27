import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';
import '../models/reflection.dart';
import '../state/app_controller.dart';
import '../widgets/soft_card.dart';
import 'journal_composer.dart';

class JournalPage extends StatelessWidget {
  const JournalPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return PageGlow(
      child: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            title: const Text('Journal'),
            actions: <Widget>[
              IconButton(
                tooltip: 'New note',
                onPressed: () => showJournalComposer(context, controller),
                icon: const Icon(Icons.add_rounded),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 5, 18, 34),
            sliver: SliverList.list(
              children: <Widget>[
                Text(
                  'Remember the day.',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 16),
                _CaptureCard(controller: controller),
                if (controller.todayJournalEntries.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 14),
                  _DailyReviewCard(controller: controller),
                ],
                const SizedBox(height: 28),
                SectionLabel(
                  controller.journalEntries.isEmpty
                      ? 'Your notes'
                      : 'Recent notes',
                  trailing: controller.journalEntries.isEmpty
                      ? null
                      : Text(
                          '${controller.journalEntries.length}',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                ),
                const SizedBox(height: 10),
                if (controller.journalEntries.isEmpty)
                  SoftCard(
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.auto_stories_outlined,
                          color: ThoughtCircleColors.purple,
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Text(
                            'Your first note can be one sentence.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  for (final entry in controller.journalEntries) ...<Widget>[
                    _JournalCard(
                      entry: entry,
                      linkedTitle: entry.linkedThoughtId == null
                          ? null
                          : controller
                                .findThought(entry.linkedThoughtId!)
                                ?.title,
                      onTap: () => _showEntry(context, entry),
                    ),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEntry(BuildContext context, JournalEntry entry) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: ThoughtCircleColors.background,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.94,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
          children: <Widget>[
            Row(
              children: <Widget>[
                _MoodDot(mood: entry.mood),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Copy to share',
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: entry.shareText),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Summary copied.')),
                      );
                    }
                  },
                  icon: const Icon(Icons.ios_share_rounded),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SectionLabel(
              entry.source == JournalSource.voice ? 'Voice summary' : 'Summary',
            ),
            const SizedBox(height: 8),
            SoftCard(
              color: const Color(0xFFF7F4FF),
              child: Text(
                entry.summary,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            if (entry.highlights.isNotEmpty) ...<Widget>[
              const SizedBox(height: 22),
              const SectionLabel('What stood out'),
              const SizedBox(height: 8),
              SoftCard(
                child: Column(
                  children: <Widget>[
                    for (final highlight in entry.highlights)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.auto_awesome_rounded,
                          size: 18,
                          color: ThoughtCircleColors.orange,
                        ),
                        title: Text(highlight),
                      ),
                  ],
                ),
              ),
            ],
            if (entry.body.isNotEmpty &&
                entry.body != entry.summary) ...<Widget>[
              const SizedBox(height: 22),
              SectionLabel(
                entry.source == JournalSource.voice
                    ? 'Transcript'
                    : 'Full note',
              ),
              const SizedBox(height: 8),
              SoftCard(
                child: Text(
                  entry.body,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
            const SizedBox(height: 18),
            TextButton.icon(
              onPressed: () async {
                await controller.deleteJournalEntry(entry.id);
                if (context.mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Delete note'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureCard extends StatelessWidget {
  const _CaptureCard({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF6F56F6),
            Color(0xFFE45EB8),
            Color(0xFFFF9B53),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x307055F8),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Capture a moment',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () =>
                            showJournalComposer(context, controller),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: ThoughtCircleColors.ink,
                          minimumSize: const Size(0, 46),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        icon: const Icon(Icons.edit_rounded, size: 17),
                        label: const Text('Write'),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => showJournalComposer(
                          context,
                          controller,
                          startWithVoice: true,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.18),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 46),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        icon: const Icon(Icons.mic_rounded, size: 17),
                        label: const Text('Speak'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 48),
        ],
      ),
    );
  }
}

class _DailyReviewCard extends StatelessWidget {
  const _DailyReviewCard({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final hasReview = controller.todayJournalEntries.any(
      (entry) => entry.source == JournalSource.dailyReview,
    );
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: ThoughtCircleColors.cream,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.wb_twilight_rounded,
              color: ThoughtCircleColors.orange,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  hasReview ? 'Today is gathered' : 'Gather today',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  hasReview
                      ? 'Your daily review is ready.'
                      : '${controller.todayJournalEntries.length} notes · one clear summary',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (!hasReview)
            IconButton.filledTonal(
              tooltip: 'Make daily review',
              onPressed: controller.journalBusy || !controller.gemma.isReady
                  ? null
                  : () async {
                      try {
                        await controller.makeDailyReview();
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(controller.message ?? 'Try again.'),
                            ),
                          );
                        }
                      }
                    },
              icon: const Icon(Icons.auto_awesome_rounded),
            ),
        ],
      ),
    );
  }
}

class _JournalCard extends StatelessWidget {
  const _JournalCard({
    required this.entry,
    required this.linkedTitle,
    required this.onTap,
  });

  final JournalEntry entry;
  final String? linkedTitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _MoodDot(mood: entry.mood),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        entry.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (entry.source == JournalSource.voice)
                      const Icon(
                        Icons.mic_rounded,
                        size: 16,
                        color: ThoughtCircleColors.purple,
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  entry.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(
                      _dateLabel(entry.createdAt),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(fontSize: 10),
                    ),
                    if (linkedTitle != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: ThoughtCircleColors.lavender,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          linkedTitle!,
                          style: Theme.of(
                            context,
                          ).textTheme.labelLarge?.copyWith(fontSize: 9),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, size: 20),
        ],
      ),
    );
  }

  static String _dateLabel(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today · ${_time(date)}';
    }
    return '${date.month}/${date.day} · ${_time(date)}';
  }

  static String _time(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${date.hour < 12 ? 'AM' : 'PM'}';
  }
}

class _MoodDot extends StatelessWidget {
  const _MoodDot({required this.mood});

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
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.circle, color: color, size: 15),
    );
  }
}
