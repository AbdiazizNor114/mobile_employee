import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../services/storage_service.dart';
import 'service_providers.dart';
import 'mock_work_provider.dart';

final messagesProvider = StateNotifierProvider<MessageController, List<AppMessage>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final cached = storage.readMessages();
  return MessageController(
    cached?.map(AppMessage.fromJson).toList() ?? const [],
    storage: storage,
    onCacheUpdated: (updatedAt) =>
        ref.read(cacheLastUpdatedProvider.notifier).state = updatedAt,
  );
});

class MessageController extends StateNotifier<List<AppMessage>> {
  MessageController(
    super.state, {
    required this.storage,
    required this.onCacheUpdated,
  });

  final StorageService storage;
  final void Function(DateTime updatedAt) onCacheUpdated;

  void replaceAll(List<AppMessage> messages) {
    state = messages;
    storage.saveMessages(messages.map((m) => m.toJson()).toList()).then((_) {
       storage.touchLastUpdated().then(onCacheUpdated);
    });
  }

  void reset() {
    state = const [];
  }
}
