import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity_item.dart';
import '../models/employee_profile.dart';
import '../models/shift.dart';
import '../services/storage_service.dart';
import 'service_providers.dart';

final employeeProfileProvider =
    StateNotifierProvider<EmployeeProfileController, EmployeeProfile>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final cachedProfile = storage.readProfile();
  return EmployeeProfileController(
    cachedProfile ?? _initialProfile(),
    storage: storage,
    persistInitialState: cachedProfile == null,
    onCacheUpdated: (updatedAt) =>
        ref.read(cacheLastUpdatedProvider.notifier).state = updatedAt,
  );
});

final cacheLastUpdatedProvider = StateProvider<DateTime?>((ref) {
  return ref.watch(storageServiceProvider).readLastUpdated();
});

class EmployeeProfileController extends StateNotifier<EmployeeProfile> {
  EmployeeProfileController(
    super.state, {
    required this.storage,
    required bool persistInitialState,
    required this.onCacheUpdated,
  }) {
    if (persistInitialState) {
      storage.saveProfile(state).then(onCacheUpdated);
    }
  }

  final StorageService storage;
  final void Function(DateTime updatedAt) onCacheUpdated;

  void save(EmployeeProfile profile) {
    state = profile;
    storage.saveProfile(profile).then(onCacheUpdated);
  }
}

final shiftsProvider = StateNotifierProvider<ShiftController, List<Shift>>((
  ref,
) {
  final storage = ref.watch(storageServiceProvider);
  final cachedShifts = storage.readShifts();
  return ShiftController(
    cachedShifts ?? _initialShifts(),
    storage: storage,
    persistInitialState: cachedShifts == null,
    onCacheUpdated: (updatedAt) =>
        ref.read(cacheLastUpdatedProvider.notifier).state = updatedAt,
    onShiftAccepted: (shift) {
      ref.read(activityProvider.notifier).addShiftAccepted(shift);
    },
  );
});

final nextShiftProvider = Provider<Shift>(
  (ref) => ref.watch(shiftsProvider).first,
);

class ShiftController extends StateNotifier<List<Shift>> {
  ShiftController(
    super.state, {
    required this.storage,
    required bool persistInitialState,
    required this.onCacheUpdated,
    required this.onShiftAccepted,
  }) {
    if (persistInitialState) {
      storage.saveShifts(state).then(onCacheUpdated);
    }
  }

  final StorageService storage;
  final void Function(DateTime updatedAt) onCacheUpdated;
  final void Function(Shift shift) onShiftAccepted;

  void acceptShift(String shiftId) {
    Shift? acceptedShift;
    for (final shift in state) {
      if (shift.id == shiftId && shift.status == ShiftStatus.available) {
        acceptedShift = shift.copyWith(status: ShiftStatus.confirmed);
        break;
      }
    }

    if (acceptedShift == null) return;

    state = [
      for (final shift in state)
        if (shift.id == shiftId) acceptedShift else shift,
    ];

    storage.saveShifts(state).then(onCacheUpdated);
    onShiftAccepted(acceptedShift);
  }
}

EmployeeProfile _initialProfile() {
  return const EmployeeProfile(
    firstName: 'Amina',
    lastName: 'Hassan',
    email: 'amina.hassan@example.com',
    phoneNumber: '+46 70 123 45 67',
    isCareAssistant: true,
    isTeamLead: false,
  );
}

List<Shift> _initialShifts() {
  final now = DateTime.now();

  return [
    Shift(
      id: 'shift-1',
      role: 'Care assistant',
      location: 'North Care Services',
      startsAt: DateTime(now.year, now.month, now.day + 1, 7),
      endsAt: DateTime(now.year, now.month, now.day + 1, 15),
      status: ShiftStatus.confirmed,
    ),
    Shift(
      id: 'shift-2',
      role: 'Evening support',
      location: 'North Care Services',
      startsAt: DateTime(now.year, now.month, now.day + 3, 15),
      endsAt: DateTime(now.year, now.month, now.day + 3, 22),
      status: ShiftStatus.changed,
    ),
    Shift(
      id: 'shift-3',
      role: 'Weekend cover',
      location: 'West Team',
      startsAt: DateTime(now.year, now.month, now.day + 5, 9),
      endsAt: DateTime(now.year, now.month, now.day + 5, 17),
      status: ShiftStatus.available,
    ),
    Shift(
      id: 'shift-4',
      role: 'Morning support',
      location: 'Central Care Hub',
      startsAt: DateTime(now.year, now.month, now.day + 7, 6),
      endsAt: DateTime(now.year, now.month, now.day + 7, 14),
      status: ShiftStatus.confirmed,
    ),
    Shift(
      id: 'shift-5',
      role: 'Home care visit',
      location: 'East Team',
      startsAt: DateTime(now.year, now.month, now.day + 8, 12),
      endsAt: DateTime(now.year, now.month, now.day + 8, 18),
      status: ShiftStatus.available,
    ),
  ];
}

final activityProvider =
    StateNotifierProvider<ActivityController, List<ActivityItem>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final cachedActivities = storage.readActivities();
  return ActivityController(
    cachedActivities ?? _initialActivities(),
    storage: storage,
    persistInitialState: cachedActivities == null,
    onCacheUpdated: (updatedAt) =>
        ref.read(cacheLastUpdatedProvider.notifier).state = updatedAt,
  );
});

final unreadActivityCountProvider = Provider<int>((ref) {
  return ref.watch(activityProvider).where((item) => item.isUnread).length;
});

class ActivityController extends StateNotifier<List<ActivityItem>> {
  ActivityController(
    super.state, {
    required this.storage,
    required bool persistInitialState,
    required this.onCacheUpdated,
  }) {
    if (persistInitialState) {
      storage.saveActivities(state).then(onCacheUpdated);
    }
  }

  final StorageService storage;
  final void Function(DateTime updatedAt) onCacheUpdated;

  void addShiftAccepted(Shift shift) {
    state = [
      ActivityItem(
        id: 'activity-accepted-${shift.id}-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Shift accepted',
        detail: '${shift.role} at ${shift.location}',
        createdAt: DateTime.now(),
        type: ActivityType.shift,
        isUnread: true,
      ),
      ...state,
    ];
    storage.saveActivities(state).then(onCacheUpdated);
  }

  void markAllRead() {
    state = [for (final item in state) item.copyWith(isUnread: false)];
    storage.saveActivities(state).then(onCacheUpdated);
  }
}

List<ActivityItem> _initialActivities() {
  final now = DateTime.now();

  return [
    ActivityItem(
      id: 'activity-1',
      title: 'Shift confirmed',
      detail: 'Tomorrow at North Care Services',
      createdAt: now.subtract(const Duration(hours: 1)),
      type: ActivityType.shift,
      isUnread: true,
    ),
    ActivityItem(
      id: 'activity-2',
      title: 'Schedule changed',
      detail: 'Friday evening support moved to 15:00',
      createdAt: now.subtract(const Duration(hours: 6)),
      type: ActivityType.shift,
    ),
    ActivityItem(
      id: 'activity-3',
      title: 'Deduction notice',
      detail: 'Break deduction added with reason',
      createdAt: now.subtract(const Duration(days: 1)),
      type: ActivityType.deduction,
      isUnread: true,
    ),
  ];
}
