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
import '../../core/models/time_entry.dart';
import '../../core/providers/mock_work_provider.dart';
import '../../core/providers/service_providers.dart';
import '../../core/utils/profile_photo.dart';
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
            shift.status != ShiftStatus.available &&
            !shift.endsAt.isBefore(now))
        .toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
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
          _NextShiftCard(
            shift: nextShift,
            profile: profile,
            onTap: () => _showShiftDetails(context, nextShift),
          ),
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

  void _showShiftDetails(BuildContext context, Shift shift) {
    final timeEntries = ref.read(timeEntriesProvider);
    final openEntry = timeEntries.where((entry) => entry.isOpen).firstOrNull;
    final companyPlan = ref.read(companyPlanProvider).toLowerCase();
    final canUseTimeClock = companyPlan == 'pro' || companyPlan == 'enterprise';

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
        openEntry: openEntry,
        canUseTimeClock: canUseTimeClock,
        onClockIn: () =>
            ref.read(timeEntriesProvider.notifier).clockIn(shiftId: shift.id),
        onClockOut: openEntry == null
            ? null
            : () => ref
                .read(timeEntriesProvider.notifier)
                .clockOut(entryId: openEntry.id),
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
      ),
    );
  }
}

class _ProfileShiftDetailSheet extends StatefulWidget {
  const _ProfileShiftDetailSheet({
    required this.shift,
    required this.openEntry,
    required this.canUseTimeClock,
    required this.onClockIn,
    required this.onClockOut,
  });

  final Shift shift;
  final TimeEntry? openEntry;
  final bool canUseTimeClock;
  final Future<void> Function() onClockIn;
  final Future<void> Function()? onClockOut;

  @override
  State<_ProfileShiftDetailSheet> createState() =>
      _ProfileShiftDetailSheetState();
}

class _ProfileShiftDetailSheetState extends State<_ProfileShiftDetailSheet> {
  bool _clockLoading = false;

  @override
  Widget build(BuildContext context) {
    final note = widget.shift.notes.trim();
    final isClockedIn = widget.openEntry != null;
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
              text: _formatShiftDate(widget.shift.startsAt),
            ),
            _DetailRow(
              icon: Icons.schedule,
              text: '${_formatTime(widget.shift.startsAt)} - '
                  '${_formatTime(widget.shift.endsAt)}',
            ),
            _DetailRow(
              icon: Icons.coffee_outlined,
              text: 'Break ${widget.shift.breakMinutes} min',
            ),
            _DetailRow(
              icon: Icons.notes_outlined,
              text: note.isEmpty ? 'No manager note for this shift.' : note,
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: widget.canUseTimeClock
                    ? AppColors.background
                    : AppColors.greenSoft,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.canUseTimeClock
                        ? (isClockedIn
                            ? Icons.timer_rounded
                            : Icons.login_rounded)
                        : Icons.lock_outline_rounded,
                    color: widget.canUseTimeClock
                        ? (isClockedIn
                            ? AppColors.primaryGreen
                            : AppColors.blueInfo)
                        : AppColors.mutedText,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      widget.canUseTimeClock
                          ? (isClockedIn
                              ? 'Clocked in at ${_formatTime(widget.openEntry!.clockInAt)}'
                              : 'Clock in for this shift')
                          : 'Clock in/out is available on Pro and Enterprise.',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: _clockLoading || !widget.canUseTimeClock
                        ? null
                        : _handleClockAction,
                    child: _clockLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(widget.canUseTimeClock
                            ? (isClockedIn ? 'Clock out' : 'Clock in')
                            : 'Pro'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleClockAction() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _clockLoading = true);
    try {
      if (widget.openEntry == null) {
        await widget.onClockIn();
      } else {
        await widget.onClockOut?.call();
      }
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content:
              Text(widget.openEntry == null ? 'Clocked in.' : 'Clocked out.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _clockLoading = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(widget.openEntry == null
              ? 'Could not clock in. Try again.'
              : 'Could not clock out. Try again.'),
        ),
      );
    }
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
                        Text('Request absence',
                            style: AppTypography.headingMedium),
                        Text(
                          pending == 0
                              ? 'Send vacation, sick leave, or other time off.'
                              : '$pending request${pending == 1 ? '' : 's'} waiting for review.',
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
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: [
                  for (final type in AbsenceType.values)
                    DropdownMenuItem(
                      value: type,
                      child: Text(_absenceTypeLabel(type)),
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
                      label: 'Start',
                      date: _startDate,
                      onPressed: _submitting
                          ? null
                          : () => _pickDate(isStartDate: true),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _DatePickButton(
                      label: 'End',
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
                decoration: const InputDecoration(
                  labelText: 'Note',
                  hintText: 'Optional message for your manager',
                  prefixIcon: Icon(Icons.notes_outlined),
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
                  label: Text(_submitting ? 'Sending...' : 'Send request'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Requests', style: AppTypography.headingMedium),
        const SizedBox(height: AppSpacing.sm),
        if (requests.isEmpty)
          DashboardCard(
            child: Text(
              'No absence requests yet.',
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
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after start date.')),
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
        const SnackBar(content: Text('Absence request sent.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_requestErrorMessage(error)),
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
          Text(_formatShortDate(date), style: AppTypography.bodyMedium),
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
    final color = _absenceStatusColor(request.status);
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _absenceTypeLabel(request.type),
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
                  _absenceStatusLabel(request.status),
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
            text:
                '${_formatShortDate(request.startDate)} - ${_formatShortDate(request.endDate)}',
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
                          ? 'Employee profile'
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
            label: 'Email',
            value: _fallback(profile.email),
          ),
          _InfoRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: _fallback(profile.phoneNumber),
          ),
          _InfoRow(
            icon: Icons.badge_outlined,
            label: 'Company role',
            value: profile.companyRoleLabel,
          ),
          _InfoRow(
            icon: Icons.work_outline_rounded,
            label: 'Job title',
            value: _fallback(profile.jobTitle),
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

String _formatShiftDate(DateTime date) {
  return '${_weekdayLong(date)}, ${date.day} ${_monthShort(date)}';
}

String _formatTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatShortDate(DateTime date) {
  return '${date.day} ${_monthShort(date)} ${date.year}';
}

String _fallback(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? 'Not added' : trimmed;
}

String _absenceTypeLabel(AbsenceType type) {
  return switch (type) {
    AbsenceType.vacation => 'Vacation',
    AbsenceType.sick => 'Sick leave',
    AbsenceType.parental => 'Parental leave',
    AbsenceType.other => 'Other',
  };
}

String _absenceStatusLabel(AbsenceStatus status) {
  return switch (status) {
    AbsenceStatus.pending => 'Pending',
    AbsenceStatus.approved => 'Approved',
    AbsenceStatus.denied => 'Denied',
  };
}

Color _absenceStatusColor(AbsenceStatus status) {
  return switch (status) {
    AbsenceStatus.pending => AppColors.orangeHours,
    AbsenceStatus.approved => AppColors.primaryGreen,
    AbsenceStatus.denied => AppColors.alertRed,
  };
}

String _requestErrorMessage(Object error) {
  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    final serverMessage = data is Map ? data['error'] ?? data['message'] : null;
    if (serverMessage is String && serverMessage.trim().isNotEmpty) {
      return serverMessage;
    }
    if (statusCode == 404) {
      return 'Absence requests are not available on this API yet. Restart with the local API.';
    }
    if (statusCode == 401 || statusCode == 403) {
      return 'Your session cannot send this request. Sign in again and retry.';
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Could not reach the API. Check the mobile app API URL.';
    }
  }
  return 'Could not send request. Pull to refresh and try again.';
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
