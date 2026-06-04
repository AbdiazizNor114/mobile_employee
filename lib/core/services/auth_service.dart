import 'dart:async';
import 'package:dio/dio.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  AuthService({
    required ApiService apiService,
    required StorageService storage,
  })  : _apiService = apiService,
        _storage = storage {
    final token = _storage.readAccessToken();
    _apiService.setAuthToken(token);
  }

  final ApiService _apiService;
  final StorageService _storage;
  final StreamController<bool> _authStateController =
      StreamController<bool>.broadcast();

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.client.post<Map<String, dynamic>>(
      '/api/v1/auth/login',
      data: {'email': email, 'password': password},
    );
    final payload = response.data?['data'];
    if (payload is! Map) {
      throw DioException(
        requestOptions: response.requestOptions,
        error: 'Invalid login response payload.',
      );
    }

    final session = payload['session'];
    if (session is! Map) {
      throw DioException(
        requestOptions: response.requestOptions,
        error: 'Session was missing from login response.',
      );
    }

    final accessToken = (session['accessToken'] as String?)?.trim();
    final refreshToken = (session['refreshToken'] as String?)?.trim();
    if (accessToken == null || refreshToken == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        error: 'Invalid session tokens from login response.',
      );
    }

    final memberships = payload['memberships'];
    if (memberships is! List || memberships.isEmpty) {
      throw DioException(
        requestOptions: response.requestOptions,
        error: 'No active company membership found for this user.',
      );
    }

    final membership = memberships.first;
    if (membership is! Map) {
      throw DioException(
        requestOptions: response.requestOptions,
        error: 'Invalid membership payload from login response.',
      );
    }

    final companyId = membership['company_id'] as String?;
    final membershipId = membership['id'] as String?;
    final companyName = (membership['company_name'] as String?) ?? 'ShaqoNet';
    final user = payload['user'];
    final userId = user is Map ? user['id'] as String? : null;
    if (companyId == null || membershipId == null || userId == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        error: 'Incomplete membership data from login response.',
      );
    }

    await _storage.saveAccessToken(accessToken);
    await _storage.saveRefreshToken(refreshToken);
    await _storage.saveCompanyId(companyId);
    await _storage.saveMembershipId(membershipId);
    await _storage.saveUserId(userId);
    await _storage.saveCompanyName(companyName);
    _apiService.setAuthToken(accessToken);
    _authStateController.add(true);
  }

  Future<void> requestPasswordReset(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty || !trimmed.contains('@')) {
      throw ArgumentError('Please enter a valid email address.');
    }

    await _apiService.client.post<Map<String, dynamic>>(
      '/api/v1/auth/password/forgot',
      data: {'email': trimmed},
    );
  }

  bool get hasActiveSession => _storage.readAccessToken() != null;

  String? get companyId => _storage.readCompanyId();

  String? get membershipId => _storage.readMembershipId();

  String? get userId => _storage.readUserId();

  Stream<bool> get authStateChanges async* {
    yield hasActiveSession;
    yield* _authStateController.stream;
  }

  Future<void> signOut() async {
    // Clear locally. A stale token can make /auth/logout return 401, which
    // would trigger the unauthorized interceptor again and loop sign-out.
    await _storage.clearAuthSession();
    _apiService.setAuthToken(null);
    _authStateController.add(false);
  }
}
