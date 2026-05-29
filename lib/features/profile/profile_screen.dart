import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/employee_profile.dart';
import '../../core/models/shift.dart';
import '../../core/providers/mock_work_provider.dart';
import '../../core/providers/service_providers.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/dashboard_card.dart';
import '../../core/widgets/offline_cache_banner.dart';
import '../../core/widgets/segmented_tabs.dart';
import '../../core/widgets/shift_list_item.dart';
import '../hours/hours_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final contentMaxWidth =
        MediaQuery.sizeOf(context).width >= 760 ? 720.0 : double.infinity;

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'My Work',
            onLeadingPressed: () => context.go('/profile/edit'),
            trailingIcon: Icons.logout_rounded,
            onTrailingPressed: () async {
              await ref.read(signOutProvider)();
              if (context.mounted) context.go('/login');
            },
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    SegmentedTabs(
                      tabs: const ['Shifts', 'Absence', 'Hours', 'Information'],
                      selectedIndex: _selectedTab,
                      onChanged: (index) =>
                          setState(() => _selectedTab = index),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const OfflineCacheBanner(),
                    const SizedBox(height: AppSpacing.md),
                    _tabBody(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBody() {
    return switch (_selectedTab) {
      0 => _DashboardPassTab(ref: ref),
      1 => const _SimpleInfoTab(
          title: 'No absence requests',
          message:
              'Approved absence, sick leave, and vacation days will appear here.',
          icon: Icons.beach_access_outlined,
        ),
      2 => const HoursScreen(showHeader: false),
      _ => const _SimpleInfoTab(
          title: 'Employment information',
          message:
              'Language, certificate, contract, and workplace details are ready for the next backend slice.',
          icon: Icons.badge_outlined,
        ),
    };
  }
}

class _DashboardPassTab extends StatelessWidget {
  const _DashboardPassTab({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final nextShift = ref.watch(nextShiftProvider);
    final now = DateTime.now();
    final shifts = ref.watch(shiftsProvider);
    final availableShifts = shifts
        .where((shift) =>
            shift.status == ShiftStatus.available &&
            !shift.endsAt.isBefore(now))
        .toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    final upcomingShifts = shifts
        .where((shift) =>
            shift.status != ShiftStatus.available)
        .toList()
      ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
    final profile = ref.watch(employeeProfileProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Next shift', style: AppTypography.headingMedium),
        const SizedBox(height: AppSpacing.sm),
        if (nextShift == null)
          DashboardCard(
            child: Text(
              'No upcoming shifts yet',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.mutedText,
              ),
            ),
          )
        else
          _NextShiftCard(shift: nextShift, profile: profile),
        const SizedBox(height: AppSpacing.lg),
        _ShiftListCard(
          title: 'Available shifts',
          shifts: availableShifts,
          accentColor: AppColors.primaryGreen,
        ),
        const SizedBox(height: AppSpacing.md),
        _ShiftListCard(
          title: 'Upcoming shifts',
          shifts: upcomingShifts,
          accentColor: AppColors.orangeHours,
        ),
      ],
    );
  }
}

class _NextShiftCard extends StatelessWidget {
  const _NextShiftCard({required this.shift, required this.profile});

  final Shift shift;
  final EmployeeProfile profile;

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.greenSoft,
            child: Text(
              profile.initials,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.fullName, style: AppTypography.headingMedium),
                Text(
                  profile.primaryRole,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  text: _formatShiftDate(shift.startsAt),
                ),
                _DetailRow(
                  icon: Icons.schedule,
                  text: '${_formatTime(shift.startsAt)} - '
                      '${_formatTime(shift.endsAt)}',
                ),
                _DetailRow(
                  icon: Icons.coffee_outlined,
                  text: 'Break ${shift.breakMinutes} min',
                ),
                _DetailRow(
                  icon: Icons.confirmation_number_outlined,
                  text: 'Shift ID ${shift.id.toUpperCase()}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.primaryGreen),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }
}

class _ShiftListCard extends StatelessWidget {
  const _ShiftListCard({
    required this.title,
    required this.shifts,
    required this.accentColor,
  });

  final String title;
  final List<Shift> shifts;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.headingMedium),
          const SizedBox(height: AppSpacing.sm),
          if (shifts.isEmpty)
            Text(
              'No shifts right now',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.mutedText,
              ),
            )
          else
            for (final shift in shifts)
              ShiftListItem(
                title: shift.role,
                subtitle: shift.location,
                time: _formatTime(shift.startsAt),
                accentColor: accentColor,
              ),
        ],
      ),
    );
  }
}

String _formatShiftDate(DateTime date) {
  return '${_weekdayLong(date)}, ${date.day} ${_monthShort(date)}';
}

String _formatTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _weekdayLong(DateTime date) {
  const labels = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  return labels[date.weekday - 1];
}

String _monthShort(DateTime date) {
  const labels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return labels[date.month - 1];
}

class _SimpleInfoTab extends StatelessWidget {
  const _SimpleInfoTab({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryGreen, size: 42),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTypography.headingMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}
