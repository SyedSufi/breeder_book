import 'package:flutter/material.dart';

/// BirdsRecord palette — Organic Biophilic / Plant Care Tracker
/// (ui-ux-pro-max design-system/birdsrecord/MASTER.md).
abstract final class AppColors {
  // —— Light ——
  static const Color primary = Color(0xFF15803D);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFF059669);
  static const Color onSecondary = Color(0xFF000000);
  static const Color accent = Color(0xFFD97706);
  static const Color onAccent = Color(0xFF000000);
  static const Color background = Color(0xFFF0FDF4);
  static const Color foreground = Color(0xFF0F172A);
  static const Color card = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFFF0F7F3);
  static const Color mutedForeground = Color(0xFF475569);
  static const Color border = Color(0xFFE2EFE7);
  static const Color destructive = Color(0xFFDC2626);
  static const Color onDestructive = Color(0xFFFFFFFF);
  static const Color ring = Color(0xFF15803D);

  // —— Dark (same brand, biophilic surfaces) ——
  static const Color darkBackground = Color(0xFF0C1A12);
  static const Color darkForeground = Color(0xFFF0FDF4);
  static const Color darkCard = Color(0xFF15261C);
  static const Color darkMuted = Color(0xFF1A2E22);
  static const Color darkMutedForeground = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF2A3F32);
  static const Color darkPrimary = Color(0xFF4ADE80);
  static const Color darkOnPrimary = Color(0xFF052E16);
  static const Color darkSecondary = Color(0xFF34D399);
  static const Color darkAccent = Color(0xFFFBBF24);

  /// Aliases used by shell / older call sites.
  static const Color surface = card;
  static const Color onSurface = foreground;
  static const Color primaryCta = primary;

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: Color(0xFFDCFCE7),
      onPrimaryContainer: Color(0xFF14532D),
      secondary: secondary,
      onSecondary: onPrimary,
      secondaryContainer: Color(0xFFD1FAE5),
      onSecondaryContainer: Color(0xFF064E3B),
      tertiary: accent,
      onTertiary: onAccent,
      tertiaryContainer: Color(0xFFFEF3C7),
      onTertiaryContainer: Color(0xFF78350F),
      error: destructive,
      onError: onDestructive,
      surface: card,
      onSurface: foreground,
      onSurfaceVariant: mutedForeground,
      outline: border,
      outlineVariant: Color(0xFFC5DDD0),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF1E293B),
      onInverseSurface: Color(0xFFF8FAFC),
      inversePrimary: Color(0xFF86EFAC),
      surfaceTint: primary,
    );
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: darkPrimary,
      onPrimary: darkOnPrimary,
      primaryContainer: Color(0xFF14532D),
      onPrimaryContainer: Color(0xFFDCFCE7),
      secondary: darkSecondary,
      onSecondary: darkOnPrimary,
      secondaryContainer: Color(0xFF064E3B),
      onSecondaryContainer: Color(0xFFD1FAE5),
      tertiary: darkAccent,
      onTertiary: Color(0xFF451A03),
      tertiaryContainer: Color(0xFF92400E),
      onTertiaryContainer: Color(0xFFFEF3C7),
      error: destructive,
      onError: onDestructive,
      surface: darkCard,
      onSurface: darkForeground,
      onSurfaceVariant: darkMutedForeground,
      outline: darkBorder,
      outlineVariant: Color(0xFF3D5245),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFE2E8F0),
      onInverseSurface: Color(0xFF0F172A),
      inversePrimary: primary,
      surfaceTint: darkPrimary,
    );
  }
}
