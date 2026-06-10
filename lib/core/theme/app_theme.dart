import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The application's Material 3 theme. Individual game screens layer their own
/// [EnvironmentTheme] gradients on top of this neutral baseline.
class AppTheme {
  AppTheme._();

  static const Color seed = Color(0xFF5B6CFF);

  static ThemeData get dark {
    final base = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      scaffoldBackgroundColor: const Color(0xFF0E0B1E),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
