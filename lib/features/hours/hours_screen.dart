import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/shift.dart';
import '../../core/providers/mock_work_provider.dart';
import '../../core/providers/service_providers.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/dashboard_card.dart';
import '../../core/widgets/offline_cache_banner.dart';
import '../../core/widgets/stat_card.dart';
import '../../l10n/generated/app_localizations.dart';

class HoursScreen extends ConsumerStatefulWidget {
  const HoursScreen({super.key, this.showHeader = true});

  final bool showHeader;

  @override
  ConsumerState<HoursScreen> createState() => _HoursScreenState();
}

class _HoursScreenState extends ConsumerState<HoursScreen> {
  late DateTimeRange _selectedRange;

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
    final l10n = AppLocalizations.of(context);
    final shifts = ref.watch(shiftsProvider);
    final workedDays = _workedDaysFromShifts(shifts);
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
    final companyPlan = ref.watch(companyPlanProvider).toLowerCase();
    final hasShiftConfirmation =
        companyPlan == 'pro' || companyPlan == 'enterprise';
    final now = DateTime.now();
    final pendingConfirmations = hasShiftConfirmation
        ? shifts.where((shift) => shift.canConfirmWork(now)).length
        : 0;
    final overdueConfirmations = hasShiftConfirmation
        ? shifts.where((shift) => shift.isWorkConfirmationOverdue(now)).length
        : 0;
    final aiInsight = _buildAiInsight(
      l10n: l10n,
      scheduledHours: totalHours,
      completedHours: completedHours,
      breakHours: breakHours,
      workDays: workDays,
      pendingConfirmations: pendingConfirmations,
      overdueConfirmations: overdueConfirmations,
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
            DashboardCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.dateRange, style: AppTypography.headingMedium),
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
                        label: Text(l10n.change),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      ActionChip(
                        label: Text(l10n.thisWeek),
                        onPressed: _selectThisWeek,
                      ),
                      ActionChip(
                        label: Text(l10n.thisMonth),
                        onPressed: _selectThisMonth,
                      ),
                      ActionChip(
                        label: Text(l10n.lastSevenDays),
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
                    label: l10n.totalShiftHours,
                    value: _formatHours(totalHours),
                    accentColor: AppColors.orangeHours,
                    icon: Icons.schedule,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: StatCard(
                    label: l10n.workDays,
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
                    label: l10n.breakTime,
                    value: '${_formatHours(breakHours)} h',
                    accentColor: AppColors.primaryGreen,
                    icon: Icons.coffee_outlined,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: StatCard(
                    label: l10n.averageShiftLength,
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
                  Text(l10n.timeBalance, style: AppTypography.headingMedium),
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
                    aiInsight.message,
                    style: AppTypography.bodyMedium.copyWith(
                      color: aiInsight.color,
                      fontWeight: aiInsight.isActionRequired
                          ? FontWeight.w800
                          : FontWeight.normal,
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
                  Text(l10n.bookedDays, style: AppTypography.headingMedium),
                  const SizedBox(height: AppSpacing.sm),
                  if (visibleDays.isEmpty)
                    Text(
                      l10n.noBookedShifts,
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
          AppHeader(title: l10n.timeReport, leadingIcon: null),
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
      helpText: AppLocalizations.of(context).chooseWorkedDays,
      saveText: AppLocalizations.of(context).apply,
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

_AiInsight _buildAiInsight({
  required AppLocalizations l10n,
  required double scheduledHours,
  required double completedHours,
  required double breakHours,
  required int workDays,
  required int pendingConfirmations,
  required int overdueConfirmations,
}) {
  if (overdueConfirmations > 0) {
    return _AiInsight(
      l10n.aiOverdueConfirmations(overdueConfirmations),
      AppColors.alertRed,
      isActionRequired: true,
    );
  }
  if (pendingConfirmations > 0) {
    return _AiInsight(
      l10n.aiPendingConfirmations(pendingConfirmations),
      AppColors.orangeHours,
      isActionRequired: true,
    );
  }
  if (workDays == 0) {
    return _AiInsight(
      l10n.aiNoAssignedShifts,
      AppColors.mutedText,
    );
  }
  if (completedHours == 0 && scheduledHours > 0) {
    return _AiInsight(
      l10n.aiScheduledNoneCompleted(_formatHours(scheduledHours)),
      AppColors.mutedText,
    );
  }
  if (scheduledHours == completedHours) {
    return _AiInsight(
      l10n.aiAllHoursCompleted,
      AppColors.mutedText,
    );
  }
  final remaining =
      (scheduledHours - completedHours).clamp(0, scheduledHours).toDouble();
  return _AiInsight(
    l10n.aiHoursProgress(
      _formatHours(completedHours),
      _formatHours(remaining),
      _formatHours(breakHours),
    ),
    AppColors.mutedText,
  );
}

class _AiInsight {
  const _AiInsight(
    this.message,
    this.color, {
    this.isActionRequired = false,
  });

  final String message;
  final Color color;
  final bool isActionRequired;
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
