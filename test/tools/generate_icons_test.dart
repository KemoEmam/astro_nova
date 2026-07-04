// One-off asset generator, kept as a test so it needs no extra tooling:
//   flutter test test/tools/generate_icons_test.dart
// Draws the AstroNova nova-star icon with dart:ui and writes the web icons.
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

Future<void> _writeIcon(String path, int size, {double padding = 0}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final s = size.toDouble();
  final center = ui.Offset(s / 2, s / 2);
  final scale = (1 - padding * 2);

  // Deep-space background with a subtle radial nebula.
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, s, s),
    ui.Paint()..color = const ui.Color(0xFF05060F),
  );
  canvas.drawCircle(
    center,
    s * 0.48,
    ui.Paint()
      ..shader = ui.Gradient.radial(center, s * 0.48, [
        const ui.Color(0xFF1A237E).withValues(alpha: 0.55),
        const ui.Color(0xFF05060F).withValues(alpha: 0),
      ]),
  );

  // Star dust.
  final random = Random(7);
  final starPaint = ui.Paint()..color = const ui.Color(0xFF9FA8DA);
  for (var i = 0; i < 26; i++) {
    canvas.drawCircle(
      ui.Offset(random.nextDouble() * s, random.nextDouble() * s),
      s * (0.003 + random.nextDouble() * 0.005),
      starPaint,
    );
  }

  // The nova: a glowing 4-point star in cyan with a magenta orbit ring.
  ui.Path novaPath(double r) {
    final path = ui.Path();
    for (var i = 0; i < 8; i++) {
      final radius = i.isEven ? r : r * 0.22;
      final a = -pi / 2 + i * pi / 4;
      final p = ui.Offset(
          center.dx + radius * cos(a), center.dy + radius * sin(a));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  final r = s * 0.34 * scale;
  // Orbit ring behind the star.
  canvas.drawOval(
    ui.Rect.fromCenter(center: center, width: r * 2.4, height: r * 1.0),
    ui.Paint()
      ..color = const ui.Color(0xFFFF4081).withValues(alpha: 0.85)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = s * 0.022
      ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, s * 0.01),
  );
  // Glow layers.
  canvas.drawPath(
    novaPath(r),
    ui.Paint()
      ..color = const ui.Color(0xFF00E5FF).withValues(alpha: 0.55)
      ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, s * 0.05),
  );
  canvas.drawPath(
    novaPath(r),
    ui.Paint()
      ..color = const ui.Color(0xFF00E5FF)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = s * 0.018,
  );
  canvas.drawPath(
    novaPath(r * 0.55),
    ui.Paint()..color = const ui.Color(0xFF00E5FF).withValues(alpha: 0.35),
  );
  // White-hot core.
  canvas.drawCircle(
    center,
    s * 0.045,
    ui.Paint()
      ..color = const ui.Color(0xFFFFFFFF)
      ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, s * 0.01),
  );

  final image = await recorder.endRecording().toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  testWidgets('generate web icons', (tester) async {
    await tester.runAsync(() async {
      await _writeIcon('web/favicon.png', 64);
      await _writeIcon('web/icons/Icon-192.png', 192);
      await _writeIcon('web/icons/Icon-512.png', 512);
      await _writeIcon('web/icons/Icon-maskable-192.png', 192, padding: 0.1);
      await _writeIcon('web/icons/Icon-maskable-512.png', 512, padding: 0.1);
    });
    expect(File('web/favicon.png').existsSync(), isTrue);
  });
}
