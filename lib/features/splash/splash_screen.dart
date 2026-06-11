import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/themes/environment_theme.dart';
import '../../state/player_controller.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/gradient_background.dart';
import '../login/login_screen.dart';
import '../menu/main_menu_screen.dart';

/// Branded splash with a short, snappy entrance animation. Kept under ~1.2s so
/// it adds polish without becoming a perceptible loading delay.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), _goHome);
  }

  void _goHome() {
    if (!mounted) return;
    // First launch (no name yet) → the welcome/login screen; otherwise the menu.
    final hasUser = ref.read(playerControllerProvider.notifier).hasUsername;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) =>
            hasUser ? const MainMenuScreen() : const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    return Scaffold(
      body: GradientBackground(
        colors: EnvironmentTheme.neon.backgroundGradient,
        child: Center(
          child: ScaleTransition(
            scale: scale,
            child: const BrandLogo(height: 220),
          ),
        ),
      ),
    );
  }
}
