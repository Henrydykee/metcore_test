import 'package:flutter/material.dart';
import 'core/platform/color.dart' as project_colors;

class AppColors {
  // Primary colors
  static const primary = project_colors.newprojectColor.blue;
  
  // Status colors
  static const success = project_colors.newprojectColor.green;
  static const warning = project_colors.newprojectColor.orange;
  static const error = project_colors.newprojectColor.red;
  static const errorBg = project_colors.newprojectColor.negative_bg;
  
  // Text colors
  static const textPrimary = project_colors.newprojectColor.black;
  static const textSecondary = project_colors.newprojectColor.black_3;
  static const textTertiary = project_colors.newprojectColor.grey;
  
  // Background colors
  static const tagBg = project_colors.newprojectColor.grey_4;
  static const surface = project_colors.newprojectColor.white_2;
  static const card = project_colors.newprojectColor.white;
  static const borderLight = project_colors.newprojectColor.text_field_border_color;
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
      ),
    );
  }
}
