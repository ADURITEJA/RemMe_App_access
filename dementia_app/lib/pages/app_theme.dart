import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryGradientStart = Color(0xFFF9EFE5); // Brand Beige
  static const Color primaryGradientEnd = Color(0xFF8F92A1); // Base Gray-Blue
  static const Color secondaryColor = Color(
    0xFF8F92A1,
  ); // Base Gray-Blue for buttons
  static const Color accentColor = Color(
    0xFFFF6F61,
  ); // Derived Coral for alerts
  static const Color textColorPrimary = Color(0xFF000000); // Brand Black
  static const Color textColorSecondary = Color(
    0xFF7F8790,
  ); // Base Muted Gray-Blue
  static const Color backgroundColor = Color(0xFFF8F8F8); // Base Light Gray

  static ThemeData get theme {
    return ThemeData(
      primaryColor: primaryGradientStart,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'IBMPlexSans',
          fontWeight: FontWeight.bold,
          fontSize: 20, // Reduced from 24
          height: 1.5,
          color: textColorPrimary,
        ),
        displayMedium: TextStyle(
          fontFamily: 'IBMPlexSans',
          fontWeight: FontWeight.bold,
          fontSize: 18, // Reduced from 20
          height: 1.5,
          color: textColorPrimary,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'IBMPlexSans',
          fontWeight: FontWeight.bold,
          fontSize: 16, // Reduced from 18
          height: 1.5,
          color: textColorPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.normal,
          fontSize: 16,
          height: 1.5,
          color: textColorPrimary,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.bold,
          fontSize: 13,
          height: 1.5,
          color: textColorPrimary,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.normal,
          fontSize: 16,
          height: 1.5,
          color: textColorSecondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryColor.withOpacity(0.8),
          foregroundColor: textColorPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          elevation: 5,
          shadowColor: textColorSecondary.withOpacity(0.2),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(
            textColorPrimary.withOpacity(0.2),
          ),
        ),
      ),
    );
  }
}
