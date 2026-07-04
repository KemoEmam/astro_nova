import 'dart:ui';

/// Timed run-buff granted by a Boss Core. Shown in the HUD sidebar with a
/// countdown bar; all effects vanish when the timer runs out.
class ActiveBuff {
  ActiveBuff({
    required this.name,
    required this.color,
    required this.duration,
    this.fireRateFactor = 1.0,
    this.bonusDamage = 0,
    this.magnet = false,
    this.scoreFactor = 1.0,
  }) : remaining = duration;

  final String name;
  final Color color;
  final double duration;
  final double fireRateFactor;
  final int bonusDamage;
  final bool magnet;
  final double scoreFactor;
  double remaining;
}

/// One unique timed relic per level's boss fight.
ActiveBuff bossRelicFor(int level) {
  switch (level) {
    case 1:
      return ActiveBuff(
          name: 'OVERCLOCK', color: const Color(0xFF76FF03), duration: 30, fireRateFactor: 0.75);
    case 2:
      return ActiveBuff(
          name: 'MAGNET CORE', color: const Color(0xFF00E5FF), duration: 35, magnet: true);
    case 3:
      return ActiveBuff(
          name: 'AMP CORE', color: const Color(0xFFFFEB3B), duration: 30, bonusDamage: 1);
    case 4:
      return ActiveBuff(
          name: 'GREED CORE', color: const Color(0xFFFFD740), duration: 30, scoreFactor: 2.0);
    case 5:
      return ActiveBuff(
          name: 'OVERCLOCK II', color: const Color(0xFFFFAB40), duration: 30, fireRateFactor: 0.7);
    case 6:
      return ActiveBuff(
          name: 'MAGNET CORE II', color: const Color(0xFFFF4081), duration: 45, magnet: true);
    case 7:
      return ActiveBuff(
          name: 'AMP CORE II', color: const Color(0xFFE040FB), duration: 30, bonusDamage: 2);
    case 8:
      return ActiveBuff(
          name: 'GREED CORE II', color: const Color(0xFF448AFF), duration: 30, scoreFactor: 2.5);
    case 9:
      return ActiveBuff(
          name: 'OVERCLOCK III', color: const Color(0xFF64FFDA), duration: 30, fireRateFactor: 0.6);
    default:
      return ActiveBuff(
        name: 'VOID SURGE',
        color: const Color(0xFFEEFF41),
        duration: 40,
        fireRateFactor: 0.6,
        bonusDamage: 2,
        magnet: true,
        scoreFactor: 2.0,
      );
  }
}
