import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/theme.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/vault_screen.dart';
import 'services/vault_service.dart';
import 'state/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('Thought Circle startup: Flutter bindings initialized.');

  if (Platform.isAndroid || Platform.isIOS) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
    );
  }

  final controller = AppController();
  await controller.initialize();
  debugPrint(
    'Thought Circle startup: vault inspected (${controller.vaultAccess.name}).',
  );
  runApp(ThoughtCircleApp(controller: controller));
  WidgetsBinding.instance.addPostFrameCallback((_) {
    debugPrint('Thought Circle startup: first Flutter frame rendered.');
  });
}

class ThoughtCircleApp extends StatefulWidget {
  const ThoughtCircleApp({super.key, required this.controller});

  final AppController controller;

  @override
  State<ThoughtCircleApp> createState() => _ThoughtCircleAppState();
}

class _ThoughtCircleAppState extends State<ThoughtCircleApp>
    with WidgetsBindingObserver {
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _backgroundedAt ??= DateTime.now();
      return;
    }
    if (state == AppLifecycleState.resumed) {
      final leftAt = _backgroundedAt;
      _backgroundedAt = null;
      if (leftAt != null &&
          DateTime.now().difference(leftAt) >= const Duration(minutes: 2) &&
          widget.controller.vaultAccess == VaultAccess.unlocked) {
        widget.controller.lock().catchError((Object _) {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thought Circle',
      debugShowCheckedModeBanner: false,
      theme: buildThoughtCircleTheme(),
      home: AnimatedBuilder(
        animation: widget.controller,
        builder: (BuildContext context, Widget? child) {
          return switch (widget.controller.vaultAccess) {
            VaultAccess.unlocked =>
              widget.controller.onboardingComplete
                  ? HomeScreen(controller: widget.controller)
                  : OnboardingScreen(controller: widget.controller),
            VaultAccess.setupRequired ||
            VaultAccess.locked => VaultScreen(controller: widget.controller),
          };
        },
      ),
    );
  }
}
