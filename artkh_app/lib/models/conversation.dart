class Conversation {
  Conversation({
    required this.sellerId,
    required this.sellerName,
    required this.online,
    required this.messages,
  });

  final int sellerId;
  final String sellerName;
  final bool online;
  final List<ChatMessage> messages;
}

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.time,
    required this.isMe,
  });

  final String text;
  final String time;
  final bool isMe;
}
