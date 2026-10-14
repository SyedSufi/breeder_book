import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// Corner radii — Organic Biophilic (16–24px).
abstract final class AppRadii {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double pill = 28;
}

/// Natural shadow tokens from MASTER.md.
abstract final class AppShadows {
  static List<BoxShadow> sm(Color ink) => [
        BoxShadow(
          color: ink.withValues(alpha: 0.05),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> md(Color ink) => [
        BoxShadow(
          color: ink.withValues(alpha: 0.10),
          blurRadius: 6,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> lg(Color ink) => [
        BoxShadow(
          color: ink.withValues(alpha: 0.10),
          blurRadius: 15,
          offset: const Offset(0, 10),
        ),
      ];
}

ThemeData buildAppTheme() => _build(AppColors.lightScheme(), Brightness.light);

ThemeData buildAppDarkTheme() =>
    _build(AppColors.darkScheme(), Brightness.dark);

ThemeData _build(ColorScheme scheme, Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scaffoldBg =
      isDark ? AppColors.darkBackground : AppColors.background;
  final border = isDark ? AppColors.darkBorder : AppColors.border;
  final muted = isDark ? AppColors.darkMuted : AppColors.muted;

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: scaffoldBg,
    canvasColor: scaffoldBg,
    dividerColor: border,
  );

  // Calm hierarchy approximating Lora (titles) + Raleway (body) weights
  // without adding google_fonts (ask owner before new deps).
  final textTheme = base.textTheme
      .copyWith(
        headlineLarge: base.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: scheme.onSurface,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: scheme.onSurface,
        ),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: scheme.onSurface,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: scheme.onSurface,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        titleSmall: base.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w400,
          height: 1.45,
          color: scheme.onSurface,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w400,
          height: 1.45,
          color: scheme.onSurface,
        ),
        bodySmall: base.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w400,
          color: scheme.onSurfaceVariant,
        ),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      )
      .apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      );

  return base.copyWith(
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: scaffoldBg,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      systemOverlayStyle:
          (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
              .copyWith(statusBarColor: Colors.transparent),
      titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 22),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      height: 68,
      indicatorColor: scheme.primaryContainer,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? scheme.primary : scheme.onSurfaceVariant,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 24,
          color: selected ? scheme.primary : scheme.onSurfaceVariant,
        );
      }),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      // Accent/CTA per MASTER — sun amber for primary actions.
      backgroundColor: scheme.tertiary,
      foregroundColor: scheme.onTertiary,
      elevation: 3,
      focusElevation: 4,
      highlightElevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.primary,
        side: BorderSide(color: scheme.primary, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: scheme.primary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: BorderSide(color: border),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: muted,
      selectedColor: scheme.secondaryContainer,
      checkmarkColor: scheme.onSecondaryContainer,
      labelStyle: TextStyle(color: scheme.onSurface, fontSize: 13),
      secondaryLabelStyle: TextStyle(color: scheme.onSecondaryContainer),
      side: BorderSide(color: border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      showDragHandle: true,
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      iconColor: scheme.primary,
    ),
    dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
    focusColor: scheme.primary.withValues(alpha: 0.18),
  );
}
