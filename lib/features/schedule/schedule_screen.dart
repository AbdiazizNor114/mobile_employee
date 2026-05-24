import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/shift.dart';
import '../../core/providers/mock_work_provider.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/dashboard_card.dart';
import '../../core/widgets/offline_cache_banner.dart';
import '../../core/widgets/segmented_tabs.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  int _selectedTab = 0;
  int _selectedDay = 1;

  @override
  Widget build(BuildContext context) {
    final shifts = ref.watch(shiftsProvider);
    final visibleShifts = switch (_selectedTab) {
      1 => shifts.where((shift) => shift.status == ShiftStatus.confirmed),
      2 => shifts.where((shift) => shift.status == ShiftStatus.available),
      _ => shifts,
    }
        .toList();
    final contentMaxWidth =
        MediaQuery.sizeOf(context).width >= 760 ? 760.0 : double.infinity;

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(
            title: 'Schedule',
            leadingIcon: Icons.calendar_month_outlined,
            trailingIcon: Icons.tune_rounded,
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    SegmentedTabs(
                      tabs: const ['All', 'Confirmed', 'Open'],
                      selectedIndex: _selectedTab,
                      onChanged: (index) =>
                          setState(() => _selectedTab = index),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const OfflineCacheBanner(),
                    const SizedBox(height: AppSpacing.md),
                    DashboardCard(
                      child: _WeekStrip(
                        selectedDay: _selectedDay,
                        onSelected: (index) =>
                            setState(() => _selectedDay = index),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ScheduleSummary(shifts: shifts),
                    const SizedBox(height: AppSpacing.md),
                    DashboardCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Upcoming shifts',
                                  style: AppTypography.headingMedium,
                                ),
                              ),
                              Text(
                                '${visibleShifts.length} shifts',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.mutedText,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          for (final shift in visibleShifts) ...[
                            _ScheduleShiftTile(
                              shift: shift,
                              onTap: () => _showShiftDetails(context, shift),
                            ),
                            if (shift != visibleShifts.last)
                              const Divider(height: AppSpacing.lg),
                          ],
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

  void _showShiftDetails(BuildContext context, Shift shift) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => _ShiftDetailSheet(
        shift: shift,
        onAccept: () => ref.read(shiftsProvider.notifier).acceptShift(shift.id),
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.selectedDay, required this.onSelected});

  final int selectedDay;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(7, (index) => today.add(Duration(days: index)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('This week', style: AppTypography.headingMedium),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            for (final entry in days.indexed)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: entry.$1 == days.length - 1 ? 0 : AppSpacing.xs,
                  ),
                  child: _DayPill(
                    date: entry.$2,
                    isSelected: selectedDay == entry.$1,
                    onTap: () => onSelected(entry.$1),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : AppColors.background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              _weekdayShort(date),
              style: AppTypography.caption.copyWith(
                color:
                    isSelected ? AppColors.cardBackground : AppColors.mutedText,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${date.day}',
              style: AppTypography.bodyLarge.copyWith(
                color:
                    isSelected ? AppColors.cardBackground : AppColors.darkText,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleSummary extends StatelessWidget {
  const _ScheduleSummary({required this.shifts});

  final List<Shift> shifts;

  @override
  Widget build(BuildContext context) {
    final confirmed =
        shifts.where((shift) => shift.status == ShiftStatus.confirmed).length;
    final open =
        shifts.where((shift) => shift.status == ShiftStatus.available).length;
    final hours = shifts.where((shift) {
      return shift.status != ShiftStatus.available;
    }).fold<double>(
      0,
      (total, shift) => total + shift.endsAt.difference(shift.startsAt).inHours,
    );

    return Row(
      children: [
        Expanded(
          child: _MiniSummaryCard(
            label: 'Confirmed',
            value: '$confirmed',
            color: AppColors.primaryGreen,
            icon: Icons.verified_outlined,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MiniSummaryCard(
            label: 'Open',
            value: '$open',
            color: AppColors.blueInfo,
            icon: Icons.add_task_rounded,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MiniSummaryCard(
            label: 'Hours',
            value: '${hours.toStringAsFixed(0)}h',
            color: AppColors.orangeHours,
            icon: Icons.schedule_rounded,
          ),
        ),
      ],
    );
  }
}

class _MiniSummaryCard extends StatelessWidget {
  const _MiniSummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.headingMedium.copyWith(color: color),
          ),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.mutedText,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleShiftTile extends StatelessWidget {
  const _ScheduleShiftTile({required this.shift, required this.onTap});

  final Shift shift;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(shift.status);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 58,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _weekdayShort(shift.startsAt),
                    style: AppTypography.caption.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${shift.startsAt.day}',
                    style: AppTypography.bodyLarge.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shift.role,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    shift.location,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _InfoChip(
                        icon: Icons.access_time_rounded,
                        label:
                            '${_time(shift.startsAt)} - ${_time(shift.endsAt)}',
                      ),
                      _StatusChip(status: shift.status),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.mutedText),
          ],
        ),
      ),
    );
  }
}

class _ShiftDetailSheet extends StatelessWidget {
  const _ShiftDetailSheet({required this.shift, required this.onAccept});

  final Shift shift;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final duration = shift.endsAt.difference(shift.startsAt).inHours;
    final statusColor = _statusColor(shift.status);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child:
                      Icon(Icons.event_available_rounded, color: statusColor),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shift.role,
                        style: AppTypography.headingMedium,
                      ),
                      Text(
                        shift.location,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _StatusChip(status: shift.status),
                _InfoChip(
                  icon: Icons.confirmation_number_outlined,
                  label: shift.id.toUpperCase(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Date',
              value:
                  '${_weekdayLong(shift.startsAt)}, ${shift.startsAt.day} ${_monthShort(shift.startsAt)}',
            ),
            _DetailRow(
              icon: Icons.access_time_rounded,
              label: 'Time',
              value: '${_time(shift.startsAt)} - ${_time(shift.endsAt)}',
            ),
            _DetailRow(
              icon: Icons.hourglass_bottom_rounded,
              label: 'Duration',
              value: '$duration hours, 30 min break',
            ),
            _DetailRow(
              icon: Icons.notes_rounded,
              label: 'Notes',
              value: shift.status == ShiftStatus.available
                  ? 'Open shift. Accepting it will notify the coordinator.'
                  : 'Bring your ID badge and check in when you arrive.',
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: shift.status == ShiftStatus.available
                    ? () {
                        onAccept();
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Open shift accepted and added to your schedule.'),
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: Text(
                  shift.status == ShiftStatus.available
                      ? 'Accept open shift'
                      : 'Already assigned',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.greenSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primaryGreen, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.mutedText),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.darkText,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ShiftStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(status),
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

String _weekdayShort(DateTime date) {
  const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return labels[date.weekday - 1];
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

String _time(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _statusLabel(ShiftStatus status) {
  return switch (status) {
    ShiftStatus.confirmed => 'Confirmed',
    ShiftStatus.available => 'Open shift',
    ShiftStatus.changed => 'Changed',
  };
}

Color _statusColor(ShiftStatus status) {
  return switch (status) {
    ShiftStatus.confirmed => AppColors.primaryGreen,
    ShiftStatus.available => AppColors.blueInfo,
    ShiftStatus.changed => AppColors.orangeHours,
  };
}
