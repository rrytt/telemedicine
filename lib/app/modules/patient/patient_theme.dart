import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PatientStyles {
  PatientStyles._();

  static bool get _isDark => Get.isDarkMode;

  // Light colors
  static const Color _navyLight = Color(0xFF1A3A5C);
  static const Color _navyDark = Color(0xFF0A1F3A);
  static const Color _teal = Color(0xFF4ECDC4);
  static const Color _blueAccent = Color(0xFF2980B9);
  static const Color _slateLight = Color(0xFF5C6F87);
  static const Color _slateLighter = Color(0xFF8DA0B5);
  static const Color _borderLight = Color(0xFFE2E8F0);
  static const Color _textSecondaryLight = Color(0xFF4ECDC4);
  static const Color _textPrimaryLight = Color(0xFF1A3A5C);
  static const Color _surfaceLight = Color(0xFFF8FAFC);
  static const Color _success = Color(0xFF4ECDC4);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _warning = Color(0xFF4ECDC4);
  static const Color _ratingStar = Color(0xFF4ECDC4);

  // Dark mode colors
  static const Color _darkSurface = Color(0xFF1E293B);
  static const Color _darkBorder = Color(0xFF334155);
  static const Color _darkTextPrimary = Color(0xFFF1F5F9);
  static const Color _darkTextSecondary = Color(0xFF94A3B8);

  // Dynamic colors
  static Color get navy => _isDark ? Color(0xFF1E3A5F) : _navyLight;
  static Color get navyDark => _navyDark;
  static Color get teal => _teal;
  static Color get blueAccent => _blueAccent;
  static Color get slate => _isDark ? _darkTextSecondary : _slateLight;
  static Color get slateLight => _isDark ? _darkTextSecondary : _slateLighter;
  static Color get border => _isDark ? _darkBorder : _borderLight;
  static Color get textSecondary => _isDark ? _darkTextSecondary : _textSecondaryLight;
  static Color get textPrimary => _isDark ? _darkTextPrimary : _textPrimaryLight;
  static Color get surface => _isDark ? _darkSurface : _surfaceLight;
  static Color get success => _success;
  static Color get danger => _danger;
  static Color get warning => _warning;
  static Color get primary => _teal;
  static Color get ratingStar => _ratingStar;

  static BoxDecoration get backgroundGradient => _isDark
      ? BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.2,
            colors: const [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF162033)],
            stops: const [0.0, 0.6, 1.0],
          ),
        )
      : BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.2,
            colors: const [Color(0xFFEFF3FC), Color(0xFFD9E2EF), Color(0xFFC9D5E8)],
            stops: const [0.0, 0.6, 1.0],
          ),
        );

  static BoxDecoration get glassCard => BoxDecoration(
        color: _isDark
            ? _darkSurface.withValues(alpha: 0.94)
            : Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: _isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, 12),
            spreadRadius: 0,
          ),
          if (!_isDark)
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.4),
              blurRadius: 4,
              offset: const Offset(0, -1),
            ),
        ],
        border: Border.all(
          color: _isDark ? _darkBorder.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.7),
          width: 1.2,
        ),
      );

  static InputDecoration inputDecoration({
    required String label,
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(
        fontWeight: FontWeight.w500,
        color: _isDark ? _darkTextSecondary : _slateLight,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: _isDark ? _darkBorder : _borderLight, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: _teal, width: 2),
      ),
      filled: true,
      fillColor: _isDark ? _darkSurface : Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
    );
  }

  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: _teal.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        minimumSize: const Size(double.infinity, 54),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      );

  static ButtonStyle get secondaryButton => ElevatedButton.styleFrom(
        backgroundColor: _isDark ? _darkSurface : _surfaceLight,
        foregroundColor: _isDark ? _darkTextPrimary : _navyLight,
        elevation: 0,
        shadowColor: Colors.transparent,
        side: BorderSide(color: _isDark ? _darkBorder : _borderLight, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        minimumSize: const Size(double.infinity, 52),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      );

  static BoxDecoration cardDecoration({
    double borderRadius = 20,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: _isDark ? _darkSurface.withValues(alpha: 0.94) : Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: _isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 6),
          spreadRadius: 0,
        ),
      ],
      border: Border.all(
        color: borderColor ?? (_isDark ? _darkBorder : _borderLight).withValues(alpha: 0.5),
        width: 1,
      ),
    );
  }

  static TextStyle get sectionHeader => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: _isDark ? _darkTextPrimary : _textPrimaryLight,
      );

  static TextStyle get bodyText => TextStyle(
        fontSize: 14,
        color: _isDark ? _darkTextSecondary : _textSecondaryLight,
      );
}
