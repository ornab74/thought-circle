import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../state/app_controller.dart';
import '../widgets/soft_card.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_page < 3) {
      await _pages.nextPage(
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeOutCubic,
      );
    } else {
      await widget.controller.finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageGlow(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 12, 0),
                child: Row(
                  children: <Widget>[
                    const ThoughtCircleMark(size: 38),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'ThoughtCircle',
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TextButton(
                      onPressed: () => widget.controller.finishOnboarding(),
                      child: const Text('Skip'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pages,
                  onPageChanged: (value) => setState(() => _page = value),
                  children: <Widget>[
                    const _WelcomeStep(),
                    const _LoopStep(),
                    const _JournalStep(),
                    _GemmaStep(controller: widget.controller),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        for (var index = 0; index < 4; index++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: index == _page ? 24 : 7,
                            height: 7,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: index == _page
                                  ? ThoughtCircleColors.purple
                                  : ThoughtCircleColors.line,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 17),
                    Row(
                      children: <Widget>[
                        if (_page > 0)
                          IconButton.outlined(
                            onPressed: () => _pages.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            ),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                        if (_page > 0) const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: _next,
                            child: Text(
                              _page == 3 ? 'Enter my circle' : 'Continue',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepFrame extends StatelessWidget {
  const _StepFrame({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.visual,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget visual;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            eyebrow.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: ThoughtCircleColors.purple,
              letterSpacing: 1.35,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          Text(title, style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: ThoughtCircleColors.muted),
          ),
          const SizedBox(height: 28),
          visual,
        ],
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep();

  @override
  Widget build(BuildContext context) {
    return _StepFrame(
      eyebrow: 'Welcome',
      title: 'Break the loop.\nBuild clarity.',
      subtitle: 'Put recurring thoughts where you can see them.',
      visual: SizedBox(
        height: 290,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const SweepGradient(
                    colors: <Color>[
                      ThoughtCircleColors.orange,
                      ThoughtCircleColors.pink,
                      ThoughtCircleColors.purple,
                      ThoughtCircleColors.orange,
                    ],
                  ),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(color: Color(0x307055F8), blurRadius: 40),
                  ],
                ),
              ),
              Container(
                width: 222,
                height: 222,
                decoration: const BoxDecoration(
                  color: ThoughtCircleColors.background,
                  shape: BoxShape.circle,
                ),
              ),
              SoftCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('5', style: Theme.of(context).textTheme.displayLarge),
                    const Text('active loops'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoopStep extends StatelessWidget {
  const _LoopStep();

  @override
  Widget build(BuildContext context) {
    return _StepFrame(
      eyebrow: 'Your circle',
      title: 'One loop.\nOne next step.',
      subtitle: 'Open a thought, see it clearly, and move.',
      visual: Column(
        children: <Widget>[
          for (final item in const <(IconData, String, String, Color)>[
            (
              Icons.circle_outlined,
              'Name it',
              'Use your own words.',
              ThoughtCircleColors.purple,
            ),
            (
              Icons.lightbulb_outline_rounded,
              'See it',
              'Find the useful signal.',
              ThoughtCircleColors.pink,
            ),
            (
              Icons.arrow_forward_rounded,
              'Move',
              'Choose something small.',
              ThoughtCircleColors.orange,
            ),
          ]) ...<Widget>[
            SoftCard(
              child: Row(
                children: <Widget>[
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: item.$4.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(item.$1, color: item.$4),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          item.$2,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.$3,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _JournalStep extends StatelessWidget {
  const _JournalStep();

  @override
  Widget build(BuildContext context) {
    return _StepFrame(
      eyebrow: 'Journal',
      title: 'Speak it.\nKeep what matters.',
      subtitle: 'Voice or text becomes a clean daily note.',
      visual: Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            colors: <Color>[Color(0xFFF0ECFF), Color(0xFFFFF0E8)],
          ),
          border: Border.all(color: ThoughtCircleColors.line),
        ),
        child: Column(
          children: <Widget>[
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: ThoughtCircleColors.purple,
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(color: Color(0x337355FF), blurRadius: 30),
                ],
              ),
              child: const Icon(
                Icons.mic_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Today, I noticed…',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 7),
            Text(
              'Transcript · summary · highlights',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _GemmaStep extends StatelessWidget {
  const _GemmaStep({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final gemma = controller.gemma;
    return _StepFrame(
      eyebrow: 'Optional',
      title: 'Add your\nlocal guide.',
      subtitle: 'Gemma brings summaries, plans, and chat.',
      visual: SoftCard(
        color: const Color(0xFFF7F4FF),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                const ThoughtCircleMark(size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Gemma 4 E2B',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        gemma.status,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (gemma.installProgress != null) ...<Widget>[
              const SizedBox(height: 18),
              LinearProgressIndicator(value: gemma.installProgress),
              const SizedBox(height: 7),
              Text(
                gemma.downloadLabel,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 18),
            if (gemma.canPause)
              OutlinedButton.icon(
                onPressed: controller.pauseModelDownload,
                icon: const Icon(Icons.pause_rounded),
                label: const Text('Pause download'),
              )
            else
              FilledButton.icon(
                onPressed: controller.busy
                    ? null
                    : () async {
                        try {
                          await controller.downloadModel();
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  controller.message ??
                                      'Try again in a moment.',
                                ),
                              ),
                            );
                          }
                        }
                      },
                icon: Icon(
                  gemma.canResume
                      ? Icons.play_arrow_rounded
                      : Icons.download_rounded,
                ),
                label: Text(
                  gemma.canResume ? 'Resume download' : 'Download Gemma',
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'About 2.4 GB · pause anytime',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
