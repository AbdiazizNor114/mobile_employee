import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

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

    return AppConfig(
      apiBaseUrl: apiBaseUrl,
      supabaseUrl: String.fromEnvironment('SHAQONET_SUPABASE_URL'),
      supabaseAnonKey: String.fromEnvironment('SHAQONET_SUPABASE_ANON_KEY'),
    );
  }

  final String apiBaseUrl;
  final String supabaseUrl;
  final String supabaseAnonKey;

  bool get hasSupabaseConfig =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;
}
