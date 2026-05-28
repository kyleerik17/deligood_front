import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class AppColors {
  AppColors._();

  // ── Surfaces ────────────────────────────────────────────────────────────────
  static const surface          = Color(0xFFF8F9FB);
  static const surfaceWarm      = Color(0xFFFFF4EE);
  static const surfaceLow       = Color(0xFFF1F3F6);
  static const surfaceContainer = Color(0xFFE9EDF2);

  /// Skeleton shimmer — teinte de base (sombre)
  static const surfaceMid       = Color(0xFFDDE2EA);

  /// Skeleton shimmer — teinte claire (pic de brillance)
  static const surfaceHigh      = Color(0xFFF1F4F8);

  static const white = Colors.white;
  static const bg    = surface;

  // ── Brand ───────────────────────────────────────────────────────────────────
  static const primary      = Color(0xFF090B0F);
  static const orange       = Color(0xFFFF5A1F);
  static const orangeDark   = Color(0xFFE84A12);
  static const orangeSoft   = Color(0xFFFFE1D2);

  // ── Green ───────────────────────────────────────────────────────────────────
  static const green      = Color(0xFF2FD384);

  /// Utilisé pour les badges "ouvert", section header count
  static const greenDark  = Color(0xFF009B63);

  /// Point lumineux dans le badge "Ouvert" et badge-border
  static const greenLight = Color(0xFF2FD384); // alias de green pour la lisibilité sémantique

  // ── Accent ──────────────────────────────────────────────────────────────────
  static const gold              = Color(0xFFBF8900);
  static const tertiaryFixed     = Color(0xFFFFDEA8);
  static const tertiaryContainer = Color(0xFFBF8900);

  // ── Text ────────────────────────────────────────────────────────────────────
  static const textPrimary   = Color(0xFF111318);
  static const textSecondary = Color(0xFF626A76);
  static const textMuted     = Color(0xFF9AA2AF);

  // ── Misc ────────────────────────────────────────────────────────────────────
  static const outline = Color(0xFFE1E5EC);
  static const error   = Color(0xFFBA1A1A);

  // ── Gradients ───────────────────────────────────────────────────────────────
  static const gradientOrange = LinearGradient(
    colors: [orange, Color(0xFFFF8B3D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientGreen = LinearGradient(
    colors: [greenDark, Color(0xFF35D07F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientDark = LinearGradient(
    colors: [Color(0xFF121212), Color(0xFF2A211C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppSpacing {
  AppSpacing._();

  static double get xs   => 0.6.h;
  static double get sm   => 1.2.h;
  static double get md   => 1.8.h;
  static double get lg   => 2.6.h;
  static double get xl   => 4.h;
  static double get page => 5.5.w;

  static BorderRadius get smRadius   => BorderRadius.circular(8);
  static BorderRadius get mdRadius   => BorderRadius.circular(12);
  static BorderRadius get lgRadius   => BorderRadius.circular(16);
  static BorderRadius get xlRadius   => BorderRadius.circular(24);
  static BorderRadius get pillRadius => BorderRadius.circular(999);

  static double get radiusSm   => 8;
  static double get radiusMd   => 12;
  static double get radiusLg   => 16;
  static double get radiusXl   => 24;
  static double get radiusFull => 999;
}

class AppText {
  AppText._();

  static TextStyle display({Color color = AppColors.textPrimary}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 28.sp,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.08,
      );

  static TextStyle h1({Color color = AppColors.textPrimary}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 24.sp,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.15,
      );

  static TextStyle h2({Color color = AppColors.textPrimary}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 19.sp,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.18,
      );

  static TextStyle h3({Color color = AppColors.textPrimary}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 15.sp,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.25,
      );

  static TextStyle h4({Color color = AppColors.textPrimary}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 12.5.sp,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle body({Color color = AppColors.textSecondary}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 11.5.sp,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.55,
      );

  static TextStyle bodyLg({Color color = AppColors.textPrimary}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.55,
      );

  static TextStyle bodySm({Color color = AppColors.textSecondary}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 10.sp,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.45,
      );

  static TextStyle label({Color color = AppColors.textPrimary}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 10.5.sp,
        fontWeight: FontWeight.w700,
        color: color,
      );

  /// Très petit texte — badges open/closed, timestamps
  static TextStyle caption({Color color = AppColors.textMuted}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 9.sp,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.3,
      );

  static TextStyle price({Color color = AppColors.orange}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 12.sp,
        fontWeight: FontWeight.w800,
        color: color,
      );

  static TextStyle priceLg({Color color = AppColors.orange}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 17.sp,
        fontWeight: FontWeight.w800,
        color: color,
      );

  static TextStyle button({Color color = AppColors.white}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 12.5.sp,
        fontWeight: FontWeight.w800,
        color: color,
      );
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> get card => [
    BoxShadow(
      color: AppColors.textPrimary.withValues(alpha: 0.07),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  static List<BoxShadow> get raised => [
    BoxShadow(
      color: AppColors.textPrimary.withValues(alpha: 0.12),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
  ];

  static List<BoxShadow> get subtle => [
    BoxShadow(
      color: AppColors.textPrimary.withValues(alpha: 0.04),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];

  static List<BoxShadow> get orange => [
    BoxShadow(
      color: AppColors.orange.withValues(alpha: 0.28),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.surface,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.orange,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.greenDark,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: AppText.h3(),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.surfaceContainer,
          disabledForegroundColor: AppColors.white,
          elevation: 0,
          shadowColor: AppColors.orange.withValues(alpha: .24),
          padding: EdgeInsets.symmetric(vertical: 1.8.h, horizontal: 5.w),
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.lgRadius),
          textStyle: AppText.button(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: BorderSide(color: AppColors.outline.withValues(alpha: .5)),
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.lgRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        hintStyle: AppText.bodySm(
          color: AppColors.textSecondary.withValues(alpha: 0.7),
        ),
        labelStyle: AppText.bodySm(),
        contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.8.h),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.mdRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.mdRadius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.mdRadius,
          borderSide: const BorderSide(color: AppColors.orange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.mdRadius,
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.mdRadius,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.lgRadius),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.outline.withValues(alpha: 0.42),
        thickness: 0.7,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.orange,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.lgRadius),
      ),
    );
  }
}

/// Configuration centralisée de l'application.
/// La clé MapTiler est injectée via --dart-define au build,
/// avec une valeur vide par défaut pour éviter toute fuite en CI.
///
/// Usage :
///   flutter run  --dart-define=MAPTILER_KEY=votre_cle
///   flutter build apk --dart-define=MAPTILER_KEY=votre_cle
class AppConfig {
  AppConfig._();

  static const mapTilerKey = String.fromEnvironment(
    'MAPTILER_KEY',
    defaultValue: '', // ne jamais committer une vraie clé ici
  );
}