import 'dart:ui';

/// Central color palette — the whole game is vector-rendered, so this file
/// *is* the art direction.
abstract final class Palette {
  static const background = Color(0xFF05060F);
  static const player = Color(0xFF00E5FF);
  static const playerCore = Color(0xFFB2FFFF);
  static const bullet = Color(0xFF76FF03);
  static const shield = Color(0xFF40C4FF);

  static const enemyDrifter = Color(0xFFFF4081);
  static const enemyWeaver = Color(0xFFFFAB40);
  static const enemyTank = Color(0xFFB388FF);

  static const powerUpWeapon = Color(0xFFFFEB3B);
  static const powerUpShield = Color(0xFF40C4FF);

  static const starDim = Color(0xFF3949AB);
  static const starBright = Color(0xFF9FA8DA);
}
