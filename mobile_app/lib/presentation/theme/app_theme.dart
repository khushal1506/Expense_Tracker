import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color _ink = Color(0xFF1D2333);
  static const Color _slate = Color(0xFF4B5670);
  static const Color _mist = Color(0xFFF7F4EE);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _primary = Color(0xFF224A82);
  static const Color _secondary = Color(0xFFD99058);
  static const Color _tertiary = Color(0xFF3E8B75);

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primary,
        brightness: Brightness.light,
        primary: _primary,
        secondary: _secondary,
        surface: _surface,
      ),
    );

    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
        .copyWith(
          headlineMedium: GoogleFonts.playfairDisplay(
            fontSize: 34,
            color: _ink,
            height: 1.08,
          ),
          headlineSmall: GoogleFonts.playfairDisplay(
            fontSize: 28,
            color: _ink,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
          titleMedium: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
          bodyMedium: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: _slate,
            height: 1.45,
          ),
          bodySmall: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: _slate.withValues(alpha: 0.85),
          ),
        );

    return base.copyWith(
      scaffoldBackgroundColor: _mist,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: _ink,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 1.2,
        shadowColor: _primary.withValues(alpha: 0.08),
        color: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        side: BorderSide(color: _primary.withValues(alpha: 0.18)),
        backgroundColor: Colors.white,
        selectedColor: _primary.withValues(alpha: 0.12),
        labelStyle: textTheme.bodySmall,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _primary.withValues(alpha: 0.18)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _primary.withValues(alpha: 0.16)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primary, width: 1.4),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        elevation: 0,
        indicatorColor: _secondary.withValues(alpha: 0.22),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return textTheme.bodySmall!.copyWith(
            color: isSelected ? _primary : _slate,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          );
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        shape: StadiumBorder(),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _tertiary,
        linearTrackColor: Color(0xFFE8EEF4),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return _primary.withValues(alpha: 0.14);
            }
            return Colors.white;
          }),
          foregroundColor: const WidgetStatePropertyAll(_ink),
        ),
      ),
      dividerTheme: DividerThemeData(color: _primary.withValues(alpha: 0.12)),
    );
  }

  static ThemeData get darkTheme {
    const Color inkDark = Color(0xFFF8FAFC);
    const Color slateDark = Color(0xFF94A3B8);
    const Color mistDark = Color(0xFF0F172A); // Deep slate/blue background
    const Color surfaceDark = Color(0xFF1E293B); // Raised card surface
    const Color primaryDark = Color(0xFF5B96EB);
    const Color secondaryDark = Color(0xFFECA36B);
    const Color tertiaryDark = Color(0xFF5CC2A7);

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryDark,
        brightness: Brightness.dark,
        primary: primaryDark,
        secondary: secondaryDark,
        surface: surfaceDark,
      ),
    );

    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
        .copyWith(
          headlineMedium: GoogleFonts.playfairDisplay(
            fontSize: 34,
            color: inkDark,
            height: 1.08,
          ),
          headlineSmall: GoogleFonts.playfairDisplay(
            fontSize: 28,
            color: inkDark,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: inkDark,
          ),
          titleMedium: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: inkDark,
          ),
          bodyMedium: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: slateDark,
            height: 1.45,
          ),
          bodySmall: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: slateDark.withValues(alpha: 0.85),
          ),
        );

    return base.copyWith(
      scaffoldBackgroundColor: mistDark,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: inkDark,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        color: surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        side: BorderSide(color: primaryDark.withValues(alpha: 0.3)),
        backgroundColor: surfaceDark,
        selectedColor: primaryDark.withValues(alpha: 0.2),
        labelStyle: textTheme.bodySmall,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryDark.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryDark.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryDark, width: 1.4),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceDark.withValues(alpha: 0.95),
        elevation: 0,
        indicatorColor: secondaryDark.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return textTheme.bodySmall!.copyWith(
            color: isSelected ? primaryDark : slateDark,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          );
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        shape: StadiumBorder(),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: tertiaryDark,
        linearTrackColor: Color(0xFF334155),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: inkDark,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: mistDark),
        behavior: SnackBarBehavior.floating,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return primaryDark.withValues(alpha: 0.2);
            }
            return surfaceDark;
          }),
          foregroundColor: const WidgetStatePropertyAll(inkDark),
        ),
      ),
      dividerTheme: DividerThemeData(color: primaryDark.withValues(alpha: 0.1)),
    );
  }
}
