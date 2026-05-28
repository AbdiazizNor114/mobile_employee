import '../models/activity_item.dart';
import '../models/employee_profile.dart';
import '../models/shift.dart';
import '../models/message.dart';
import 'api_service.dart';
import 'auth_service.dart';

class WorkerSyncPayload {
  const WorkerSyncPayload({
    required this.profile,
    required this.shifts,
    required this.activities,
    required this.messages,
  });

  final EmployeeProfile profile;
  final List<Shift> shifts;
  final List<ActivityItem> activities;
  final List<AppMessage> messages;
}

class WorkerSyncService {
  WorkerSyncService({
    required ApiService apiService,
    required AuthService authService,
  })  : _apiService = apiService,
        _authService = authService;

  final ApiService _apiService;
  final AuthService _authService;

  Future<WorkerSyncPayload> fetchWorkerData() async {
    final companyId = _authService.companyId;
    final membershipId = _authService.membershipId;
    if (companyId == null || membershipId == null) {
      throw StateError('Missing company or membership context.');
    }

    final meResponse =
        await _apiService.client.get<Map<String, dynamic>>('/api/v1/me');
    final meData = (meResponse.data?['data'] as Map?) ?? const {};
    final profileMap = (meData['profile'] as Map?) ?? const {};
    final List memberships = (meData['memberships'] as List?) ?? const [];

    Map employeeData = const {};
    try {
      final employeeResponse =
          await _apiService.client.get<Map<String, dynamic>>(
        '/api/v1/companies/$companyId/employees/$membershipId',
      );
      employeeData = (employeeResponse.data?['data'] as Map?) ?? const {};
    } catch (_) {}

    List shiftsRaw = const [];
    try {
      final shiftsResponse = await _apiService.client.get<Map<String, dynamic>>(
        '/api/v1/companies/$companyId/shifts',
      );
      shiftsRaw = (shiftsResponse.data?['data'] as List?) ?? const [];
    } catch (_) {}

    List activityRaw = const [];
    try {
      final activityResponse =
          await _apiService.client.get<Map<String, dynamic>>(
        '/api/v1/companies/$companyId/activity',
      );
      activityRaw = (activityResponse.data?['data'] as List?) ?? const [];
    } catch (_) {}

    List messagesRaw = const [];
    try {
      final messagesResponse = await _apiService.client.get<Map<String, dynamic>>(
        '/api/v1/companies/$companyId/messages',
      );
      messagesRaw = (messagesResponse.data?['data'] as List?) ?? const [];
    } catch (_) {}

    return WorkerSyncPayload(
      profile: _mapProfile(profileMap, memberships, employeeData, shiftsRaw),
      shifts: shiftsRaw
          .whereType<Map>()
          .map(_mapShift)
          .whereType<Shift>()
          .toList(),
      activities: activityRaw.whereType<Map>().map(_mapActivity).toList(),
      messages: messagesRaw.whereType<Map>().map(_mapMessage).toList(),
    );
  }

  Future<void> acceptShift(String shiftId) async {
    final companyId = _authService.companyId;
    final membershipId = _authService.membershipId;
    if (companyId == null || membershipId == null) {
      throw StateError('Missing company or membership context.');
    }

    await _apiService.client.post(
      '/api/v1/companies/$companyId/shifts/$shiftId/accept',
      data: {'membership_id': membershipId},
    );
  }

  Future<void> markMessageAsRead(String messageId) async {
    final companyId = _authService.companyId;
    if (companyId == null) {
      throw StateError('Missing company context.');
    }

    await _apiService.client.patch(
      '/api/v1/companies/$companyId/messages/$messageId/read',
    );
  }

  Future<void> updateProfile(EmployeeProfile profile) async {
    final companyId = _authService.companyId;
    final membershipId = _authService.membershipId;
    if (companyId == null || membershipId == null) {
      throw StateError('Missing company or membership context.');
    }

    await _apiService.client.patch(
      '/api/v1/companies/$companyId/employees/$membershipId',
      data: {
        'first_name': profile.firstName,
        'last_name': profile.lastName,
        'email': profile.email,
        'phone': profile.phoneNumber,
        'job_title': profile.jobTitle,
      },
    );
  }

  EmployeeProfile _mapProfile(
    Map profile,
    List memberships,
    Map employee,
    List shiftsRaw,
  ) {
    final firstName =
        (employee['first_name'] ?? profile['first_name'] ?? '') as String;
    final lastName =
        (employee['last_name'] ?? profile['last_name'] ?? '') as String;
    final role = (employee['role'] as String?) ??
        (memberships.isNotEmpty && memberships.first is Map
            ? ((memberships.first as Map)['role'] as String?) ?? ''
            : '');
    final employeeJobTitle = (employee['job_title'] as String?) ?? '';
    final shiftJobTitle = shiftsRaw.isNotEmpty && shiftsRaw.first is Map
        ? ((shiftsRaw.first as Map)['job_role'] as String?) ?? ''
        : '';
    return EmployeeProfile(
      firstName: firstName,
      lastName: lastName,
      email: (employee['email'] ?? profile['email'] ?? '') as String,
      phoneNumber: (employee['phone'] ?? profile['phone'] ?? '') as String,
      isCareAssistant: role == 'worker',
      isTeamLead: role == 'manager',
      jobTitle:
          employeeJobTitle.trim().isNotEmpty ? employeeJobTitle : shiftJobTitle,
      companyRole: role,
    );
  }

  Shift? _mapShift(Map raw) {
    if (raw['deleted_at'] != null) {
      return null;
    }

    final date = (raw['shift_date'] as String?) ?? '';
    final startTime = (raw['start_time'] as String?) ?? '00:00:00';
    final endTime = (raw['end_time'] as String?) ?? '00:00:00';
    final start = DateTime.tryParse('${date}T$startTime');
    final end = DateTime.tryParse('${date}T$endTime');
    if (start == null || end == null) {
      return null;
    }

    final status = (raw['status'] as String?) ?? '';
    if (status != 'open' && status != 'assigned' && status != 'published') {
      return null;
    }
    final breakMinutesRaw = raw['break_minutes'];
    final breakMinutes = breakMinutesRaw is int
        ? breakMinutesRaw
        : int.tryParse('$breakMinutesRaw') ?? 0;

    return Shift(
      id: (raw['id'] as String?) ?? '',
      role: (raw['job_role'] as String?) ?? 'Shift',
      location: ((raw['location'] as String?) ?? '').isEmpty
          ? 'ShaqoNet'
          : (raw['location'] as String),
      startsAt: start,
      endsAt: end,
      breakMinutes: breakMinutes,
      status: switch (status) {
        'open' => ShiftStatus.available,
        'assigned' || 'published' => ShiftStatus.confirmed,
        _ => ShiftStatus.changed,
      },
    );
  }

  ActivityItem _mapActivity(Map raw) {
    final createdAt = DateTime.tryParse((raw['createdAt'] as String?) ?? '') ??
        DateTime.now();
    final typeRaw = (raw['type'] as String?) ?? '';
    return ActivityItem(
      id: (raw['id'] as String?) ??
          'activity-${createdAt.millisecondsSinceEpoch}',
      title: _toTitle(typeRaw),
      detail: (raw['description'] as String?) ?? 'Activity update',
      createdAt: createdAt,
      type:
          typeRaw.contains('shift') ? ActivityType.shift : ActivityType.system,
      isUnread: false,
    );
  }

  AppMessage _mapMessage(Map raw) {
    return AppMessage.fromJson(raw);
  }

  String _toTitle(String value) {
    if (value.isEmpty) return 'Update';
    return value
        .split('_')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
