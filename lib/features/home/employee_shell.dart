import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/providers/backend_sync_provider.dart';
import '../../core/providers/mock_work_provider.dart';
import '../../core/providers/service_providers.dart';
import '../../core/widgets/dashboard_card.dart';
import '../../core/widgets/shaqonet_bottom_nav_bar.dart';
import '../activity/activity_screen.dart';
import '../messages/messages_screen.dart';
import '../profile/account_screen.dart';
import '../profile/profile_screen.dart';
import '../schedule/schedule_screen.dart';

class EmployeeShell extends ConsumerStatefulWidget {
  const EmployeeShell({super.key});

  @override
  ConsumerState<EmployeeShell> createState() => _EmployeeShellState();
}

class _EmployeeShellState extends ConsumerState<EmployeeShell> {
  static const _autoSyncInterval = Duration(seconds: 12);
  int _currentIndex = 0;
  Timer? _autoSyncTimer;
  bool _syncInFlight = false;
  bool _manualSyncInFlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    _startAutoSync();
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  late final _AppLifecycleObserver _lifecycleObserver = _AppLifecycleObserver(
    onResume: _syncNow,
  );

  void _startAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(_autoSyncInterval, (_) => _syncNow());
  }

  Future<void> _syncNow({bool force = false}) async {
    if (!mounted || (_syncInFlight && !force)) return;
    _syncInFlight = true;
    try {
      ref.invalidate(backendSyncProvider);
      await ref.read(backendSyncProvider.future);
    } catch (_) {
      // Surface errors via providers/UI; keep timer alive.
    } finally {
      _syncInFlight = false;
    }
  }

  Future<void> _retrySync() async {
    if (_manualSyncInFlight) return;
    setState(() => _manualSyncInFlight = true);
    try {
      await _syncNow(force: true);
    } finally {
      if (mounted) setState(() => _manualSyncInFlight = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(backendSyncProvider);
    final syncError = ref.watch(lastSyncErrorProvider);
    final unreadActivityCount = ref.watch(unreadActivityCountProvider);
    final hasData = ref.watch(employeeProfileProvider).firstName.isNotEmpty;

    const screens = [
      ProfileScreen(),
      ScheduleScreen(),
      ActivityScreen(),
      MessagesScreen(),
      AccountScreen(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: screens),
          if (syncError != null && hasData)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              left: 12,
              right: 12,
              child: Material(
                color: Colors.transparent,
                child: DashboardCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.sync_problem_rounded,
                        color: AppColors.alertRed,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          syncError,
                          style: AppTypography.bodyMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: _manualSyncInFlight ? null : _retrySync,
                        child: Text(
                          _manualSyncInFlight ? 'Retrying...' : 'Retry',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (syncState.hasError && !hasData)
            _SyncErrorOverlay(
              error: syncState.error,
              isRetrying: _manualSyncInFlight,
              onRetry: _retrySync,
            ),
        ],
      ),
      bottomNavigationBar: ShaqoNetBottomNavBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        unreadActivityCount: unreadActivityCount,
      ),
    );
  }
}

class _AppLifecycleObserver extends WidgetsBindingObserver {
  _AppLifecycleObserver({required this.onResume});

  final Future<void> Function() onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    }
  }
}

class _SyncErrorOverlay extends ConsumerWidget {
  const _SyncErrorOverlay({
    required this.error,
    required this.isRetrying,
    required this.onRetry,
  });

  final Object? error;
  final bool isRetrying;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: DashboardCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  color: AppColors.alertRed, size: 48),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Sync Failed',
                style: AppTypography.headingMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'We could not fetch your work data. Check your connection or API configuration.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: isRetrying ? null : onRetry,
                child: Text(isRetrying ? 'Retrying...' : 'Retry Sync'),
              ),
              TextButton(
                onPressed: () => ref.read(signOutProvider)(),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
