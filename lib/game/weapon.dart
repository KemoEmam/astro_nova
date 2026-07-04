import 'dart:ui';

/// The 30-tier weapon progression.
///
/// Tiers are generated from a progression formula so every pickup changes
/// something real: straight barrels, spread pairs, homing missiles, piercing,
/// damage, and fire rate each unlock and grow on their own schedule, and the
/// bullet look (color + shape) evolves through the tiers.
class ShotSpec {
  const ShotSpec({
    this.dx = 0,
    this.dy = 0,
    this.angleDeg = 0,
    this.damage = 1,
    this.pierce = 0,
    this.homing = false,
  });

  final double dx;
  final double dy;

  /// Degrees off straight-up; positive fans right.
  final double angleDeg;
  final int damage;

  /// Extra enemies the bullet can pass through after the first hit.
  final int pierce;
  final bool homing;
}

enum BulletShape { bolt, diamond, orb, beam }

class WeaponSpec {
  const WeaponSpec(
      this.name, this.fireInterval, this.shots, this.color, this.shape);

  final String name;
  final double fireInterval;
  final List<ShotSpec> shots;
  final Color color;
  final BulletShape shape;
}

const maxWeaponLevel = 30;

const _weaponNames = <String>[
  'PULSE SHOT', 'TWIN PULSE', 'SPREAD BOLT', 'RAPID BOLT', 'TRI CANNON',
  'ARC VOLLEY', 'PRISM FANG', 'PRISM FANG+', 'LANCE DRIVER', 'QUAD LANCE',
  'STORM EDGE', 'SEEKER SPARK', 'NOVA BURST', 'NOVA BURST+', 'ION SCATTER',
  'ION TEMPEST', 'PHASE RIPPER', 'PHASE RIPPER+', 'HELIX STORM', 'DUAL SEEKER',
  'PLASMA REIGN', 'PLASMA REIGN+', 'QUASAR FANG', 'QUASAR FANG+', 'NEBULA WRATH',
  'TRIPLE SEEKER', 'SUPERNOVA', 'SUPERNOVA+', 'EVENT HORIZON', 'VOID LASER',
];

const _tierColors = <Color>[
  Color(0xFF76FF03), // lime
  Color(0xFF00E5FF), // cyan
  Color(0xFFFFEB3B), // yellow
  Color(0xFFFFAB40), // orange
  Color(0xFFFF4081), // pink
  Color(0xFFE040FB), // purple
  Color(0xFF448AFF), // blue
  Color(0xFF64FFDA), // teal
  Color(0xFFFF5252), // red
  Color(0xFFEEFF41), // void yellow-green
];

WeaponSpec _tier(int level) {
  // Unlock schedule (level thresholds).
  final straightBarrels = 1 +
      (level >= 4 ? 1 : 0) +
      (level >= 10 ? 1 : 0) +
      (level >= 16 ? 1 : 0) +
      (level >= 22 ? 1 : 0) +
      (level >= 28 ? 1 : 0);
  final spreadPairs = (level >= 3 ? 1 : 0) +
      (level >= 7 ? 1 : 0) +
      (level >= 13 ? 1 : 0) +
      (level >= 19 ? 1 : 0) +
      (level >= 25 ? 1 : 0);
  final homingPairs =
      (level >= 12 ? 1 : 0) + (level >= 20 ? 1 : 0) + (level >= 26 ? 1 : 0);

  final damage = 1 + (level - 1) ~/ 7;
  final pierce = level >= 9 ? (level - 5) ~/ 5 : 0;
  final fireInterval = 0.30 - 0.0076 * (level - 1);

  final shots = <ShotSpec>[];
  // Straight barrels, centered.
  for (var i = 0; i < straightBarrels; i++) {
    final offset = (i - (straightBarrels - 1) / 2) * 9.0;
    shots.add(ShotSpec(dx: offset, damage: damage, pierce: pierce));
  }
  // Angled pairs at widening angles; slightly weaker, no pierce.
  for (var p = 0; p < spreadPairs; p++) {
    final angle = 12.0 + p * 8.0;
    final dx = 12.0 + p * 5.0;
    final dy = 4.0 + p * 2.0;
    final spreadDamage = (damage - (p >= 2 ? 1 : 0)).clamp(1, damage);
    shots.add(ShotSpec(dx: -dx, dy: dy, angleDeg: -angle, damage: spreadDamage));
    shots.add(ShotSpec(dx: dx, dy: dy, angleDeg: angle, damage: spreadDamage));
  }
  // Homing missiles from the wingtips.
  for (var h = 0; h < homingPairs; h++) {
    final dx = 17.0 + h * 4.0;
    final dy = 9.0 + h * 3.0;
    shots.add(ShotSpec(dx: -dx, dy: dy, homing: true, damage: damage));
    shots.add(ShotSpec(dx: dx, dy: dy, homing: true, damage: damage));
  }

  final shape = switch (level) {
    <= 8 => BulletShape.bolt,
    <= 16 => BulletShape.diamond,
    <= 24 => BulletShape.orb,
    _ => BulletShape.beam,
  };

  return WeaponSpec(
    _weaponNames[level - 1],
    fireInterval,
    shots,
    _tierColors[(level - 1) * _tierColors.length ~/ maxWeaponLevel],
    shape,
  );
}

final weaponLevels = List<WeaponSpec>.unmodifiable(
  List.generate(maxWeaponLevel, (i) => _tier(i + 1)),
);

/// Shield progression: 5 unique tiers.
/// 1-2: more charges. 3-4: absorbing a hit releases a shockwave that clears
/// nearby enemies. 5: charges regenerate over time.
const maxShieldLevel = 5;

const shieldNames = <String>[
  'AEGIS I',
  'AEGIS II',
  'NOVA GUARD',
  'NOVA GUARD+',
  'ETERNAL AEGIS',
];

bool shieldHasShockwave(int level) => level >= 3;
bool shieldRegenerates(int level) => level >= 5;
double shieldShockwaveRadius(int level) => level >= 4 ? 170 : 130;
