import 'package:flutter/material.dart';

final class ThoughtCircleColors {
  const ThoughtCircleColors._();

  static const Color ink = Color(0xFF171A3D);
  static const Color muted = Color(0xFF68708F);
  static const Color purple = Color(0xFF7357FF);
  static const Color pink = Color(0xFFEF5DBB);
  static const Color orange = Color(0xFFFF914D);
  static const Color gold = Color(0xFFF6B94B);
  static const Color lavender = Color(0xFFF0EDFF);
  static const Color cream = Color(0xFFFFF4EA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFFAF9FE);
  static const Color line = Color(0xFFE8E5F2);
  static const Color good = Color(0xFF2E9D72);
  static const Color dark = Color(0xFF0C0C21);
}

const _sansFallback = <String>[
  'Manrope',
  'Avenir Next',
  'Roboto',
  'Noto Sans',
  'sans-serif',
];

const _serifFallback = <String>[
  'Newsreader',
  'Iowan Old Style',
  'Noto Serif Display',
  'Noto Serif',
  'Georgia',
  'serif',
];

ThemeData buildThoughtCircleTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Manrope',
    fontFamilyFallback: _sansFallback,
    colorScheme: ColorScheme.fromSeed(
      seedColor: ThoughtCircleColors.purple,
      brightness: Brightness.light,
      surface: ThoughtCircleColors.surface,
      primary: ThoughtCircleColors.purple,
      secondary: ThoughtCircleColors.orange,
    ),
  );

  final bodyText = base.textTheme.apply(
    bodyColor: ThoughtCircleColors.ink,
    displayColor: ThoughtCircleColors.ink,
  );

  TextStyle sans({
    required double size,
    FontWeight weight = FontWeight.w400,
    double? height,
    Color color = ThoughtCircleColors.ink,
  }) {
    return TextStyle(
      fontFamily: 'Manrope',
      fontFamilyFallback: _sansFallback,
      fontSize: size,
      fontWeight: weight,
      height: height ?? 1.2,
      letterSpacing: size >= 20 ? -0.35 : -0.05,
      color: color,
    );
  }

  TextStyle serif(double size, double height) {
    return TextStyle(
      fontFamily: 'Newsreader',
      fontFamilyFallback: _serifFallback,
      fontSize: size,
      height: height,
      color: ThoughtCircleColors.ink,
    );
  }

  return base.copyWith(
    scaffoldBackgroundColor: ThoughtCircleColors.background,
    textTheme: bodyText.copyWith(
      displayLarge: serif(50, 1.0),
      headlineLarge: serif(38, 1.05),
      headlineMedium: serif(30, 1.08),
      titleLarge: sans(size: 21, weight: FontWeight.w800, height: 1.18),
      titleMedium: sans(size: 16, weight: FontWeight.w700, height: 1.22),
      bodyLarge: sans(size: 15, height: 1.48),
      bodyMedium: sans(
        size: 14,
        height: 1.42,
        color: ThoughtCircleColors.muted,
      ),
      labelLarge: sans(size: 13, weight: FontWeight.w800),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: ThoughtCircleColors.ink,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: ThoughtCircleColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: const BorderSide(color: ThoughtCircleColors.line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: ThoughtCircleColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: ThoughtCircleColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: ThoughtCircleColors.purple,
          width: 1.6,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ThoughtCircleColors.purple,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: sans(size: 14, weight: FontWeight.w800),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 76,
      elevation: 0,
      backgroundColor: Colors.white,
      indicatorColor: ThoughtCircleColors.lavender,
      labelTextStyle: WidgetStatePropertyAll(
        sans(size: 11, weight: FontWeight.w700),
      ),
    ),
  );
}
