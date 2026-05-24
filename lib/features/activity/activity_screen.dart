import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/models/activity_item.dart';
import '../../core/providers/mock_work_provider.dart';
import '../../core/widgets/activity_list_item.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/dashboard_card.dart';
import '../../core/widgets/offline_cache_banner.dart';

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
    final activity = ref.watch(activityProvider);
    final unreadCount = ref.watch(unreadActivityCountProvider);
    final contentMaxWidth =
        MediaQuery.sizeOf(context).width >= 760 ? 720.0 : double.infinity;

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(title: 'Activities', leadingIcon: null),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    const OfflineCacheBanner(),
                    const SizedBox(height: AppSpacing.md),
                    DashboardCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$unreadCount unread',
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
                            child: const Text('Mark all read'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DashboardCard(
                      child: Column(
                        children: [
                          for (final item in activity)
                            ActivityListItem(
                              icon: _iconFor(item.type),
                              iconColor: _colorFor(item.type),
                              title: item.title,
                              subtitle: item.detail,
                              time: _timeFor(item.createdAt),
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

  String _timeFor(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} h ago';
    return '${difference.inDays} d ago';
  }
}
