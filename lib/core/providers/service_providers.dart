import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final apiServiceProvider = Provider<ApiService>((ref) {
  final config = ref.watch(appConfigProvider);
  return ApiService(
    dio: Dio(
      BaseOptions(
        baseUrl: config.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
      ),
    ),
  );
});

final authServiceProvider = Provider<AuthService>((ref) {
  final config = ref.watch(appConfigProvider);
  final client = config.hasSupabaseConfig ? Supabase.instance.client : null;

  return AuthService(client: client);
});

final demoSessionProvider = StateProvider<bool>((ref) => false);

final languageCodeProvider =
    StateNotifierProvider<LanguageCodeController, String>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return LanguageCodeController(
    storage.readLanguageCode(),
    storage: storage,
  );
});

class LanguageCodeController extends StateNotifier<String> {
  LanguageCodeController(super.state, {required this.storage});

  final StorageService storage;

  void setLanguage(String languageCode) {
    final next = languageCode == 'so' ? 'so' : 'en';
    state = next;
    storage.saveLanguageCode(next);
  }
}

final isSignedInProvider = StreamProvider<bool>((ref) {
  final authService = ref.watch(authServiceProvider);
  final demoSession = ref.watch(demoSessionProvider);

  if (demoSession) {
    return Stream<bool>.value(true);
  }

  return authService.authStateChanges;
});

final currentSessionProvider = Provider<bool>((ref) {
  final demoSession = ref.watch(demoSessionProvider);
  if (demoSession) return true;

  return ref.watch(authServiceProvider).hasActiveSession;
});

final signOutProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    ref.read(demoSessionProvider.notifier).state = false;
    await ref.read(authServiceProvider).signOut();
  };
});

final appBootstrapProvider = FutureProvider<void>((ref) async {
  final config = ref.read(appConfigProvider);
  await ref.read(storageServiceProvider).initialize();

  if (config.hasSupabaseConfig) {
    await Supabase.initialize(
      url: config.supabaseUrl,
      anonKey: config.supabaseAnonKey,
    );
  }
});
