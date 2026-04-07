import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

enum BadgeType { success, warning, error, info, muted }

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeType type;

  const StatusBadge({super.key, required this.label, required this.type});

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.$2, width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: colors.$3,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  (Color, Color, Color) _getColors() {
    switch (type) {
      case BadgeType.success:
        return (
          AppColors.success.withValues(alpha: 0.12),
          AppColors.success.withValues(alpha: 0.3),
          AppColors.success,
        );
      case BadgeType.warning:
        return (
          AppColors.warning.withValues(alpha: 0.12),
          AppColors.warning.withValues(alpha: 0.3),
          AppColors.warning,
        );
      case BadgeType.error:
        return (
          AppColors.destructive.withValues(alpha: 0.12),
          AppColors.destructive.withValues(alpha: 0.3),
          AppColors.destructive,
        );
      case BadgeType.info:
        return (
          AppColors.primary.withValues(alpha: 0.12),
          AppColors.primary.withValues(alpha: 0.3),
          AppColors.primary,
        );
      case BadgeType.muted:
        return (
          AppColors.muted,
          AppColors.border,
          AppColors.mutedForeground,
        );
    }
  }
}
