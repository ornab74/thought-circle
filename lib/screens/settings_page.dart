import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../services/gemma_service.dart';
import '../state/app_controller.dart';
import '../widgets/soft_card.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return PageGlow(
      child: CustomScrollView(
        slivers: <Widget>[
          const SliverAppBar(title: Text('You')),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 5, 18, 34),
            sliver: SliverList.list(
              children: <Widget>[
                Text(
                  'Make it yours.',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 20),
                const SectionLabel('Local guide'),
                const SizedBox(height: 9),
                _GemmaCard(controller: controller),
                const SizedBox(height: 25),
                const SectionLabel('My space'),
                const SizedBox(height: 9),
                SoftCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 5,
                  ),
                  child: Column(
                    children: <Widget>[
                      _SettingTile(
                        icon: Icons.password_rounded,
                        color: ThoughtCircleColors.purple,
                        title: 'Startup password',
                        onTap: () => _changePassword(context),
                      ),
                      const Divider(height: 1),
                      _SettingTile(
                        icon: Icons.lock_clock_outlined,
                        color: ThoughtCircleColors.orange,
                        title: 'Lock now',
                        onTap: controller.busy
                            ? null
                            : () async {
                                try {
                                  await controller.lock();
                                } catch (_) {
                                  if (context.mounted) _show(context);
                                }
                              },
                      ),
                      const Divider(height: 1),
                      _SettingTile(
                        icon: Icons.explore_outlined,
                        color: ThoughtCircleColors.pink,
                        title: 'Welcome guide',
                        onTap: controller.restartOnboarding,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                const SectionLabel('About'),
                const SizedBox(height: 9),
                const SoftCard(
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  child: Column(
                    children: <Widget>[
                      _SettingTile(
                        icon: Icons.cloud_off_outlined,
                        color: ThoughtCircleColors.good,
                        title: 'Works on this device',
                        subtitle: 'No account or cloud chat',
                      ),
                      Divider(height: 1),
                      _SettingTile(
                        icon: Icons.health_and_safety_outlined,
                        color: ThoughtCircleColors.orange,
                        title: 'Reflection support',
                        subtitle: 'Not medical or emergency care',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'Thought Circle 0.2',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword(BuildContext context) async {
    final password = TextEditingController();
    final confirm = TextEditingController();
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New startup password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: password,
              autofocus: true,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            const SizedBox(height: 11),
            TextField(
              controller: confirm,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm password'),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Change'),
          ),
        ],
      ),
    );
    if (approved != true || !context.mounted) {
      password.dispose();
      confirm.dispose();
      return;
    }
    if (password.text != confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Those passwords do not match.')),
      );
      password.dispose();
      confirm.dispose();
      return;
    }
    try {
      await controller.changePassword(password.text);
      if (context.mounted) _show(context);
    } catch (_) {
      if (context.mounted) _show(context);
    } finally {
      password.dispose();
      confirm.dispose();
    }
  }

  void _show(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(controller.message ?? 'Try again.')),
      );
  }
}

class _GemmaCard extends StatelessWidget {
  const _GemmaCard({required this.controller});

  final AppController controller;

  Future<void> _act(BuildContext context) async {
    try {
      final state = controller.gemma.state;
      if (state == LocalAiState.ready) {
        await controller.closeModel();
      } else if (state == LocalAiState.readyToLoad) {
        await controller.loadModel();
      } else {
        await controller.downloadModel();
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(controller.message ?? 'Try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gemma = controller.gemma;
    return SoftCard(
      color: const Color(0xFFF7F4FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[
                      ThoughtCircleColors.purple,
                      ThoughtCircleColors.pink,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Gemma 4 E2B',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      gemma.status,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: <Widget>[
              _InfoPill(icon: Icons.phone_android_rounded, label: 'On device'),
              _InfoPill(icon: Icons.memory_rounded, label: '2,100 context'),
              _InfoPill(icon: Icons.mic_rounded, label: 'Voice notes'),
            ],
          ),
          if (gemma.installProgress != null) ...<Widget>[
            const SizedBox(height: 17),
            LinearProgressIndicator(value: gemma.installProgress),
            const SizedBox(height: 7),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    gemma.downloadLabel,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (gemma.totalDownloadBytes > 0)
                  Text(
                    '${(gemma.installProgress! * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          if (gemma.canPause)
            FilledButton.icon(
              onPressed: controller.pauseModelDownload,
              icon: const Icon(Icons.pause_rounded),
              label: const Text('Pause download'),
            )
          else
            FilledButton.icon(
              onPressed: controller.busy ? null : () => _act(context),
              icon: Icon(_actionIcon(gemma.state)),
              label: Text(_actionLabel(gemma)),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: controller.busy
                ? null
                : () async {
                    try {
                      await controller.chooseAndInstallModel();
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
            icon: const Icon(Icons.folder_open_rounded),
            label: const Text('Choose a model file'),
          ),
        ],
      ),
    );
  }

  String _actionLabel(GemmaService gemma) => switch (gemma.state) {
    LocalAiState.ready => 'Stop Gemma',
    LocalAiState.readyToLoad => 'Start Gemma',
    LocalAiState.paused => 'Resume download',
    LocalAiState.error when gemma.canResume => 'Resume download',
    LocalAiState.loading => 'Starting…',
    LocalAiState.working => 'Gemma is working…',
    _ => 'Download Gemma · about 2.4 GB',
  };

  IconData _actionIcon(LocalAiState state) => switch (state) {
    LocalAiState.ready => Icons.power_settings_new_rounded,
    LocalAiState.readyToLoad => Icons.play_arrow_rounded,
    LocalAiState.paused => Icons.play_arrow_rounded,
    _ => Icons.download_rounded,
  };
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ThoughtCircleColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: ThoughtCircleColors.purple),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: color, size: 21),
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded),
    );
  }
}
