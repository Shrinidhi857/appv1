import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,

    scaffoldBackgroundColor: AppColors.softGrey,

    colorScheme: ColorScheme.light(
      primary: AppColors.softBlue,      // replacing accentBlue
      secondary: AppColors.softGreen,
      surface: AppColors.pureWhite,
      background: AppColors.softGrey,
      onPrimary: AppColors.pureWhite,
      onSurface: AppColors.pureBlack,
    ),

    // -------------------------
    // TEXT THEME USING URBANIST
    // -------------------------
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontFamily: "Urbanist",
        fontWeight: FontWeight.w700,
        fontSize: 34,
        color: AppColors.pureBlack,
      ),
      bodyMedium: TextStyle(
        fontFamily: "Urbanist",
        fontWeight: FontWeight.w400,
        fontSize: 16,
        color: AppColors.pureBlack,
      ),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.pureWhite,
      foregroundColor: AppColors.pureBlack,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: "Urbanist",
        fontWeight: FontWeight.w600,
        fontSize: 20,
        color: AppColors.pureBlack,
      ),
    ),

    iconTheme: const IconThemeData(
      color: AppColors.pureBlack,
    ),
  );
}
