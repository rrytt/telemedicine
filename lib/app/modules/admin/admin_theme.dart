import 'package:flutter/material.dart';

class AdminStyles {
  AdminStyles._();

  static const Color navy = Color(0xFF1E3A5F);
  static const Color navyDark = Color(0xFF0A1F3A);
  static const Color blue = Color(0xFF3B82F6);
  static const Color blueDark = Color(0xFF1E5A7D);
  static const Color slate = Color(0xFF5C6F87);
  static const Color slateLight = Color(0xFF8DA0B5);
  static const Color border = Color(0xFFE2E8F0);
  static const Color textSecondary = Color(0xFF4A627A);
  static const Color textPrimary = Color(0xFF0A1F3A);
  static const Color surface = Color(0xFFF8FAFC);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFFEA500);
  static const Color danger = Color(0xFFEF4444);

  static BoxDecoration get backgroundGradient => const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topLeft,
          radius: 1.2,
          colors: [Color(0xFFEFF3FC), Color(0xFFD9E2EF), Color(0xFFC9D5E8)],
          stops: [0.0, 0.6, 1.0],
        ),
      );

  static BoxDecoration get glassCard => BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, 12),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.7),
          width: 1.2,
        ),
      );

  static InputDecoration inputDecoration({
    required String label,
    String? hint,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(fontWeight: FontWeight.w500, color: slate),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: blue, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      prefixIcon: prefixIcon,
    );
  }

  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: navy.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        minimumSize: const Size(double.infinity, 54),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      );

  static BoxDecoration cardDecoration({double borderRadius = 20}) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 6),
          spreadRadius: 0,
        ),
      ],
      border: Border.all(color: border.withValues(alpha: 0.5), width: 1),
    );
  }

  static const TextStyle sectionHeader = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static const TextStyle statValue = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: textPrimary,
  );

  static const TextStyle statLabel = TextStyle(
    fontSize: 13,
    color: slate,
    fontWeight: FontWeight.w600,
  );
}
