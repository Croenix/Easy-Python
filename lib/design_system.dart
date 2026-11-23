import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ink = Color(0xFF202545);
  static const blue = Color(0xFF3478F6);
  static const violet = Color(0xFF7666F4);
  static const orange = Color(0xFFFFA23A);
  static const coral = Color(0xFFFF745E);
  static const green = Color(0xFF16A58A);
  static const danger = Color(0xFFD94D62);
  static const code = Color(0xFF18243D);

  static const lightBackground = Color(0xFFF4F6FF);
  static const lightSurface = Colors.white;
  static const lightBorder = Color(0xFFE6EAF6);
  static const darkBackground = Color(0xFF111329);
  static const darkSurface = Color(0xFF1B1E39);
  static const darkBorder = Color(0xFF303451);
}

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final surface = dark ? AppColors.darkSurface : AppColors.lightSurface;
    final background = dark
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final border = dark ? AppColors.darkBorder : AppColors.lightBorder;
    final foreground = dark ? const Color(0xFFF3F4FF) : AppColors.ink;
    final muted = dark ? const Color(0xFFB2B7D1) : const Color(0xFF68758B);
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.violet,
          brightness: brightness,
          primary: AppColors.blue,
          secondary: AppColors.violet,
          tertiary: AppColors.orange,
          surface: surface,
          error: AppColors.danger,
        ).copyWith(
          onSurface: foreground,
          onSurfaceVariant: muted,
          outline: border,
          surface: surface,
          surfaceContainerLowest: background,
          surfaceContainerLow: dark
              ? const Color(0xFF20233F)
              : const Color(0xFFF8F9FD),
          surfaceContainer: dark
              ? const Color(0xFF242844)
              : const Color(0xFFF3F5FB),
          surfaceContainerHigh: dark
              ? const Color(0xFF292D49)
              : const Color(0xFFEEF1F8),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: surface,
      fontFamily: 'Poppins',
      textTheme: ThemeData(
        brightness: brightness,
        fontFamily: 'Poppins',
      ).textTheme.apply(bodyColor: foreground, displayColor: foreground),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: foreground,
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: dark ? 0 : 2,
        shadowColor: dark ? Colors.transparent : const Color(0x160F2860),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: border),
        ),
        titleTextStyle: TextStyle(
          color: foreground,
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(
          color: muted,
          fontFamily: 'Poppins',
          fontSize: 14,
          height: 1.5,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: dark ? const Color(0xFF242844) : const Color(0xFFF0F3F6),
        surfaceTintColor: Colors.transparent,
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        labelStyle: TextStyle(
          fontFamily: 'Poppins',
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.blue,
        textColor: foreground,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF242844) : const Color(0xFFF6F7FC),
        hintStyle: TextStyle(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.blue, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: AppColors.ink,
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
          minimumSize: const Size(44, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.blue,
          side: BorderSide(color: border),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.blue,
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: dark
            ? const Color(0xFF37345C)
            : const Color(0xFFE8E7FF),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.blue);
          }
          return IconThemeData(color: muted);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontFamily: 'Poppins',
              color: AppColors.blue,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            );
          }
          return TextStyle(
            fontFamily: 'Poppins',
            color: muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? const Color(0xFF303451) : AppColors.ink,
        contentTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

extension AppPaletteContext on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  Color get appSurface => Theme.of(this).colorScheme.surface;
  Color get appText => Theme.of(this).colorScheme.onSurface;
  Color get appMuted => Theme.of(this).colorScheme.onSurfaceVariant;
  Color get appBorder => Theme.of(this).colorScheme.outline;
  Color get appSubtle => Theme.of(this).colorScheme.surfaceContainerHigh;
  Color get appBackground => Theme.of(this).scaffoldBackgroundColor;
  Color get appPrimary => Theme.of(this).colorScheme.primary;
}
