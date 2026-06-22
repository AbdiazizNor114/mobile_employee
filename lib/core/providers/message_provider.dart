import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../services/storage_service.dart';
import '../services/worker_sync_service.dart';
import 'service_providers.dart';
import 'mock_work_provider.dart';

final messagesProvider =
    StateNotifierProvider<MessageController, List<AppMessage>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final syncService = ref.watch(workerSyncServiceProvider);
  final cached = storage.readMessages();
  return MessageController(
    cached?.map(AppMessage.fromJson).toList() ?? const [],
    storage: storage,
    syncService: syncService,
    onCacheUpdated: (updatedAt) =>
        ref.read(cacheLastUpdatedProvider.notifier).state = updatedAt,
  );
});

class MessageController extends StateNotifier<List<AppMessage>> {
  MessageController(
    super.state, {
    required this.storage,
    required this.syncService,
    required this.onCacheUpdated,
  });

  final StorageService storage;
  final WorkerSyncService syncService;
  final void Function(DateTime updatedAt) onCacheUpdated;

  void replaceAll(List<AppMessage> messages) {
    state = messages;
    storage.saveMessages(messages.map((m) => m.toJson()).toList()).then((_) {
      storage.touchLastUpdated().then(onCacheUpdated);
    });
  }

  Future<void> markAsRead(String messageId) async {
    final message = state.where((m) => m.id == messageId).firstOrNull;
    if (message == null || message.isRead) return;

    // Call API
    await syncService.markMessageAsRead(messageId);

    // Update local state
    state = [
      for (final m in state)
        if (m.id == messageId)
          AppMessage(
            id: m.id,
            senderName: m.senderName,
            subject: m.subject,
            content: m.content,
            sentAt: m.sentAt,
            senderMemberId: m.senderMemberId,
            recipientMemberId: m.recipientMemberId,
            isRead: true,
            reactionCounts: m.reactionCounts,
            myReaction: m.myReaction,
          )
        else
          m,
    ];

    storage.saveMessages(state.map((m) => m.toJson()).toList()).then((_) {
      storage.touchLastUpdated().then(onCacheUpdated);
    });
  }

  Future<void> toggleReaction(String messageId, String emoji) async {
    final message = state.where((m) => m.id == messageId).firstOrNull;
    if (message == null) return;

    final nextReaction = message.myReaction == emoji ? null : emoji;
    final previous = state;
    state = [
      for (final m in state)
        if (m.id == messageId) _copyMessageWithReaction(m, nextReaction) else m,
    ];
    storage.saveMessages(state.map((m) => m.toJson()).toList()).then((_) {
      storage.touchLastUpdated().then(onCacheUpdated);
    });

    try {
      await syncService.setMessageReaction(messageId, nextReaction);
    } catch (_) {
      state = previous;
      storage.saveMessages(state.map((m) => m.toJson()).toList()).then((_) {
        storage.touchLastUpdated().then(onCacheUpdated);
      });
      rethrow;
    }
  }

  void reset() {
    state = const [];
  }
}

AppMessage _copyMessageWithReaction(AppMessage message, String? nextReaction) {
  final counts = Map<String, int>.from(message.reactionCounts);
  final previousReaction = message.myReaction;
  if (previousReaction != null) {
    final nextCount = (counts[previousReaction] ?? 0) - 1;
    if (nextCount <= 0) {
      counts.remove(previousReaction);
    } else {
      counts[previousReaction] = nextCount;
    }
  }
  if (nextReaction != null) {
    counts[nextReaction] = (counts[nextReaction] ?? 0) + 1;
  }
  return AppMessage(
    id: message.id,
    senderName: message.senderName,
    subject: message.subject,
    content: message.content,
    sentAt: message.sentAt,
    senderMemberId: message.senderMemberId,
    recipientMemberId: message.recipientMemberId,
    isRead: message.isRead,
    reactionCounts: counts,
    myReaction: nextReaction,
  );
}
