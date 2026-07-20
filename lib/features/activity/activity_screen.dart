import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/activity_item.dart';
import '../../core/providers/mock_work_provider.dart';
import '../../core/providers/backend_sync_provider.dart';
import '../../core/widgets/activity_list_item.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/dashboard_card.dart';
import '../../l10n/generated/app_localizations.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  Timer? _relativeTimeTimer;

  @override
  void initState() {
    super.initState();
    _relativeTimeTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _relativeTimeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final activity = [...ref.watch(activityProvider)]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final unreadCount = ref.watch(unreadActivityCountProvider);
    final contentMaxWidth =
        MediaQuery.sizeOf(context).width >= 760 ? 720.0 : double.infinity;

    return Scaffold(
      body: Column(
        children: [
          AppHeader(title: l10n.activities, leadingIcon: null),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(backendSyncProvider.future),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentMaxWidth),
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      DashboardCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.unreadCount(unreadCount),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: unreadCount == 0
                                  ? null
                                  : () => ref
                                      .read(activityProvider.notifier)
                                      .markAllRead(),
                              child: Text(l10n.markAllRead),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DashboardCard(
                        child: Column(
                          children: [
                            if (activity.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(AppSpacing.xl),
                                child: Text(
                                  l10n.noActivityYet,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.mutedText,
                                  ),
                                ),
                              )
                            else
                              for (final item in activity)
                                ActivityListItem(
                                  icon: _iconFor(item.type),
                                  iconColor: _colorFor(item.type),
                                  title: _localizedTitleFor(item, l10n),
                                  subtitle: item.detail,
                                  time: _timeFor(item.createdAt, l10n),
                                  isUnread: item.isUnread,
                                ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(ActivityType type) {
    return switch (type) {
      ActivityType.shift => Icons.task_alt_rounded,
      ActivityType.deduction => Icons.notifications_active_rounded,
      ActivityType.swap => Icons.sync_alt_rounded,
      ActivityType.system => Icons.verified_outlined,
    };
  }

  Color _colorFor(ActivityType type) {
    return switch (type) {
      ActivityType.deduction => AppColors.alertRed,
      ActivityType.shift => AppColors.primaryGreen,
      ActivityType.swap => AppColors.blueInfo,
      ActivityType.system => AppColors.blueInfo,
    };
  }

  String _timeFor(DateTime createdAt, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    if (difference.inMinutes < 1) return l10n.justNow;
    if (difference.inMinutes < 60) {
      return l10n.minutesAgo(difference.inMinutes);
    }
    if (difference.inHours < 24) return l10n.hoursAgo(difference.inHours);
    return l10n.daysAgo(difference.inDays);
  }

  String _localizedTitleFor(ActivityItem item, AppLocalizations l10n) {
    final normalized =
        item.title.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (normalized == 'shiftpublished' || normalized == 'shiftspublished') {
      return l10n.activityShiftPublished;
    }
    return item.title;
  }
}
