import 'package:flutter/material.dart';

abstract class AppColors {
  // ── Brand core ────────────────────────────────────────────────────────────
  /// Primary — Base Blue #2F5BFF: CTAs, nav active, links, focus rings
  static const primary = Color(0xFF2F5BFF);

  /// Secondary — Purple #7A5CFA: gradient end, secondary actions, highlights
  static const secondary = Color(0xFF7A5CFA);

  /// Accent — Teal #2EC4B6: income, success, positive states
  static const accent = Color(0xFF2EC4B6);

  // ── Semantic ──────────────────────────────────────────────────────────────
  /// Success / Income — Teal: positive money flows
  static const success = Color(0xFF2EC4B6);
  static const income  = Color(0xFF2EC4B6);

  /// Danger / Expense / Error — Coral Red: expenses, errors, debt
  static const danger  = Color(0xFFFF6B6B);
  static const expense = Color(0xFFFF6B6B);

  /// Warning — Amber: alerts, investment caution
  static const warning = Color(0xFFF59E0B);

  // ── Brand gradient (#2F5BFF → #7A5CFA) ───────────────────────────────────
  /// Used for balance card, auth panel, gamification highlights, main CTAs
  static const gradientBegin = Color(0xFF2F5BFF);
  static const gradientEnd   = Color(0xFF7A5CFA);
  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientBegin, gradientEnd],
  );

  // ── Neutral scale ─────────────────────────────────────────────────────────
  static const white     = Color(0xFFFFFFFF);
  static const black     = Color(0xFF000000);
  static const bg        = Color(0xFFF7F9FC); // App scaffold background
  static const grey50    = Color(0xFFF7F9FC);
  static const grey100   = Color(0xFFEEF1F7);
  static const grey200   = Color(0xFFDDE3EE);
  static const grey300   = Color(0xFFC4CEDF);
  static const grey400   = Color(0xFF9AAABF);
  static const grey500   = Color(0xFF6B7A9A);
  static const grey600   = Color(0xFF4B5A7A);
  static const grey700   = Color(0xFF344060);
  static const grey800   = Color(0xFF1E2B48);
  static const grey900   = Color(0xFF0F1830);

  // ── Account type colors ───────────────────────────────────────────────────
  static const cashColor       = Color(0xFF2EC4B6); // teal — accessible cash
  static const bankColor       = Color(0xFF2F5BFF); // primary blue — institutional trust
  static const savingsColor    = Color(0xFF7A5CFA); // purple — goals/future
  static const creditColor     = Color(0xFFFF6B6B); // coral — debt awareness
  static const investmentColor = Color(0xFFF59E0B); // amber — growth

  // ── Category palette (10 vibrant, harmonized with brand) ─────────────────
  static const categoryColors = [
    Color(0xFF2F5BFF), // primary blue
    Color(0xFF2EC4B6), // teal
    Color(0xFFFF6B6B), // coral
    Color(0xFFF59E0B), // amber
    Color(0xFF7A5CFA), // purple
    Color(0xFFEC4899), // pink
    Color(0xFF06B6D4), // cyan
    Color(0xFF84CC16), // lime
    Color(0xFFFB923C), // orange
    Color(0xFFA78BFA), // lavender
  ];

  // ── Surface tints (light backgrounds for chips, badges, tags) ────────────
  static const primaryTint  = Color(0xFFEEF2FF); // blue-50
  static const accentTint   = Color(0xFFE6FAF8); // teal-50
  static const dangerTint   = Color(0xFFFFF0F0); // red-50
  static const warningTint  = Color(0xFFFFFBEB); // amber-50
  static const secondaryTint= Color(0xFFF5F0FF); // purple-50
}
