import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import '../../l10n/generated/app_localizations.dart';

class OfflineCacheBanner extends ConsumerWidget {
  const OfflineCacheBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.greenSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_done_outlined, color: AppColors.primaryGreen),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.offlineReady,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.darkText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
