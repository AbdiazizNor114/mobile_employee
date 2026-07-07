import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/absence_request.dart';
import '../models/activity_item.dart';
import '../models/employee_profile.dart';
import '../models/shift.dart';
import '../models/time_entry.dart';

class StorageService {
  static const _boxName = 'shaqonet_offline_cache';
  static const _profileKey = 'employee_profile';
  static const _shiftsKey = 'shifts';
  static const _activitiesKey = 'activities';
  static const _lastUpdatedKey = 'last_updated';
  static const _languageCodeKey = 'language_code';
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _companyIdKey = 'company_id';
  static const _membershipIdKey = 'membership_id';
  static const _userIdKey = 'user_id';
  static const _companyNameKey = 'company_name';
  static const _companyPlanKey = 'company_plan';
  static const _enabledLanguagesKey = 'enabled_languages';
  static const _messagesKey = 'messages';
  static const _staffContactsKey = 'staff_contacts';
  static const _absenceRequestsKey = 'absence_requests';
  static const _timeEntriesKey = 'time_entries';

  Box<dynamic>? _box;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  final Map<String, Object?> _memoryFallback = {};
  final Map<String, String?> _secureAuthCache = {};

  Future<void> initialize() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<dynamic>(_boxName);
    await _loadSecureAuthValue(_accessTokenKey);
    await _loadSecureAuthValue(_refreshTokenKey);
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

  String? readAccessToken() {
    final value = _readSecureAuthValue(_accessTokenKey);
    return value is String && value.trim().isNotEmpty ? value : null;
  }

  Future<void> saveAccessToken(String token) async {
    await _writeSecureAuthValue(_accessTokenKey, token);
  }

  String? readRefreshToken() {
    final value = _readSecureAuthValue(_refreshTokenKey);
    return value is String && value.trim().isNotEmpty ? value : null;
  }

  Future<void> saveRefreshToken(String token) async {
    await _writeSecureAuthValue(_refreshTokenKey, token);
  }

  String? readCompanyId() {
    final value = _read(_companyIdKey);
    return value is String && value.trim().isNotEmpty ? value : null;
  }

  Future<void> saveCompanyId(String companyId) async {
    await _write(_companyIdKey, companyId);
  }

  String? readMembershipId() {
    final value = _read(_membershipIdKey);
    return value is String && value.trim().isNotEmpty ? value : null;
  }

  Future<void> saveMembershipId(String membershipId) async {
    await _write(_membershipIdKey, membershipId);
  }

  String? readUserId() {
    final value = _read(_userIdKey);
    return value is String && value.trim().isNotEmpty ? value : null;
  }

  Future<void> saveUserId(String userId) async {
    await _write(_userIdKey, userId);
  }

  String readCompanyName() {
    final value = _read(_companyNameKey);
    if (value is String && value.trim().isNotEmpty) return value;
    return 'ShaqoNet';
  }

  Future<void> saveCompanyName(String companyName) async {
    await _write(
        _companyNameKey, companyName.trim().isEmpty ? 'ShaqoNet' : companyName);
  }

  String readCompanyPlan() {
    final value = _read(_companyPlanKey);
    return value is String && value.trim().isNotEmpty ? value : 'free';
  }

  Future<void> saveCompanyPlan(String plan) async {
    final normalized = plan.trim().toLowerCase();
    await _write(_companyPlanKey, normalized.isEmpty ? 'free' : normalized);
  }

  List<String> readEnabledLanguages() {
    final value = _read(_enabledLanguagesKey);
    if (value is! List) return const ['en'];
    final languages = value.whereType<String>().toSet().toList();
    if (!languages.contains('en')) languages.insert(0, 'en');
    return languages;
  }

  Future<void> saveEnabledLanguages(List<String> languages) async {
    final normalized = languages
        .where((code) => const {'en', 'so', 'sw'}.contains(code))
        .toSet()
        .toList();
    if (!normalized.contains('en')) normalized.insert(0, 'en');
    await _write(_enabledLanguagesKey, normalized);
  }

  List<Map>? readMessages() {
    final data = _read(_messagesKey);
    if (data is! List) return null;
    return data.whereType<Map>().toList();
  }

  Future<void> saveMessages(List<Map> messages) async {
    await _write(_messagesKey, messages);
  }

  List<StaffContact>? readStaffContacts() {
    final data = _read(_staffContactsKey);
    if (data is! List) return null;
    return data
        .whereType<Map<dynamic, dynamic>>()
        .map(StaffContact.fromJson)
        .toList();
  }

  Future<void> saveStaffContacts(List<StaffContact> contacts) async {
    await _write(
      _staffContactsKey,
      contacts.map((contact) => contact.toJson()).toList(),
    );
  }

  List<AbsenceRequest>? readAbsenceRequests() {
    final data = _read(_absenceRequestsKey);
    if (data is! List) return null;
    return data
        .whereType<Map<dynamic, dynamic>>()
        .map(AbsenceRequest.fromJson)
        .toList();
  }

  Future<DateTime> saveAbsenceRequests(List<AbsenceRequest> requests) async {
    await _write(
      _absenceRequestsKey,
      requests.map((request) => request.toJson()).toList(),
    );
    return touchLastUpdated();
  }

  List<TimeEntry>? readTimeEntries() {
    final data = _read(_timeEntriesKey);
    if (data is! List) return null;
    return data
        .whereType<Map<dynamic, dynamic>>()
        .map(TimeEntry.fromJson)
        .toList();
  }

  Future<DateTime> saveTimeEntries(List<TimeEntry> entries) async {
    await _write(
      _timeEntriesKey,
      entries.map((entry) => entry.toJson()).toList(),
    );
    return touchLastUpdated();
  }

  Future<void> clearAuthSession() async {
    await _writeSecureAuthValue(_accessTokenKey, null);
    await _writeSecureAuthValue(_refreshTokenKey, null);
    await _write(_companyIdKey, null);
    await _write(_membershipIdKey, null);
    await _write(_userIdKey, null);
    await _write(_companyNameKey, null);
    await _write(_companyPlanKey, null);
    await _write(_enabledLanguagesKey, null);
  }

  Future<void> clearWorkCache() async {
    await _write(_profileKey, null);
    await _write(_shiftsKey, null);
    await _write(_activitiesKey, null);
    await _write(_messagesKey, null);
    await _write(_staffContactsKey, null);
    await _write(_absenceRequestsKey, null);
    await _write(_timeEntriesKey, null);
    await _write(_lastUpdatedKey, null);
  }

  Future<void> _loadSecureAuthValue(String key) async {
    var value = await _secureStorage.read(key: key);

    if (value == null || value.trim().isEmpty) {
      final legacyValue = _read(key);
      if (legacyValue is String && legacyValue.trim().isNotEmpty) {
        value = legacyValue;
        await _secureStorage.write(key: key, value: legacyValue);
      }
    }

    _secureAuthCache[key] = value;
    await _write(key, null);
  }

  String? _readSecureAuthValue(String key) {
    final value = _secureAuthCache[key];
    if (value is String && value.trim().isNotEmpty) return value;
    return null;
  }

  Future<void> _writeSecureAuthValue(String key, String? value) async {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      await _secureStorage.delete(key: key);
      _secureAuthCache[key] = null;
    } else {
      await _secureStorage.write(key: key, value: normalized);
      _secureAuthCache[key] = normalized;
    }
    await _write(key, null);
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
