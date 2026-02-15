import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// 🎨 Main App Theme - Based on JobHuntly Design
class AppTheme {
  AppTheme._();

  // ============================================
  // 🌞 LIGHT THEME
  // ============================================
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      
      // Color Scheme
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.white,
        primaryContainer: AppColors.primaryLighter,
        onPrimaryContainer: AppColors.primaryDark,
        
        secondary: AppColors.purple,
        onSecondary: AppColors.white,
        secondaryContainer: AppColors.purpleLight,
        onSecondaryContainer: AppColors.purple,
        
        tertiary: AppColors.teal,
        onTertiary: AppColors.white,
        tertiaryContainer: AppColors.tealLight,
        onTertiaryContainer: AppColors.teal,
        
        error: AppColors.error,
        onError: AppColors.white,
        errorContainer: AppColors.errorLight,
        onErrorContainer: AppColors.errorDark,
        
        surface: AppColors.white,
        onSurface: AppColors.neutral900,
        surfaceContainerHighest: AppColors.neutral50,
        
        outline: AppColors.neutral200,
        outlineVariant: AppColors.neutral100,
        
        shadow: AppColors.shadowColor,
        scrim: AppColors.overlay,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: AppColors.neutral50,
      
      // Text Theme
      textTheme: AppTypography.textTheme,
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.shadowColor.withOpacity(0.1),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: AppTypography.h5.copyWith(
          color: AppColors.neutral900,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.neutral700,
          size: AppSpacing.iconMd,
        ),
        actionsIconTheme: const IconThemeData(
          color: AppColors.primary,
          size: AppSpacing.iconMd,
        ),
        toolbarHeight: AppSpacing.appBarHeight,
      ),
      
      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.neutral200,
          disabledForegroundColor: AppColors.neutral400,
          elevation: 0,
          shadowColor: AppColors.shadowColor,
          padding: AppSpacing.buttonPaddingMd,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          textStyle: AppTypography.button,
          minimumSize: const Size(64, 48),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.neutral400,
          padding: AppSpacing.buttonPaddingMd,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          textStyle: AppTypography.button,
        ),
      ),
      
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing16,
          vertical: AppSpacing.spacing12,
        ),
        
        // Border styles
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(
            color: AppColors.neutral300,
            width: AppSpacing.borderThin,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(
            color: AppColors.neutral300,
            width: AppSpacing.borderThin,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: AppSpacing.borderMedium,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(
            color: AppColors.error,
            width: AppSpacing.borderThin,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(
            color: AppColors.error,
            width: AppSpacing.borderMedium,
          ),
        ),
        
        // Text styles
        hintStyle: AppTypography.inputHint,
        labelStyle: AppTypography.labelMedium,
        errorStyle: AppTypography.error,
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shadowColor: AppColors.shadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg,
          side: BorderSide(
            color: AppColors.neutral200,
            width: AppSpacing.borderThin,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.neutral100,
        deleteIconColor: AppColors.neutral600,
        disabledColor: AppColors.neutral50,
        selectedColor: AppColors.primaryLighter,
        secondarySelectedColor: AppColors.purpleLight,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing12,
          vertical: AppSpacing.spacing8,
        ),
        labelStyle: AppTypography.labelSmall,
        secondaryLabelStyle: AppTypography.labelSmall,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        elevation: 8,
        shadowColor: AppColors.shadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusXl,
        ),
        titleTextStyle: AppTypography.h4,
        contentTextStyle: AppTypography.bodyMedium,
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.neutral400,
        selectedLabelStyle: AppTypography.labelSmall,
        unselectedLabelStyle: AppTypography.labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      
      // Navigation Bar Theme (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.primaryLighter,
        height: AppSpacing.bottomNavBarHeight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.labelSmall.copyWith(
              color: AppColors.primary,
            );
          }
          return AppTypography.labelSmall.copyWith(
            color: AppColors.neutral400,
          );
        }),
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusXl,
        ),
      ),
      
      // Drawer Theme
      drawerTheme: DrawerThemeData(
        backgroundColor: AppColors.white,
        elevation: 8,
        shadowColor: AppColors.shadowColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(AppSpacing.radiusXl),
            bottomRight: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
      ),
      
      // Divider Theme
      dividerTheme: DividerThemeData(
        color: AppColors.neutral200,
        thickness: AppSpacing.dividerThin,
        space: AppSpacing.spacing16,
      ),
      
      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.neutral900,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        circularTrackColor: AppColors.neutral200,
        linearTrackColor: AppColors.neutral200,
      ),
      
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.neutral400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryLight;
          }
          return AppColors.neutral200;
        }),
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.white;
        }),
        checkColor: WidgetStateProperty.all(AppColors.white),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusXs,
        ),
      ),
      
      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.neutral400;
        }),
      ),
    );
  }

  // ============================================
  // 🌙 DARK THEME
  // ============================================
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      
      // Color Scheme
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryLight,
        onPrimary: AppColors.neutral900,
        primaryContainer: AppColors.primaryDark,
        onPrimaryContainer: AppColors.primaryLighter,
        
        secondary: AppColors.purple,
        onSecondary: AppColors.neutral900,
        secondaryContainer: AppColors.purple,
        onSecondaryContainer: AppColors.purpleLight,
        
        tertiary: AppColors.teal,
        onTertiary: AppColors.neutral900,
        tertiaryContainer: AppColors.teal,
        onTertiaryContainer: AppColors.tealLight,
        
        error: AppColors.error,
        onError: AppColors.neutral900,
        errorContainer: AppColors.errorDark,
        onErrorContainer: AppColors.errorLight,
        
        surface: AppColors.neutral900,
        onSurface: AppColors.neutral50,
        surfaceContainerHighest: AppColors.neutral800,
        
        outline: AppColors.neutral700,
        outlineVariant: AppColors.neutral800,
        
        shadow: AppColors.black,
        scrim: AppColors.black.withOpacity(0.7),
      ),
      
      // Scaffold
      scaffoldBackgroundColor: AppColors.neutral900,
      
      // Text Theme
      textTheme: AppTypography.textTheme.apply(
        bodyColor: AppColors.neutral50,
        displayColor: AppColors.white,
      ),
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.neutral900,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.black.withOpacity(0.3),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: AppTypography.h5.copyWith(
          color: AppColors.white,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.neutral300,
          size: AppSpacing.iconMd,
        ),
        actionsIconTheme: const IconThemeData(
          color: AppColors.primaryLight,
          size: AppSpacing.iconMd,
        ),
        toolbarHeight: AppSpacing.appBarHeight,
      ),
      
      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.neutral900,
          disabledBackgroundColor: AppColors.neutral700,
          disabledForegroundColor: AppColors.neutral500,
          elevation: 0,
          shadowColor: AppColors.black,
          padding: AppSpacing.buttonPaddingMd,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          textStyle: AppTypography.button,
          minimumSize: const Size(64, 48),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          disabledForegroundColor: AppColors.neutral600,
          padding: AppSpacing.buttonPaddingMd,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          textStyle: AppTypography.button,
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          disabledForegroundColor: AppColors.neutral600,
          side: const BorderSide(
            color: AppColors.primaryLight,
            width: AppSpacing.borderThin,
          ),
          padding: AppSpacing.buttonPaddingMd,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          textStyle: AppTypography.button,
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.neutral800,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing16,
          vertical: AppSpacing.spacing12,
        ),
        
        // Border styles
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(
            color: AppColors.neutral700,
            width: AppSpacing.borderThin,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(
            color: AppColors.neutral700,
            width: AppSpacing.borderThin,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(
            color: AppColors.primaryLight,
            width: AppSpacing.borderMedium,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(
            color: AppColors.error,
            width: AppSpacing.borderThin,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(
            color: AppColors.error,
            width: AppSpacing.borderMedium,
          ),
        ),
        
        // Text styles
        hintStyle: AppTypography.inputHint.copyWith(
          color: AppColors.neutral500,
        ),
        labelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.neutral400,
        ),
        errorStyle: AppTypography.error,
      ),
      
      // // Card Theme
      // cardTheme: CardTheme(
      //   color: AppColors.neutral800,
      //   elevation: 0,
      //   shadowColor: AppColors.black,
      //   shape: RoundedRectangleBorder(
      //     borderRadius: AppSpacing.borderRadiusLg,
      //     side: BorderSide(
      //       color: AppColors.neutral700,
      //       width: AppSpacing.borderThin,
      //     ),
      //   ),
      //   clipBehavior: Clip.antiAlias,
      //   margin: EdgeInsets.zero,
      // ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.neutral800,
        deleteIconColor: AppColors.neutral400,
        disabledColor: AppColors.neutral900,
        selectedColor: AppColors.primaryDark,
        secondarySelectedColor: AppColors.purple,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing12,
          vertical: AppSpacing.spacing8,
        ),
        labelStyle: AppTypography.labelSmall.copyWith(
          color: AppColors.neutral200,
        ),
        secondaryLabelStyle: AppTypography.labelSmall.copyWith(
          color: AppColors.neutral200,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
      ),
      
      // // Dialog Theme
      // dialogTheme: DialogTheme(
      //   backgroundColor: AppColors.neutral800,
      //   elevation: 8,
      //   shadowColor: AppColors.black,
      //   shape: RoundedRectangleBorder(
      //     borderRadius: AppSpacing.borderRadiusXl,
      //   ),
      //   titleTextStyle: AppTypography.h4.copyWith(
      //     color: AppColors.white,
      //   ),
      //   contentTextStyle: AppTypography.bodyMedium.copyWith(
      //     color: AppColors.neutral200,
      //   ),
      // ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.neutral900,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.neutral500,
        selectedLabelStyle: AppTypography.labelSmall,
        unselectedLabelStyle: AppTypography.labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      
      // Navigation Bar Theme (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.neutral900,
        indicatorColor: AppColors.primaryDark,
        height: AppSpacing.bottomNavBarHeight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.labelSmall.copyWith(
              color: AppColors.primaryLight,
            );
          }
          return AppTypography.labelSmall.copyWith(
            color: AppColors.neutral500,
          );
        }),
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.neutral900,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusXl,
        ),
      ),
      
      // Drawer Theme
      drawerTheme: DrawerThemeData(
        backgroundColor: AppColors.neutral900,
        elevation: 8,
        shadowColor: AppColors.black,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(AppSpacing.radiusXl),
            bottomRight: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
      ),
      
      // Divider Theme
      dividerTheme: DividerThemeData(
        color: AppColors.neutral700,
        thickness: AppSpacing.dividerThin,
        space: AppSpacing.spacing16,
      ),
      
      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.neutral800,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryLight,
        circularTrackColor: AppColors.neutral700,
        linearTrackColor: AppColors.neutral700,
      ),
      
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryLight;
          }
          return AppColors.neutral500;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryDark;
          }
          return AppColors.neutral700;
        }),
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryLight;
          }
          return AppColors.neutral800;
        }),
        checkColor: WidgetStateProperty.all(AppColors.neutral900),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusXs,
        ),
      ),
      
      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryLight;
          }
          return AppColors.neutral500;
        }),
      ),
    );
  }
}
