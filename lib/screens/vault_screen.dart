import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../services/vault_service.dart';
import '../state/app_controller.dart';
import '../widgets/soft_card.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _passwordFocus = FocusNode(debugLabel: 'vault-password');
  final _confirmFocus = FocusNode(debugLabel: 'vault-password-confirmation');
  bool _obscure = true;
  bool _showPasswordStep = false;
  bool _usePassword = true;

  bool get _isSetup =>
      widget.controller.vaultAccess == VaultAccess.setupRequired;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _passwordFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final password = _password.text;
    if (_isSetup && password != _confirm.text) {
      _show('The passwords do not match.');
      return;
    }
    try {
      if (_isSetup) {
        await widget.controller.createVault(password);
      } else {
        await widget.controller.unlock(password);
      }
    } catch (_) {
      if (mounted) _show(widget.controller.message ?? 'Please try again.');
    }
  }

  void _show(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isSetup && !_showPasswordStep) {
      return _buildWelcome(context);
    }
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Row(
                    children: <Widget>[
                      ThoughtCircleMark(size: 48),
                      SizedBox(width: 14),
                      Text(
                        'Thought Circle',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: ThoughtCircleColors.ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 46),
                  Text(
                    _isSetup
                        ? 'A private place\nfor busy thoughts.'
                        : 'Welcome back.',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _isSetup
                        ? 'Create a startup password for this space.'
                        : 'Enter your password to open your circle.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: ThoughtCircleColors.muted,
                    ),
                  ),
                  const SizedBox(height: 30),
                  SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (_isSetup)
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            value: _usePassword,
                            onChanged: (value) =>
                                setState(() => _usePassword = value),
                            title: const Text('Use a startup password'),
                            subtitle: Text(
                              _usePassword
                                  ? 'Recommended for a private space.'
                                  : 'Anyone with access to this device can open it.',
                            ),
                          ),
                        if (!_isSetup || _usePassword)
                          TextField(
                            controller: _password,
                            focusNode: _passwordFocus,
                            obscureText: _obscure,
                            autofocus: true,
                            textInputAction: _isSetup
                                ? TextInputAction.next
                                : TextInputAction.done,
                            onSubmitted: (_) {
                              if (_isSetup) {
                                _confirmFocus.requestFocus();
                              } else {
                                _submit();
                              }
                            },
                            decoration: InputDecoration(
                              labelText: _isSetup
                                  ? 'Create password'
                                  : 'Password',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                          ),
                        if (_isSetup && _usePassword) ...<Widget>[
                          const SizedBox(height: 14),
                          TextField(
                            controller: _confirm,
                            focusNode: _confirmFocus,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            decoration: const InputDecoration(
                              labelText: 'Confirm password',
                              prefixIcon: Icon(
                                Icons.check_circle_outline_rounded,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Use at least 12 characters. Keep it somewhere safe.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                        const SizedBox(height: 22),
                        FilledButton.icon(
                          onPressed: widget.controller.busy ? null : _submit,
                          icon: widget.controller.busy
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.arrow_forward_rounded),
                          label: Text(
                            _isSetup ? 'Create my circle' : 'Open my circle',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.shield_outlined,
                        size: 18,
                        color: ThoughtCircleColors.good,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No account. No ads. Just your space.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcome(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: SoftCard(
                padding: const EdgeInsets.all(28),
                color: const Color(0xFFF7F4FF),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const ThoughtCircleMark(size: 64),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome to Thought Circle',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'A quiet place to name what is on your mind, see patterns, and choose one useful next step.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 22),
                    const _WelcomePoint(
                      icon: Icons.circle_outlined,
                      text:
                          'Capture thoughts, journals, and moods in one simple space.',
                    ),
                    const _WelcomePoint(
                      icon: Icons.auto_awesome_outlined,
                      text:
                          'Use the optional local guide when you want another perspective.',
                    ),
                    const _WelcomePoint(
                      icon: Icons.lock_outline_rounded,
                      text: 'Your circle stays on this device.',
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () =>
                            setState(() => _showPasswordStep = true),
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('Set up my circle'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomePoint extends StatelessWidget {
  const _WelcomePoint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: ThoughtCircleColors.purple),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
