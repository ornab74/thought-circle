import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../app/theme.dart';
import '../models/reflection.dart';
import '../services/gemma_service.dart';
import '../state/app_controller.dart';
import '../widgets/soft_card.dart';

class GuidePage extends StatefulWidget {
  const GuidePage({super.key, required this.controller});

  final AppController controller;

  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  final _message = TextEditingController();
  final _scroll = ScrollController();
  GuideMode _mode = GuideMode.reflect;

  @override
  void dispose() {
    _message.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? suggestion]) async {
    final text = (suggestion ?? _message.text).trim();
    if (text.isEmpty) return;
    _message.clear();
    _scrollToEnd();
    try {
      await widget.controller.sendGuideMessage(text, _mode);
    } catch (_) {
      if (mounted) _show(widget.controller.message ?? 'Try again in a moment.');
    }
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  void _show(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return PageGlow(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Guide'),
          actions: <Widget>[
            if (controller.guideTurns.isNotEmpty)
              IconButton(
                tooltip: 'Clear conversation',
                onPressed: controller.guideBusy
                    ? null
                    : () => controller.clearGuideChat(),
                icon: const Icon(Icons.refresh_rounded),
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 5, 18, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Talk it out.',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    _GuideStatus(controller: controller),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedButton<GuideMode>(
                        segments: const <ButtonSegment<GuideMode>>[
                          ButtonSegment(
                            value: GuideMode.reflect,
                            icon: Icon(Icons.chat_bubble_outline_rounded),
                            label: Text('Reflect'),
                          ),
                          ButtonSegment(
                            value: GuideMode.circle,
                            icon: Icon(Icons.circle_outlined),
                            label: Text('My circle'),
                          ),
                          ButtonSegment(
                            value: GuideMode.nextStep,
                            icon: Icon(Icons.arrow_forward_rounded),
                            label: Text('Next step'),
                          ),
                        ],
                        selected: <GuideMode>{_mode},
                        onSelectionChanged: (value) {
                          setState(() => _mode = value.first);
                        },
                        showSelectedIcon: false,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: controller.gemma.hasLoadedModel
                    ? _Conversation(
                        controller: controller,
                        scrollController: _scroll,
                        onSuggestion: _send,
                      )
                    : Column(
                        children: <Widget>[
                          Flexible(
                            flex: 0,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 255),
                              child: _GuideSetup(
                                controller: controller,
                                show: _show,
                              ),
                            ),
                          ),
                          Expanded(
                            child: _Conversation(
                              controller: controller,
                              scrollController: _scroll,
                              onSuggestion: _send,
                            ),
                          ),
                        ],
                      ),
              ),
              if (controller.gemma.hasLoadedModel)
                _Composer(
                  controller: controller,
                  textController: _message,
                  onSend: _send,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Conversation extends StatelessWidget {
  const _Conversation({
    required this.controller,
    required this.scrollController,
    required this.onSuggestion,
  });

  final AppController controller;
  final ScrollController scrollController;
  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) {
    if (controller.guideTurns.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        children: <Widget>[
          SoftCard(
            color: const Color(0xFFF5F2FF),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: ThoughtCircleColors.purple,
                ),
                const SizedBox(height: 12),
                Text(
                  'What’s on your mind?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final prompt in const <String>[
            'Help me name this feeling.',
            'Which loop needs attention?',
            'Give me one small step.',
          ]) ...<Widget>[
            OutlinedButton(
              onPressed: () => onSuggestion(prompt),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 15,
                ),
              ),
              child: Text(prompt),
            ),
            const SizedBox(height: 8),
          ],
        ],
      );
    }
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
      itemCount: controller.guideTurns.length + (controller.guideBusy ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == controller.guideTurns.length) {
          return const Align(
            alignment: Alignment.centerLeft,
            child: _ThinkingBubble(),
          );
        }
        final turn = controller.guideTurns[index];
        final user = turn.role == ChatRole.user;
        return Align(
          alignment: user ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: user ? ThoughtCircleColors.ink : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(user ? 20 : 5),
                bottomRight: Radius.circular(user ? 5 : 20),
              ),
              border: user ? null : Border.all(color: ThoughtCircleColors.line),
            ),
            child: user
                ? Text(
                    turn.text,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                  )
                : _GuideMarkdown(data: turn.text),
          ),
        );
      },
    );
  }
}

class _GuideStatus extends StatelessWidget {
  const _GuideStatus({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final active = controller.gemma.isBusy;
    final ready = controller.gemma.isReady;
    final color = active
        ? ThoughtCircleColors.orange
        : ready
        ? ThoughtCircleColors.purple
        : ThoughtCircleColors.muted;
    return Row(
      children: <Widget>[
        _BreathingDot(color: color, active: active),
        const SizedBox(width: 8),
        Text(
          active
              ? 'Working quietly…'
              : ready
              ? 'Ready when you are'
              : 'Guide is optional',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _BreathingDot extends StatefulWidget {
  const _BreathingDot({required this.color, required this.active});

  final Color color;
  final bool active;

  @override
  State<_BreathingDot> createState() => _BreathingDotState();
}

class _BreathingDotState extends State<_BreathingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _animation.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _BreathingDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _animation.repeat(reverse: true);
    } else if (!widget.active && oldWidget.active) {
      _animation.stop();
      _animation.value = 0;
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, _) => Container(
        width: 12 + (widget.active ? _animation.value * 5 : 0),
        height: 12 + (widget.active ? _animation.value * 5 : 0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: 0.18 + _animation.value * 0.18),
          border: Border.all(color: widget.color, width: 2),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: widget.color.withValues(alpha: 0.24),
              blurRadius: 10,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ThoughtCircleColors.line),
      ),
      child: const SizedBox.square(
        dimension: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _GuideMarkdown extends StatelessWidget {
  const _GuideMarkdown({required this.data});

  final String data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = theme.textTheme.bodyLarge?.copyWith(
      color: ThoughtCircleColors.ink,
    );
    final heading = theme.textTheme.titleMedium?.copyWith(
      color: ThoughtCircleColors.ink,
    );
    return MarkdownBody(
      data: data,
      selectable: true,
      softLineBreak: true,
      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
        p: body,
        a: body?.copyWith(
          color: ThoughtCircleColors.purple,
          decoration: TextDecoration.underline,
        ),
        h1: theme.textTheme.titleLarge,
        h2: heading,
        h3: heading,
        strong: body?.copyWith(fontWeight: FontWeight.w800),
        em: body?.copyWith(fontStyle: FontStyle.italic),
        listBullet: body?.copyWith(color: ThoughtCircleColors.purple),
        blockSpacing: 8,
        listIndent: 20,
        code: theme.textTheme.bodyMedium?.copyWith(
          fontFamily: 'monospace',
          color: ThoughtCircleColors.ink,
          backgroundColor: ThoughtCircleColors.lavender,
        ),
        codeblockPadding: const EdgeInsets.all(12),
        codeblockDecoration: BoxDecoration(
          color: ThoughtCircleColors.lavender.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(12),
        ),
        blockquote: body?.copyWith(color: ThoughtCircleColors.muted),
        blockquotePadding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
        blockquoteDecoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: ThoughtCircleColors.purple, width: 3),
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.textController,
    required this.onSend,
  });

  final AppController controller;
  final TextEditingController textController;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        10,
        14,
        10 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: ThoughtCircleColors.line)),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: textController,
                  enabled: controller.gemma.isReady && !controller.guideBusy,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) {
                    if (controller.gemma.isReady && !controller.guideBusy) {
                      onSend();
                    }
                  },
                  decoration: const InputDecoration(
                    hintText: 'Message…',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 17,
                      vertical: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              IconButton.filled(
                onPressed: controller.guideBusy || !controller.gemma.isReady
                    ? null
                    : onSend,
                icon: const Icon(Icons.arrow_upward_rounded),
              ),
            ],
          ),
          if (controller.guideContextTokens > 0) ...<Widget>[
            const SizedBox(height: 5),
            Text(
              'Context ~${controller.guideContextTokens} / 2,100',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}

class _GuideSetup extends StatelessWidget {
  const _GuideSetup({required this.controller, required this.show});

  final AppController controller;
  final ValueChanged<String> show;

  @override
  Widget build(BuildContext context) {
    final gemma = controller.gemma;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: <Widget>[
        SoftCard(
          color: const Color(0xFFF5F2FF),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const ThoughtCircleMark(size: 46),
              const SizedBox(height: 16),
              Text(
                'Add your local guide',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(gemma.status, style: Theme.of(context).textTheme.bodyMedium),
              if (gemma.installProgress != null) ...<Widget>[
                const SizedBox(height: 16),
                LinearProgressIndicator(value: gemma.installProgress),
                const SizedBox(height: 7),
                Text(
                  gemma.downloadLabel,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: controller.busy
                    ? null
                    : () async {
                        try {
                          if (gemma.state == LocalAiState.readyToLoad) {
                            await controller.loadModel();
                          } else {
                            await controller.downloadModel();
                          }
                        } catch (_) {
                          show(controller.message ?? 'Try again in a moment.');
                        }
                      },
                icon: Icon(
                  gemma.state == LocalAiState.readyToLoad
                      ? Icons.play_arrow_rounded
                      : Icons.download_rounded,
                ),
                label: Text(
                  gemma.state == LocalAiState.readyToLoad
                      ? 'Start local guide'
                      : gemma.canResume
                      ? 'Resume download'
                      : 'Add local guide',
                ),
              ),
              if (gemma.canPause) ...<Widget>[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: controller.pauseModelDownload,
                  icon: const Icon(Icons.pause_rounded),
                  label: const Text('Pause'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'For reflection, not urgent help.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}
