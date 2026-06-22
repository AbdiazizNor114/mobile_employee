import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
  String? _confirmingShiftId;

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
    final locale = Localizations.localeOf(context).languageCode;
    final shifts = ref.watch(shiftsProvider);
    final workedDays = _workedDaysFromShifts(shifts);
    final visibleDays = workedDays.where((day) {
      return !day.date.isBefore(_selectedRange.start) &&
          !day.date.isAfter(_selectedRange.end);
    }).toList();
    final visibleShifts = shifts.where((shift) {
      if (shift.status == ShiftStatus.available) return false;
      final date = DateTime(
        shift.startsAt.year,
        shift.startsAt.month,
        shift.startsAt.day,
      );
      return !date.isBefore(_selectedRange.start) &&
          !date.isAfter(_selectedRange.end);
    }).toList()
      ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
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
    final pendingShifts = hasShiftConfirmation
        ? shifts.where((shift) => shift.canConfirmWork(now)).toList()
        : <Shift>[]
      ..sort((a, b) =>
          a.workConfirmationDeadline.compareTo(b.workConfirmationDeadline));
    final pendingConfirmations = pendingShifts.length;
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
      pendingDaysRemaining: pendingShifts.isEmpty
          ? 0
          : _daysUntil(pendingShifts.first.workConfirmationDeadline, now),
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
                          '${_formatMonthDay(_selectedRange.start, locale)} - '
                          '${_formatMonthDay(_selectedRange.end, locale)}',
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
                  if (visibleShifts.isEmpty)
                    Text(
                      l10n.noBookedShifts,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.mutedText,
                      ),
                    )
                  else
                    for (final shift in visibleShifts) ...[
                      _ShiftHistoryRow(
                        shift: shift,
                        now: now,
                        confirmationEnabled: hasShiftConfirmation,
                        isConfirming: _confirmingShiftId == shift.id,
                        onConfirm: () => _confirmShift(shift),
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

  Future<void> _confirmShift(Shift shift) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.confirmWorkedQuestion),
        content: Text(
          '${shift.role}\n'
          '${_localizedShiftDate(shift.startsAt, Localizations.localeOf(context).languageCode)}, '
          '${_formatTime(shift.startsAt)} - ${_formatTime(shift.endsAt)}\n\n'
          '${l10n.confirmAttestation}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.check_rounded),
            label: Text(l10n.confirmWorked),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _confirmingShiftId = shift.id);
    try {
      await ref.read(shiftsProvider.notifier).confirmShiftWorked(shift.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.shiftConfirmedAsWorked)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.shiftConfirmationFailed)),
      );
    } finally {
      if (mounted) setState(() => _confirmingShiftId = null);
    }
  }
}

class _ShiftHistoryRow extends StatelessWidget {
  const _ShiftHistoryRow({
    required this.shift,
    required this.now,
    required this.confirmationEnabled,
    required this.isConfirming,
    required this.onConfirm,
  });

  final Shift shift;
  final DateTime now;
  final bool confirmationEnabled;
  final bool isConfirming;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final state = _confirmationState(shift, now, confirmationEnabled);
    final color = switch (state) {
      _ConfirmationVisualState.pending => AppColors.orangeHours,
      _ConfirmationVisualState.confirmed => AppColors.primaryGreen,
      _ConfirmationVisualState.overdue => AppColors.alertRed,
      _ConfirmationVisualState.absent => AppColors.mutedText,
      _ConfirmationVisualState.neutral => AppColors.blueInfo,
    };
    final label = switch (state) {
      _ConfirmationVisualState.pending => l10n.awaitingConfirmation,
      _ConfirmationVisualState.confirmed => l10n.confirmed,
      _ConfirmationVisualState.overdue => l10n.confirmationOverdue,
      _ConfirmationVisualState.absent => l10n.absent,
      _ConfirmationVisualState.neutral => l10n.scheduled,
    };
    final detail = switch (state) {
      _ConfirmationVisualState.pending => l10n.confirmBy(
          _localizedShiftDate(shift.workConfirmationDeadline, locale),
        ),
      _ConfirmationVisualState.overdue => l10n.managerReviewRequired,
      _ => '',
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 5,
          height: 72,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
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
              if (shift.location.trim().isNotEmpty)
                Text(
                  shift.location,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.mutedText,
                  ),
                ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${_localizedShiftDate(shift.startsAt, locale)} · '
                '${_formatTime(shift.startsAt)} - ${_formatTime(shift.endsAt)} · '
                '${_formatHours(_shiftDurationHours(shift))} h',
                style: AppTypography.caption.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      label,
                      style: AppTypography.caption.copyWith(
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (detail.isNotEmpty)
                    Text(
                      detail,
                      style: AppTypography.caption.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  if (state == _ConfirmationVisualState.pending)
                    FilledButton.icon(
                      onPressed: isConfirming ? null : onConfirm,
                      icon: isConfirming
                          ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        isConfirming ? l10n.confirming : l10n.confirmWorked,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _ConfirmationVisualState { pending, confirmed, overdue, absent, neutral }

_ConfirmationVisualState _confirmationState(
  Shift shift,
  DateTime now,
  bool confirmationEnabled,
) {
  if (shift.workConfirmationStatus == WorkConfirmationStatus.absent) {
    return _ConfirmationVisualState.absent;
  }
  if (shift.isWorkConfirmed) return _ConfirmationVisualState.confirmed;
  if (!confirmationEnabled || !shift.workConfirmationRequired) {
    return _ConfirmationVisualState.neutral;
  }
  if (shift.isWorkConfirmationOverdue(now)) {
    return _ConfirmationVisualState.overdue;
  }
  if (shift.canConfirmWork(now)) return _ConfirmationVisualState.pending;
  return _ConfirmationVisualState.neutral;
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
  required int pendingDaysRemaining,
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
      l10n.aiPendingConfirmationReminder(
        pendingConfirmations,
        pendingDaysRemaining,
      ),
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

String _formatMonthDay(DateTime date, String locale) {
  if (locale != 'so') return DateFormat('MMM d', locale).format(date);
  const months = [
    'Jan',
    'Feb',
    'Maar',
    'Abr',
    'May',
    'Juun',
    'Luul',
    'Ago',
    'Seb',
    'Okt',
    'Nof',
    'Dis',
  ];
  return '${months[date.month - 1]} ${date.day}';
}

String _formatHours(double hours) {
  if (hours == hours.roundToDouble()) return hours.toStringAsFixed(0);
  return hours.toStringAsFixed(1);
}

String _formatTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

int _daysUntil(DateTime deadline, DateTime now) {
  final remainingMinutes = deadline.difference(now).inMinutes;
  if (remainingMinutes <= 0) return 0;
  return (remainingMinutes / Duration.minutesPerDay).ceil();
}

String _localizedShiftDate(DateTime date, String locale) {
  if (locale != 'so') return DateFormat('EEE d MMM', locale).format(date);
  const weekdays = ['Isn', 'Tal', 'Arb', 'Kha', 'Jim', 'Sab', 'Axd'];
  const months = [
    'Jan',
    'Feb',
    'Maar',
    'Abr',
    'May',
    'Juun',
    'Luul',
    'Ago',
    'Seb',
    'Okt',
    'Nof',
    'Dis',
  ];
  return '${weekdays[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
}

class _WorkedDay {
  const _WorkedDay(this.date, this.hours, this.breakHours);

  final DateTime date;
  final double hours;
  final double breakHours;
}
