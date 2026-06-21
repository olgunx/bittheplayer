import 'dart:ui';
import 'package:flutter/material.dart';

class GameTheme {
  // Theme Colors
  static const Color background = Color(0xFF0A0E1A);
  static const Color surface = Color(0xFF151D30);
  static const Color surfaceLight = Color(0xFF1E293B);
  
  static const Color primary = Color(0xFF10B981); // Neon Emerald
  static const Color secondary = Color(0xFF6366F1); // Neon Indigo
  static const Color accent = Color(0xFF06B6D4); // Cyan
  
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  
  static const Color gold = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Gradient definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, Color(0xFFEC4899)], // Indigo to Pink
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [background, Color(0xFF1E1B4B)], // Deep dark blue/indigo
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: error,
      ),
      fontFamily: 'Inter', // Will fall back to system font if not installed
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary),
        headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
        bodyLarge: TextStyle(fontSize: 16, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: textSecondary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x3394A3B8), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        hintStyle: const TextStyle(color: textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0x3394A3B8), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }
}

// Reusable Frosted Glass Card
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? borderColor;
  final Color? fillColor;

  const GlassCard({
    Key? key,
    required this.child,
    this.padding,
    this.borderRadius = 16,
    this.borderColor,
    this.fillColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: fillColor ?? const Color(0x1A1E293B), // Translucent fill
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? const Color(0x1F94A3B8), // Muted translucent border
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// Reusable Gradient Button
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final LinearGradient gradient;
  final IconData? icon;
  final double height;
  final double? width;

  const GradientButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.gradient = GameTheme.primaryGradient,
    this.icon,
    this.height = 54,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;
    
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: isEnabled ? gradient : null,
        color: isEnabled ? null : GameTheme.textMuted.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: gradient.colors.first.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: isEnabled ? Colors.white : GameTheme.textMuted, size: 20),
              const SizedBox(width: 10),
            ],
            Text(
              text,
              style: TextStyle(
                color: isEnabled ? Colors.white : GameTheme.textMuted,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
