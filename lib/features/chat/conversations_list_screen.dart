import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/app_user.dart';
import '../../models/conversation.dart';
import '../../services/chat_repository.dart';
import '../../services/storage_repository.dart';
import 'chat_screen.dart';

/// Feature #12 entry point — every deal-scoped chat thread the signed-in
/// trader is part of (as buyer or seller), newest first.
class ConversationsListScreen extends StatelessWidget {
  const ConversationsListScreen({
    super.key,
    required this.chatRepository,
    required this.storageRepository,
    required this.currentUser,
  });

  final ChatRepository chatRepository;
  final StorageRepository storageRepository;
  final AppUser currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('محادثاتي')),
      body: StreamBuilder<List<Conversation>>(
        stream: chatRepository.watchConversations(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final conversations = snapshot.data ?? const [];
          if (conversations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.forum_outlined, size: 40, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text('ما عندك محادثات بعد', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'اضغط "اطلب عرض سعر" من أي منتج بالسوق تبدأ محادثة.',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: conversations.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final c = conversations[index];
              final unread = c.isUnreadFor(currentUser.uid);
              return _ConversationTile(
                conversation: c,
                currentUserId: currentUser.uid,
                unread: unread,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      chatRepository: chatRepository,
                      storageRepository: storageRepository,
                      currentUser: currentUser,
                      conversation: c,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
    required this.unread,
    required this.onTap,
  });

  final Conversation conversation;
  final String currentUserId;
  final bool unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final otherName = conversation.otherPartyName(currentUserId);
    final timeLabel = DateFormat.Hm('ar').format(conversation.lastMessageAt);
    final youSentLast = conversation.lastMessageSenderId == currentUserId;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.surfaceAlt,
        child: Text(
          otherName.isNotEmpty ? otherName.substring(0, 1) : '؟',
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy),
        ),
      ),
      title: Text(
        otherName,
        style: TextStyle(fontWeight: unread ? FontWeight.w800 : FontWeight.w600),
      ),
      subtitle: Text(
        '${conversation.productName} · ${youSentLast ? "أنت: " : ""}${conversation.lastMessage}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: unread ? AppColors.textPrimary : AppColors.textMuted,
          fontWeight: unread ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(timeLabel, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          if (unread) ...[
            const SizedBox(height: 6),
            Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
            ),
          ],
        ],
      ),
    );
  }
}
