import 'package:flutter/material.dart';

class AppColors {
  // ── Brand (matches PlayLammah client app) ───────────────────────────────────
  static const primaryRed = Color(0xFFD64453);
  static const navbarDark = Color(0xFF600522);   // sidebar background

  // ── Semantic ─────────────────────────────────────────────────────────────────
  static const primary = primaryRed;
  static const primaryLight = Color(0xFFFFE8EC);
  static const primaryDark = navbarDark;

  // ── Backgrounds ──────────────────────────────────────────────────────────────
  static const background = Color(0xFFF5F6FA);   // page scaffold
  static const surface = Colors.white;            // cards / panels

  // ── Sidebar ───────────────────────────────────────────────────────────────────
  static const sidebarBg = navbarDark;
  static const sidebarActive = primaryRed;
  static const sidebarHover = Color(0xFF7A0A2E);
  static const sidebarText = Colors.white;
  static const sidebarDivider = Color(0xFF7A1535);

  // ── Text ─────────────────────────────────────────────────────────────────────
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF6B7280);
  static const textLight = Color(0xFF9CA3AF);

  // ── Borders ──────────────────────────────────────────────────────────────────
  static const border = Color(0xFFE5E7EB);
  static const borderLight = Color(0xFFF3F4F6);

  // ── Status ───────────────────────────────────────────────────────────────────
  static const danger = Color(0xFFEF4444);
  static const dangerLight = Color(0xFFFFEBEE);
  static const dangerDark = Color(0xFFB91C1C);
  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFFFBEB);
  static const success = Color(0xFF10B981);
  static const successLight = Color(0xFFECFDF5);

  // ── Backwards-compat aliases (used in pages) ─────────────────────────────────
  static const secondary = navbarDark;
  static const accent = primaryRed;
  static const offWhite = Color(0xFFF5F6FA);
  static const secondaryLight = Color(0xFFFFE8EC);
  static const secondaryDark = navbarDark;
}
