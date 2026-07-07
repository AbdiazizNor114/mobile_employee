import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/employee_profile.dart';
import '../models/message.dart';
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
        .read(staffContactsProvider.notifier)
        .replaceAll(_enrichContacts(payload.staffContacts, payload.messages));
    ref
        .read(absenceRequestsProvider.notifier)
        .replaceAll(payload.absenceRequests);
    ref.read(timeEntriesProvider.notifier).replaceAll(payload.timeEntries);
    await ref.read(storageServiceProvider).saveCompanyPlan(payload.companyPlan);
    ref.read(companyPlanProvider.notifier).state = payload.companyPlan;
    await ref
        .read(storageServiceProvider)
        .saveEnabledLanguages(payload.enabledLanguages);
    ref.read(enabledLanguagesProvider.notifier).state =
        payload.enabledLanguages;
    final preferredLanguage = payload.enabledLanguages.contains(
      payload.profile.preferredLanguage,
    )
        ? payload.profile.preferredLanguage
        : payload.defaultLanguage;
    if (ref.read(languageCodeProvider) != preferredLanguage) {
      await ref
          .read(languageCodeProvider.notifier)
          .setLanguage(preferredLanguage);
    }
    ref.read(lastSyncErrorProvider.notifier).state = null;
  } on StateError catch (_) {
    // Missing IDs, likely signing out
  } catch (error) {
    ref.read(lastSyncErrorProvider.notifier).state =
        'Sync failed. Pull to refresh and try again.';
    rethrow;
  }
});

List<StaffContact> _enrichContacts(
  List<StaffContact> contacts,
  List<AppMessage> messages,
) {
  return contacts.map((contact) {
    final matchingMessages = messages
        .where((message) => message.senderMemberId == contact.id)
        .toList()
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
    final messageWithPhoto = matchingMessages
        .where((message) => message.senderProfilePhotoUrl.trim().isNotEmpty)
        .firstOrNull;
    final messageWithName = matchingMessages
        .where((message) =>
            message.senderName.trim().isNotEmpty &&
            message.senderName.trim().toLowerCase() != 'system')
        .firstOrNull;
    final name = contact.name.trim().isNotEmpty &&
            contact.name.trim() != contact.email.trim()
        ? contact.name
        : messageWithName?.senderName ?? contact.name;
    final photo = contact.profilePhotoUrl.trim().isNotEmpty
        ? contact.profilePhotoUrl
        : messageWithPhoto?.senderProfilePhotoUrl ?? '';

    if (name == contact.name && photo == contact.profilePhotoUrl) {
      return contact;
    }
    return StaffContact(
      id: contact.id,
      name: name,
      role: contact.role,
      jobTitle: contact.jobTitle,
      email: contact.email,
      phone: contact.phone,
      profilePhotoUrl: photo,
    );
  }).toList();
}
