import 'package:flutter/material.dart';

/// The dark, high-contrast palette used across Lockout.
///
/// The design language is intentionally "quiet terminal": near-black surfaces,
/// mint for a healthy allowance, coral for a hard block and amber for time that
/// needs attention. Screens stay readable outdoors without turning the whole app
/// into a warning banner.
class LockoutPalette {
  const LockoutPalette._();

  static const Color background = Color(0xFF060A0C);
  static const Color surface = Color(0xFF101619);
  static const Color surfaceHigh = Color(0xFF172024);
  static const Color surfaceSoft = Color(0xFF1D292D);
  static const Color outline = Color(0xFF243337);
  static const Color mint = Color(0xFF63F4CE);
  static const Color mintDeep = Color(0xFF12362F);
  static const Color coral = Color(0xFFFF9696);
  static const Color coralDeep = Color(0xFF3A1C1F);
  static const Color amber = Color(0xFFFFC75C);
  static const Color text = Color(0xFFF2F9F7);
  static const Color muted = Color(0xFF899895);
}

/// Material 3 themes for Lockout.
class AppTheme {
  const AppTheme._();

  static ThemeData get light => dark;

  static ThemeData get dark => _build();

  static ThemeData _build() {
    final scheme =
        const ColorScheme.dark(
          primary: LockoutPalette.mint,
          onPrimary: LockoutPalette.background,
          primaryContainer: LockoutPalette.mintDeep,
          onPrimaryContainer: LockoutPalette.mint,
          secondary: Color(0xFFB9D7D0),
          onSecondary: LockoutPalette.background,
          secondaryContainer: Color(0xFF18302B),
          onSecondaryContainer: Color(0xFFCDEFE6),
          tertiary: LockoutPalette.amber,
          onTertiary: LockoutPalette.background,
          tertiaryContainer: Color(0xFF3A2C12),
          onTertiaryContainer: LockoutPalette.amber,
          error: LockoutPalette.coral,
          onError: LockoutPalette.background,
          errorContainer: LockoutPalette.coralDeep,
          onErrorContainer: Color(0xFFFFD9D9),
          surface: LockoutPalette.background,
          onSurface: LockoutPalette.text,
          onSurfaceVariant: LockoutPalette.muted,
          outline: LockoutPalette.outline,
          outlineVariant: Color(0xFF1A2629),
          inverseSurface: Color(0xFFE6F2EE),
          onInverseSurface: LockoutPalette.background,
          inversePrimary: Color(0xFF0E6E5C),
          shadow: Color(0xFF000000),
          scrim: Color(0xB3000000),
        ).copyWith(
          surfaceContainerLowest: LockoutPalette.background,
          surfaceContainerLow: Color(0xFF0B1113),
          surfaceContainer: LockoutPalette.surface,
          surfaceContainerHigh: LockoutPalette.surfaceHigh,
          surfaceContainerHighest: LockoutPalette.surfaceSoft,
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: LockoutPalette.background,
      canvasColor: LockoutPalette.background,
      splashFactory: InkSparkle.splashFactory,
    );
    final typography = base.textTheme.apply(
      bodyColor: LockoutPalette.text,
      displayColor: LockoutPalette.text,
    );

    return base.copyWith(
      textTheme: typography.copyWith(
        displaySmall: typography.displaySmall?.copyWith(
          fontSize: 42,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.6,
          height: 1.05,
        ),
        headlineMedium: typography.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.9,
        ),
        headlineSmall: typography.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        titleLarge: typography.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleMedium: typography.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
        titleSmall: typography.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: typography.bodyMedium?.copyWith(
          height: 1.4,
          color: LockoutPalette.text,
        ),
        bodySmall: typography.bodySmall?.copyWith(
          height: 1.4,
          color: LockoutPalette.muted,
        ),
        labelLarge: typography.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        labelSmall: typography.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: LockoutPalette.muted,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: LockoutPalette.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: LockoutPalette.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        toolbarHeight: 76,
        iconTheme: IconThemeData(color: LockoutPalette.text, size: 22),
        actionsIconTheme: IconThemeData(color: LockoutPalette.muted, size: 21),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: LockoutPalette.surface,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: LockoutPalette.outline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          backgroundColor: LockoutPalette.mint,
          foregroundColor: LockoutPalette.background,
          disabledBackgroundColor: LockoutPalette.surfaceHigh,
          disabledForegroundColor: LockoutPalette.muted,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          foregroundColor: LockoutPalette.text,
          side: const BorderSide(color: LockoutPalette.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: LockoutPalette.mint,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: LockoutPalette.muted,
          highlightColor: LockoutPalette.mint.withValues(alpha: 0.12),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: LockoutPalette.mint,
        inactiveTrackColor: LockoutPalette.surfaceSoft,
        thumbColor: LockoutPalette.mint,
        overlayColor: LockoutPalette.mint.withValues(alpha: 0.14),
        valueIndicatorColor: LockoutPalette.mint,
        valueIndicatorTextStyle: const TextStyle(
          color: LockoutPalette.background,
          fontWeight: FontWeight.w700,
        ),
        trackHeight: 6,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? LockoutPalette.background
              : LockoutPalette.muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? LockoutPalette.mint
              : LockoutPalette.surfaceSoft,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? LockoutPalette.mint
              : LockoutPalette.outline,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? LockoutPalette.mint
              : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(LockoutPalette.background),
        side: const BorderSide(color: LockoutPalette.muted, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: LockoutPalette.surfaceHigh,
        selectedColor: LockoutPalette.mint,
        disabledColor: LockoutPalette.surface,
        labelStyle: const TextStyle(
          color: LockoutPalette.text,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        secondaryLabelStyle: const TextStyle(
          color: LockoutPalette.background,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
        side: const BorderSide(color: LockoutPalette.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LockoutPalette.surface,
        hintStyle: const TextStyle(color: LockoutPalette.muted),
        prefixIconColor: LockoutPalette.muted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: LockoutPalette.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: LockoutPalette.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: LockoutPalette.mint, width: 1.4),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: LockoutPalette.outline,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: LockoutPalette.mint,
        linearTrackColor: LockoutPalette.surfaceSoft,
        circularTrackColor: LockoutPalette.surfaceSoft,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: LockoutPalette.surfaceHigh,
        contentTextStyle: const TextStyle(color: LockoutPalette.text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: LockoutPalette.outline),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: LockoutPalette.surface,
        indicatorColor: LockoutPalette.mintDeep,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? LockoutPalette.mint
                : LockoutPalette.muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: LockoutPalette.muted,
        textColor: LockoutPalette.text,
      ),
    );
  }
}
