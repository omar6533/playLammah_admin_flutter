import 'package:flutter/material.dart';

class AppColors {
  // Brand Palette
  static const primaryRed = Color(0xFFEC0901);
  static const secondaryRed = Color(0xFFFF525B);
  static const offWhite = Color(0xFFEDEDED);
  static const lightGray = Color(0xFFBDBDBD);
  static const darkBlueGray = Color(0xFF556E78);

  // Semantic Aliases
  static const primary = primaryRed;
  // Use Secondary Red as an accent/secondary variant, or potentially darkBlueGray depending on usage.
  // Given "Secondary Red" name, let's map it here, but keep Dark Blue Gray accessible.
  static const secondary = darkBlueGray;
  static const accent = secondaryRed;

  static const primaryDark = Color(0xFFC00701); // Darker shade of primaryRed
  static const primaryLight = Color(0xFFFFE5E5); // Light shade of primaryRed

  static const background = offWhite;
  static const surface = Colors.white;

  static const danger = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const success = Color(0xFF10B981);

  static const textPrimary =
      Color(0xFF1A1A1A); // Keep standard dark for body readability
  static const textSecondary =
      darkBlueGray; // Use brand color for distinct text elements
  static const textLight = lightGray;

  static const border = lightGray;

  static const sidebarBg = darkBlueGray;
  static const sidebarDivider =
      Color(0xFF455A64); // Slightly darker/lighter than sidebarBg
  static const sidebarText = Colors.white;

  // Variant Backwards Compatibility / Derived Colors
  static const secondaryLight = Color(0xFFCFD8DC); // Light Blue Gray
  static const secondaryDark = Color(0xFF37474F); // Darker Blue Gray

  static const dangerLight = Color(0xFFFFEBEE); // Light Red
  static const dangerDark = Color(0xFFB71C1C); // Dark Red
}
