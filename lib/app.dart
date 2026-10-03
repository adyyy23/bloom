import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'core/theme.dart';
import 'core/widgets.dart';
import 'data/repositories.dart';
import 'features/onboarding.dart';
import 'features/shell.dart';
import 'companion/pip.dart';

/// Root of the Bloom app: loads all repositories, applies theme settings,
/// enforces the optional biometric lock, and routes to onboarding or the
/// main shell.
class BloomApp extends ConsumerStatefulWidget {
  const BloomApp({super.key});

  @override
  ConsumerState<BloomApp> createState() => _BloomAppState();
}

class _BloomAppState extends ConsumerState<BloomApp> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    // Load every repository from local storage (all offline).
    ref.read(profileRepoProvider).load();
    ref.read(settingsRepoProvider).load();
    ref.read(foodRepoProvider).load();
    ref.read(recipeRepoProvider).load();
    ref.read(planRepoProvider).load();
    ref.read(progressRepoProvider).load();
    ref.read(moveRepoProvider).load();
    ref.read(wellnessRepoProvider).load();
    ref.read(healthRepoProvider).load();
    ref.read(chatRepoProvider).load();
    ref.read(reminderRepoProvider).load();
    ref.read(motivationRepoProvider).load();
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsRepoProvider).settings;
    final themeMode = switch (settings.themeMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    return MaterialApp(
      title: 'Bloom',
      debugShowCheckedModeBanner: false,
      theme: BloomTheme.light(),
      darkTheme: BloomTheme.dark(),
      themeMode: themeMode,
      home: !_ready
          ? const _Splash()
          : settings.biometricLock
              ? const LockGate(child: _Root())
              : const _Root(),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: PipCompanion(size: 140, reducedMotion: true),
      ),
    );
  }
}

class _Root extends ConsumerWidget {
  const _Root();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = ref.watch(settingsRepoProvider).settings.onboardingDone;
    return done ? const Shell() : const OnboardingFlow();
  }
}

/// Optional biometric app lock shown before the app content.
class LockGate extends StatefulWidget {
  final Widget child;
  const LockGate({super.key, required this.child});

  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> {
  bool _unlocked = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _auth();
  }

  Future<void> _auth() async {
    setState(() => _error = null);
    try {
      final auth = LocalAuthentication();
      final canCheck = await auth.canCheckBiometrics;
      final isSupported = await auth.isDeviceSupported();
      if (!canCheck && !isSupported) {
        // Honest fallback: no biometric hardware here (e.g. web preview).
        setState(() => _error =
            'Biometric unlock is not available on this device, so the app opened without it.');
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) setState(() => _unlocked = true);
        return;
      }
      final ok = await auth.authenticate(
        localizedReason: 'Unlock Bloom to see your health data',
        options: const AuthenticationOptions(biometricOnly: false),
      );
      if (mounted) setState(() => _unlocked = ok);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Could not start biometric unlock: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return widget.child;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(BloomSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const PipCompanion(size: 130, reducedMotion: true),
              const SizedBox(height: BloomSpacing.lg),
              Text('Bloom is locked',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: BloomSpacing.sm),
              Text(
                'Unlock to see your private health data.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (_error != null) ...[
                const SizedBox(height: BloomSpacing.md),
                InfoNote(text: _error!),
              ],
              const SizedBox(height: BloomSpacing.lg),
              PillButton(
                  label: 'Unlock', icon: Icons.fingerprint, onPressed: _auth),
            ],
          ),
        ),
      ),
    );
  }
}
