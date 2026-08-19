import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/app_user.dart';
import '../../models/chat_message.dart';
import '../../models/conversation.dart';
import '../../services/chat_repository.dart';
import '../../services/storage_repository.dart';

/// Feature #12 (شات مباشر) + #13 (إرسال صور وملفات) + #15 (حالة الرسالة:
/// تم الإرسال / تم القراءة).
///
/// "تم الإرسال" is implicit — a message appearing in the stream at all
/// means Firestore accepted the write. "تم القراءة" is derived by
/// comparing the OTHER participant's `lastReadAt` against this message's
/// `createdAt` (see [Conversation.isUnreadFor] for the mirror-image logic
/// used in the conversations list).
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.chatRepository,
    required this.storageRepository,
    required this.currentUser,
    required this.conversation,
  });

  final ChatRepository chatRepository;
  final StorageRepository storageRepository;
  final AppUser currentUser;
  final Conversation conversation;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sendingText = false;
  bool _sendingImage = false;

  @override
  void initState() {
    super.initState();
    // Fire-and-forget: opening the thread is what "read" means here.
    widget.chatRepository.markAsRead(
      conversationId: widget.conversation.id,
      uid: widget.currentUser.uid,
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    final text = _textController.text;
    if (text.trim().isEmpty || _sendingText) return;
    setState(() => _sendingText = true);
    _textController.clear();
    try {
      await widget.chatRepository.sendMessage(
        conversationId: widget.conversation.id,
        sender: widget.currentUser,
        text: text,
      );
    } finally {
      if (mounted) setState(() => _sendingText = false);
    }
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    setState(() => _sendingImage = true);
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: source, imageQuality: 82, maxWidth: 1600);
      if (file == null) return; // user cancelled

      final bytes = await file.readAsBytes();
      final path =
          'chat/${widget.conversation.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final url = await widget.storageRepository.uploadImage(path: path, bytes: bytes);

      await widget.chatRepository.sendMessage(
        conversationId: widget.conversation.id,
        sender: widget.currentUser,
        text: '',
        imageUrl: url,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تعذّر إرسال الصورة. حاول مرة ثانية.')));
      }
    } finally {
      if (mounted) setState(() => _sendingImage = false);
    }
  }

  void _showAttachSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.navy),
              title: const Text('التقاط صورة بالكاميرا'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAndSendImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.navy),
              title: const Text('اختيار من المعرض'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAndSendImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final other = widget.conversation.otherPartyName(widget.currentUser.uid);
    final isBuyer = widget.currentUser.uid == widget.conversation.buyerId;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(other, style: const TextStyle(fontSize: 15)),
            Text(
              widget.conversation.productName,
              style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.normal),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_sendingImage)
            const LinearProgressIndicator(minHeight: 2, color: AppColors.gold),
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: widget.chatRepository.watchMessages(widget.conversation.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data ?? const [];

                // Whichever side we're NOT on tells us when the other
                // party last read — used to show "تم القراءة" under our
                // own most recent message.
                final otherLastRead =
                    isBuyer ? widget.conversation.sellerLastReadAt : widget.conversation.buyerLastReadAt;

                // Find the index of our own last message so only THAT
                // bubble gets a read-receipt label (matches how WhatsApp/
                // iMessage-style chats behave — not every bubble needs one).
                int lastOwnMessageIndex = -1;
                for (var i = messages.length - 1; i >= 0; i--) {
                  if (messages[i].senderId == widget.currentUser.uid) {
                    lastOwnMessageIndex = i;
                    break;
                  }
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(14),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final m = messages[index];
                    final isMe = m.senderId == widget.currentUser.uid;
                    final showRead = isMe &&
                        index == lastOwnMessageIndex &&
                        otherLastRead != null &&
                        otherLastRead.isAfter(m.createdAt);
                    return _MessageBubble(message: m, isMe: isMe, showReadReceipt: showRead);
                  },
                );
              },
            ),
          ),
          _Composer(
            controller: _textController,
            sending: _sendingText,
            onSend: _sendText,
            onAttach: _showAttachSheet,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMe, required this.showReadReceipt});

  final ChatMessage message;
  final bool isMe;
  final bool showReadReceipt;

  @override
  Widget build(BuildContext context) {
    final timeLabel = DateFormat.Hm('ar').format(message.createdAt);
    return Align(
      alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: message.hasImage
            ? const EdgeInsets.all(6)
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMe ? AppColors.navy : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 4 : 16),
            bottomRight: Radius.circular(isMe ? 16 : 4),
          ),
          border: isMe ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  message.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const SizedBox(
                      width: 180,
                      height: 180,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    width: 180,
                    height: 180,
                    color: AppColors.surfaceAlt,
                    child: const Icon(Icons.broken_image_outlined, color: AppColors.textMuted),
                  ),
                ),
              ),
            if (message.text.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: message.hasImage ? 6 : 0, right: message.hasImage ? 6 : 0, left: message.hasImage ? 6 : 0),
                child: Text(
                  message.text,
                  style: TextStyle(color: isMe ? Colors.white : AppColors.textPrimary, fontSize: 14),
                ),
              ),
            Padding(
              padding: EdgeInsets.only(top: 4, right: message.hasImage ? 6 : 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeLabel,
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white70 : AppColors.textMuted,
                    ),
                  ),
                  if (showReadReceipt) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.done_all, size: 13, color: AppColors.goldLight),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.onAttach,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 8, 10, 8),
        child: Row(
          children: [
            IconButton(
              onPressed: onAttach,
              icon: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.navy),
              tooltip: 'إرسال صورة',
            ),
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'اكتب رسالة...',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: sending ? null : onSend,
              style: IconButton.styleFrom(backgroundColor: AppColors.navy),
              icon: sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send, size: 18, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
