import 'package:cloud_firestore/cloud_firestore.dart';

/// A single message inside a conversation's `messages` subcollection.
/// Feature #12 (شات مباشر), #13 (إرسال صور وملفات), #15 (حالة الرسالة).
/// Read state is NOT stored per-message (that would mean a write per
/// message per read) — instead [Conversation] stores a per-participant
/// `lastReadAt` timestamp, and a message counts as read if it's older
/// than the other participant's `lastReadAt`. See ChatScreen for where
/// that comparison happens.
///
/// A message is either text, an image, or (rarely) both — [text] can be
/// empty when [imageUrl] is set, matching how a photo-only chat message
/// normally works.
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final String imageUrl;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.imageUrl = '',
    required this.createdAt,
  });

  bool get hasImage => imageUrl.isNotEmpty;

  factory ChatMessage.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return ChatMessage(
      id: doc.id,
      senderId: (data['senderId'] as String?) ?? '',
      senderName: (data['senderName'] as String?) ?? '',
      text: (data['text'] as String?) ?? '',
      imageUrl: (data['imageUrl'] as String?) ?? '',
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      if (imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
