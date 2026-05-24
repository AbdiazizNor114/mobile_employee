import 'package:hive_flutter/hive_flutter.dart';
import '../models/activity_item.dart';
import '../models/employee_profile.dart';
import '../models/shift.dart';

class StorageService {
  static const _boxName = 'shaqonet_offline_cache';
  static const _profileKey = 'employee_profile';
  static const _shiftsKey = 'shifts';
  static const _activitiesKey = 'activities';
  static const _lastUpdatedKey = 'last_updated';
  static const _languageCodeKey = 'language_code';

  Box<dynamic>? _box;
  final Map<String, Object?> _memoryFallback = {};

  Future<void> initialize() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<dynamic>(_boxName);
  }

  EmployeeProfile? readProfile() {
    final data = _read(_profileKey);
    if (data is Map) return EmployeeProfile.fromJson(data);
    return null;
  }

  Future<DateTime> saveProfile(EmployeeProfile profile) async {
    await _write(_profileKey, profile.toJson());
    return touchLastUpdated();
  }

  List<Shift>? readShifts() {
    final data = _read(_shiftsKey);
    if (data is! List) return null;
    return data.whereType<Map<dynamic, dynamic>>().map(Shift.fromJson).toList();
  }

  Future<DateTime> saveShifts(List<Shift> shifts) async {
    await _write(_shiftsKey, shifts.map((shift) => shift.toJson()).toList());
    return touchLastUpdated();
  }

  List<ActivityItem>? readActivities() {
    final data = _read(_activitiesKey);
    if (data is! List) return null;
    return data
        .whereType<Map<dynamic, dynamic>>()
        .map(ActivityItem.fromJson)
        .toList();
  }

  Future<DateTime> saveActivities(List<ActivityItem> activities) async {
    await _write(
      _activitiesKey,
      activities.map((activity) => activity.toJson()).toList(),
    );
    return touchLastUpdated();
  }

  DateTime? readLastUpdated() {
    final value = _read(_lastUpdatedKey);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Future<DateTime> touchLastUpdated() async {
    final value = DateTime.now();
    await _write(_lastUpdatedKey, value.toIso8601String());
    return value;
  }

  String readLanguageCode() {
    final value = _read(_languageCodeKey);
    return value is String && value == 'so' ? 'so' : 'en';
  }

  Future<void> saveLanguageCode(String languageCode) async {
    await _write(_languageCodeKey, languageCode == 'so' ? 'so' : 'en');
  }

  Object? _read(String key) {
    if (_box != null && _box!.isOpen) return _box!.get(key);
    return _memoryFallback[key];
  }

  Future<void> _write(String key, Object? value) async {
    if (_box != null && _box!.isOpen) {
      await _box!.put(key, value);
      return;
    }
    _memoryFallback[key] = value;
  }
}
