import 'package:flutter/material.dart';

/// Shared neon look for all overlay UI.
const kAccent = Color(0xFF00E5FF);
const kGold = Color(0xFFFFD740);

TextStyle neon(double size, {Color color = kAccent, FontWeight? weight}) {
  return TextStyle(
    color: color,
    fontSize: size,
    fontWeight: weight ?? FontWeight.w600,
    letterSpacing: 2,
    shadows: [Shadow(color: color.withValues(alpha: 0.8), blurRadius: 12)],
  );
}

class NeonButton extends StatelessWidget {
  const NeonButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: kAccent,
        side: const BorderSide(color: kAccent, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      child: Text(label, style: neon(18)),
    );
  }
}
