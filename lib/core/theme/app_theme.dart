import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:municipality/core/theme/app_colors.dart';

abstract final class AppTheme {
  /// Dark theme matching the website's slate-900 shell.
  /// Uses Cairo for Arabic and Inter for English, same as `index.css`.
  static ThemeData dark(Locale locale) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.slate900,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.teal500,
        brightness: Brightness.dark,
        primary: AppColors.teal400,
        surface: AppColors.slate900,
        error: AppColors.rose400,
      ),
    );

    final textTheme = locale.languageCode == 'ar'
        ? GoogleFonts.cairoTextTheme(base.textTheme)
        : GoogleFonts.interTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: textTheme.apply(
        bodyColor: AppColors.slate100,
        displayColor: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.slate900,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      dividerColor: AppColors.slate700,
      // Website inputs: bg-slate-800 border-slate-700 rounded-xl focus:border-teal-500.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.slate800,
        hintStyle: const TextStyle(color: AppColors.slate500),
        labelStyle: const TextStyle(color: AppColors.slate300),
        floatingLabelStyle: const TextStyle(color: AppColors.teal400),
        prefixIconColor: WidgetStateColor.resolveWith((states) =>
            states.contains(WidgetState.error)
                ? AppColors.rose400
                : states.contains(WidgetState.focused)
                    ? AppColors.teal400
                    : AppColors.slate400),
        suffixIconColor: AppColors.slate400,
        errorStyle: const TextStyle(color: AppColors.rose300),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: _border(AppColors.slate700),
        enabledBorder: _border(AppColors.slate700),
        focusedBorder: _border(AppColors.teal500, width: 1.5),
        errorBorder: _border(AppColors.rose400),
        focusedErrorBorder: _border(AppColors.rose400, width: 1.5),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.slate800,
        contentTextStyle: TextStyle(color: AppColors.slate100),
        actionTextColor: AppColors.teal400,
      ),
    );
  }

  static OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
}
