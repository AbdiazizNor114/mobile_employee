import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

class AppConfigException implements Exception {
  const AppConfigException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  factory AppConfig.fromEnvironment() {
    const rawApiBaseUrl = String.fromEnvironment(
      'SHAQONET_API_BASE_URL',
      defaultValue: 'http://localhost:4000',
    );
    final apiBaseUrl = !kIsWeb && Platform.isAndroid
        ? rawApiBaseUrl
            .replaceFirst('localhost', '10.0.2.2')
            .replaceFirst('127.0.0.1', '10.0.2.2')
        : rawApiBaseUrl;

    final config = AppConfig(
      apiBaseUrl: apiBaseUrl,
      supabaseUrl: String.fromEnvironment('SHAQONET_SUPABASE_URL'),
      supabaseAnonKey: String.fromEnvironment('SHAQONET_SUPABASE_ANON_KEY'),
    );
    config.validate(isReleaseLike: kReleaseMode || kProfileMode);
    return config;
  }

  final String apiBaseUrl;
  final String supabaseUrl;
  final String supabaseAnonKey;

  bool get hasSupabaseConfig =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  void validate({required bool isReleaseLike}) {
    final parsedApiBaseUrl = Uri.tryParse(apiBaseUrl.trim());
    if (parsedApiBaseUrl == null || !parsedApiBaseUrl.hasScheme) {
      throw const AppConfigException('Missing SHAQONET_API_BASE_URL.');
    }

    if (isReleaseLike) {
      final host = parsedApiBaseUrl.host.toLowerCase();
      final isLocalApi = host == 'localhost' ||
          host == '127.0.0.1' ||
          host == '10.0.2.2' ||
          host == '::1';
      if (isLocalApi || parsedApiBaseUrl.scheme != 'https') {
        throw const AppConfigException(
          'Release builds must use an HTTPS ShaqoNet API URL.',
        );
      }
    }
  }
}
