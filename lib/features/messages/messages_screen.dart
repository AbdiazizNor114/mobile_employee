import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/message.dart';
import '../../core/providers/backend_sync_provider.dart';
import '../../core/providers/message_provider.dart';
import '../../core/providers/service_providers.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  bool _showUnreadOnly = false;
  bool _isSending = false;

  bool get _canReply {
    final plan = ref.read(companyPlanProvider).toLowerCase();
    return plan == 'pro' || plan == 'enterprise';
  }

  Future<void> _refreshMessages() async {
    ref.invalidate(backendSyncProvider);
    await ref.read(backendSyncProvider.future);
  }

  Future<void> _sendMessage(String content) async {
    final message = content.trim();
    if (message.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      await ref.read(workerSyncServiceProvider).sendMessageToManagers(message);
      await _refreshMessages();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent to your manager.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send message. Retry sync and try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _openComposer() async {
    if (!_canReply) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Worker replies are available on Pro and Enterprise.'),
        ),
      );
      return;
    }

    final content = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _MessageComposerSheet(),
    );

    if (content != null) await _sendMessage(content);
  }

  Future<void> _openMessage(AppMessage message) async {
    if (!message.isRead) {
      await ref.read(messagesProvider.notifier).markAsRead(message.id);
    }

    if (!mounted) return;
    final reply = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MessageDetailSheet(
        message: message,
        canReply: _canReply,
      ),
    );

    if (reply != null) await _sendMessage(reply);
  }

  Future<void> _markAllRead(List<AppMessage> messages) async {
    for (final message in messages) {
      if (!message.isRead) {
        await ref.read(messagesProvider.notifier).markAsRead(message.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesProvider);
    final visibleMessages = _showUnreadOnly
        ? messages.where((message) => !message.isRead).toList()
        : messages;
    final unreadCount = messages.where((message) => !message.isRead).length;
    final plan = ref.watch(companyPlanProvider).toLowerCase();
    final canReply = plan == 'pro' || plan == 'enterprise';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              MediaQuery.paddingOf(context).top + AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
            ),
            decoration: const BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Messages',
                    style: AppTypography.headingMedium.copyWith(
                      color: AppColors.cardBackground,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isSending ? null : _openComposer,
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          canReply
                              ? Icons.edit_outlined
                              : Icons.lock_outline_rounded,
                        ),
                  color: AppColors.cardBackground,
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz_rounded),
                  color: AppColors.cardBackground,
                  onSelected: (value) {
                    if (value == 'mark_all_read') _markAllRead(messages);
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'mark_all_read',
                      child: Text('Mark all as read'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshMessages,
              child: visibleMessages.isEmpty
                  ? const _NoMessagesView()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.xxl,
                      ),
                      itemCount: visibleMessages.length + 1,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, color: AppColors.line),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Row(
                              children: [
                                _FilterChip(
                                  label: 'All',
                                  isSelected: !_showUnreadOnly,
                                  onTap: () =>
                                      setState(() => _showUnreadOnly = false),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                _FilterChip(
                                  label: 'Unread ($unreadCount)',
                                  isSelected: _showUnreadOnly,
                                  onTap: () =>
                                      setState(() => _showUnreadOnly = true),
                                ),
                              ],
                            ),
                          );
                        }

                        final message = visibleMessages[index - 1];
                        return _MessageRow(
                          message: message,
                          onTap: () => _openMessage(message),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageDetailSheet extends StatelessWidget {
  const _MessageDetailSheet({
    required this.message,
    required this.canReply,
  });

  final AppMessage message;
  final bool canReply;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.86,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      message.senderName,
                      style: AppTypography.headingMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                _relativeTimeLabel(message.sentAt),
                style: AppTypography.caption.copyWith(
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  message.content,
                  style: AppTypography.bodyLarge.copyWith(height: 1.45),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: FilledButton.icon(
                onPressed: canReply
                    ? () async {
                        final reply = await showModalBottomSheet<String>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const _MessageComposerSheet(),
                        );
                        if (context.mounted) Navigator.of(context).pop(reply);
                      }
                    : null,
                icon: Icon(
                  canReply ? Icons.reply_rounded : Icons.lock_outline_rounded,
                ),
                label: Text(
                  canReply
                      ? 'Reply to manager'
                      : 'Replies are Pro and Enterprise',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageComposerSheet extends StatefulWidget {
  const _MessageComposerSheet();

  @override
  State<_MessageComposerSheet> createState() => _MessageComposerSheetState();
}

class _MessageComposerSheetState extends State<_MessageComposerSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Message manager',
                      style: AppTypography.headingMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Send a work update, question, or request directly to your manager.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _controller,
                minLines: 3,
                maxLines: 6,
                maxLength: 2000,
                autofocus: true,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  hintText: 'Write your message...',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.send_rounded),
                label: const Text('Send message'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _relativeTimeLabel(DateTime value) {
  final diff = DateTime.now().difference(value);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month';
}

class _NoMessagesView extends StatelessWidget {
  const _NoMessagesView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.mark_email_unread_outlined,
              color: AppColors.primaryGreen,
              size: 42,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('No messages yet', style: AppTypography.headingMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'New team updates will appear here automatically.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.greenSoft : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : AppColors.line,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isSelected ? AppColors.primaryGreenDark : AppColors.darkText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({required this.message, required this.onTap});

  final AppMessage message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: message.isRead ? AppColors.background : AppColors.cardBackground,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      message.senderName,
                      style: AppTypography.headingSmall.copyWith(
                        fontWeight:
                            message.isRead ? FontWeight.w700 : FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _relativeTimeLabel(message.sentAt),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                message.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyLarge.copyWith(
                  color:
                      message.isRead ? AppColors.mutedText : AppColors.darkText,
                ),
              ),
              if (!message.isRead) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  height: 6,
                  width: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
