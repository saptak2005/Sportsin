import 'package:flutter/material.dart';

/// SportsIN app color scheme (Red / Black / White)
/// Primary accents are red, with black and white surfaces/typography.
class AppColors {
    // Primary (Red) accents
    // Using Material Red scale: light/dark variants for emphasis and containers
    static const Color linkedInBlue = Color(0xFFD32F2F); // Primary Red (700)
    static const Color linkedInBlueDark = Color(0xFFB71C1C); // Dark Red (900)
    static const Color linkedInBlueLight = Color(0xFFEF5350); // Light Red (400)

  // LinkedIn Supporting Colors
  static const Color linkedInGreen =
      Color(0xFF057642); // Success/online indicator
  static const Color linkedInOrange = Color(0xFFDD5143); // Warning/notification
  static const Color linkedInPurple = Color(0xFF7B68EE); // Premium features

    // Light Theme Colors
    static const Color lightBackground = Color(0xFFFFFFFF); // Pure white
    static const Color lightSurface = Color(0xFFFFFFFF); // Pure white cards
    static const Color lightSurfaceVariant = Color(0xFFF5F5F5); // Subtle grey
  static const Color lightPrimary = linkedInBlue;
    static const Color lightPrimaryContainer = Color(0xFFFFEBEE); // Light red
  static const Color lightSecondary = Color(0xFF666666); // Secondary text
  static const Color lightSecondaryContainer =
      Color(0xFFF0F0F0); // Secondary containers
  static const Color lightTertiary = linkedInGreen;
  static const Color lightTertiaryContainer =
      Color(0xFFE8F5E8); // Light green container

  // Light Theme Text Colors
  static const Color lightOnBackground = Color(0xFF000000);
  static const Color lightOnSurface = Color(0xFF000000);
  static const Color lightOnSurfaceVariant = Color(0xFF666666);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightOnSecondary = Color(0xFFFFFFFF);
  static const Color lightOnTertiary = Color(0xFFFFFFFF);
  static const Color lightOutline =
      Color(0xFFD9D9D9); // LinkedIn's border color

    // Dark Theme Colors
    static const Color darkBackground = Color(0xFF0D1117); // Near-black
    static const Color darkSurface = Color(0xFF161B22); // Dark cards
    static const Color darkSurfaceVariant = Color(0xFF1F242A); // Darker surface
    static const Color darkPrimary = Color(0xFFEF5350); // Light Red for dark
    static const Color darkPrimaryContainer = Color(0xFF4A0E0E); // Deep red
  static const Color darkSecondary =
      Color(0xFFB0B0B0); // Secondary text in dark
  static const Color darkSecondaryContainer =
      Color(0xFF3A3A3A); // Secondary containers
  static const Color darkTertiary = Color(0xFF57A773); // Green for dark mode
  static const Color darkTertiaryContainer =
      Color(0xFF1A472A); // Dark green container

  // Dark Theme Text Colors
  static const Color darkOnBackground = Color(0xFFFFFFFF);
  static const Color darkOnSurface = Color(0xFFFFFFFF);
  static const Color darkOnSurfaceVariant = Color(0xFFB0B0B0);
  static const Color darkOnPrimary = Color(0xFF000000);
  static const Color darkOnSecondary = Color(0xFF000000);
  static const Color darkOnTertiary = Color(0xFF000000);
  static const Color darkOutline = Color(0xFF5A5A5A); // Dark mode borders

  // Error Colors (consistent across themes)
  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color errorDark = Color(0xFFB71C1C);
  static const Color onError = Color(0xFFFFFFFF);

  // Success Colors (LinkedIn Green variants)
  static const Color success = linkedInGreen;
  static const Color successLight = Color(0xFFE8F5E8);
  static const Color successDark = Color(0xFF2E7D32);
  static const Color onSuccess = Color(0xFFFFFFFF);

  // Warning Colors (LinkedIn Orange variants)
  static const Color warning = linkedInOrange;
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color warningDark = Color(0xFFE65100);
  static const Color onWarning = Color(0xFFFFFFFF);

    // Info Colors (aligned to primary red palette)
    static const Color info = linkedInBlue;
    static const Color infoLight = Color(0xFFFFEBEE);
    static const Color infoDark = Color(0xFF8E0000);
  static const Color onInfo = Color(0xFFFFFFFF);

    // Sports-specific colors
    static const Color sportsGreen = Color(0xFF057642); // Field/success color
    static const Color sportsBlue = linkedInBlue; // Primary accent (red now)
    static const Color sportsOrange = Color(0xFFFF8A00); // Energy/activity color
    static const Color sportsPurple = linkedInPurple; // Premium/special features

  // Social Media Colors (for authentication buttons)
  static const Color googleRed = Color(0xFFDB4437);
  static const Color facebookBlue = Color(0xFF4267B2);
  static const Color twitterBlue = Color(0xFF1DA1F2);
  static const Color appleBlack = Color(0xFF000000);

    // Primary gradients (red)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [linkedInBlue, linkedInBlueDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [linkedInGreen, Color(0xFF2E7D32)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [linkedInPurple, Color(0xFF9C27B0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
