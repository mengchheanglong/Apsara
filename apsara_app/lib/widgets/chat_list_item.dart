import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/message_model.dart';
import '../theme/app_theme.dart';
import 'app_cached_media.dart';

class ChatListItem extends StatelessWidget {
  const ChatListItem({
    super.key,
    required this.room,
    required this.currentUserId,
    required this.onTap,
    this.peer,
    this.onLongPress,
  });

  final ChatRoomPreview room;
  final String currentUserId;
  final VoidCallback onTap;
  final ChatPeer? peer;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final visiblePeer = peer ?? room.otherParticipant(currentUserId);
    final unread = room.unreadCountFor(currentUserId);
    final isTyping = room.typingUsers.entries.any(
      (entry) => entry.key != currentUserId && entry.value,
    );
    final preview = isTyping
        ? 'Typing...'
        : room.lastMessageType == MessageType.image
            ? 'Photo'
            : room.lastMessage;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 7),
      onTap: onTap,
      onLongPress: onLongPress,
      leading: AppAvatar(
        displayName: visiblePeer.displayName,
        imageUrl: visiblePeer.avatarUrl,
        radius: 24,
        backgroundColor: AppColors.chatAccent,
      ),
      title: Text(
        visiblePeer.displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        preview.isEmpty ? 'No messages yet' : preview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isTyping ? AppColors.chatAccent : AppColors.textSecondary,
          fontSize: 12.5,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _timeLabel(room.updatedAt),
            style: const TextStyle(color: AppColors.textLight, fontSize: 11),
          ),
          if (unread > 0) ...[
            const SizedBox(height: 6),
            CircleAvatar(
              radius: 10,
              backgroundColor: AppColors.chatOutgoing,
              child: Text(
                unread > 9 ? '9+' : unread.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _timeLabel(DateTime? value) {
    if (value == null) {
      return '';
    }
    final now = DateTime.now();
    if (DateUtils.isSameDay(now, value)) {
      return DateFormat.jm().format(value);
    }
    return DateFormat.MMMd().format(value);
  }
}
