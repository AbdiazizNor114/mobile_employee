import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
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
    final workedDays = _workedDays();
    final visibleDays = workedDays.where((day) {
      return !day.date.isBefore(_selectedRange.start) &&
          !day.date.isAfter(_selectedRange.end);
    }).toList();
    final totalHours = visibleDays.fold<double>(
      0,
      (total, day) => total + day.hours,
    );
    final workDays = visibleDays.length;
    final breakHours = workDays * 0.5;
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
                    'AI insight: Your time record is stable for the selected range. Review changed shifts before the report closes.',
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
}

DateTimeRange _normalizeRange(DateTime start, DateTime end) {
  return DateTimeRange(
    start: DateTime(start.year, start.month, start.day),
    end: DateTime(end.year, end.month, end.day),
  );
}

List<_WorkedDay> _workedDays() {
  final today = DateTime.now();
  final base = DateTime(today.year, today.month, today.day);

  return [
    _WorkedDay(base.subtract(const Duration(days: 15)), 8),
    _WorkedDay(base.subtract(const Duration(days: 10)), 7.5),
    _WorkedDay(base.subtract(const Duration(days: 6)), 8),
    _WorkedDay(base.subtract(const Duration(days: 3)), 7.5),
    _WorkedDay(base.subtract(const Duration(days: 2)), 6.5),
    _WorkedDay(base.subtract(const Duration(days: 1)), 8),
    _WorkedDay(base, 4),
  ];
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
  const _WorkedDay(this.date, this.hours);

  final DateTime date;
  final double hours;
}
