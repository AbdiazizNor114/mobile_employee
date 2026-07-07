import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/absence_request.dart';
import '../models/activity_item.dart';
import '../models/employee_profile.dart';
import '../models/shift.dart';
import '../models/time_entry.dart';
import '../services/storage_service.dart';
import '../services/worker_sync_service.dart';
import 'service_providers.dart';

final employeeProfileProvider =
    StateNotifierProvider<EmployeeProfileController, EmployeeProfile>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final syncService = ref.watch(workerSyncServiceProvider);
  final cachedProfile = storage.readProfile();
  return EmployeeProfileController(
    cachedProfile ?? _emptyProfile(),
    storage: storage,
    syncService: syncService,
    persistInitialState: false,
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
    required this.syncService,
    required bool persistInitialState,
    required this.onCacheUpdated,
  }) {
    if (persistInitialState) {
      storage.saveProfile(state).then(onCacheUpdated);
    }
  }

  final StorageService storage;
  final WorkerSyncService syncService;
  final void Function(DateTime updatedAt) onCacheUpdated;

  Future<void> save(EmployeeProfile profile) async {
    // Call API
    await syncService.updateProfile(profile);

    state = profile;
    storage.saveProfile(profile).then(onCacheUpdated);
  }

  void replace(EmployeeProfile profile) {
    state = profile;
    storage.saveProfile(profile).then(onCacheUpdated);
  }

  void reset() {
    state = _emptyProfile();
  }
}

final shiftsProvider = StateNotifierProvider<ShiftController, List<Shift>>((
  ref,
) {
  final storage = ref.watch(storageServiceProvider);
  final syncService = ref.watch(workerSyncServiceProvider);
  final cachedShifts = storage.readShifts();
  return ShiftController(
    cachedShifts ?? const [],
    storage: storage,
    syncService: syncService,
    persistInitialState: false,
    onCacheUpdated: (updatedAt) =>
        ref.read(cacheLastUpdatedProvider.notifier).state = updatedAt,
    onShiftAccepted: (shift) {
      ref.read(activityProvider.notifier).addShiftAccepted(shift);
    },
  );
});

final nextShiftProvider = Provider<Shift?>((ref) {
  final now = DateTime.now();
  final shifts = [...ref.watch(shiftsProvider)]
    ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  if (shifts.isEmpty) return null;

  final activeAndUpcoming = shifts.where(
    (shift) =>
        shift.status != ShiftStatus.available && !shift.endsAt.isBefore(now),
  );
  if (activeAndUpcoming.isEmpty) return null;

  final current =
      activeAndUpcoming.where((shift) => !shift.startsAt.isAfter(now));
  if (current.isNotEmpty) return current.first;
  return activeAndUpcoming.first;
});

class ShiftController extends StateNotifier<List<Shift>> {
  ShiftController(
    super.state, {
    required this.storage,
    required this.syncService,
    required bool persistInitialState,
    required this.onCacheUpdated,
    required this.onShiftAccepted,
  }) {
    if (persistInitialState) {
      storage.saveShifts(state).then(onCacheUpdated);
    }
  }

  final StorageService storage;
  final WorkerSyncService syncService;
  final void Function(DateTime updatedAt) onCacheUpdated;
  final void Function(Shift shift) onShiftAccepted;

  Future<void> acceptShift(String shiftId) async {
    Shift? acceptedShift;
    final now = DateTime.now();
    for (final shift in state) {
      if (shift.id == shiftId && shift.canBeAccepted(now)) {
        acceptedShift = shift.copyWith(status: ShiftStatus.confirmed);
        break;
      }
    }

    if (acceptedShift == null) return;

    // Call API first
    await syncService.acceptShift(shiftId);

    state = [
      for (final shift in state)
        if (shift.id == shiftId) acceptedShift else shift,
    ];

    storage.saveShifts(state).then(onCacheUpdated);
    onShiftAccepted(acceptedShift);
  }

  Future<void> confirmShiftWorked(String shiftId) async {
    final shift = state.where((item) => item.id == shiftId).firstOrNull;
    if (shift == null || !shift.canConfirmWork()) {
      throw StateError('This shift is not eligible for confirmation.');
    }

    final confirmedAt = await syncService.confirmShiftWork(shiftId);
    state = [
      for (final item in state)
        if (item.id == shiftId)
          item.copyWith(
            workConfirmationStatus: WorkConfirmationStatus.confirmed,
            workConfirmationSource: 'employee',
            workConfirmedAt: confirmedAt,
          )
        else
          item,
    ];
    storage.saveShifts(state).then(onCacheUpdated);
  }

  void replaceAll(List<Shift> shifts) {
    final sorted = [...shifts]
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    state = sorted;
    storage.saveShifts(state).then(onCacheUpdated);
  }

  void reset() {
    state = const [];
  }
}

EmployeeProfile _emptyProfile() {
  return const EmployeeProfile(
    firstName: '',
    lastName: '',
    email: '',
    phoneNumber: '',
    isCareAssistant: false,
    isTeamLead: false,
    jobTitle: '',
    companyRole: '',
  );
}

final activityProvider =
    StateNotifierProvider<ActivityController, List<ActivityItem>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final cachedActivities = storage.readActivities();
  return ActivityController(
    cachedActivities ?? const [],
    storage: storage,
    persistInitialState: false,
    onCacheUpdated: (updatedAt) =>
        ref.read(cacheLastUpdatedProvider.notifier).state = updatedAt,
  );
});

final staffContactsProvider =
    StateNotifierProvider<StaffContactsController, List<StaffContact>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final cachedContacts = storage.readStaffContacts();
  return StaffContactsController(
    cachedContacts ?? const [],
    storage: storage,
    onCacheUpdated: (updatedAt) =>
        ref.read(cacheLastUpdatedProvider.notifier).state = updatedAt,
  );
});

class StaffContactsController extends StateNotifier<List<StaffContact>> {
  StaffContactsController(
    super.state, {
    required this.storage,
    required this.onCacheUpdated,
  });

  final StorageService storage;
  final void Function(DateTime updatedAt) onCacheUpdated;

  void replaceAll(List<StaffContact> contacts) {
    state = contacts;
    storage.saveStaffContacts(contacts).then((_) {
      storage.touchLastUpdated().then(onCacheUpdated);
    });
  }

  void reset() {
    state = const [];
  }
}

final unreadActivityCountProvider = Provider<int>((ref) {
  return ref.watch(activityProvider).where((item) => item.isUnread).length;
});

final absenceRequestsProvider =
    StateNotifierProvider<AbsenceRequestController, List<AbsenceRequest>>((
  ref,
) {
  final storage = ref.watch(storageServiceProvider);
  final syncService = ref.watch(workerSyncServiceProvider);
  final cachedRequests = storage.readAbsenceRequests();
  return AbsenceRequestController(
    cachedRequests ?? const [],
    storage: storage,
    syncService: syncService,
    persistInitialState: false,
    onCacheUpdated: (updatedAt) =>
        ref.read(cacheLastUpdatedProvider.notifier).state = updatedAt,
  );
});

class AbsenceRequestController extends StateNotifier<List<AbsenceRequest>> {
  AbsenceRequestController(
    super.state, {
    required this.storage,
    required this.syncService,
    required bool persistInitialState,
    required this.onCacheUpdated,
  }) {
    if (persistInitialState) {
      storage.saveAbsenceRequests(state).then(onCacheUpdated);
    }
  }

  final StorageService storage;
  final WorkerSyncService syncService;
  final void Function(DateTime updatedAt) onCacheUpdated;

  Future<void> submit({
    required AbsenceType type,
    required DateTime startDate,
    required DateTime endDate,
    String note = '',
  }) async {
    final saved = await syncService.submitAbsenceRequest(
      type: type,
      startDate: startDate,
      endDate: endDate,
      note: note,
    );
    state = [saved, ...state.where((request) => request.id != saved.id)];
    storage.saveAbsenceRequests(state).then(onCacheUpdated);
  }

  void replaceAll(List<AbsenceRequest> requests) {
    final sorted = [...requests]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = sorted;
    storage.saveAbsenceRequests(state).then(onCacheUpdated);
  }

  void reset() {
    state = const [];
  }
}

final timeEntriesProvider =
    StateNotifierProvider<TimeEntryController, List<TimeEntry>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final cachedEntries = storage.readTimeEntries();
  return TimeEntryController(
    cachedEntries ?? const [],
    storage: storage,
    onCacheUpdated: (updatedAt) =>
        ref.read(cacheLastUpdatedProvider.notifier).state = updatedAt,
  );
});

class TimeEntryController extends StateNotifier<List<TimeEntry>> {
  TimeEntryController(
    super.state, {
    required this.storage,
    required this.onCacheUpdated,
  });

  final StorageService storage;
  final void Function(DateTime updatedAt) onCacheUpdated;

  void replaceAll(List<TimeEntry> entries) {
    final sorted = [...entries]
      ..sort((a, b) => b.clockInAt.compareTo(a.clockInAt));
    state = sorted;
    storage.saveTimeEntries(state).then(onCacheUpdated);
  }

  void reset() {
    state = const [];
  }
}

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

  void replaceAll(List<ActivityItem> activities) {
    state = [...activities]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    storage.saveActivities(state).then(onCacheUpdated);
  }

  void reset() {
    state = const [];
  }
}
