import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary       = Color(0xFFE87D1E);
  static const primaryDark   = Color(0xFFC45F00);
  static const secondary     = Color(0xFF2E7D32);
  static const accent        = Color(0xFFFFF3E0);
  static const background    = Color(0xFFFAF7F2);
  static const surface       = Color(0xFFFFFFFF);
  static const error         = Color(0xFFD32F2F);
  static const success       = Color(0xFF388E3C);
  static const warning       = Color(0xFFF57C00);
  static const textPrimary   = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF6B6B6B);
  static const divider       = Color(0xFFEEEEEE);

  static const List<Color> categoryColors = [
    Color(0xFFE87D1E), Color(0xFF2E7D32), Color(0xFF1565C0),
    Color(0xFF6A1B9A), Color(0xFFAD1457), Color(0xFF00695C),
    Color(0xFFBF360C), Color(0xFF37474F), Color(0xFF558B2F),
  ];
}

class AppTheme {
  static ThemeData get lightTheme {
    final poppins = GoogleFonts.poppinsTextTheme();

    return ThemeData(
      useMaterial3: true,
      textTheme: poppins,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shadowColor: Color.fromRGBO(0, 0, 0, 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.accent,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide.none,
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        labelStyle: GoogleFonts.poppins(
          color: AppColors.textSecondary,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        selectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 11,
        ),
      ),
    );
  }
}

