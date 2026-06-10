import 'package:flutter/material.dart';

/// Visual environment themes that re-skin the board, background and palette.
class EnvironmentTheme {
  const EnvironmentTheme({
    required this.id,
    required this.name,
    required this.backgroundGradient,
    required this.boardColor,
    required this.gridLineColor,
    required this.exitGlow,
    required this.targetColor,
    required this.vehiclePalette,
  });

  final int id;
  final String name;
  final List<Color> backgroundGradient;
  final Color boardColor;
  final Color gridLineColor;
  final Color exitGlow;
  final Color targetColor;
  final List<Color> vehiclePalette;

  Color vehicleColor(int skinIndex) =>
      vehiclePalette[skinIndex % vehiclePalette.length];

  static const List<EnvironmentTheme> all = [city, neon, rainy, desert, snow];

  static EnvironmentTheme byIndex(int i) => all[i % all.length];

  static const city = EnvironmentTheme(
    id: 0,
    name: 'City',
    backgroundGradient: [Color(0xFF6DD5FA), Color(0xFF2980B9)],
    boardColor: Color(0xFFECEFF4),
    gridLineColor: Color(0x22000000),
    exitGlow: Color(0xFF2ECC71),
    targetColor: Color(0xFFE74C3C),
    vehiclePalette: [
      Color(0xFF3498DB),
      Color(0xFF9B59B6),
      Color(0xFFF39C12),
      Color(0xFF1ABC9C),
      Color(0xFF34495E),
      Color(0xFFE67E22),
    ],
  );

  static const neon = EnvironmentTheme(
    id: 1,
    name: 'Night Neon',
    backgroundGradient: [Color(0xFF0F0C29), Color(0xFF302B63)],
    boardColor: Color(0xFF1B1830),
    gridLineColor: Color(0x33FFFFFF),
    exitGlow: Color(0xFF00FFC6),
    targetColor: Color(0xFFFF2E63),
    vehiclePalette: [
      Color(0xFF00E5FF),
      Color(0xFFB388FF),
      Color(0xFFFFEA00),
      Color(0xFF1DE9B6),
      Color(0xFFFF6E40),
      Color(0xFFEEFF41),
    ],
  );

  static const rainy = EnvironmentTheme(
    id: 2,
    name: 'Rainy Road',
    backgroundGradient: [Color(0xFF485563), Color(0xFF29323C)],
    boardColor: Color(0xFFCfD8DC),
    gridLineColor: Color(0x22000000),
    exitGlow: Color(0xFF4FC3F7),
    targetColor: Color(0xFFEF5350),
    vehiclePalette: [
      Color(0xFF26A69A),
      Color(0xFF7E57C2),
      Color(0xFFFFB74D),
      Color(0xFF42A5F5),
      Color(0xFF66BB6A),
      Color(0xFF8D6E63),
    ],
  );

  static const desert = EnvironmentTheme(
    id: 3,
    name: 'Desert Highway',
    backgroundGradient: [Color(0xFFF2C94C), Color(0xFFE67E22)],
    boardColor: Color(0xFFFFF3E0),
    gridLineColor: Color(0x22000000),
    exitGlow: Color(0xFF2ECC71),
    targetColor: Color(0xFFC0392B),
    vehiclePalette: [
      Color(0xFF8E44AD),
      Color(0xFF2980B9),
      Color(0xFF16A085),
      Color(0xFFD35400),
      Color(0xFF7F8C8D),
      Color(0xFF27AE60),
    ],
  );

  static const snow = EnvironmentTheme(
    id: 4,
    name: 'Snow',
    backgroundGradient: [Color(0xFFE6DADA), Color(0xFF8E9EAB)],
    boardColor: Color(0xFFFFFFFF),
    gridLineColor: Color(0x1A000000),
    exitGlow: Color(0xFF42A5F5),
    targetColor: Color(0xFFE53935),
    vehiclePalette: [
      Color(0xFF5C6BC0),
      Color(0xFF26C6DA),
      Color(0xFFAB47BC),
      Color(0xFFFFA726),
      Color(0xFF66BB6A),
      Color(0xFF78909C),
    ],
  );
}
