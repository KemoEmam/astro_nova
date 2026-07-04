import 'dart:ui';

/// Visual identity for each of the 10 levels: background, star colors, and
/// an accent used for banners and the level progress bar.
class LevelTheme {
  const LevelTheme({
    required this.name,
    required this.background,
    required this.starDim,
    required this.starBright,
    required this.accent,
  });

  final String name;
  final Color background;
  final Color starDim;
  final Color starBright;
  final Color accent;
}

const levelThemes = <LevelTheme>[
  LevelTheme(
    name: 'DEEP VOID',
    background: Color(0xFF05060F),
    starDim: Color(0xFF3949AB),
    starBright: Color(0xFF9FA8DA),
    accent: Color(0xFF00E5FF),
  ),
  LevelTheme(
    name: 'CRIMSON DRIFT',
    background: Color(0xFF10050A),
    starDim: Color(0xFF880E4F),
    starBright: Color(0xFFF48FB1),
    accent: Color(0xFFFF4081),
  ),
  LevelTheme(
    name: 'EMERALD SECTOR',
    background: Color(0xFF04100B),
    starDim: Color(0xFF1B5E20),
    starBright: Color(0xFFA5D6A7),
    accent: Color(0xFF69F0AE),
  ),
  LevelTheme(
    name: 'AMBER REACH',
    background: Color(0xFF120C04),
    starDim: Color(0xFF8D6E63),
    starBright: Color(0xFFFFCC80),
    accent: Color(0xFFFFAB40),
  ),
  LevelTheme(
    name: 'AZURE ABYSS',
    background: Color(0xFF040A16),
    starDim: Color(0xFF1565C0),
    starBright: Color(0xFF90CAF9),
    accent: Color(0xFF448AFF),
  ),
  LevelTheme(
    name: 'VIOLET EXPANSE',
    background: Color(0xFF0C0614),
    starDim: Color(0xFF6A1B9A),
    starBright: Color(0xFFCE93D8),
    accent: Color(0xFFE040FB),
  ),
  LevelTheme(
    name: 'TEAL RIFT',
    background: Color(0xFF041210),
    starDim: Color(0xFF00695C),
    starBright: Color(0xFF80CBC4),
    accent: Color(0xFF64FFDA),
  ),
  LevelTheme(
    name: 'BLOOD NEBULA',
    background: Color(0xFF140406),
    starDim: Color(0xFFB71C1C),
    starBright: Color(0xFFEF9A9A),
    accent: Color(0xFFFF5252),
  ),
  LevelTheme(
    name: 'GOLDEN STORM',
    background: Color(0xFF141004),
    starDim: Color(0xFFF57F17),
    starBright: Color(0xFFFFF59D),
    accent: Color(0xFFFFD740),
  ),
  LevelTheme(
    name: 'VOID PRIME',
    background: Color(0xFF0E0E14),
    starDim: Color(0xFF9E9E9E),
    starBright: Color(0xFFFFFFFF),
    accent: Color(0xFFEEFF41),
  ),
];
