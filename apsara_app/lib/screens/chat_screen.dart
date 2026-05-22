import 'package:flutter/material.dart';

import '../models/conversation.dart';
import '../theme/app_theme.dart';
import '../utils/text_utils.dart';
import '../widgets/empty_state.dart';
import '../widgets/pills.dart';
import '../widgets/typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversations,
    required this.onSend,
  });

  final List<Conversation> conversations;
  final void Function(Conversation conversation, String text) onSend;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  Conversation? _activeConversation;
  final _message = TextEditingController();

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeConversation;
    if (active != null) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 14, 8),
            child: Row(
              children: [
                IconButton(
                    onPressed: () => setState(() => _activeConversation = null),
                    icon: const Icon(Icons.arrow_back)),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.text,
                  child: Text(initialFor(active.sellerName),
                      style: const TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(active.sellerName,
                          style: const TextStyle(fontWeight: FontWeight.w900)),
                      Text(
                        active.online ? 'Active now' : 'Last seen recently',
                        style: TextStyle(
                            color: active.online
                                ? AppColors.success
                                : AppColors.textLight,
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.call_outlined),
                const SizedBox(width: 16),
                const Icon(Icons.more_vert),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              children: [
                const Center(child: Pill(label: 'Today, 10:42 AM')),
                const SizedBox(height: 12),
                for (final message in active.messages)
                  MessageBubble(message: message),
                const Padding(
                  padding: EdgeInsets.only(left: 4, top: 6),
                  child: TypingDots(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
            child: Row(
              children: [
                const Icon(Icons.add_circle_outline,
                    color: AppColors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _message,
                    decoration:
                        const InputDecoration(hintText: 'Type a message...'),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 25,
                  backgroundColor: AppColors.primary,
                  child: IconButton(
                    color: Colors.white,
                    onPressed: () {
                      final text = _message.text.trim();
                      if (text.isEmpty) return;
                      widget.onSend(active, text);
                      _message.clear();
                    },
                    icon: const Icon(Icons.send),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 96),
      children: [
        const Text(
          'Messages',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 24),
        if (widget.conversations.isEmpty)
          const EmptyState(
            icon: Icons.mode_comment_outlined,
            title: 'No messages yet',
            subtitle: 'Start a conversation from any post',
          )
        else
          for (final conversation in widget.conversations)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              onTap: () => setState(() => _activeConversation = conversation),
              leading: Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.text,
                    child: Text(initialFor(conversation.sellerName),
                        style: const TextStyle(color: Colors.white)),
                  ),
                  if (conversation.online)
                    Positioned(
                      right: 0,
                      bottom: 2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              title: Text(conversation.sellerName,
                  style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text(
                conversation.messages.isEmpty
                    ? 'Tap to start chatting'
                    : conversation.messages.last.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                conversation.messages.isEmpty
                    ? ''
                    : conversation.messages.last.time,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800),
              ),
            ),
      ],
    );
  }
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
  });

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: message.isMe ? AppColors.primary : AppColors.soft,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(message.isMe ? 14 : 4),
            bottomRight: Radius.circular(message.isMe ? 4 : 14),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
              color: message.isMe ? Colors.white : AppColors.text,
              height: 1.35),
        ),
      ),
    );
  }
}
