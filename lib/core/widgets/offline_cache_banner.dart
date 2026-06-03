import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import '../providers/mock_work_provider.dart';

class OfflineCacheBanner extends ConsumerWidget {
  const OfflineCacheBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastUpdated = ref.watch(cacheLastUpdatedProvider);

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
              'Synced data • ${_lastUpdatedLabel(lastUpdated)}',
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

String _lastUpdatedLabel(DateTime? value) {
  if (value == null) return 'Caching now';

  final difference = DateTime.now().difference(value);
  if (difference.inMinutes < 1) return 'Last updated just now';
  if (difference.inMinutes < 60) {
    return 'Last updated ${difference.inMinutes} min ago';
  }
  if (difference.inHours < 24) {
    return 'Last updated ${difference.inHours} h ago';
  }
  return 'Last updated ${difference.inDays} d ago';
}
