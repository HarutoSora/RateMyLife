import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'presentation/screens/screens.dart';
import 'presentation/state/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Anonymous auth gives every device a stable, private identity for
  // syncing its own data without ever collecting a name/email — the
  // same anonymity this app already promises locally. Best-effort: a
  // sign-in failure (offline, provider misconfigured) must not block
  // the app from starting in local-only mode.
  if (FirebaseAuth.instance.currentUser == null) {
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (error) {
      debugPrint('Anonymous sign-in failed, continuing in local-only mode: $error');
    }
  }
  runApp(const ProviderScope(child: RateMyLifeApp()));
}

class RateMyLifeApp extends ConsumerWidget {
  const RateMyLifeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rate My Life',
      theme: AppTheme.dark,
      // A call must appear the instant it starts or arrives no matter
      // which route is on top of the Navigator (calling from inside a
      // pushed ConversationScreen, or an incoming call while three
      // screens deep) — `builder` wraps every route the Navigator ever
      // shows, so layering CallScreen here is route-independent. The
      // old approach (AppShell swapping its own body) only worked when
      // AppShell itself happened to be the topmost route.
      builder: (context, child) => Stack(
        children: [
          if (child != null) child,
          if (state.currentCall != null) const CallScreen(),
        ],
      ),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: state.isLoading
            ? const SplashScreen()
            : !state.hasSeenOnboarding
                ? const OnboardingScreen()
                : state.currentProfile == null
                    ? const ProfileWizardScreen()
                    : const AppShell(),
      ),
    );
  }
}
