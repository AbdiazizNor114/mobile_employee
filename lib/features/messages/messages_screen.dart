import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/employee_profile.dart';
import '../../core/models/message.dart';
import '../../core/providers/mock_work_provider.dart';
import '../../core/providers/backend_sync_provider.dart';
import '../../core/providers/message_provider.dart';
import '../../core/providers/service_providers.dart';
import '../../core/utils/profile_photo.dart';
import '../../l10n/generated/app_localizations.dart';

enum _MessageFilter { inbox, unread, sent }

enum _HubSection { feed, contacts }

enum _ComposeAudience { managers, teamHub }

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  _MessageFilter _filter = _MessageFilter.inbox;
  _HubSection _hubSection = _HubSection.feed;
  bool _isSending = false;

  Color _accentForPlan(String plan) {
    return AppColors.primaryGreen;
  }

  bool _canCompose(String plan) => plan == 'pro' || plan == 'enterprise';
  bool _canUseTeamHub(String plan) => plan == 'enterprise';

  Future<void> _refreshMessages() async {
    ref.invalidate(backendSyncProvider);
    await ref.read(backendSyncProvider.future);
  }

  Future<void> _sendMessage(_ComposeResult result) async {
    if (_isSending) return;
    setState(() => _isSending = true);
    try {
      await ref.read(workerSyncServiceProvider).sendWorkerMessage(
            subject: result.subject,
            content: result.content,
            sendToAll: result.audience == _ComposeAudience.teamHub,
          );
      await _refreshMessages();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.audience == _ComposeAudience.teamHub
                ? 'Posted to team hub.'
                : 'Message sent to your manager.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not post. Retry sync and try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _openComposer(String plan) async {
    if (!_canCompose(plan)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Team updates are read-only on this plan.')),
      );
      return;
    }

    final result = await Navigator.of(context).push<_ComposeResult>(
      MaterialPageRoute(
        builder: (context) => _ComposeMessagePage(
          accent: _accentForPlan(plan),
          canUseTeamHub: _canUseTeamHub(plan),
          defaultToTeamHub: _canUseTeamHub(plan),
        ),
      ),
    );
    if (result != null) await _sendMessage(result);
  }

  Future<void> _openMessage({
    required AppMessage message,
    required bool isSent,
    required String plan,
  }) async {
    if (!isSent && !message.isRead) {
      await ref.read(messagesProvider.notifier).markAsRead(message.id);
    }

    if (!mounted) return;
    final result = await Navigator.of(context).push<_ComposeResult>(
      MaterialPageRoute(
        builder: (context) => _MessageDetailPage(
          message: message,
          accent: _accentForPlan(plan),
          isSent: isSent,
          canReply: _canCompose(plan),
          canUseTeamHub: _canUseTeamHub(plan),
        ),
      ),
    );
    if (result != null) await _sendMessage(result);
  }

  Future<void> _openHubTopic({
    required _HubTopic topic,
    required String plan,
  }) async {
    for (final message in topic.comments) {
      if (!message.isRead) {
        await ref.read(messagesProvider.notifier).markAsRead(message.id);
      }
    }

    if (!mounted) return;
    final result = await Navigator.of(context).push<_ComposeResult>(
      MaterialPageRoute(
        builder: (context) => _MessageDetailPage(
          message: topic.root,
          thread: topic.comments,
          accent: _accentForPlan(plan),
          isSent: false,
          canReply: _canCompose(plan),
          canUseTeamHub: true,
        ),
      ),
    );
    if (result != null) await _sendMessage(result);
  }

  Future<void> _markAllRead(
      List<AppMessage> messages, String? membershipId) async {
    for (final message in messages) {
      final isSent = message.senderMemberId == membershipId;
      if (!isSent && !message.isRead) {
        await ref.read(messagesProvider.notifier).markAsRead(message.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final messages = ref.watch(messagesProvider);
    final plan = ref.watch(companyPlanProvider).toLowerCase();
    final membershipId = ref.watch(authServiceProvider).membershipId;
    final accent = _accentForPlan(plan);
    final isEnterprise = plan == 'enterprise';
    final canCompose = _canCompose(plan);
    final contacts = ref.watch(staffContactsProvider);
    final unreadCount = messages
        .where((message) =>
            message.senderMemberId != membershipId && !message.isRead)
        .length;
    final hubTopics = _buildHubTopics(messages, membershipId);

    final visibleMessages = messages.where((message) {
      final isSent = message.senderMemberId == membershipId;
      return switch (_filter) {
        _MessageFilter.inbox => !isSent,
        _MessageFilter.unread => !isSent && !message.isRead,
        _MessageFilter.sent => isSent,
      };
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _MessagesHeader(
            accent: accent,
            title: isEnterprise ? l10n.hub : l10n.messages,
            isSending: _isSending,
            canCompose: canCompose,
            isHub: isEnterprise,
            unreadCount: unreadCount,
            onCompose: () => _openComposer(plan),
            onMarkAllRead: () => _markAllRead(messages, membershipId),
          ),
          if (isEnterprise)
            Container(
              color: AppColors.cardBackground,
              child: Row(
                children: [
                  _MailboxTab(
                    label: l10n.hub,
                    isSelected: _hubSection == _HubSection.feed,
                    accent: accent,
                    onTap: () => setState(() => _hubSection = _HubSection.feed),
                  ),
                  _MailboxTab(
                    label: l10n.contacts,
                    isSelected: _hubSection == _HubSection.contacts,
                    accent: accent,
                    onTap: () =>
                        setState(() => _hubSection = _HubSection.contacts),
                  ),
                ],
              ),
            )
          else
            Container(
              color: AppColors.cardBackground,
              child: Row(
                children: [
                  _MailboxTab(
                    label: l10n.inbox,
                    isSelected: _filter == _MessageFilter.inbox,
                    accent: accent,
                    onTap: () => setState(() => _filter = _MessageFilter.inbox),
                  ),
                  _MailboxTab(
                    label: l10n.unreadWithCount(unreadCount),
                    isSelected: _filter == _MessageFilter.unread,
                    accent: accent,
                    onTap: () =>
                        setState(() => _filter = _MessageFilter.unread),
                  ),
                  _MailboxTab(
                    label: l10n.sent,
                    isSelected: _filter == _MessageFilter.sent,
                    accent: accent,
                    onTap: () => setState(() => _filter = _MessageFilter.sent),
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshMessages,
              child: isEnterprise
                  ? (_hubSection == _HubSection.contacts
                      ? _ContactsList(contacts: contacts, accent: accent)
                      : hubTopics.isEmpty
                          ? const _EmptyHubView()
                          : ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: hubTopics.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(
                                      height: 1, color: AppColors.line),
                              itemBuilder: (context, index) {
                                final topic = hubTopics[index];
                                return _HubTopicRow(
                                  topic: topic,
                                  accent: accent,
                                  onReact: (emoji) => ref
                                      .read(messagesProvider.notifier)
                                      .toggleReaction(topic.root.id, emoji),
                                  onTap: () => _openHubTopic(
                                    topic: topic,
                                    plan: plan,
                                  ),
                                );
                              },
                            ))
                  : visibleMessages.isEmpty
                      ? _NoMessagesView(filter: _filter)
                      : ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: visibleMessages.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1, color: AppColors.line),
                          itemBuilder: (context, index) {
                            final message = visibleMessages[index];
                            final isSent =
                                message.senderMemberId == membershipId;
                            return _MessageRow(
                              message: message,
                              isSent: isSent,
                              accent: accent,
                              onTap: () => _openMessage(
                                message: message,
                                isSent: isSent,
                                plan: plan,
                              ),
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

class _MessagesHeader extends StatelessWidget {
  const _MessagesHeader({
    required this.accent,
    required this.title,
    required this.isSending,
    required this.canCompose,
    required this.isHub,
    required this.unreadCount,
    required this.onCompose,
    required this.onMarkAllRead,
  });

  final Color accent;
  final String title;
  final bool isSending;
  final bool canCompose;
  final bool isHub;
  final int unreadCount;
  final VoidCallback onCompose;
  final VoidCallback onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: accent,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        MediaQuery.paddingOf(context).top + AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: AppTypography.headingLarge.copyWith(
                      color: AppColors.cardBackground,
                    ),
                  ),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.cardBackground.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      '$unreadCount unread',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.cardBackground,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Mark all as read',
            onPressed: unreadCount == 0 ? null : onMarkAllRead,
            icon: const Icon(Icons.mark_email_read_outlined),
            color: AppColors.cardBackground,
            disabledColor: AppColors.cardBackground.withValues(alpha: 0.45),
          ),
          IconButton(
            tooltip: canCompose
                ? (isHub ? 'Post hub comment' : 'Write message')
                : 'Team updates are read-only',
            onPressed: isSending ? null : onCompose,
            icon: isSending
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(canCompose ? Icons.edit_outlined : Icons.lock_outline),
            color: AppColors.cardBackground,
            disabledColor: AppColors.cardBackground.withValues(alpha: 0.45),
          ),
        ],
      ),
    );
  }
}

class _MailboxTab extends StatelessWidget {
  const _MailboxTab({
    required this.label,
    required this.isSelected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? accent : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: isSelected ? accent : AppColors.mutedText,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({
    required this.message,
    required this.isSent,
    required this.accent,
    required this.onTap,
  });

  final AppMessage message;
  final bool isSent;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !isSent && !message.isRead;

    return Material(
      color: AppColors.cardBackground,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor:
                    unread ? accent.withValues(alpha: 0.14) : AppColors.line,
                child: Text(
                  _initials(message.senderName),
                  style: AppTypography.caption.copyWith(
                    color: unread ? accent : AppColors.darkText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (unread) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Expanded(
                          child: Text(
                            message.subject,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight:
                                  unread ? FontWeight.w800 : FontWeight.w700,
                              color: AppColors.darkText,
                            ),
                          ),
                        ),
                        Text(
                          _dateLabel(message.sentAt),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      isSent ? 'You' : message.senderName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.mutedText,
                        fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      message.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HubTopicRow extends StatelessWidget {
  const _HubTopicRow({
    required this.topic,
    required this.accent,
    required this.onTap,
    required this.onReact,
  });

  final _HubTopic topic;
  final Color accent;
  final VoidCallback onTap;
  final ValueChanged<String> onReact;

  @override
  Widget build(BuildContext context) {
    final unread = topic.unreadCount > 0;

    return Material(
      color: AppColors.cardBackground,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: unread
                        ? accent.withValues(alpha: 0.14)
                        : AppColors.line,
                    child: Text(
                      _initials(topic.root.senderName),
                      style: AppTypography.caption.copyWith(
                        color: unread ? accent : AppColors.darkText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (unread) ...[
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                            ],
                            Expanded(
                              child: Text(
                                topic.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodyLarge.copyWith(
                                  color: AppColors.darkText,
                                  fontWeight: unread
                                      ? FontWeight.w800
                                      : FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${topic.root.senderName} · ${_dateLabel(topic.latestAt)}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                topic.latest.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.mutedText,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _MetaChip(
                    icon: Icons.mode_comment_outlined,
                    label:
                        '${topic.commentCount} comment${topic.commentCount == 1 ? '' : 's'}',
                  ),
                  if (unread) ...[
                    const SizedBox(width: AppSpacing.sm),
                    _MetaChip(
                      icon: Icons.mark_email_unread_outlined,
                      label: '${topic.unreadCount} unread',
                    ),
                  ],
                  const Spacer(),
                  for (final emoji in const ['👍', '❤️', '✅'])
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.xs),
                      child: InkWell(
                        onTap: () => onReact(emoji),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: topic.root.myReaction == emoji
                                ? accent.withValues(alpha: 0.14)
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: topic.root.myReaction == emoji
                                  ? accent
                                  : AppColors.line,
                            ),
                          ),
                          child: Text(
                            '$emoji${(topic.root.reactionCounts[emoji] ?? 0) > 0 ? ' ${topic.root.reactionCounts[emoji]}' : ''}',
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.mutedText),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactsList extends StatelessWidget {
  const _ContactsList({required this.contacts, required this.accent});

  final List<StaffContact> contacts;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                const Icon(
                  Icons.contact_page_outlined,
                  color: AppColors.mutedText,
                  size: 42,
                ),
                const SizedBox(height: AppSpacing.md),
                Text('No manager contacts yet',
                    style: AppTypography.headingMedium),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: contacts.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, color: AppColors.line),
      itemBuilder: (context, index) {
        final contact = contacts[index];
        final photo = profilePhotoProvider(contact.profilePhotoUrl);
        return Material(
          color: AppColors.cardBackground,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: accent.withValues(alpha: 0.14),
                  backgroundImage: photo,
                  child: photo == null
                      ? Text(
                          contact.initials,
                          style: AppTypography.caption.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.name.isEmpty ? contact.roleLabel : contact.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.darkText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        [
                          contact.roleLabel,
                          if (contact.jobTitle.trim().isNotEmpty)
                            contact.jobTitle,
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.mutedText,
                        ),
                      ),
                      if (contact.email.trim().isNotEmpty ||
                          contact.phone.trim().isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          [
                            if (contact.email.trim().isNotEmpty) contact.email,
                            if (contact.phone.trim().isNotEmpty) contact.phone,
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MessageDetailPage extends ConsumerStatefulWidget {
  const _MessageDetailPage({
    required this.message,
    required this.accent,
    required this.isSent,
    required this.canReply,
    required this.canUseTeamHub,
    this.thread = const [],
  });

  final AppMessage message;
  final List<AppMessage> thread;
  final Color accent;
  final bool isSent;
  final bool canReply;
  final bool canUseTeamHub;

  @override
  ConsumerState<_MessageDetailPage> createState() => _MessageDetailPageState();
}

class _MessageDetailPageState extends ConsumerState<_MessageDetailPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final comments = widget.thread
        .where((item) => item.id != widget.message.id)
        .toList()
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: widget.accent,
        foregroundColor: AppColors.cardBackground,
        title: Text(
          widget.canUseTeamHub
              ? l10n.hub
              : (widget.isSent
                  ? l10n.sentMessage
                  : l10n.messageFrom(widget.message.senderName)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _ThreadMessageCard(
            message: widget.message,
            accent: widget.accent,
            title: widget.message.subject,
            authorLabel: widget.isSent ? l10n.you : widget.message.senderName,
            onReact: (emoji) => ref
                .read(messagesProvider.notifier)
                .toggleReaction(widget.message.id, emoji),
            elevated: true,
          ),
          if (widget.canUseTeamHub) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Comments',
              style: AppTypography.headingSmall.copyWith(
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (comments.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.line),
                ),
                child: Text(
                  'No comments yet. Add the first one so the whole team can see it.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.mutedText,
                  ),
                ),
              )
            else
              for (final comment in comments) ...[
                _ThreadMessageCard(
                  message: comment,
                  accent: widget.accent,
                  authorLabel: comment.senderMemberId == null
                      ? comment.senderName
                      : comment.senderName,
                  onReact: (emoji) => ref
                      .read(messagesProvider.notifier)
                      .toggleReaction(comment.id, emoji),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
          ],
          const SizedBox(height: AppSpacing.lg),
          if (widget.canReply)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final result =
                          await Navigator.of(context).push<_ComposeResult>(
                        MaterialPageRoute(
                          builder: (context) => _ComposeMessagePage(
                            accent: widget.accent,
                            canUseTeamHub: widget.canUseTeamHub,
                            hubOnly: widget.canUseTeamHub,
                            initialSubject:
                                'Re: ${_rootSubject(widget.message.subject)}',
                          ),
                        ),
                      );
                      if (context.mounted) Navigator.of(context).pop(result);
                    },
                    icon: const Icon(Icons.reply_rounded),
                    label:
                        Text(widget.canUseTeamHub ? l10n.comment : l10n.reply),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ThreadMessageCard extends StatelessWidget {
  const _ThreadMessageCard({
    required this.message,
    required this.accent,
    required this.authorLabel,
    required this.onReact,
    this.title,
    this.elevated = false,
  });

  final AppMessage message;
  final Color accent;
  final String authorLabel;
  final String? title;
  final bool elevated;
  final ValueChanged<String> onReact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.line),
        boxShadow: elevated
            ? const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: elevated ? 24 : 20,
                backgroundColor: accent.withValues(alpha: 0.14),
                child: Text(
                  _initials(authorLabel),
                  style: AppTypography.caption.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  authorLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: elevated
                      ? AppTypography.headingSmall
                      : AppTypography.bodyLarge.copyWith(
                          color: AppColors.darkText,
                          fontWeight: FontWeight.w800,
                        ),
                ),
              ),
              Text(
                _dateLabel(message.sentAt),
                style: AppTypography.caption.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
            ],
          ),
          if (title != null && title!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              title!,
              style: AppTypography.headingLarge.copyWith(
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(color: AppColors.line),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            message.content,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.darkText,
              height: 1.55,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (final emoji in const ['👍', '❤️', '✅', '🙏'])
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: InkWell(
                    onTap: () => onReact(emoji),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: message.myReaction == emoji
                            ? accent.withValues(alpha: 0.14)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: message.myReaction == emoji
                              ? accent
                              : AppColors.line,
                        ),
                      ),
                      child: Text(
                        '$emoji${(message.reactionCounts[emoji] ?? 0) > 0 ? ' ${message.reactionCounts[emoji]}' : ''}',
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComposeMessagePage extends StatefulWidget {
  const _ComposeMessagePage({
    required this.accent,
    required this.canUseTeamHub,
    this.hubOnly = false,
    this.defaultToTeamHub = false,
    this.initialSubject = '',
  });

  final Color accent;
  final bool canUseTeamHub;
  final bool hubOnly;
  final bool defaultToTeamHub;
  final String initialSubject;

  @override
  State<_ComposeMessagePage> createState() => _ComposeMessagePageState();
}

class _ComposeMessagePageState extends State<_ComposeMessagePage> {
  late final TextEditingController _subjectController;
  final _contentController = TextEditingController();
  late _ComposeAudience _audience;

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(text: widget.initialSubject);
    _audience = widget.hubOnly || widget.defaultToTeamHub
        ? _ComposeAudience.teamHub
        : _ComposeAudience.managers;
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _submit() {
    final subject = _subjectController.text.trim();
    final content = _contentController.text.trim();
    if (subject.isEmpty || content.isEmpty) return;
    Navigator.of(context).pop(
      _ComposeResult(
        subject: subject,
        content: content,
        audience: _audience,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: widget.accent,
        foregroundColor: AppColors.cardBackground,
        title: Text(widget.hubOnly
            ? 'Post hub comment'
            : widget.canUseTeamHub
                ? l10n.writeMessage
                : l10n.writeMessage),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(widget.hubOnly ? l10n.hub : l10n.subject,
              style: AppTypography.headingSmall),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _subjectController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: widget.hubOnly
                  ? 'What should the team track?'
                  : l10n.whatIsThisAbout,
              filled: true,
              fillColor: AppColors.cardBackground,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!widget.hubOnly) ...[
            Text(l10n.audience, style: AppTypography.headingSmall),
            const SizedBox(height: AppSpacing.sm),
            _AudienceOption(
              title: l10n.managers,
              subtitle: widget.canUseTeamHub
                  ? 'Send a private text to managers.'
                  : l10n.sendDirectlyToManagers,
              value: _ComposeAudience.managers,
              groupValue: _audience,
              accent: widget.accent,
              onChanged: (value) => setState(() => _audience = value),
            ),
            if (widget.canUseTeamHub)
              _AudienceOption(
                title: l10n.hub,
                subtitle: 'Post so everyone can see and comment.',
                value: _ComposeAudience.teamHub,
                groupValue: _audience,
                accent: widget.accent,
                onChanged: (value) => setState(() => _audience = value),
              ),
            const SizedBox(height: AppSpacing.lg),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.line),
              ),
              child: Text(
                'This comment stays in the public Team Hub thread so everyone works from the same record.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text(widget.hubOnly ? l10n.comment : l10n.message,
              style: AppTypography.headingSmall),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _contentController,
            minLines: 7,
            maxLines: 12,
            maxLength: 2000,
            decoration: InputDecoration(
              hintText: widget.hubOnly
                  ? 'Add a hub comment for your team...'
                  : l10n.writeYourMessage,
              filled: true,
              fillColor: AppColors.cardBackground,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: _submit,
            icon: Icon(
                widget.hubOnly ? Icons.forum_outlined : Icons.send_rounded),
            label: Text(widget.hubOnly
                ? 'Post comment'
                : _audience == _ComposeAudience.teamHub
                    ? 'Post to hub'
                    : l10n.sendPrivateText),
          ),
        ],
      ),
    );
  }
}

class _AudienceOption extends StatelessWidget {
  const _AudienceOption({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.accent,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final _ComposeAudience value;
  final _ComposeAudience groupValue;
  final Color accent;
  final ValueChanged<_ComposeAudience> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;

    return Material(
      color: AppColors.cardBackground,
      child: InkWell(
        onTap: () => onChanged(value),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? accent : AppColors.mutedText,
                    width: 2,
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.bodyLarge),
                    Text(
                      subtitle,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComposeResult {
  const _ComposeResult({
    required this.subject,
    required this.content,
    required this.audience,
  });

  final String subject;
  final String content;
  final _ComposeAudience audience;
}

class _NoMessagesView extends StatelessWidget {
  const _NoMessagesView({required this.filter});

  final _MessageFilter filter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = switch (filter) {
      _MessageFilter.inbox => l10n.noMessagesYet,
      _MessageFilter.unread => l10n.noUnreadMessages,
      _MessageFilter.sent => l10n.noSentMessages,
    };

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                color: AppColors.mutedText,
                size: 42,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(label, style: AppTypography.headingMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyHubView extends StatelessWidget {
  const _EmptyHubView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              const Icon(
                Icons.forum_outlined,
                color: AppColors.mutedText,
                size: 42,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('No hub posts yet', style: AppTypography.headingMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Post an update or comment when the whole team should see it.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HubTopic {
  const _HubTopic({
    required this.key,
    required this.title,
    required this.root,
    required this.comments,
    required this.unreadCount,
  });

  final String key;
  final String title;
  final AppMessage root;
  final List<AppMessage> comments;
  final int unreadCount;

  AppMessage get latest => comments.isEmpty ? root : comments.last;
  DateTime get latestAt => latest.sentAt;
  int get commentCount => comments.length > 1 ? comments.length - 1 : 0;
}

List<_HubTopic> _buildHubTopics(
  List<AppMessage> messages,
  String? membershipId,
) {
  final grouped = <String, List<AppMessage>>{};
  for (final message in messages) {
    final key = _topicKey(message.subject);
    grouped.putIfAbsent(key, () => []).add(message);
  }

  final topics = grouped.entries.map((entry) {
    final thread = [...entry.value]
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
    final root = thread.firstWhere(
      (message) => !_isReplySubject(message.subject),
      orElse: () => thread.first,
    );
    final comments = [
      root,
      ...thread.where((message) => message.id != root.id),
    ];
    return _HubTopic(
      key: entry.key,
      title: _rootSubject(root.subject),
      root: root,
      comments: comments,
      unreadCount: comments
          .where((message) =>
              message.senderMemberId != membershipId && !message.isRead)
          .length,
    );
  }).toList()
    ..sort((a, b) => b.latestAt.compareTo(a.latestAt));

  return topics;
}

String _topicKey(String subject) {
  return _rootSubject(subject).toLowerCase().trim();
}

String _rootSubject(String subject) {
  var value = subject.trim();
  while (value.toLowerCase().startsWith('re:')) {
    value = value.substring(3).trim();
  }
  return value.isEmpty ? 'Team update' : value;
}

bool _isReplySubject(String subject) {
  return subject.trim().toLowerCase().startsWith('re:');
}

String _initials(String value) {
  final parts = value.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
  return letters.isEmpty ? 'SN' : letters;
}

String _dateLabel(DateTime value) {
  final now = DateTime.now();
  if (now.year == value.year &&
      now.month == value.month &&
      now.day == value.day) {
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
  return '${value.day}/${value.month}/${value.year}';
}
