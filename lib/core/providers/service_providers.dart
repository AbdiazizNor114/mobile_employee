import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/worker_sync_service.dart';

import 'mock_work_provider.dart';
import 'message_provider.dart';

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
  return AuthService(
    apiService: ref.watch(apiServiceProvider),
    storage: ref.watch(storageServiceProvider),
  );
});

final workerSyncServiceProvider = Provider<WorkerSyncService>((ref) {
  return WorkerSyncService(
    apiService: ref.watch(apiServiceProvider),
    authService: ref.watch(authServiceProvider),
  );
});

final demoSessionProvider = StateProvider<bool>((ref) => false);
final companyNameProvider = Provider<String>((ref) {
  return ref.watch(storageServiceProvider).readCompanyName();
});

final companyPlanProvider = StateProvider<String>((ref) {
  return ref.watch(storageServiceProvider).readCompanyPlan();
});

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

  // By watching isSignedInProvider (a StreamProvider), we ensure this provider
  // re-evaluates whenever the authentication state changes.
  final authState = ref.watch(isSignedInProvider);
  return authState.value ?? ref.watch(authServiceProvider).hasActiveSession;
});

final signOutProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    ref.read(demoSessionProvider.notifier).state = false;
    await ref.read(authServiceProvider).signOut();
    await ref.read(storageServiceProvider).clearWorkCache();

    // Reset work providers to empty state
    ref.read(resetWorkDataProvider)();
  };
});

final resetWorkDataProvider = Provider<void Function()>((ref) {
  return () {
    ref.read(employeeProfileProvider.notifier).reset();
    ref.read(shiftsProvider.notifier).reset();
    ref.read(activityProvider.notifier).reset();
    ref.read(messagesProvider.notifier).reset();
    ref.read(absenceRequestsProvider.notifier).reset();
    ref.read(timeEntriesProvider.notifier).reset();
    ref.read(companyPlanProvider.notifier).state = 'free';
    ref.read(cacheLastUpdatedProvider.notifier).state = null;
  };
});

final appBootstrapProvider = FutureProvider<void>((ref) async {
  await ref.read(storageServiceProvider).initialize();
  ref
      .read(apiServiceProvider)
      .setUnauthorizedCallback(() => ref.read(signOutProvider)());
  ref.read(authServiceProvider);
});
