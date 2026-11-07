import 'package:flutter/material.dart';

/// Design tokens extracted from the Stitch prototypes.
abstract final class AppColors {
  static const primary = Color(0xFF005BBF);
  static const primaryContainer = Color(0xFF1A73E8);
  static const primaryFixed = Color(0xFFD8E2FF);
  static const onPrimaryFixedVariant = Color(0xFF004493);
  static const secondary = Color(0xFF006E2A);
  static const tertiary = Color(0xFFB81D17);
  static const error = Color(0xFFBA1A1A);

  static const background = Color(0xFFF7F9FF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF1F4FA);
  static const surfaceContainer = Color(0xFFEBEEF4);

  static const onSurface = Color(0xFF181C20);
  static const onSurfaceVariant = Color(0xFF414754);
  static const outline = Color(0xFF727785);
  static const outlineVariant = Color(0xFFC1C6D6);
  static const neutral = Color(0xFF5F6368);

  static const mapMarker = Color(0xFFEA4335);
  static const success = Color(0xFF137333);
  static const successSurface = Color(0xFFE6F4EA);

  static const splashTop = Color(0xFF071A30);
  static const splashMid = Color(0xFF0D2A4D);
  static const splashBottom = Color(0xFF041224);
  static const sky = Color(0xFF38BDF8);
  static const cyan = Color(0xFF0284C7);
}

abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          primaryContainer: AppColors.primaryContainer,
          onPrimaryContainer: Colors.white,
          secondary: AppColors.secondary,
          onSecondary: Colors.white,
          tertiary: AppColors.tertiary,
          onTertiary: Colors.white,
          error: AppColors.error,
          surface: AppColors.background,
          onSurface: AppColors.onSurface,
          onSurfaceVariant: AppColors.onSurfaceVariant,
          outline: AppColors.outline,
          outlineVariant: AppColors.outlineVariant,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: _textTheme,
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: _textTheme.bodyMedium?.copyWith(
          color: AppColors.outline.withValues(alpha: 0.7),
        ),
        border: _outlineBorder(AppColors.outline),
        enabledBorder: _outlineBorder(AppColors.outline),
        focusedBorder: _outlineBorder(AppColors.primary, width: 2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          textStyle: _textTheme.titleSmall,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: _textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: AppColors.outline),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : Colors.transparent,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static OutlineInputBorder _outlineBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static const TextTheme _textTheme = TextTheme(
    displaySmall: TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: -0.6,
    ),
    headlineLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.333,
      letterSpacing: -0.24,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    headlineSmall: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.333,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.375,
      letterSpacing: 0.16,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.428,
      letterSpacing: 0.14,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0.16,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.428,
      letterSpacing: 0.21,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.333,
      letterSpacing: 0.24,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.428,
      letterSpacing: 0.14,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.333,
      letterSpacing: 0.24,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      height: 1.272,
      letterSpacing: 0.44,
    ),
  );
}
