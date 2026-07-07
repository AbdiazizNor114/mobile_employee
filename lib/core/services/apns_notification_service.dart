import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'api_service.dart';
import 'auth_service.dart';

class ApnsNotificationService {
  ApnsNotificationService({
    required ApiService apiService,
    required AuthService authService,
  })  : _apiService = apiService,
        _authService = authService;

  static const _channel = MethodChannel('shaqonet/apns');

  final ApiService _apiService;
  final AuthService _authService;

  Future<void> registerCurrentDevice() async {
    if (kIsWeb || !Platform.isIOS) return;
    final companyId = _authService.companyId;
    if (companyId == null || !_authService.hasActiveSession) return;

    try {
      final token = await _channel.invokeMethod<String>(
        'registerForRemoteNotifications',
      );
      if (token == null || token.trim().isEmpty) return;
      await _apiService.client.put(
        '/api/v1/companies/$companyId/push/apns-token',
        data: {'token': token},
      );
    } on DioException catch (error) {
      debugPrint(
        'ShaqoNet APNs token registration failed: ${error.response?.statusCode ?? error.message}',
      );
    } on PlatformException catch (error) {
      debugPrint('ShaqoNet APNs unavailable: ${error.message ?? error.code}');
    } catch (error) {
      debugPrint('ShaqoNet APNs token registration failed: $error');
    }
  }
}
