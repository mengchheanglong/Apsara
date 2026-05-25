import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/message_model.dart';
import '../theme/app_theme.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.peerId,
  });

  final MessageModel message;
  final bool isMine;
  final String peerId;

  @override
  Widget build(BuildContext context) {
    final bubbleColor =
        isMine ? AppColors.chatOutgoing : AppColors.chatIncoming;
    final textColor = isMine ? Colors.white : AppColors.text;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 8),
        constraints: const BoxConstraints(maxWidth: 292),
        padding: EdgeInsets.all(message.type == MessageType.image ? 4 : 11),
        decoration: BoxDecoration(
          color: bubbleColor,
          border:
              isMine ? null : Border.all(color: AppColors.chatIncomingBorder),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMine ? 18 : 5),
            bottomRight: Radius.circular(isMine ? 5 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message.type == MessageType.image)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CachedNetworkImage(
                  imageUrl: message.imageUrl,
                  width: 230,
                  height: 260,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width: 230,
                    height: 260,
                    color: AppColors.soft,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 230,
                    height: 180,
                    color: AppColors.soft,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              )
            else
              Text(
                message.text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            const SizedBox(height: 5),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _timeLabel(message.timestamp),
                  style: TextStyle(
                    color: isMine ? Colors.white70 : AppColors.textLight,
                    fontSize: 10.5,
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  _ReceiptIcon(message: message, peerId: peerId),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _timeLabel(DateTime? value) {
    if (value == null) {
      return 'Now';
    }
    return DateFormat.jm().format(value);
  }
}

class _ReceiptIcon extends StatelessWidget {
  const _ReceiptIcon({
    required this.message,
    required this.peerId,
  });

  final MessageModel message;
  final String peerId;

  @override
  Widget build(BuildContext context) {
    if (message.localStatus == LocalMessageStatus.failed) {
      return const Icon(Icons.error_outline, size: 14, color: Colors.white70);
    }
    if (message.localStatus == LocalMessageStatus.sending) {
      return const SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 1.7,
          color: Colors.white70,
        ),
      );
    }

    if (message.wasReadBy(peerId)) {
      return const Icon(Icons.done_all, size: 15, color: AppColors.chatRead);
    }
    if (message.wasDeliveredTo(peerId)) {
      return const Icon(Icons.done_all, size: 15, color: Colors.white70);
    }
    return const Icon(Icons.done, size: 15, color: Colors.white70);
  }
}
