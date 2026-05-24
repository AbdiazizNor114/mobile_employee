import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.leadingIcon = Icons.settings_outlined,
    this.trailingIcon,
    this.onLeadingPressed,
    this.onTrailingPressed,
  });

  final String title;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final VoidCallback? onLeadingPressed;
  final VoidCallback? onTrailingPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        MediaQuery.paddingOf(context).top + AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          _HeaderIcon(icon: leadingIcon, onPressed: onLeadingPressed),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.headingMedium.copyWith(
                color: AppColors.cardBackground,
              ),
            ),
          ),
          _HeaderIcon(icon: trailingIcon, onPressed: onTrailingPressed),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon, this.onPressed});

  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (icon == null) {
      return const SizedBox(width: 44, height: 44);
    }

    return IconButton.filled(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.cardBackground.withValues(alpha: 0.2),
        foregroundColor: AppColors.cardBackground,
      ),
      icon: Icon(icon),
    );
  }
}
