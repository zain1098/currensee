import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Centralized theme system for CurrenSee Pro
///
/// This file contains all theme definitions and provides a consistent
/// design system across the entire application. The themes are designed
/// to be professional, accessible, and responsive.
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // Brand Colors
  static const Color _primaryBlue = Color(0xFF1E3A8A);
  static const Color _primaryBlueLight = Color(0xFF3B82F6);
  static const Color _secondaryGold = Color(0xFFD4AF37);
  static const Color _secondaryGoldLight = Color(0xFFF59E0B);

  // Light Theme Colors
  static const Color _lightScaffold = Color(0xFFF8FAFC);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightCard = Color(0xFFFFFFFF);
  static const Color _lightTextPrimary = Color(0xFF1E293B);
  static const Color _lightTextSecondary = Color(0xFF334155);
  static const Color _lightTextTertiary = Color(0xFF64748B);
  static const Color _lightDivider = Color(0xFFE2E8F0);
  static const Color _lightInputBackground = Color(0xFFFFFFFF);
  static const Color _lightError = Color(0xFFEF4444);
  static const Color _lightSuccess = Color(0xFF10B981);
  static const Color _lightWarning = Color(0xFFF59E0B);

  // Dark Theme Colors
  static const Color _darkScaffold = Color(0xFF111827);
  static const Color _darkSurface = Color(0xFF1F2937);
  static const Color _darkCard = Color(0xFF1F2937);
  static const Color _darkTextPrimary = Color(0xFFF9FAFB);
  static const Color _darkTextSecondary = Color(0xFFD1D5DB);
  static const Color _darkTextTertiary = Color(0xFF9CA3AF);
  static const Color _darkDivider = Color(0xFF374151);
  static const Color _darkInputBackground = Color(0xFF374151);
  static const Color _darkError = Color(0xFFEF4444);
  static const Color _darkSuccess = Color(0xFF10B981);
  static const Color _darkWarning = Color(0xFFF59E0B);

  /// Light theme configuration
  static ThemeData lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: _createMaterialColor(_primaryBlue),
      colorScheme: const ColorScheme.light(
        primary: _primaryBlue,
        primaryContainer: Color(0xFFDBEAFE),
        secondary: _secondaryGold,
        secondaryContainer: Color(0xFFFEF3C7),
        surface: _lightSurface,
        error: _lightError,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: _lightTextPrimary,
        onError: Colors.white,
        outline: _lightDivider,
        outlineVariant: Color(0xFFE2E8F0),
        shadow: Color(0x1A000000),
        scrim: Color(0x52000000),
        inverseSurface: _darkSurface,
        onInverseSurface: _darkTextPrimary,
        inversePrimary: _primaryBlueLight,
        surfaceTint: _primaryBlue,
      ),
      scaffoldBackgroundColor: _lightScaffold,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      fontFamily: 'Poppins',

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: _lightTextPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: _lightTextPrimary,
          letterSpacing: -0.25,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: _lightTextPrimary,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: _lightTextPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _lightTextPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _lightTextPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: _lightTextPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _lightTextPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _lightTextSecondary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: _lightTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: _lightTextSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: _lightTextTertiary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _lightTextPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _lightTextSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: _lightTextTertiary,
        ),
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: Colors.white, size: 24),
        actionsIconTheme: IconThemeData(color: Colors.white, size: 24),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: _lightCard,
        margin: const EdgeInsets.all(8),
        shadowColor: const Color(0x1A000000),
        surfaceTintColor: _primaryBlue,
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightInputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _lightDivider, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _lightDivider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _lightError, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _lightError, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        labelStyle: const TextStyle(color: _lightTextSecondary),
        hintStyle: const TextStyle(color: _lightTextTertiary),
        errorStyle: const TextStyle(color: _lightError, fontSize: 12),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: const Color(0x1A000000),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryBlue,
          side: const BorderSide(color: _primaryBlue, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _secondaryGold,
        foregroundColor: Colors.black,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryBlue;
          }
          return _lightTextTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryBlue.withOpacity(0.5);
          }
          return _lightDivider;
        }),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: _lightDivider,
        thickness: 1,
        space: 1,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(color: _primaryBlue, size: 24),

      // List Tile Theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: _lightTextPrimary,
        ),
        subtitleTextStyle: TextStyle(fontSize: 14, color: _lightTextSecondary),
        leadingAndTrailingTextStyle: TextStyle(
          fontSize: 14,
          color: _lightTextSecondary,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _lightSurface,
        selectedItemColor: _primaryBlue,
        unselectedItemColor: _lightTextTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: _lightDivider.withOpacity(0.3),
        selectedColor: _primaryBlue.withOpacity(0.1),
        disabledColor: _lightDivider.withOpacity(0.1),
        labelStyle: const TextStyle(color: _lightTextPrimary),
        secondaryLabelStyle: const TextStyle(color: _primaryBlue),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide.none,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: _lightSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: _lightTextPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 16,
          color: _lightTextSecondary,
        ),
      ),

      // Snack Bar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _lightSurface,
        contentTextStyle: const TextStyle(color: _lightTextPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _primaryBlue,
        linearTrackColor: _lightDivider,
        circularTrackColor: _lightDivider,
      ),

      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: _primaryBlue,
        inactiveTrackColor: _lightDivider,
        thumbColor: _primaryBlue,
        overlayColor: _primaryBlue.withOpacity(0.2),
        valueIndicatorColor: _primaryBlue,
        valueIndicatorTextStyle: const TextStyle(color: Colors.white),
      ),
    );
  }

  /// Dark theme configuration
  static ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: _createMaterialColor(_primaryBlueLight),
      colorScheme: const ColorScheme.dark(
        primary: _primaryBlueLight,
        primaryContainer: Color(0xFF1E40AF),
        secondary: _secondaryGoldLight,
        secondaryContainer: Color(0xFF92400E),
        surface: _darkSurface,
        error: _darkError,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: _darkTextPrimary,
        onError: Colors.white,
        outline: _darkDivider,
        outlineVariant: Color(0xFF374151),
        shadow: Color(0x40000000),
        scrim: Color(0x52000000),
        inverseSurface: _lightSurface,
        onInverseSurface: _lightTextPrimary,
        inversePrimary: _primaryBlue,
        surfaceTint: _primaryBlueLight,
      ),
      scaffoldBackgroundColor: _darkScaffold,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      fontFamily: 'Poppins',

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: _darkTextPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: _darkTextPrimary,
          letterSpacing: -0.25,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: _darkTextPrimary,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: _darkTextPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _darkTextPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _darkTextPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: _darkTextPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _darkTextPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _darkTextSecondary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: _darkTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: _darkTextSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: _darkTextTertiary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _darkTextPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _darkTextSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: _darkTextTertiary,
        ),
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _darkSurface,
        foregroundColor: _darkTextPrimary,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: _darkTextPrimary,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: _darkTextPrimary, size: 24),
        actionsIconTheme: IconThemeData(color: _darkTextPrimary, size: 24),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: _darkCard,
        margin: const EdgeInsets.all(8),
        shadowColor: const Color(0x40000000),
        surfaceTintColor: _primaryBlueLight,
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkInputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _darkDivider, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _darkDivider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _primaryBlueLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _darkError, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _darkError, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        labelStyle: const TextStyle(color: _darkTextSecondary),
        hintStyle: const TextStyle(color: _darkTextTertiary),
        errorStyle: const TextStyle(color: _darkError, fontSize: 12),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryBlueLight,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: const Color(0x40000000),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryBlueLight,
          side: const BorderSide(color: _primaryBlueLight, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryBlueLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _secondaryGoldLight,
        foregroundColor: Colors.black,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryBlueLight;
          }
          return _darkTextTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryBlueLight.withOpacity(0.5);
          }
          return _darkDivider;
        }),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: _darkDivider,
        thickness: 1,
        space: 1,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(color: _primaryBlueLight, size: 24),

      // List Tile Theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: _darkTextPrimary,
        ),
        subtitleTextStyle: TextStyle(fontSize: 14, color: _darkTextSecondary),
        leadingAndTrailingTextStyle: TextStyle(
          fontSize: 14,
          color: _darkTextSecondary,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _darkSurface,
        selectedItemColor: _primaryBlueLight,
        unselectedItemColor: _darkTextTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: _darkDivider.withOpacity(0.3),
        selectedColor: _primaryBlueLight.withOpacity(0.1),
        disabledColor: _darkDivider.withOpacity(0.1),
        labelStyle: const TextStyle(color: _darkTextPrimary),
        secondaryLabelStyle: const TextStyle(color: _primaryBlueLight),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide.none,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: _darkSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: _darkTextPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 16,
          color: _darkTextSecondary,
        ),
      ),

      // Snack Bar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _darkSurface,
        contentTextStyle: const TextStyle(color: _darkTextPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _primaryBlueLight,
        linearTrackColor: _darkDivider,
        circularTrackColor: _darkDivider,
      ),

      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: _primaryBlueLight,
        inactiveTrackColor: _darkDivider,
        thumbColor: _primaryBlueLight,
        overlayColor: _primaryBlueLight.withOpacity(0.2),
        valueIndicatorColor: _primaryBlueLight,
        valueIndicatorTextStyle: const TextStyle(color: Colors.white),
      ),
    );
  }

  /// Creates a MaterialColor from a Color
  static MaterialColor _createMaterialColor(Color color) {
    final strengths = <double>[.05];
    final swatch = <int, Color>{};
    final r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }

    for (var strength in strengths) {
      final ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }

    return MaterialColor(color.value, swatch);
  }

  /// Get theme-aware colors based on current theme
  static ColorScheme getColorScheme(BuildContext context) {
    return Theme.of(context).colorScheme;
  }

  /// Get theme-aware text styles based on current theme
  static TextTheme getTextTheme(BuildContext context) {
    return Theme.of(context).textTheme;
  }

  /// Get responsive spacing based on screen size
  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) return baseSpacing * 0.8; // Small phones
    if (screenWidth < 600) return baseSpacing; // Normal phones
    if (screenWidth < 900) return baseSpacing * 1.2; // Tablets
    return baseSpacing * 1.5; // Large screens
  }

  /// Get responsive font size based on screen size
  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) return baseSize * 0.9; // Small phones
    if (screenWidth < 600) return baseSize; // Normal phones
    if (screenWidth < 900) return baseSize * 1.1; // Tablets
    return baseSize * 1.2; // Large screens
  }

  /// Get theme-aware card decoration
  static BoxDecoration getCardDecoration(BuildContext context) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.shadow,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Get theme-aware gradient decoration
  static BoxDecoration getGradientDecoration(BuildContext context) {
    final theme = Theme.of(context);
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          theme.colorScheme.primary.withOpacity(0.1),
          theme.colorScheme.secondary.withOpacity(0.05),
        ],
      ),
      borderRadius: BorderRadius.circular(12),
    );
  }
}
