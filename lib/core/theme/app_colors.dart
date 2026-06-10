import 'package:flutter/material.dart';

/// Design tokens ported 1-to-1 from the Velo Shipping dashboard.
abstract class AppColors {
  // ── Backgrounds ────────────────────────────────────────────────────────────
  static const bg       = Color(0xFF0A0812); // deepest bg
  static const bg2      = Color(0xFF0F0D1A); // sidebar / panels
  static const bg3      = Color(0xFF141224); // table headers
  static const surface  = Color(0xFF1A1730); // cards
  static const surface2 = Color(0xFF201D38); // hover / elevated cards
  static const surface3 = Color(0xFF272446); // raised elements

  // ── Borders — purple-tinted at varying opacity ─────────────────────────────
  static const border   = Color(0x248B5CF6); // rgba(139,92,246,.14)
  static const border2  = Color(0x388B5CF6); // rgba(139,92,246,.22)
  static const border3  = Color(0x598B5CF6); // rgba(139,92,246,.35)

  // ── Primary (Violet) ───────────────────────────────────────────────────────
  static const primary      = Color(0xFF7C3AED); // --v
  static const primaryMid   = Color(0xFF9D5FF5); // --v-2
  static const primaryLight = Color(0xFFB98FFF); // --v-3
  static const primaryGlow  = Color(0x1F7C3AED); // --v-4  12 %
  static const primaryFaint = Color(0x0F7C3AED); // --v-5   6 %

  // ── Accents ────────────────────────────────────────────────────────────────
  static const fuchsia = Color(0xFFC026D3);
  static const cyan    = Color(0xFF06B6D4);
  static const amber   = Color(0xFFF59E0B);
  static const emerald = Color(0xFF10B981);
  static const rose    = Color(0xFFF43F5E);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const success  = emerald;
  static const warning  = amber;
  static const error    = rose;
  static const info     = cyan;
  static const punchIn  = cyan;
  static const punchOut = fuchsia;

  // ── Text ───────────────────────────────────────────────────────────────────
  static const textPrimary   = Color(0xFFE8E4F8); // --txt
  static const textSecondary = Color(0xFF9B93C4); // --txt-2
  static const textMuted     = Color(0xFF5C5480); // --txt-3

  // ── Legacy compat aliases ──────────────────────────────────────────────────
  static const card        = surface;
  static const cardBorder  = border;
  static const primaryDark = Color(0xFF4A2A8F);
}
