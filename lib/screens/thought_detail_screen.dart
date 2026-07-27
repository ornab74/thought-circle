import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/thought.dart';
import '../state/app_controller.dart';
import '../widgets/soft_card.dart';
import 'guide_page.dart';

class ThoughtDetailScreen extends StatelessWidget {
  const ThoughtDetailScreen({
    super.key,
    required this.controller,
    required this.thoughtId,
  });

  final AppController controller;
  final String thoughtId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final thought = controller.findThought(thoughtId);
        if (thought == null) {
          return const Scaffold(
            body: Center(child: Text('This loop is gone.')),
          );
        }
        return PageGlow(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text('Loop'),
              actions: <Widget>[
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenu(context, thought, value),
                  itemBuilder: (context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: thought.state == ThoughtState.active
                          ? 'settle'
                          : 'restore',
                      child: Text(
                        thought.state == ThoughtState.active
                            ? 'Mark as moved through'
                            : 'Return to circle',
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Delete loop'),
                    ),
                  ],
                ),
              ],
            ),
            body: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 38),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _ThoughtHeader(thought: thought),
                        const SizedBox(height: 22),
                        if (thought.plan == null)
                          _NoPlan(controller: controller, thought: thought)
                        else
                          _PlanTabs(
                            controller: controller,
                            thought: thought,
                            plan: thought.plan!,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleMenu(
    BuildContext context,
    Thought thought,
    String value,
  ) async {
    try {
      if (value == 'delete') {
        final approved = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete this loop?'),
            content: const Text('This removes the loop and its plan.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (approved == true) {
          await controller.deleteThought(thought.id);
          if (context.mounted) Navigator.pop(context);
        }
      } else if (value == 'settle') {
        await controller.settleThought(thought.id);
      } else if (value == 'restore') {
        await controller.restoreThought(thought.id);
      }
    } catch (_) {
      if (context.mounted) {
        showMessage(context, controller.message ?? 'Try again.');
      }
    }
  }

  static void showMessage(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}

class _ThoughtHeader extends StatelessWidget {
  const _ThoughtHeader({required this.thought});

  final Thought thought;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                thought.color.withValues(alpha: 0.18),
                thought.color.withValues(alpha: 0.06),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: thought.color.withValues(alpha: 0.3)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: thought.color.withValues(alpha: 0.15),
                blurRadius: 26,
              ),
            ],
          ),
          child: Icon(thought.icon, size: 31, color: thought.color),
        ),
        const SizedBox(height: 15),
        Text(
          thought.title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        if (thought.detail.isNotEmpty) ...<Widget>[
          const SizedBox(height: 7),
          Text(
            '“${thought.detail}”',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: ThoughtCircleColors.muted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

class _NoPlan extends StatelessWidget {
  const _NoPlan({required this.controller, required this.thought});

  final AppController controller;
  final Thought thought;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SoftCard(
          color: const Color(0xFFFFF7F0),
          child: Row(
            children: <Widget>[
              const _FeatureIcon(
                icon: Icons.route_rounded,
                color: ThoughtCircleColors.orange,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Find the next step',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose a quick plan or ask Gemma.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: controller.busy
              ? null
              : () async {
                  try {
                    await controller.makeStarterPlan(thought.id);
                  } catch (_) {
                    if (context.mounted) {
                      ThoughtDetailScreen.showMessage(context, 'Try again.');
                    }
                  }
                },
          icon: const Icon(Icons.bolt_rounded),
          label: const Text('Quick plan'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
          ),
        ),
        const SizedBox(height: 10),
        GradientAction(
          title: 'Build with Gemma',
          subtitle: controller.gemma.isReady
              ? 'Made around this loop'
              : 'Start Gemma in You',
          icon: Icons.auto_awesome_rounded,
          onTap: controller.busy
              ? null
              : () async {
                  if (!controller.gemma.isReady) {
                    ThoughtDetailScreen.showMessage(
                      context,
                      'Start Gemma from the You tab first.',
                    );
                    return;
                  }
                  try {
                    await controller.makeAiPlan(thought.id);
                  } catch (_) {
                    if (context.mounted) {
                      ThoughtDetailScreen.showMessage(
                        context,
                        controller.message ?? 'Try again.',
                      );
                    }
                  }
                },
        ),
      ],
    );
  }
}

class _PlanTabs extends StatefulWidget {
  const _PlanTabs({
    required this.controller,
    required this.thought,
    required this.plan,
  });

  final AppController controller;
  final Thought thought;
  final ThoughtPlan plan;

  @override
  State<_PlanTabs> createState() => _PlanTabsState();
}

class _PlanTabsState extends State<_PlanTabs> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Understanding(plan: widget.plan),
        const SizedBox(height: 12),
        _Support(controller: widget.controller, plan: widget.plan),
        const SizedBox(height: 12),
        _Actions(
          controller: widget.controller,
          thought: widget.thought,
          plan: widget.plan,
        ),
      ],
    );
  }
}

class _Understanding extends StatelessWidget {
  const _Understanding({required this.plan});

  final ThoughtPlan plan;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _CardHeading(
            icon: Icons.psychology_alt_outlined,
            title: 'Understanding the loop',
            color: ThoughtCircleColors.orange,
          ),
          const SizedBox(height: 15),
          Text(
            plan.understanding,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _Support extends StatelessWidget {
  const _Support({required this.controller, required this.plan});

  final AppController controller;
  final ThoughtPlan plan;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SoftCard(
          color: const Color(0xFFF7F4FF),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _CardHeading(
                icon: Icons.auto_awesome_rounded,
                title: 'Guide insight',
                color: ThoughtCircleColors.purple,
              ),
              const SizedBox(height: 15),
              Text(plan.support, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GradientAction(
          title: 'Talk to your guide',
          subtitle: 'Keep exploring this loop',
          icon: Icons.chat_bubble_outline_rounded,
          onTap: controller.gemma.isReady
              ? () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => GuidePage(controller: controller),
                  ),
                )
              : () => ThoughtDetailScreen.showMessage(
                  context,
                  'Start Gemma from the You tab first.',
                ),
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.controller,
    required this.thought,
    required this.plan,
  });

  final AppController controller;
  final Thought thought;
  final ThoughtPlan plan;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SectionLabel('Anti-looping chain'),
        const SizedBox(height: 9),
        SoftCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Column(
            children: <Widget>[
              for (var index = 0; index < plan.steps.length; index++)
                _StepRow(
                  step: plan.steps[index],
                  last: index == plan.steps.length - 1,
                  onTap: () =>
                      controller.toggleStep(thought.id, plan.steps[index].id),
                ),
            ],
          ),
        ),
        if (plan.helpfulActions.isNotEmpty) ...<Widget>[
          const SizedBox(height: 20),
          const SectionLabel('Quick options'),
          const SizedBox(height: 9),
          SoftCard(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Column(
              children: <Widget>[
                for (final action in plan.helpfulActions)
                  ListTile(
                    leading: const Icon(
                      Icons.bolt_rounded,
                      color: ThoughtCircleColors.orange,
                      size: 20,
                    ),
                    title: Text(action),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 19),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.last, required this.onTap});

  final ThoughtStep step;
  final bool last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Column(
              children: <Widget>[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: step.done
                        ? ThoughtCircleColors.orange
                        : ThoughtCircleColors.cream,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    step.done ? Icons.check_rounded : Icons.circle_outlined,
                    color: step.done
                        ? Colors.white
                        : ThoughtCircleColors.orange,
                    size: 17,
                  ),
                ),
                if (!last)
                  Container(
                    width: 1,
                    height: 31,
                    color: ThoughtCircleColors.line,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    step.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      decoration: step.done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.detail,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardHeading extends StatelessWidget {
  const _CardHeading({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _FeatureIcon(icon: icon, color: color),
        const SizedBox(width: 11),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
      ],
    );
  }
}

class _FeatureIcon extends StatelessWidget {
  const _FeatureIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
