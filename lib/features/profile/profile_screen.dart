import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/absence_request.dart';
import '../../core/models/employee_profile.dart';
import '../../core/models/shift.dart';
import '../../core/providers/mock_work_provider.dart';
import '../../core/providers/service_providers.dart';
import '../../core/utils/profile_photo.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/dashboard_card.dart';
import '../../core/widgets/segmented_tabs.dart';
import '../../core/widgets/shift_list_item.dart';
import '../hours/hours_screen.dart';
import '../../l10n/generated/app_localizations.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final contentMaxWidth =
        MediaQuery.sizeOf(context).width >= 760 ? 720.0 : double.infinity;

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: l10n.loginTitle,
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
                      tabs: [
                        l10n.shifts,
                        l10n.absence,
                        l10n.hours,
                        l10n.information,
                      ],
                      selectedIndex: _selectedTab,
                      onChanged: (index) =>
                          setState(() => _selectedTab = index),
                    ),
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
      1 => const _AbsenceTab(),
      2 => const HoursScreen(showHeader: false),
      _ => _InformationTab(profile: ref.watch(employeeProfileProvider)),
    };
  }
}

class _DashboardPassTab extends StatelessWidget {
  const _DashboardPassTab({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final nextShift = ref.watch(nextShiftProvider);
    final now = DateTime.now();
    final shifts = ref.watch(shiftsProvider);
    final availableShifts = shifts
        .where((shift) =>
            shift.status == ShiftStatus.available && !shift.hasEnded(now))
        .toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    final upcomingShifts = shifts
        .where((shift) =>
            shift.status != ShiftStatus.available && !shift.hasEnded(now))
        .toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    final profile = ref.watch(employeeProfileProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.nextShift, style: AppTypography.headingMedium),
        const SizedBox(height: AppSpacing.sm),
        if (nextShift == null)
          DashboardCard(
            child: Text(
              l10n.noUpcomingShifts,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.mutedText,
              ),
            ),
          )
        else
          _NextShiftCard(
            shift: nextShift,
            profile: profile,
            onTap: () => _showShiftDetails(context, nextShift),
          ),
        const SizedBox(height: AppSpacing.lg),
        _ShiftListCard(
          title: l10n.availableShifts,
          shifts: availableShifts,
          accentColor: AppColors.primaryGreen,
          onShiftTap: (shift) => _showShiftDetails(context, shift),
        ),
        const SizedBox(height: AppSpacing.md),
        _ShiftListCard(
          title: l10n.upcomingShifts,
          shifts: upcomingShifts,
          accentColor: AppColors.orangeHours,
          onShiftTap: (shift) => _showShiftDetails(context, shift),
        ),
      ],
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
      builder: (context) => _ProfileShiftDetailSheet(
        shift: shift,
      ),
    );
  }
}

class _NextShiftCard extends StatelessWidget {
  const _NextShiftCard({
    required this.shift,
    required this.profile,
    required this.onTap,
  });

  final Shift shift;
  final EmployeeProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    return DashboardCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: AppColors.greenSoft,
              backgroundImage: profilePhotoProvider(profile.profilePhotoUrl),
              child: profilePhotoProvider(profile.profilePhotoUrl) != null
                  ? null
                  : Text(
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
                    label: l10n.date,
                    text: _formatShiftDate(shift.startsAt, locale),
                  ),
                  _DetailRow(
                    icon: Icons.schedule,
                    label: l10n.time,
                    text: '${_formatTime(shift.startsAt)} - '
                        '${_formatTime(shift.endsAt)}',
                  ),
                  _DetailRow(
                    icon: Icons.coffee_outlined,
                    label: l10n.breakTime,
                    text: l10n.hoursAndBreak(
                      _formatShiftHours(shift),
                      shift.breakMinutes,
                    ),
                  ),
                  _DetailRow(
                    icon: Icons.confirmation_number_outlined,
                    label: l10n.shiftIdLabel,
                    text: shift.id.toUpperCase(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileShiftDetailSheet extends StatefulWidget {
  const _ProfileShiftDetailSheet({
    required this.shift,
  });

  final Shift shift;

  @override
  State<_ProfileShiftDetailSheet> createState() =>
      _ProfileShiftDetailSheetState();
}

class _ProfileShiftDetailSheetState extends State<_ProfileShiftDetailSheet> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final note = widget.shift.notes.trim();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 27,
                  backgroundColor: AppColors.greenSoft,
                  child: Icon(
                    Icons.event_available_rounded,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.shift.role,
                          style: AppTypography.headingMedium),
                      Text(
                        widget.shift.location,
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
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: l10n.date,
              text: _formatShiftDate(widget.shift.startsAt, locale),
            ),
            _DetailRow(
              icon: Icons.schedule,
              label: l10n.time,
              text: '${_formatTime(widget.shift.startsAt)} - '
                  '${_formatTime(widget.shift.endsAt)}',
            ),
            _DetailRow(
              icon: Icons.coffee_outlined,
              label: l10n.breakTime,
              text: l10n.hoursAndBreak(
                _formatShiftHours(widget.shift),
                widget.shift.breakMinutes,
              ),
            ),
            _DetailRow(
              icon: Icons.notes_outlined,
              label: l10n.notes,
              text: note.isEmpty ? l10n.noManagerNote : note,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text, this.label});

  final IconData icon;
  final String text;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.primaryGreen),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label != null && label!.trim().isNotEmpty)
                  Text(
                    label!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.mutedText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                Text(text, style: AppTypography.bodyMedium),
              ],
            ),
          ),
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
    required this.onShiftTap,
  });

  final String title;
  final List<Shift> shifts;
  final Color accentColor;
  final ValueChanged<Shift> onShiftTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.headingMedium),
          const SizedBox(height: AppSpacing.sm),
          if (shifts.isEmpty)
            Text(
              l10n.noShiftsRightNow,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.mutedText,
              ),
            )
          else
            for (final shift in shifts)
              ShiftListItem(
                title: shift.role,
                subtitle: shift.location,
                date: _formatShiftListDate(shift.startsAt, locale),
                time: _formatTime(shift.startsAt),
                detail: '${_formatTime(shift.startsAt)} - '
                    '${_formatTime(shift.endsAt)} · '
                    '${l10n.hoursAndBreak(
                  _formatShiftHours(shift),
                  shift.breakMinutes,
                )}',
                onTap: () => onShiftTap(shift),
                accentColor: accentColor,
              ),
        ],
      ),
    );
  }
}

class _AbsenceTab extends ConsumerStatefulWidget {
  const _AbsenceTab();

  @override
  ConsumerState<_AbsenceTab> createState() => _AbsenceTabState();
}

class _AbsenceTabState extends ConsumerState<_AbsenceTab> {
  AbsenceType _type = AbsenceType.vacation;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  final _noteController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final requests = ref.watch(absenceRequestsProvider);
    final pending = requests
        .where((request) => request.status == AbsenceStatus.pending)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.greenSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.beach_access_outlined,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.requestAbsence,
                          style: AppTypography.headingMedium,
                        ),
                        Text(
                          pending == 0
                              ? l10n.absenceRequestHelp
                              : l10n.pendingAbsenceRequests(pending),
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<AbsenceType>(
                initialValue: _type,
                decoration: InputDecoration(
                  labelText: l10n.reason,
                  prefixIcon: const Icon(Icons.category_outlined),
                ),
                items: [
                  for (final type in AbsenceType.values)
                    DropdownMenuItem(
                      value: type,
                      child: Text(_absenceTypeLabel(type, l10n)),
                    ),
                ],
                onChanged: _submitting
                    ? null
                    : (value) => setState(() {
                          if (value != null) _type = value;
                        }),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _DatePickButton(
                      label: l10n.start,
                      date: _startDate,
                      onPressed: _submitting
                          ? null
                          : () => _pickDate(isStartDate: true),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _DatePickButton(
                      label: l10n.end,
                      date: _endDate,
                      onPressed: _submitting
                          ? null
                          : () => _pickDate(isStartDate: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _noteController,
                enabled: !_submitting,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: l10n.note,
                  hintText: l10n.optionalManagerMessage,
                  prefixIcon: const Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(_submitting ? l10n.sending : l10n.sendRequest),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.requests, style: AppTypography.headingMedium),
        const SizedBox(height: AppSpacing.sm),
        if (requests.isEmpty)
          DashboardCard(
            child: Text(
              l10n.noAbsenceRequestsYet,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.mutedText,
              ),
            ),
          )
        else
          for (final request in requests) ...[
            _AbsenceRequestCard(request: request),
            if (request != requests.last) const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }

  Future<void> _pickDate({required bool isStartDate}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;

    setState(() {
      if (isStartDate) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      } else {
        _endDate = picked.isBefore(_startDate) ? _startDate : picked;
      }
    });
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.endDateAfterStart)),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(absenceRequestsProvider.notifier).submit(
            type: _type,
            startDate: _startDate,
            endDate: _endDate,
            note: _noteController.text,
          );
      _noteController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.absenceRequestSent)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_requestErrorMessage(error, l10n)),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _DatePickButton extends StatelessWidget {
  const _DatePickButton({
    required this.label,
    required this.date,
    required this.onPressed,
  });

  final String label;
  final DateTime date;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.all(AppSpacing.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.mutedText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _formatShortDate(date, locale),
            style: AppTypography.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _AbsenceRequestCard extends StatelessWidget {
  const _AbsenceRequestCard({required this.request});

  final AbsenceRequest request;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final color = _absenceStatusColor(request.status);
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _absenceTypeLabel(request.type, l10n),
                  style: AppTypography.headingMedium,
                ),
              ),
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
                  _absenceStatusLabel(request.status, l10n),
                  style: AppTypography.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _DetailRow(
            icon: Icons.date_range_outlined,
            text: '${_formatShortDate(request.startDate, locale)} - '
                '${_formatShortDate(request.endDate, locale)}',
          ),
          if (request.note.trim().isNotEmpty)
            _DetailRow(icon: Icons.notes_outlined, text: request.note.trim()),
          if (request.managerNote.trim().isNotEmpty)
            _DetailRow(
              icon: Icons.supervisor_account_outlined,
              text: request.managerNote.trim(),
            ),
        ],
      ),
    );
  }
}

class _InformationTab extends StatelessWidget {
  const _InformationTab({required this.profile});

  final EmployeeProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.greenSoft,
                backgroundImage: profilePhotoProvider(profile.profilePhotoUrl),
                child: profilePhotoProvider(profile.profilePhotoUrl) != null
                    ? null
                    : Text(
                        profile.initials,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName.isEmpty
                          ? l10n.profile
                          : profile.fullName,
                      style: AppTypography.headingMedium,
                    ),
                    Text(
                      profile.primaryRole,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _InfoRow(
            icon: Icons.mail_outline_rounded,
            label: l10n.email,
            value: profile.email.isEmpty ? l10n.notProvided : profile.email,
          ),
          _InfoRow(
            icon: Icons.phone_outlined,
            label: l10n.phone,
            value: profile.phoneNumber.isEmpty
                ? l10n.notProvided
                : profile.phoneNumber,
          ),
          _InfoRow(
            icon: Icons.work_outline_rounded,
            label: l10n.jobTitle,
            value: profile.primaryRole,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
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
          Icon(icon, size: 19, color: AppColors.primaryGreen),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(value, style: AppTypography.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatShiftDate(DateTime date, String locale) {
  final weekdays = switch (locale) {
    'so' => const [
        'Isniin',
        'Talaado',
        'Arbaco',
        'Khamiis',
        'Jimce',
        'Sabti',
        'Axad',
      ],
    'sw' => const [
        'Jumatatu',
        'Jumanne',
        'Jumatano',
        'Alhamisi',
        'Ijumaa',
        'Jumamosi',
        'Jumapili',
      ],
    _ => const [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ],
  };
  final months = switch (locale) {
    'so' => const [
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
      ],
    'sw' => const [
        'Jan',
        'Feb',
        'Mac',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Ago',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ],
    _ => const [
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
      ],
  };
  return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
}

String _formatTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatShiftHours(Shift shift) {
  var end = shift.endsAt;
  if (!end.isAfter(shift.startsAt)) {
    end = end.add(const Duration(days: 1));
  }
  final hours = end.difference(shift.startsAt).inMinutes / 60;
  if (hours == hours.roundToDouble()) return hours.toStringAsFixed(0);
  return hours.toStringAsFixed(1);
}

String _formatShortDate(DateTime date, String locale) {
  return '${date.day} ${_monthShort(date, locale)} ${date.year}';
}

String _formatShiftListDate(DateTime date, String locale) {
  final weekday = switch (locale) {
    'so' => const ['Isn', 'Tal', 'Arb', 'Kha', 'Jim', 'Sab', 'Axd'],
    'sw' => const ['Jtt', 'Jnn', 'Jtn', 'Alh', 'Ijm', 'Jms', 'Jpl'],
    _ => const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
  };
  return '${weekday[date.weekday - 1]} ${date.day}';
}

String _absenceTypeLabel(AbsenceType type, AppLocalizations l10n) {
  return switch (type) {
    AbsenceType.vacation => l10n.vacation,
    AbsenceType.sick => l10n.sickLeave,
    AbsenceType.parental => l10n.parentalLeave,
    AbsenceType.other => l10n.otherAbsence,
  };
}

String _absenceStatusLabel(AbsenceStatus status, AppLocalizations l10n) {
  return switch (status) {
    AbsenceStatus.pending => l10n.pending,
    AbsenceStatus.approved => l10n.approved,
    AbsenceStatus.denied => l10n.denied,
  };
}

Color _absenceStatusColor(AbsenceStatus status) {
  return switch (status) {
    AbsenceStatus.pending => AppColors.orangeHours,
    AbsenceStatus.approved => AppColors.primaryGreen,
    AbsenceStatus.denied => AppColors.alertRed,
  };
}

String _requestErrorMessage(Object error, AppLocalizations l10n) {
  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    final serverMessage = data is Map ? data['error'] ?? data['message'] : null;
    if (serverMessage is String && serverMessage.trim().isNotEmpty) {
      return serverMessage;
    }
    if (statusCode == 404) {
      return l10n.absenceRequestsUnavailable;
    }
    if (statusCode == 401 || statusCode == 403) {
      return l10n.sessionCannotSendRequest;
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return l10n.connectionFailedRetry;
    }
  }
  return l10n.absenceRequestFailed;
}

String _monthShort(DateTime date, [String locale = 'en']) {
  final labels = switch (locale) {
    'so' => const [
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
      ],
    'sw' => const [
        'Jan',
        'Feb',
        'Mac',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Ago',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ],
    _ => const [
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
      ],
  };
  return labels[date.month - 1];
}
