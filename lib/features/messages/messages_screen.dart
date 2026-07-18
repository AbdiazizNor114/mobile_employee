import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
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

enum _MessageFilter { inbox, unread, sent, contacts }

enum _HubSection { direct, feed, contacts }

enum _ComposeAudience { contacts, teamHub }

String _messageTitle(AppMessage message, AppLocalizations l10n) {
  final subject = message.subject.trim();
  if (subject.isNotEmpty && subject.toLowerCase() != 'team update') {
    return subject;
  }
  final firstLine = message.content
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .firstOrNull;
  if (firstLine == null) return l10n.message;
  return firstLine.length > 72 ? '${firstLine.substring(0, 69)}...' : firstLine;
}

String _friendlySendError(BuildContext context, Object error) {
  final fallback = AppLocalizations.of(context).couldNotPost;
  if (error is DioException) {
    final status = error.response?.statusCode;
    final body = error.response?.data;
    final serverMessage = body is Map ? body['error']?.toString() : null;
    if (status == 401) return 'Please sign in again before sending.';
    if (status == 403) {
      return serverMessage?.isNotEmpty == true
          ? serverMessage!
          : 'You do not have permission to send this message.';
    }
    if (status == 404) {
      return serverMessage?.isNotEmpty == true
          ? serverMessage!
          : 'No recipient was found for this message.';
    }
    if (status != null && status >= 500) {
      return 'Server update is not ready yet. Please try again shortly.';
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Connection problem. Check internet and try again.';
    }
    if (serverMessage?.isNotEmpty == true) return serverMessage!;
  }
  return fallback;
}

bool _isDirectMessage(AppMessage message) {
  return message.messageScope == 'direct' ||
      (message.messageScope != 'post' &&
          message.messageScope != 'comment' &&
          message.parentMessageId == null);
}

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  _HubSection _hubSection = _HubSection.direct;
  bool _isSending = false;

  Color _accentForPlan(String plan) {
    return AppColors.primaryGreen;
  }

  bool _canCompose(String plan) => true;
  bool _canUseTeamHub(String plan) => plan == 'enterprise';
  bool _canPublishPosts(String plan, String role) {
    return _canUseTeamHub(plan) &&
        const {'company_owner', 'company_admin', 'manager'}.contains(role);
  }

  Future<void> _refreshMessages() async {
    ref.invalidate(backendSyncProvider);
    await ref.read(backendSyncProvider.future);
  }

  Future<void> _sendMessage(_ComposeResult result) async {
    if (_isSending) return;
    setState(() => _isSending = true);
    try {
      final sync = ref.read(workerSyncServiceProvider);
      if (result.audience == _ComposeAudience.teamHub) {
        await sync.sendWorkerMessage(
          subject: result.subject,
          content: result.content,
          sendToAll: true,
          messageScope: 'post',
        );
      } else {
        for (final recipientId in result.recipientMemberIds) {
          await sync.sendWorkerMessage(
            subject: result.subject,
            content: result.content,
            recipientMemberId: recipientId,
          );
        }
      }
      await _refreshMessages();
      if (!mounted) return;
      setState(() {
        _hubSection = result.audience == _ComposeAudience.teamHub
            ? _HubSection.feed
            : _HubSection.direct;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.audience == _ComposeAudience.teamHub
                ? AppLocalizations.of(context).postedToTeamHub
                : result.recipientMemberIds.length == 1
                    ? AppLocalizations.of(context).messageSentToManager
                    : 'Private messages sent.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlySendError(context, error)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _openComposer(String plan) async {
    var dmRecipients = ref.read(staffContactsProvider);
    try {
      dmRecipients =
          await ref.read(workerSyncServiceProvider).fetchDirectMessageRecipients();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_friendlySendError(context, error))),
        );
      }
    }
    if (!mounted) return;
    final result = await Navigator.of(context).push<_ComposeResult>(
      MaterialPageRoute(
        builder: (context) => _ComposeMessagePage(
          accent: _accentForPlan(plan),
          canUseTeamHub: _canPublishPosts(
            plan,
            ref.read(employeeProfileProvider).companyRole,
          ),
          contacts: dmRecipients,
          defaultToTeamHub: _hubSection == _HubSection.feed &&
              _canPublishPosts(
                plan,
                ref.read(employeeProfileProvider).companyRole,
              ),
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
    if (_isDirectMessage(message)) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => _DirectMessagePage(
            seedMessage: message,
            accent: _accentForPlan(plan),
            currentMemberId: ref.read(authServiceProvider).membershipId,
            canReply: _canCompose(plan),
          ),
        ),
      );
      return;
    }

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
          canUseTeamHub: _canUseTeamHub(plan),
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
    final profile = ref.watch(employeeProfileProvider);
    final canCompose = _canCompose(plan);
    final canUsePosts = _canUseTeamHub(plan);
    final canPublishPosts = _canPublishPosts(plan, profile.companyRole);
    final contacts = ref.watch(staffContactsProvider);
    final unreadCount = messages
        .where((message) =>
            message.senderMemberId != membershipId && !message.isRead)
        .length;
    final directMessages = messages.where(_isDirectMessage).toList();
    final hubMessages = messages
        .where((message) =>
            message.messageScope == 'post' ||
            message.messageScope == 'comment' ||
            message.parentMessageId != null)
        .toList();
    final hubTopics = _buildHubTopics(hubMessages, membershipId);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _MessagesHeader(
            accent: accent,
            title: l10n.messages,
            isSending: _isSending,
            canCompose: canCompose,
            isHub: _hubSection == _HubSection.feed && canPublishPosts,
            unreadCount: unreadCount,
            onCompose: () => _openComposer(plan),
            onMarkAllRead: () => _markAllRead(messages, membershipId),
          ),
          Container(
            color: AppColors.cardBackground,
            child: Row(
              children: [
                _MailboxTab(
                  label: 'Messages',
                  isSelected: _hubSection == _HubSection.direct,
                  accent: accent,
                  onTap: () => setState(() => _hubSection = _HubSection.direct),
                ),
                _MailboxTab(
                  label: 'Posts',
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
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshMessages,
              child: _hubSection == _HubSection.contacts
                  ? _ContactsList(contacts: contacts, accent: accent)
                  : _hubSection == _HubSection.direct
                      ? (directMessages.isEmpty
                          ? _NoMessagesView(
                              filter: _MessageFilter.inbox,
                              onAction: () => _openComposer(plan),
                            )
                          : ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: directMessages.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(
                                      height: 1, color: AppColors.line),
                              itemBuilder: (context, index) {
                                final message = directMessages[index];
                                final isSent =
                                    message.senderMemberId == membershipId;
                                return _MessageRow(
                                  message: message,
                                  isSent: isSent,
                                  accent: accent,
                                  onTap: () => _openMessage(
                                    message: message,
                                    isSent: isSent,
                                    plan: 'pro',
                                  ),
                                );
                              },
                            ))
                      : hubTopics.isEmpty
                          ? _EmptyHubView(
                              isEnterprise: canUsePosts,
                              canCreatePost: canPublishPosts,
                              onAction: canPublishPosts
                                  ? () => _openComposer(plan)
                                  : null,
                            )
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
                                  onTap: () => _openHubTopic(
                                    topic: topic,
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
    final l10n = AppLocalizations.of(context);

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
                      l10n.unreadWithCount(unreadCount),
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
            tooltip: canCompose
                ? (isHub
                    ? AppLocalizations.of(context).postHubComment
                    : AppLocalizations.of(context).writeMessage)
                : AppLocalizations.of(context).teamUpdatesReadOnly,
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
          PopupMenuButton<_MessageMenuAction>(
            tooltip: 'Message options',
            icon: const Icon(Icons.more_horiz_rounded),
            color: AppColors.cardBackground,
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (action) {
              if (action == _MessageMenuAction.markAllRead && unreadCount > 0) {
                onMarkAllRead();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                enabled: false,
                child: _MessageMenuHeader(),
              ),
              const PopupMenuItem(
                value: _MessageMenuAction.all,
                child: Text('All'),
              ),
              const PopupMenuItem(
                value: _MessageMenuAction.unread,
                child: Text('Unread'),
              ),
              const PopupMenuItem(
                value: _MessageMenuAction.public,
                child: Text('Public'),
              ),
              const PopupMenuItem(
                value: _MessageMenuAction.groups,
                child: Text('Groups'),
              ),
              const PopupMenuItem(
                value: _MessageMenuAction.day,
                child: Text('Day'),
              ),
              const PopupMenuItem(
                value: _MessageMenuAction.archived,
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('Archived'),
                  trailing: Icon(Icons.inventory_2_outlined),
                ),
              ),
              const PopupMenuItem(
                value: _MessageMenuAction.searchPerson,
                child: Text('Search person'),
              ),
              const PopupMenuItem(
                value: _MessageMenuAction.manage,
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('Manage messages'),
                  trailing: Icon(Icons.settings_outlined),
                ),
              ),
              PopupMenuItem(
                enabled: unreadCount > 0,
                value: _MessageMenuAction.markAllRead,
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.mark_email_read_outlined),
                  title: Text(l10n.markAllRead),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _MessageMenuAction {
  all,
  unread,
  public,
  groups,
  day,
  archived,
  searchPerson,
  manage,
  markAllRead,
}

class _MessageMenuHeader extends StatelessWidget {
  const _MessageMenuHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Filter messages',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.darkText,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Icon(Icons.filter_alt_outlined, color: AppColors.mutedText),
      ],
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
    final l10n = AppLocalizations.of(context);
    final unread = !isSent && !message.isRead;
    final photo = profilePhotoProvider(message.senderProfilePhotoUrl);

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
                backgroundImage: photo,
                child: photo == null
                    ? Text(
                        _initials(message.senderName),
                        style: AppTypography.caption.copyWith(
                          color: unread ? accent : AppColors.darkText,
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
                            _messageTitle(message, l10n),
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
                      isSent ? l10n.you : message.senderName,
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
  });

  final _HubTopic topic;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = topic.unreadCount > 0;
    final preview = topic.latest.id == topic.root.id
        ? topic.root.content
        : topic.latest.content;

    return Material(
      color: AppColors.cardBackground,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
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
                      topic.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.darkText,
                        fontWeight: unread ? FontWeight.w800 : FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    _dateLabel(topic.latestAt),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                preview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.mutedText,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactsList extends ConsumerWidget {
  const _ContactsList({required this.contacts, required this.accent});

  final List<StaffContact> contacts;
  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                Text(
                  AppLocalizations.of(context).noManagerContactsYet,
                  style: AppTypography.headingMedium,
                ),
              ],
            ),
          ),
        ],
      );
    }

    final companyName = ref.watch(companyNameProvider);
    final companyLabel = companyName.trim().isEmpty
        ? 'YOUR COMPANY'
        : companyName.trim().toUpperCase();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        Text(
          'CONTACTS AT $companyLabel',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.mutedText,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final contact in contacts) ...[
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: _ContactCard(
                contact: contact,
                accent: accent,
                companyName: companyName,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => _ContactDetailPage(
                      contact: contact,
                      accent: accent,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.contact,
    required this.accent,
    required this.companyName,
    required this.onTap,
  });

  final StaffContact contact;
  final Color accent;
  final String companyName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final photo = profilePhotoProvider(contact.profilePhotoUrl);
    final groupLine = [
      if (companyName.trim().isNotEmpty) companyName.trim(),
      contact.subtitle,
    ].join(' / ');

    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 14,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 64,
                    backgroundColor: accent.withValues(alpha: 0.14),
                    backgroundImage: photo,
                    child: photo == null
                        ? Text(
                            contact.initials,
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w900,
                              fontSize: 28,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: contact.role == 'manager'
                            ? accent
                            : const Color(0xFF9CA3AF),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.cardBackground,
                          width: 4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                contact.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTypography.headingLarge.copyWith(color: accent),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                contact.roleLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                groupLine,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactDetailPage extends ConsumerWidget {
  const _ContactDetailPage({
    required this.contact,
    required this.accent,
  });

  final StaffContact contact;
  final Color accent;

  Future<void> _launchContactUri(
    BuildContext context,
    Uri uri,
    String fallback,
  ) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(fallback)),
      );
    }
  }

  Future<void> _messageInApp(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.of(context).push<_ComposeResult>(
      MaterialPageRoute(
        builder: (context) => _ComposeMessagePage(
          accent: accent,
          canUseTeamHub: false,
          contacts: [contact],
        ),
      ),
    );
    if (result == null || result.recipientMemberIds.isEmpty) return;

    try {
      final sync = ref.read(workerSyncServiceProvider);
      for (final recipientId in result.recipientMemberIds) {
        await sync.sendWorkerMessage(
          subject: result.subject,
          content: result.content,
          recipientMemberId: recipientId,
        );
      }
      ref.invalidate(backendSyncProvider);
      await ref.read(backendSyncProvider.future);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlySendError(context, error))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyName = ref.watch(companyNameProvider);
    final photo = profilePhotoProvider(contact.profilePhotoUrl);
    final companyLabel = companyName.trim().isEmpty
        ? 'YOUR COMPANY'
        : companyName.trim().toUpperCase();
    final groupLine = [
      if (companyName.trim().isNotEmpty) companyName.trim(),
      contact.roleLabel,
    ].join(' / ');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: accent,
        foregroundColor: AppColors.cardBackground,
        title: const Text('Contact'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          Text(
            'CONTACTS AT $companyLabel',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.mutedText,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.xl,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 14,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 64,
                          backgroundColor: accent.withValues(alpha: 0.14),
                          backgroundImage: photo,
                          child: photo == null
                              ? Text(
                                  contact.initials,
                                  style: TextStyle(
                                    color: accent,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 28,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.cardBackground,
                                width: 4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      contact.displayName,
                      textAlign: TextAlign.center,
                      style: AppTypography.headingLarge.copyWith(
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      contact.subtitle,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      groupLine,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _ContactActionButton(
                          icon: Icons.phone_outlined,
                          label: 'Call',
                          accent: accent,
                          enabled: contact.phone.trim().isNotEmpty,
                          onTap: () => _launchContactUri(
                            context,
                            Uri(scheme: 'tel', path: contact.phone.trim()),
                            'Could not open phone.',
                          ),
                        ),
                        _ContactActionButton(
                          icon: Icons.mail_outline_rounded,
                          label: 'Email',
                          accent: accent,
                          enabled: contact.email.trim().isNotEmpty,
                          onTap: () => _launchContactUri(
                            context,
                            Uri(
                              scheme: 'mailto',
                              path: contact.email.trim(),
                            ),
                            'Could not open email.',
                          ),
                        ),
                        _ContactActionButton(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: 'Message',
                          accent: accent,
                          onTap: () => _messageInApp(context, ref),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (contact.email.trim().isNotEmpty)
            _ContactDetailRow(
              icon: Icons.mail_outline_rounded,
              label: 'Email',
              value: contact.email.trim(),
              accent: accent,
            ),
          if (contact.phone.trim().isNotEmpty)
            _ContactDetailRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: contact.phone.trim(),
              accent: accent,
            ),
        ],
      ),
    );
  }
}

class _ContactActionButton extends StatelessWidget {
  const _ContactActionButton({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? accent : AppColors.mutedText;
    return OutlinedButton.icon(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: enabled ? accent : AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }
}

class _ContactDetailRow extends StatelessWidget {
  const _ContactDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Icon(icon, color: accent),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.mutedText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.darkText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectMessagePage extends ConsumerStatefulWidget {
  const _DirectMessagePage({
    required this.seedMessage,
    required this.accent,
    required this.currentMemberId,
    required this.canReply,
  });

  final AppMessage seedMessage;
  final Color accent;
  final String? currentMemberId;
  final bool canReply;

  @override
  ConsumerState<_DirectMessagePage> createState() => _DirectMessagePageState();
}

class _DirectMessagePageState extends ConsumerState<_DirectMessagePage> {
  final _replyController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  String? get _otherMemberId {
    final current = widget.currentMemberId;
    if (current == null) return null;
    return widget.seedMessage.senderMemberId == current
        ? widget.seedMessage.recipientMemberId
        : widget.seedMessage.senderMemberId;
  }

  Future<void> _sendReply() async {
    final content = _replyController.text.trim();
    if (content.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(workerSyncServiceProvider).sendWorkerMessage(
            subject: _rootSubject(widget.seedMessage).isEmpty
                ? 'Direct message'
                : 'Re: ${_rootSubject(widget.seedMessage)}',
            content: content,
            recipientMemberId: _otherMemberId,
            recipientRole: 'manager',
          );
      _replyController.clear();
      ref.invalidate(backendSyncProvider);
      await ref.read(backendSyncProvider.future);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).couldNotPost)),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesProvider);
    final currentId = widget.currentMemberId;
    final otherId = _otherMemberId;
    final conversation = messages.where((message) {
      if (currentId == null || otherId == null) {
        return message.id == widget.seedMessage.id;
      }
      final sentByMeToOther = message.senderMemberId == currentId &&
          message.recipientMemberId == otherId;
      final sentByOtherToMe = message.senderMemberId == otherId &&
          message.recipientMemberId == currentId;
      return sentByMeToOther || sentByOtherToMe;
    }).toList()
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
    final title = widget.seedMessage.senderMemberId == currentId
        ? 'Managers'
        : widget.seedMessage.senderName;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: widget.accent,
        foregroundColor: AppColors.cardBackground,
        title: Text(title),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: conversation.length,
              itemBuilder: (context, index) {
                final message = conversation[index];
                final isMine = message.senderMemberId == currentId;
                return _DmBubble(
                  message: message,
                  isMine: isMine,
                  accent: widget.accent,
                );
              },
            ),
          ),
          if (widget.canReply)
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.cardBackground,
                  border: Border(top: BorderSide(color: AppColors.line)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText:
                              AppLocalizations.of(context).writeYourMessage,
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton.filled(
                      onPressed: _sending ? null : _sendReply,
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: widget.accent,
                        foregroundColor: AppColors.cardBackground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DmBubble extends StatelessWidget {
  const _DmBubble({
    required this.message,
    required this.isMine,
    required this.accent,
  });

  final AppMessage message;
  final bool isMine;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final photo = profilePhotoProvider(message.senderProfilePhotoUrl);
    final bubbleColor = isMine ? accent : AppColors.cardBackground;
    final textColor = isMine ? AppColors.cardBackground : AppColors.darkText;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: accent.withValues(alpha: 0.14),
              backgroundImage: photo,
              child: photo == null
                  ? Text(
                      _initials(message.senderName),
                      style: AppTypography.caption.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMine ? 18 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 18),
                ),
                border: isMine ? null : Border.all(color: AppColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: AppTypography.bodyMedium.copyWith(
                      color: textColor,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _dateLabel(message.sentAt),
                    style: AppTypography.caption.copyWith(
                      color: isMine
                          ? AppColors.cardBackground.withValues(alpha: 0.75)
                          : AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
  final _commentController = TextEditingController();
  bool _sendingComment = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment(AppMessage post) async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _sendingComment) return;

    setState(() => _sendingComment = true);
    try {
      await ref.read(workerSyncServiceProvider).sendWorkerMessage(
            subject: 'Re: ${_rootSubject(post)}',
            content: content,
            parentMessageId: post.id,
            sendToAll: true,
            messageScope: 'comment',
          );
      _commentController.clear();
      ref.invalidate(backendSyncProvider);
      await ref.read(backendSyncProvider.future);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlySendError(context, error))),
      );
    } finally {
      if (mounted) setState(() => _sendingComment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final messages = ref.watch(messagesProvider);
    final currentMessage = messages.firstWhere(
      (message) => message.id == widget.message.id,
      orElse: () => widget.message,
    );
    final comments = messages
        .where((item) =>
            item.id != currentMessage.id &&
            (item.parentMessageId == currentMessage.id ||
                widget.thread.any((threadItem) => threadItem.id == item.id)))
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
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _ThreadMessageCard(
                  message: currentMessage,
                  accent: widget.accent,
                  title: _messageTitle(currentMessage, l10n),
                  authorLabel:
                      widget.isSent ? l10n.you : currentMessage.senderName,
                  onReact: (emoji) async {
                    await ref
                        .read(messagesProvider.notifier)
                        .toggleReaction(currentMessage.id, emoji);
                    ref.invalidate(backendSyncProvider);
                  },
                  elevated: true,
                ),
                if (widget.canUseTeamHub) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.comments,
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
                        l10n.noCommentsYet,
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
                        onReact: (emoji) async {
                          await ref
                              .read(messagesProvider.notifier)
                              .toggleReaction(comment.id, emoji);
                          ref.invalidate(backendSyncProvider);
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                ],
              ],
            ),
          ),
          if (widget.canUseTeamHub && widget.canReply)
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.cardBackground,
                  border: Border(top: BorderSide(color: AppColors.line)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: l10n.addHubComment,
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton.filled(
                      onPressed: _sendingComment
                          ? null
                          : () => _sendComment(currentMessage),
                      icon: _sendingComment
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: widget.accent,
                        foregroundColor: AppColors.cardBackground,
                      ),
                    ),
                  ],
                ),
              ),
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
    final photo = profilePhotoProvider(message.senderProfilePhotoUrl);

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
                backgroundImage: photo,
                child: photo == null
                    ? Text(
                        _initials(authorLabel),
                        style: AppTypography.caption.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : null,
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
    required this.contacts,
    this.defaultToTeamHub = false,
  });

  final Color accent;
  final bool canUseTeamHub;
  final List<StaffContact> contacts;
  final bool defaultToTeamHub;

  @override
  State<_ComposeMessagePage> createState() => _ComposeMessagePageState();
}

class _ComposeMessagePageState extends State<_ComposeMessagePage> {
  late final TextEditingController _subjectController;
  final _contentController = TextEditingController();
  late _ComposeAudience _audience;
  final Set<String> _selectedContactIds = <String>{};

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController();
    _audience = widget.defaultToTeamHub
        ? _ComposeAudience.teamHub
        : _ComposeAudience.contacts;
    if (widget.contacts.length == 1) {
      _selectedContactIds.add(widget.contacts.first.id);
    }
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
    if (_audience == _ComposeAudience.contacts && _selectedContactIds.isEmpty) {
      return;
    }
    Navigator.of(context).pop(
      _ComposeResult(
        subject: subject,
        content: content,
        audience: _audience,
        recipientMemberIds: _selectedContactIds.toList(),
      ),
    );
  }

  void _applyFormat(_FormatAction action) {
    final selection = _contentController.selection;
    final text = _contentController.text;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final selected = start == end ? '' : text.substring(start, end);

    String next;
    int cursorOffset;
    switch (action) {
      case _FormatAction.attach:
        next = '[attachment]';
        cursorOffset = next.length;
      case _FormatAction.bold:
        next = selected.isEmpty ? '**bold text**' : '**$selected**';
        cursorOffset = selected.isEmpty ? 2 : next.length;
      case _FormatAction.italic:
        next = selected.isEmpty ? '_italic text_' : '_${selected}_';
        cursorOffset = selected.isEmpty ? 1 : next.length;
      case _FormatAction.strike:
        next = selected.isEmpty ? '~~text~~' : '~~$selected~~';
        cursorOffset = selected.isEmpty ? 2 : next.length;
      case _FormatAction.link:
        next = selected.isEmpty ? '[text](https://)' : '[$selected](https://)';
        cursorOffset = selected.isEmpty ? 1 : next.length - 1;
      case _FormatAction.heading:
        next = selected.isEmpty ? '## Heading' : '## $selected';
        cursorOffset = next.length;
      case _FormatAction.quote:
        next = selected.isEmpty
            ? '> Quote'
            : selected.split('\n').map((line) => '> $line').join('\n');
        cursorOffset = next.length;
      case _FormatAction.code:
        next = selected.isEmpty ? '`code`' : '`$selected`';
        cursorOffset = selected.isEmpty ? 1 : next.length;
      case _FormatAction.bullets:
        next = selected.isEmpty
            ? '- List item'
            : selected.split('\n').map((line) => '- ${line.trim()}').join('\n');
        cursorOffset = next.length;
      case _FormatAction.numbers:
        if (selected.isEmpty) {
          next = '1. List item';
        } else {
          var index = 0;
          next = selected.split('\n').map((line) {
            index += 1;
            return '$index. ${line.trim()}';
          }).join('\n');
        }
        cursorOffset = next.length;
    }

    _contentController.text = text.replaceRange(start, end, next);
    final offset = start + cursorOffset;
    _contentController.selection = TextSelection.collapsed(
      offset: offset.clamp(0, _contentController.text.length).toInt(),
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
        title: Text(l10n.writeMessage),
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
          Text(l10n.subject, style: AppTypography.headingSmall),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _subjectController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: l10n.whatIsThisAbout,
              filled: true,
              fillColor: AppColors.cardBackground,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Send to', style: AppTypography.headingSmall),
          const SizedBox(height: AppSpacing.sm),
          if (widget.canUseTeamHub)
            _AudienceOption(
              title: 'Team Hub post',
              subtitle: l10n.postEveryoneCanSee,
              value: _ComposeAudience.teamHub,
              groupValue: _audience,
              accent: widget.accent,
              onChanged: (value) => setState(() {
                _audience = value;
                _selectedContactIds.clear();
              }),
            ),
          _AudienceOption(
            title: 'Private message',
            subtitle: 'Choose exactly who should receive it.',
            value: _ComposeAudience.contacts,
            groupValue: _audience,
            accent: widget.accent,
            onChanged: (value) => setState(() => _audience = value),
          ),
          if (_audience == _ComposeAudience.contacts) ...[
            const SizedBox(height: AppSpacing.sm),
            if (widget.contacts.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.line),
                ),
                child: Text(
                  AppLocalizations.of(context).noManagerContactsYet,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.mutedText,
                  ),
                ),
              )
            else
              for (final contact in widget.contacts)
                _RecipientOption(
                  contact: contact,
                  accent: widget.accent,
                  selected: _selectedContactIds.contains(contact.id),
                  onChanged: (selected) => setState(() {
                    _audience = _ComposeAudience.contacts;
                    if (selected) {
                      _selectedContactIds.add(contact.id);
                    } else {
                      _selectedContactIds.remove(contact.id);
                    }
                  }),
                ),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (_audience == _ComposeAudience.teamHub) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.line),
              ),
              child: Text(
                l10n.postEveryoneCanSee,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text(l10n.message, style: AppTypography.headingSmall),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: [
                _FormatToolbar(
                  onFormat: _applyFormat,
                ),
                const Divider(height: 1, color: AppColors.line),
                TextField(
                  controller: _contentController,
                  minLines: 7,
                  maxLines: 12,
                  maxLength: 2000,
                  decoration: InputDecoration(
                    hintText: l10n.writeYourMessage,
                    filled: true,
                    fillColor: AppColors.cardBackground,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.all(AppSpacing.md),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: _submit,
            icon: Icon(_audience == _ComposeAudience.teamHub
                ? Icons.forum_outlined
                : Icons.send_rounded),
            label: Text(_audience == _ComposeAudience.teamHub
                    ? l10n.postToHub
                    : _selectedContactIds.length == 1
                        ? l10n.sendPrivateText
                        : 'Send private messages'),
          ),
        ],
      ),
    );
  }
}

enum _FormatAction {
  attach,
  bold,
  italic,
  strike,
  link,
  heading,
  quote,
  code,
  bullets,
  numbers,
}

class _FormatToolbar extends StatelessWidget {
  const _FormatToolbar({
    required this.onFormat,
  });

  final ValueChanged<_FormatAction> onFormat;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          _FormatButton(
            icon: Icons.attach_file_rounded,
            tooltip: 'Attachment',
            onTap: () => onFormat(_FormatAction.attach),
          ),
          _FormatButton(
            label: 'B',
            tooltip: 'Bold',
            onTap: () => onFormat(_FormatAction.bold),
          ),
          _FormatButton(
            label: 'I',
            italic: true,
            tooltip: 'Italic',
            onTap: () => onFormat(_FormatAction.italic),
          ),
          _FormatButton(
            icon: Icons.strikethrough_s_rounded,
            tooltip: 'Strikethrough',
            onTap: () => onFormat(_FormatAction.strike),
          ),
          _FormatButton(
            icon: Icons.link_rounded,
            tooltip: 'Link',
            onTap: () => onFormat(_FormatAction.link),
          ),
          _FormatButton(
            icon: Icons.title_rounded,
            tooltip: 'Heading',
            onTap: () => onFormat(_FormatAction.heading),
          ),
          _FormatButton(
            icon: Icons.format_quote_rounded,
            tooltip: 'Quote',
            onTap: () => onFormat(_FormatAction.quote),
          ),
          _FormatButton(
            icon: Icons.code_rounded,
            tooltip: 'Code',
            onTap: () => onFormat(_FormatAction.code),
          ),
          _FormatButton(
            icon: Icons.format_list_bulleted_rounded,
            tooltip: 'Bullet list',
            onTap: () => onFormat(_FormatAction.bullets),
          ),
          _FormatButton(
            icon: Icons.format_list_numbered_rounded,
            tooltip: 'Numbered list',
            onTap: () => onFormat(_FormatAction.numbers),
          ),
        ],
      ),
    );
  }
}

class _FormatButton extends StatelessWidget {
  const _FormatButton({
    required this.tooltip,
    required this.onTap,
    this.icon,
    this.label,
    this.italic = false,
  });

  final IconData? icon;
  final String? label;
  final bool italic;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 38,
          child: Center(
            child: icon != null
                ? Icon(icon, color: AppColors.darkText)
                : Text(
                    label ?? '',
                    style: AppTypography.headingSmall.copyWith(
                      color: AppColors.darkText,
                      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
        ),
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

class _RecipientOption extends StatelessWidget {
  const _RecipientOption({
    required this.contact,
    required this.accent,
    required this.selected,
    required this.onChanged,
  });

  final StaffContact contact;
  final Color accent;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final photo = profilePhotoProvider(contact.profilePhotoUrl);
    final subtitleParts = [
      contact.roleLabel,
      if (contact.phone.trim().isNotEmpty) contact.phone.trim(),
    ];

    return Material(
      color: AppColors.cardBackground,
      child: InkWell(
        onTap: () => onChanged(!selected),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: accent.withValues(alpha: 0.14),
                backgroundImage: photo,
                child: photo == null
                    ? Text(
                        contact.initials,
                        style: AppTypography.caption.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w900,
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
                      contact.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitleParts.join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: selected,
                activeColor: accent,
                onChanged: (value) => onChanged(value ?? false),
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
    this.recipientMemberIds = const [],
  });

  final String subject;
  final String content;
  final _ComposeAudience audience;
  final List<String> recipientMemberIds;
}

class _NoMessagesView extends StatelessWidget {
  const _NoMessagesView({
    required this.filter,
    this.onAction,
  });

  final _MessageFilter filter;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = switch (filter) {
      _MessageFilter.inbox => l10n.noMessagesYet,
      _MessageFilter.unread => l10n.noUnreadMessages,
      _MessageFilter.sent => l10n.noSentMessages,
      _MessageFilter.contacts => l10n.noManagerContactsYet,
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
              const SizedBox(height: AppSpacing.sm),
              Text(
                filter == _MessageFilter.inbox
                    ? 'Start a private message or pull down to refresh.'
                    : 'Pull down to refresh this list.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
              if (onAction != null) ...[
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Write message'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyHubView extends StatelessWidget {
  const _EmptyHubView({
    required this.isEnterprise,
    required this.canCreatePost,
    this.onAction,
  });

  final bool isEnterprise;
  final bool canCreatePost;
  final VoidCallback? onAction;

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
              Text(
                isEnterprise ? 'No posts yet.' : 'Posts and announcements are available on the Enterprise plan.',
                style: AppTypography.headingMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                isEnterprise
                    ? (canCreatePost
                        ? 'No posts yet. Create the first announcement for your team.'
                        : 'No posts yet. Managers and admins can publish announcements here.')
                    : 'Posts and announcements are available on the Enterprise plan. You can continue using private messages.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
              if (onAction != null) ...[
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Create post'),
                ),
              ],
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
  int get commentCount => comments.length;
}

List<_HubTopic> _buildHubTopics(
  List<AppMessage> messages,
  String? membershipId,
) {
  final byId = {for (final message in messages) message.id: message};
  final grouped = <String, List<AppMessage>>{};
  for (final message in messages) {
    final key = _topicKey(message, byId);
    grouped.putIfAbsent(key, () => []).add(message);
  }

  final topics = grouped.entries.map((entry) {
    final thread = [...entry.value]
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
    final root = thread.firstWhere(
      (message) =>
          message.parentMessageId == null && !_isReplySubject(message.subject),
      orElse: () => thread.first,
    );
    final comments = thread.where((message) => message.id != root.id).toList();
    return _HubTopic(
      key: entry.key,
      title: _rootSubject(root),
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

String _topicKey(AppMessage message, Map<String, AppMessage> byId) {
  final parentId = message.parentMessageId;
  if (parentId != null && parentId.trim().isNotEmpty) {
    final root = byId[parentId];
    if (root != null) return root.id;
    final subject = _rootSubject(message).toLowerCase().trim();
    if (subject.isNotEmpty) return subject;
    return parentId;
  }
  final subject = _rootSubject(message).toLowerCase().trim();
  if (subject.isNotEmpty) return subject;
  final firstLine = message.content
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .firstOrNull;
  return '${message.id}:${firstLine ?? message.content}'.toLowerCase();
}

String _rootSubject(AppMessage message) {
  var value = message.subject.trim();
  while (value.toLowerCase().startsWith('re:')) {
    value = value.substring(3).trim();
  }
  if (value.isNotEmpty && value.toLowerCase() != 'team update') return value;
  final firstLine = message.content
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .firstOrNull;
  return firstLine ?? '';
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
