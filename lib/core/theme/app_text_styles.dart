import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// Pre-built text styles using Outfit (body) and JetBrains Mono (labels/mono).
abstract class AppTs {
  // ── Outfit ─────────────────────────────────────────────────────────────────
  static TextStyle h1({Color? color}) => GoogleFonts.outfit(
      fontSize: 26,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
      color: color ?? AppColors.textPrimary);

  static TextStyle h2({Color? color}) => GoogleFonts.outfit(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      color: color ?? AppColors.textPrimary);

  static TextStyle h3({Color? color}) => GoogleFonts.outfit(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: color ?? AppColors.textPrimary);

  static TextStyle body({Color? color, FontWeight? weight}) =>
      GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: weight ?? FontWeight.w400,
          color: color ?? AppColors.textPrimary);

  static TextStyle bodySmall({Color? color}) =>
      GoogleFonts.outfit(fontSize: 12, color: color ?? AppColors.textSecondary);

  static TextStyle label({Color? color}) => GoogleFonts.outfit(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: color ?? AppColors.textPrimary);

  static TextStyle caption({Color? color}) =>
      GoogleFonts.outfit(fontSize: 11, color: color ?? AppColors.textMuted);

  // ── JetBrains Mono ─────────────────────────────────────────────────────────
  /// Section tag — "CORE", "RECENT ORDERS", uppercase small caps label
  static TextStyle tag({Color? color}) => GoogleFonts.jetBrainsMono(
      fontSize: 9,
      fontWeight: FontWeight.w500,
      color: color ?? AppColors.textMuted,
      letterSpacing: 1.5);

  /// Code / IDs / AWB numbers
  static TextStyle mono({double? size, Color? color}) =>
      GoogleFonts.jetBrainsMono(
          fontSize: size ?? 12, color: color ?? AppColors.textSecondary);

  /// Large stat value — "3,482"
  static TextStyle stat({Color? color}) => GoogleFonts.outfit(
      fontSize: 26,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
      height: 1,
      color: color ?? AppColors.textPrimary);

  /// Medium stat — "22px" used in metric cards
  static TextStyle statMd({Color? color}) => GoogleFonts.outfit(
      fontSize: 22,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
      height: 1,
      color: color ?? AppColors.textPrimary);

  /// Tracker value — "5"
  static TextStyle statLg({Color? color}) => GoogleFonts.outfit(
      fontSize: 28,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
      height: 1,
      color: color ?? AppColors.textPrimary);
}

// ─────────────────────────────────────────────────────────────────────────────
//  Reusable Badge widget
// ─────────────────────────────────────────────────────────────────────────────

enum BadgeVariant { green, purple, amber, rose, cyan, gray }

class VeloBadge extends StatelessWidget {
  final String text;
  final BadgeVariant variant;
  final Widget? leading;
  const VeloBadge(this.text,
      {super.key, this.variant = BadgeVariant.gray, this.leading});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, bd) = _colors(variant);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: bd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 4)],
          Text(text,
              style: GoogleFonts.outfit(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: fg,
                  letterSpacing: .2)),
        ],
      ),
    );
  }

  static (Color, Color, Color) _colors(BadgeVariant v) => switch (v) {
        BadgeVariant.green => (
            const Color(0x1F10B981),
            const Color(0xFF34D399),
            const Color(0x3310B981)
          ),
        BadgeVariant.purple => (
            AppColors.primaryGlow,
            AppColors.primaryLight,
            AppColors.border2
          ),
        BadgeVariant.amber => (
            const Color(0x1AF59E0B),
            const Color(0xFFFBBF24),
            const Color(0x33F59E0B)
          ),
        BadgeVariant.rose => (
            const Color(0x1AF43F5E),
            const Color(0xFFFB7185),
            const Color(0x33F43F5E)
          ),
        BadgeVariant.cyan => (
            const Color(0x1A06B6D4),
            const Color(0xFF67E8F9),
            const Color(0x3306B6D4)
          ),
        BadgeVariant.gray => (
            const Color(0x0FFFFFFF),
            AppColors.textSecondary,
            AppColors.border
          ),
      };
}

// ─────────────────────────────────────────────────────────────────────────────
//  Section header
// ─────────────────────────────────────────────────────────────────────────────

class VeloSectionHeader extends StatelessWidget {
  final String label;
  final Color dotColor;
  final String? trailing;
  const VeloSectionHeader(
    this.label, {
    super.key,
    this.dotColor = AppColors.primaryMid,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: dotColor == AppColors.emerald
                  ? [
                      BoxShadow(
                          color: dotColor.withValues(alpha: .5),
                          blurRadius: AppSpace.sm)
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: AppTs.tag(color: AppColors.textSecondary)
                  .copyWith(fontSize: 11, fontWeight: FontWeight.w700)),
          if (trailing != null) ...[
            const Spacer(),
            Text(trailing!, style: AppTs.tag()),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Velo status dot
// ─────────────────────────────────────────────────────────────────────────────

class VeloDot extends StatelessWidget {
  final Color color;
  final bool glow;
  const VeloDot({super.key, required this.color, this.glow = false});

  @override
  Widget build(BuildContext context) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: glow
              ? [
                  BoxShadow(
                      color: color.withValues(alpha: .5),
                      blurRadius: AppSpace.sm)
                ]
              : null,
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Velo card container
// ─────────────────────────────────────────────────────────────────────────────

class VeloCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  const VeloCard({
    super.key,
    required this.child,
    this.borderColor,
    this.padding = AppSpace.cardPadding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: borderColor ?? AppColors.border),
        ),
        child: child,
      ),
    );
  }
}
