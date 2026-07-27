import 'package:flutter/material.dart';

import '../state/app_controller.dart';
import '../services/gemma_service.dart';
import 'circle_page.dart';
import '../widgets/soft_card.dart';
import 'guide_page.dart';
import 'journal_page.dart';
import 'mood_colors_page.dart';
import 'settings_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await widget.controller.initializeModel();
        if (widget.controller.gemma.state == LocalAiState.readyToLoad) {
          await widget.controller.loadModel();
        }
      } catch (_) {
        // Local AI remains optional; the rest of the app stays available.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          IndexedStack(
            index: _index,
            children: <Widget>[
              CirclePage(
                controller: widget.controller,
                onOpenGuide: () => setState(() => _index = 3),
                onOpenJournal: () => setState(() => _index = 2),
              ),
              MoodColorsPage(controller: widget.controller),
              JournalPage(controller: widget.controller),
              GuidePage(controller: widget.controller),
              SettingsPage(controller: widget.controller),
            ],
          ),
          if (widget.controller.gemma.state == LocalAiState.loading)
            const _ModelBootOverlay(),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE8E5F2))),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.circle_outlined),
              selectedIcon: Icon(Icons.circle),
              label: 'Circle',
            ),
            NavigationDestination(
              icon: Icon(Icons.palette_outlined),
              selectedIcon: Icon(Icons.palette_rounded),
              label: 'Mood colors',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book_rounded),
              label: 'Journal',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome_rounded),
              label: 'Guide',
            ),
            NavigationDestination(icon: Icon(Icons.tune_rounded), label: 'You'),
          ],
        ),
      ),
    );
  }
}

class _ModelBootOverlay extends StatelessWidget {
  const _ModelBootOverlay();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white.withValues(alpha: 0.94),
      child: Center(
        child: SoftCard(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const ThoughtCircleMark(size: 66),
              const SizedBox(height: 18),
              Text(
                'Opening your local guide',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'A quick on-device check, then you are ready.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              const SizedBox(width: 150, child: LinearProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}
