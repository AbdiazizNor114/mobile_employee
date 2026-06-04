import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mock_work_provider.dart';
import 'message_provider.dart';
import 'service_providers.dart';

final lastSyncErrorProvider = StateProvider<String?>((ref) => null);

final backendSyncProvider = FutureProvider<void>((ref) async {
  final isSignedIn = ref.watch(currentSessionProvider);
  if (!isSignedIn) return;

  try {
    final payload = await ref.read(workerSyncServiceProvider).fetchWorkerData();
    ref.read(employeeProfileProvider.notifier).replace(payload.profile);
    ref.read(shiftsProvider.notifier).replaceAll(payload.shifts);
    ref.read(activityProvider.notifier).replaceAll(payload.activities);
    ref.read(messagesProvider.notifier).replaceAll(payload.messages);
    ref
        .read(absenceRequestsProvider.notifier)
        .replaceAll(payload.absenceRequests);
    ref.read(timeEntriesProvider.notifier).replaceAll(payload.timeEntries);
    ref.read(lastSyncErrorProvider.notifier).state = null;
  } on StateError catch (_) {
    // Missing IDs, likely signing out
  } catch (error) {
    ref.read(lastSyncErrorProvider.notifier).state =
        'Sync failed. Pull to refresh and try again.';
    rethrow;
  }
});
