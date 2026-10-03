import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../data/repositories.dart';
import 'today.dart';
import 'nutrition.dart';
import 'move.dart';
import 'wellness.dart';
import 'settings.dart';
import 'chat.dart';
import '../companion/pip.dart';

/// Main navigation shell: five tabs plus a persistent companion button
/// that opens the Pip chat.
class Shell extends ConsumerStatefulWidget {
  const Shell({super.key});

  @override
  ConsumerState<Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<Shell> {
  int _index = 0;
  final _pipController = PipController();

  static const _tabs = [
    (Icons.wb_sunny_outlined, Icons.wb_sunny, 'Today'),
    (Icons.restaurant_outlined, Icons.restaurant, 'Nutrition'),
    (Icons.directions_run_outlined, Icons.directions_run, 'Move'),
    (Icons.spa_outlined, Icons.spa, 'Wellness'),
    (Icons.person_outline, Icons.person, 'Profile'),
  ];

  @override
  void dispose() {
    _pipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsRepoProvider).settings;
    final pages = const [
      TodayScreen(),
      NutritionScreen(),
      MoveScreen(),
      WellnessScreen(),
      ProfileScreen(),
    ];
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _index, children: pages),
          if (settings.companionVisible && _index != 0)
            Positioned(
              right: 18,
              bottom: 96,
              child: _CompanionFab(
                controller: _pipController,
                onOpen: () => _openChat(context),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(BloomRadii.pill),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.08)
                : BloomColors.line.withOpacity(0.7),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                  Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(BloomRadii.pill),
          child: NavigationBar(
            height: 66,
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            backgroundColor: Colors.transparent,
            elevation: 0,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              for (final t in _tabs)
                NavigationDestination(
                  icon: Icon(t.$1),
                  selectedIcon: Icon(t.$2),
                  label: t.$3,
                ),
            ],
          ),
        ),
      ),
      // Keep scaffold from adding its own padding under our floating bar.
      extendBody: true,
    );
  }

  void _openChat(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
  }
}

class _CompanionFab extends ConsumerWidget {
  final PipController controller;
  final VoidCallback onOpen;
  const _CompanionFab({required this.controller, required this.onOpen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsRepoProvider).settings;
    final accessory = ref.watch(motivationRepoProvider).activeAccessory;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onOpen,
      child: Semantics(
        button: true,
        label: 'Open chat with Pip',
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(dark ? 0.3 : 0.08),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: dark
                  ? Colors.white.withOpacity(0.12)
                  : Theme.of(context).colorScheme.primary.withOpacity(0.2),
              width: 1.2,
            ),
          ),
          padding: const EdgeInsets.all(5),
          child: PipCompanion(
            size: 48,
            controller: controller,
            accessory: accessory,
            reducedMotion: settings.reducedMotion,
          ),
        ),
      ),
    );
  }
}
