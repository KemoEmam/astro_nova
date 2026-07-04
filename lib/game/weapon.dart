/// The 10-tier weapon progression. Each tier is a hand-designed loadout, not
/// just a stat bump — new barrels, spread angles, piercing, homing, and fire
/// rate arrive at specific tiers so every pickup feels different.
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

class WeaponSpec {
  const WeaponSpec(this.name, this.fireInterval, this.shots);

  final String name;
  final double fireInterval;
  final List<ShotSpec> shots;
}

const maxWeaponLevel = 10;

const weaponLevels = <WeaponSpec>[
  WeaponSpec('PULSE SHOT', 0.30, [ShotSpec()]),
  WeaponSpec('TWIN CANNON', 0.28, [
    ShotSpec(dx: -8),
    ShotSpec(dx: 8),
  ]),
  WeaponSpec('TRIPLE SPREAD', 0.26, [
    ShotSpec(),
    ShotSpec(dx: -10, dy: 4, angleDeg: -12),
    ShotSpec(dx: 10, dy: 4, angleDeg: 12),
  ]),
  WeaponSpec('RAPID SPREAD', 0.19, [
    ShotSpec(),
    ShotSpec(dx: -10, dy: 4, angleDeg: -12),
    ShotSpec(dx: 10, dy: 4, angleDeg: 12),
  ]),
  WeaponSpec('QUAD BARRAGE', 0.19, [
    ShotSpec(dx: -6),
    ShotSpec(dx: 6),
    ShotSpec(dx: -12, dy: 5, angleDeg: -18),
    ShotSpec(dx: 12, dy: 5, angleDeg: 18),
  ]),
  WeaponSpec('PIERCING LANCE', 0.19, [
    ShotSpec(damage: 2, pierce: 2),
    ShotSpec(dx: -12, dy: 5, angleDeg: -15),
    ShotSpec(dx: 12, dy: 5, angleDeg: 15),
  ]),
  WeaponSpec('PENTA STORM', 0.17, [
    ShotSpec(damage: 2, pierce: 2),
    ShotSpec(dx: -9, dy: 3, angleDeg: -12),
    ShotSpec(dx: 9, dy: 3, angleDeg: 12),
    ShotSpec(dx: -16, dy: 7, angleDeg: -24),
    ShotSpec(dx: 16, dy: 7, angleDeg: 24),
  ]),
  WeaponSpec('HOMING FURY', 0.17, [
    ShotSpec(damage: 2, pierce: 2),
    ShotSpec(dx: -9, dy: 3, angleDeg: -12),
    ShotSpec(dx: 9, dy: 3, angleDeg: 12),
    ShotSpec(dx: -18, dy: 10, homing: true),
    ShotSpec(dx: 18, dy: 10, homing: true),
  ]),
  WeaponSpec('OVERDRIVE', 0.13, [
    ShotSpec(damage: 2, pierce: 3),
    ShotSpec(dx: -9, dy: 3, angleDeg: -12, damage: 2),
    ShotSpec(dx: 9, dy: 3, angleDeg: 12, damage: 2),
    ShotSpec(dx: -18, dy: 10, homing: true, damage: 2),
    ShotSpec(dx: 18, dy: 10, homing: true, damage: 2),
  ]),
  WeaponSpec('VOID LASER', 0.10, [
    ShotSpec(damage: 3, pierce: 6),
    ShotSpec(dx: -7, damage: 3, pierce: 6),
    ShotSpec(dx: 7, damage: 3, pierce: 6),
    ShotSpec(dx: -14, dy: 5, angleDeg: -20, damage: 2),
    ShotSpec(dx: 14, dy: 5, angleDeg: 20, damage: 2),
    ShotSpec(dx: -20, dy: 12, homing: true, damage: 2),
    ShotSpec(dx: 20, dy: 12, homing: true, damage: 2),
  ]),
];

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
