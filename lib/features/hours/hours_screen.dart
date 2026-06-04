import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/shift.dart';
import '../../core/models/time_entry.dart';
import '../../core/providers/mock_work_provider.dart';
import '../../core/providers/service_providers.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/dashboard_card.dart';
import '../../core/widgets/offline_cache_banner.dart';
import '../../core/widgets/stat_card.dart';

class HoursScreen extends ConsumerStatefulWidget {
  const HoursScreen({super.key, this.showHeader = true});

  final bool showHeader;

  @override
  ConsumerState<HoursScreen> createState() => _HoursScreenState();
}

class _HoursScreenState extends ConsumerState<HoursScreen> {
  late DateTimeRange _selectedRange;
  bool _clockLoading = false;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedRange = DateTimeRange(
      start: DateTime(today.year, today.month),
      end: DateTime(today.year, today.month + 1, 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shifts = ref.watch(shiftsProvider);
    final timeEntries = ref.watch(timeEntriesProvider);
    final companyPlan = ref.watch(companyPlanProvider).toLowerCase();
    final canUseTimeClock = companyPlan == 'pro' || companyPlan == 'enterprise';
    final openEntry = timeEntries.where((entry) => entry.isOpen).firstOrNull;
    final nextShift = ref.watch(nextShiftProvider);
    final workedDays = timeEntries.isNotEmpty
        ? _workedDaysFromTimeEntries(timeEntries)
        : _workedDaysFromShifts(shifts);
    final visibleDays = workedDays.where((day) {
      return !day.date.isBefore(_selectedRange.start) &&
          !day.date.isAfter(_selectedRange.end);
    }).toList();
    final totalHours = visibleDays.fold<double>(
      0,
      (total, day) => total + day.hours,
    );
    final workDays = visibleDays.length;
    final breakHours =
        visibleDays.fold<double>(0, (sum, day) => sum + day.breakHours);
    final completedHours = _completedShiftHoursInRange(
      shifts: shifts,
      start: _selectedRange.start,
      end: _selectedRange.end,
    );
    final aiInsight = _buildAiInsight(
      scheduledHours: totalHours,
      completedHours: completedHours,
      breakHours: breakHours,
      workDays: workDays,
    );
    final contentMaxWidth =
        MediaQuery.sizeOf(context).width >= 760 ? 720.0 : double.infinity;

    final content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: contentMaxWidth),
        child: ListView(
          shrinkWrap: !widget.showHeader,
          physics:
              widget.showHeader ? null : const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const OfflineCacheBanner(),
            const SizedBox(height: AppSpacing.md),
            _ClockCard(
              openEntry: openEntry,
              nextShift: nextShift,
              loading: _clockLoading,
              canUseTimeClock: canUseTimeClock,
              onClockIn: () => _clockIn(nextShift?.id),
              onClockOut:
                  openEntry == null ? null : () => _clockOut(openEntry.id),
            ),
            const SizedBox(height: AppSpacing.md),
            DashboardCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date range', style: AppTypography.headingMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_formatDate(_selectedRange.start)} - ${_formatDate(_selectedRange.end)}',
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _pickDateRange,
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: const Text('Change'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      ActionChip(
                        label: const Text('This week'),
                        onPressed: _selectThisWeek,
                      ),
                      ActionChip(
                        label: const Text('This month'),
                        onPressed: _selectThisMonth,
                      ),
                      ActionChip(
                        label: const Text('Last 7 days'),
                        onPressed: _selectLastSevenDays,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Total shift hours',
                    value: _formatHours(totalHours),
                    accentColor: AppColors.orangeHours,
                    icon: Icons.schedule,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: StatCard(
                    label: 'Work days',
                    value: '$workDays',
                    accentColor: AppColors.purpleWorkdays,
                    icon: Icons.work_outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Break time',
                    value: '${_formatHours(breakHours)} h',
                    accentColor: AppColors.primaryGreen,
                    icon: Icons.coffee_outlined,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: StatCard(
                    label: 'Avg shift length',
                    value: workDays == 0
                        ? '0'
                        : _formatHours(totalHours / workDays),
                    accentColor: AppColors.blueInfo,
                    icon: Icons.timelapse_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            DashboardCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Time balance', style: AppTypography.headingMedium),
                  const SizedBox(height: AppSpacing.sm),
                  LinearProgressIndicator(
                    value: (totalHours / 40).clamp(0.0, 1.0),
                    minHeight: 10,
                    color: AppColors.primaryGreen,
                    backgroundColor: AppColors.greenSoft,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    aiInsight,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DashboardCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Worked days', style: AppTypography.headingMedium),
                  const SizedBox(height: AppSpacing.sm),
                  if (visibleDays.isEmpty)
                    Text(
                      'No worked days in this range',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.mutedText,
                      ),
                    )
                  else
                    for (final row in visibleDays)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(_formatWorkedDay(row.date)),
                        trailing: Text(
                          '${_formatHours(row.hours)} h',
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.orangeHours,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (!widget.showHeader) return content;

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(title: 'Hours / Time report', leadingIcon: null),
          Expanded(child: content),
        ],
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final today = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedRange,
      firstDate: DateTime(today.year, today.month - 3),
      lastDate: DateTime(today.year, today.month + 3),
      helpText: 'Choose worked days',
      saveText: 'Apply',
    );

    if (range == null) return;
    setState(() => _selectedRange = _normalizeRange(range.start, range.end));
  }

  void _selectThisWeek() {
    final today = DateTime.now();
    final start = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: today.weekday - 1));
    setState(() => _selectedRange = _normalizeRange(start, today));
  }

  void _selectThisMonth() {
    final today = DateTime.now();
    setState(() {
      _selectedRange = _normalizeRange(
        DateTime(today.year, today.month),
        DateTime(today.year, today.month + 1, 0),
      );
    });
  }

  void _selectLastSevenDays() {
    final today = DateTime.now();
    setState(() {
      _selectedRange = _normalizeRange(
        today.subtract(const Duration(days: 6)),
        today,
      );
    });
  }

  Future<void> _clockIn(String? shiftId) async {
    setState(() => _clockLoading = true);
    try {
      await ref.read(timeEntriesProvider.notifier).clockIn(shiftId: shiftId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clocked in.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not clock in. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _clockLoading = false);
    }
  }

  Future<void> _clockOut(String entryId) async {
    setState(() => _clockLoading = true);
    try {
      await ref.read(timeEntriesProvider.notifier).clockOut(entryId: entryId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clocked out.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not clock out. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _clockLoading = false);
    }
  }
}

class _ClockCard extends StatelessWidget {
  const _ClockCard({
    required this.openEntry,
    required this.nextShift,
    required this.loading,
    required this.canUseTimeClock,
    required this.onClockIn,
    required this.onClockOut,
  });

  final TimeEntry? openEntry;
  final Shift? nextShift;
  final bool loading;
  final bool canUseTimeClock;
  final VoidCallback onClockIn;
  final VoidCallback? onClockOut;

  @override
  Widget build(BuildContext context) {
    final isClockedIn = openEntry != null;
    return DashboardCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isClockedIn ? AppColors.greenSoft : AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isClockedIn ? Icons.timer_rounded : Icons.login_rounded,
              color: isClockedIn ? AppColors.primaryGreen : AppColors.blueInfo,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  !canUseTimeClock
                      ? 'Time clock locked'
                      : isClockedIn
                          ? 'Clocked in'
                          : 'Ready to clock in',
                  style: AppTypography.headingMedium,
                ),
                Text(
                  !canUseTimeClock
                      ? 'Clock in/out is available on Pro and Enterprise.'
                      : isClockedIn
                          ? 'Started ${_formatClockTime(openEntry!.clockInAt)}'
                          : nextShift == null
                              ? 'No shift selected'
                              : '${nextShift!.role} at ${_formatClockTime(nextShift!.startsAt)}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: loading || !canUseTimeClock
                ? null
                : (isClockedIn ? onClockOut : onClockIn),
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    isClockedIn ? Icons.logout_rounded : Icons.login_rounded),
            label: Text(!canUseTimeClock
                ? 'Pro'
                : isClockedIn
                    ? 'Clock out'
                    : 'Clock in'),
          ),
        ],
      ),
    );
  }
}

DateTimeRange _normalizeRange(DateTime start, DateTime end) {
  return DateTimeRange(
    start: DateTime(start.year, start.month, start.day),
    end: DateTime(end.year, end.month, end.day),
  );
}

List<_WorkedDay> _workedDaysFromShifts(List<Shift> shifts) {
  final grouped = <String, _WorkedDay>{};
  for (final shift in shifts) {
    if (shift.status == ShiftStatus.available) continue;
    final date = DateTime(
      shift.startsAt.year,
      shift.startsAt.month,
      shift.startsAt.day,
    );
    final key = '${date.year}-${date.month}-${date.day}';
    final totalHours = _shiftDurationHours(shift);
    final breakHours = shift.breakMinutes / 60;
    final existing = grouped[key];
    if (existing == null) {
      grouped[key] = _WorkedDay(date, totalHours, breakHours);
    } else {
      grouped[key] = _WorkedDay(
        date,
        existing.hours + totalHours,
        existing.breakHours + breakHours,
      );
    }
  }
  final days = grouped.values.toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  return days;
}

List<_WorkedDay> _workedDaysFromTimeEntries(List<TimeEntry> entries) {
  final grouped = <String, _WorkedDay>{};
  for (final entry in entries) {
    if (entry.clockOutAt == null) continue;
    final date = DateTime(
      entry.clockInAt.year,
      entry.clockInAt.month,
      entry.clockInAt.day,
    );
    final key = '${date.year}-${date.month}-${date.day}';
    final hours = entry.workedMinutes / 60;
    final breakHours = entry.breakMinutes / 60;
    final existing = grouped[key];
    if (existing == null) {
      grouped[key] = _WorkedDay(date, hours, breakHours);
    } else {
      grouped[key] = _WorkedDay(
        date,
        existing.hours + hours,
        existing.breakHours + breakHours,
      );
    }
  }
  final days = grouped.values.toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  return days;
}

double _completedShiftHoursInRange({
  required List<Shift> shifts,
  required DateTime start,
  required DateTime end,
}) {
  final now = DateTime.now();
  return shifts.where((shift) {
    if (shift.status == ShiftStatus.available) return false;
    if (_effectiveShiftEnd(shift).isAfter(now)) return false;
    final shiftDate = DateTime(
      shift.startsAt.year,
      shift.startsAt.month,
      shift.startsAt.day,
    );
    return !shiftDate.isBefore(start) && !shiftDate.isAfter(end);
  }).fold<double>(0, (sum, shift) => sum + _shiftDurationHours(shift));
}

String _buildAiInsight({
  required double scheduledHours,
  required double completedHours,
  required double breakHours,
  required int workDays,
}) {
  if (workDays == 0) {
    return 'AI insight: No assigned shifts in this range yet. Add a shift or widen the date range.';
  }
  if (completedHours == 0 && scheduledHours > 0) {
    return 'AI insight: You have ${_formatHours(scheduledHours)} scheduled hours in this range, but none completed yet.';
  }
  if (scheduledHours == completedHours) {
    return 'AI insight: Great consistency. All scheduled hours in this range are completed.';
  }
  final remaining =
      (scheduledHours - completedHours).clamp(0, scheduledHours).toDouble();
  return 'AI insight: ${_formatHours(completedHours)}h completed, ${_formatHours(remaining)}h remaining, with ${_formatHours(breakHours)}h break time scheduled.';
}

double _shiftDurationHours(Shift shift) {
  return _effectiveShiftEnd(shift).difference(shift.startsAt).inMinutes / 60;
}

DateTime _effectiveShiftEnd(Shift shift) {
  var end = shift.endsAt;
  if (!end.isAfter(shift.startsAt)) {
    end = end.add(const Duration(days: 1));
  }
  return end;
}

String _formatDate(DateTime date) {
  return '${_monthShort(date)} ${date.day}';
}

String _formatWorkedDay(DateTime date) {
  return '${_weekdayShort(date)} ${date.day} ${_monthShort(date)}';
}

String _formatClockTime(DateTime date) {
  return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

String _formatHours(double hours) {
  if (hours == hours.roundToDouble()) return hours.toStringAsFixed(0);
  return hours.toStringAsFixed(1);
}

String _weekdayShort(DateTime date) {
  const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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

class _WorkedDay {
  const _WorkedDay(this.date, this.hours, this.breakHours);

  final DateTime date;
  final double hours;
  final double breakHours;
}
