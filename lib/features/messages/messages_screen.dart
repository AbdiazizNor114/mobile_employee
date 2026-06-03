import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/message.dart';
import '../../core/providers/backend_sync_provider.dart';
import '../../core/providers/message_provider.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  bool _showUnreadOnly = false;

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesProvider);
    final visibleMessages = _showUnreadOnly
        ? messages.where((message) => !message.isRead).toList()
        : messages;
    final unreadCount = messages.where((message) => !message.isRead).length;

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
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Managers send messages from dashboard. Reply composer is coming next.',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined),
                  color: AppColors.cardBackground,
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz_rounded),
                  color: AppColors.cardBackground,
                  onSelected: (value) {
                    if (value == 'mark_all_read') {
                      for (final message in messages) {
                        if (!message.isRead) {
                          ref
                              .read(messagesProvider.notifier)
                              .markAsRead(message.id);
                        }
                      }
                    }
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
              onRefresh: () => ref.refresh(backendSyncProvider.future),
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
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                          onTap: () {
                            if (!message.isRead) {
                              ref
                                  .read(messagesProvider.notifier)
                                  .markAsRead(message.id);
                            }
                          },
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
                  color: message.isRead ? AppColors.mutedText : AppColors.darkText,
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
