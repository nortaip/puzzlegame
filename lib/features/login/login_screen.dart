import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/haptics.dart';
import '../../game/themes/environment_theme.dart';
import '../../state/player_controller.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/gradient_background.dart';
import '../menu/main_menu_screen.dart';

/// First-launch "login": the player picks a display name, which becomes their
/// user identity (shown in the menu and on the leaderboard).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final name = _controller.text.trim();
    if (name.length < 2 || _busy) return;
    setState(() => _busy = true);
    Haptics.selection();
    await ref.read(playerControllerProvider.notifier).setUsername(name);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => const MainMenuScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: GradientBackground(
        colors: EnvironmentTheme.neon.backgroundGradient,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: GlassPanel(
                opacity: 0.22,
                padding: const EdgeInsets.all(26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_parking_rounded,
                        size: 64, color: Colors.white),
                    const SizedBox(height: 14),
                    const Text('Welcome!',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    const Text('Choose a name to start playing',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 22),
                    TextField(
                      controller: _controller,
                      textAlign: TextAlign.center,
                      maxLength: 16,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _start(),
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700),
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        counterStyle: const TextStyle(color: Colors.white38),
                        hintText: 'Your name',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed:
                            _controller.text.trim().length >= 2 ? _start : null,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Start Playing'),
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
