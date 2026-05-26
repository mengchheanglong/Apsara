import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/message_model.dart';
import '../models/user_profile.dart';
import '../services/chat_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_logger.dart';
import '../widgets/app_cached_media.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/empty_state.dart';
import '../widgets/message_input.dart';
import '../widgets/typing_indicator.dart';
import 'public_user_profile_screen.dart';

class ChatRoomView extends StatefulWidget {
  const ChatRoomView({
    super.key,
    required this.currentUser,
    required this.currentProfile,
    required this.peer,
    required this.onBack,
  });

  final User currentUser;
  final UserProfile currentProfile;
  final ChatPeer peer;
  final VoidCallback onBack;

  @override
  State<ChatRoomView> createState() => _ChatRoomViewState();
}

class _ChatRoomViewState extends State<ChatRoomView> {
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final List<MessageModel> _olderMessages = [];
  final List<MessageModel> _pendingMessages = [];
  StreamSubscription<List<MessageModel>>? _messagesSubscription;
  List<MessageModel> _liveMessages = const [];
  bool _isLoadingMessages = true;
  Object? _roomError;
  bool _isLoadingOlder = false;
  bool _hasMoreOlder = true;
  bool _didInitialScroll = false;

  String get _roomId => ChatService.instance.roomIdFor(
        widget.currentUser.uid,
        widget.peer.uid,
      );

  List<MessageModel> get _messages {
    final byId = <String, MessageModel>{
      for (final message in _olderMessages) message.id: message,
      for (final message in _liveMessages) message.id: message,
      for (final message in _pendingMessages) message.id: message,
    };
    final messages = byId.values.toList();
    messages.sort((a, b) {
      final aTime = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aTime.compareTo(bTime);
    });
    return messages;
  }

  @override
  void initState() {
    super.initState();
    _startRoom();
    _scrollController.addListener(_handleScroll);
    _focusNode.addListener(_handleKeyboardFocus);
  }

  @override
  void didUpdateWidget(covariant ChatRoomView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.peer.uid != widget.peer.uid) {
      _olderMessages.clear();
      _pendingMessages.clear();
      _liveMessages = const [];
      _isLoadingMessages = true;
      _roomError = null;
      _hasMoreOlder = true;
      _didInitialScroll = false;
      _messagesSubscription?.cancel();
      _startRoom();
    }
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _scrollController.dispose();
    _focusNode.dispose();
    ChatService.instance.setTyping(
      roomId: _roomId,
      userId: widget.currentUser.uid,
      isTyping: false,
    );
    super.dispose();
  }

  Future<void> _startRoom() async {
    try {
      await ChatService.instance.ensureRoom(
        currentUser: widget.currentProfile,
        peer: widget.peer,
      );
    } catch (error) {
      AppLogger.warn('Chat room start failed', error);
      if (mounted) {
        setState(() {
          _roomError = error;
          _isLoadingMessages = false;
        });
      }
      return;
    }

    if (!mounted) {
      return;
    }

    _messagesSubscription = ChatService.instance
        .getMessagesStream(_roomId)
        .listen(_handleLiveMessages, onError: (error) {
      if (mounted) {
        setState(() {
          _roomError = error;
          _isLoadingMessages = false;
        });
      }
    });
    unawaited(_markRead());
  }

  void _handleLiveMessages(List<MessageModel> messages) {
    final hadMessages = _messages.isNotEmpty;
    final confirmedNonces = messages
        .map((message) => message.clientNonce)
        .whereType<String>()
        .toSet();
    setState(() {
      _liveMessages = messages;
      _isLoadingMessages = false;
      _roomError = null;
      _pendingMessages.removeWhere(
        (message) => confirmedNonces.contains(message.clientNonce),
      );
    });
    unawaited(_markRead());
    if (!_didInitialScroll || _isNearBottom || !hadMessages) {
      _scrollToBottom();
    }
    _didInitialScroll = true;
  }

  Future<void> _markRead() {
    return ChatService.instance.markMessagesRead(
      roomId: _roomId,
      currentUserId: widget.currentUser.uid,
    );
  }

  bool get _isNearBottom {
    if (!_scrollController.hasClients) {
      return true;
    }
    return _scrollController.position.maxScrollExtent -
            _scrollController.offset <
        220;
  }

  Future<void> _loadOlderMessages() async {
    if (_isLoadingOlder || !_hasMoreOlder || _messages.isEmpty) {
      return;
    }
    final firstTimestamp = _messages.first.timestamp;
    if (firstTimestamp == null) {
      return;
    }

    setState(() => _isLoadingOlder = true);
    final previousMaxScroll = _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent
        : 0.0;

    try {
      final older = await ChatService.instance.getOlderMessages(
        roomId: _roomId,
        before: firstTimestamp,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _hasMoreOlder = older.length == ChatService.pageSize;
        _olderMessages.insertAll(0, older);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) {
          return;
        }
        final diff =
            _scrollController.position.maxScrollExtent - previousMaxScroll;
        _scrollController.jumpTo(_scrollController.offset + diff);
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingOlder = false);
      }
    }
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    if (_scrollController.offset <= 120) {
      unawaited(_loadOlderMessages());
    }
  }

  void _handleKeyboardFocus() {
    if (_focusNode.hasFocus) {
      _scrollToBottom(delay: const Duration(milliseconds: 220));
    }
  }

  void _scrollToBottom({Duration delay = const Duration(milliseconds: 40)}) {
    Future<void>.delayed(delay, () {
      if (!_scrollController.hasClients || !mounted) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = _messages;
    final isSelfChat = widget.peer.uid == widget.currentUser.uid;
    return Column(
      children: [
        _ChatAppBar(
          fallbackPeer: widget.peer,
          onBack: widget.onBack,
          isSelfChat: isSelfChat,
        ),
        const Divider(height: 1),
        Expanded(
          child: Container(
            color: AppColors.chatCanvas,
            child: StreamBuilder<bool>(
              stream: ChatService.instance.watchTyping(
                roomId: _roomId,
                peerId: widget.peer.uid,
              ),
              builder: (context, typingSnapshot) {
                final isTyping = typingSnapshot.data == true;
                if (_roomError != null && messages.isEmpty) {
                  return Column(
                    children: [
                      const Expanded(
                        child: EmptyState(
                          icon: Icons.wifi_tethering_error_rounded,
                          title: 'Chat is unavailable',
                          subtitle: 'Check your connection and try again',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TextButton(
                          onPressed: _retryRoom,
                          child: const Text('Retry'),
                        ),
                      ),
                    ],
                  );
                }
                if (_isLoadingMessages && messages.isEmpty) {
                  return const _ChatRoomLoading();
                }
                if (messages.isEmpty) {
                  return Column(
                    children: [
                      const Expanded(
                        child: EmptyState(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'Start the conversation',
                          subtitle: 'Send a message or photo',
                        ),
                      ),
                      if (isTyping)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: TypingDots(),
                          ),
                        ),
                    ],
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  itemCount: messages.length +
                      (isTyping ? 1 : 0) +
                      (_isLoadingOlder ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isLoadingOlder && index == 0) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }
                    final adjustedIndex = index - (_isLoadingOlder ? 1 : 0);
                    if (adjustedIndex >= messages.length) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: TypingDots(),
                        ),
                      );
                    }

                    final message = messages[adjustedIndex];
                    final previous =
                        adjustedIndex == 0 ? null : messages[adjustedIndex - 1];
                    final showDate = _shouldShowDate(previous, message);

                    return Column(
                      children: [
                        if (showDate) _DateSeparator(date: message.timestamp),
                        ChatBubble(
                          message: message,
                          isMine: message.isFrom(widget.currentUser.uid),
                          peerId: widget.peer.uid,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
        MessageInput(
          focusNode: _focusNode,
          onSendText: _sendText,
          onSendImage: _sendImage,
          onTypingChanged: _setTyping,
          quickActions: _quickActionsFor(messages.isEmpty, isSelfChat),
        ),
      ],
    );
  }

  List<String> _quickActionsFor(bool isEmptyChat, bool isSelfChat) {
    if (!isEmptyChat || isSelfChat) {
      return const [];
    }
    return const [
      'Is this still available?',
      'Can you share more details?',
      'What is your best price?',
    ];
  }

  bool _shouldShowDate(MessageModel? previous, MessageModel current) {
    final currentDate = current.timestamp;
    if (currentDate == null) {
      return false;
    }
    final previousDate = previous?.timestamp;
    if (previousDate == null) {
      return true;
    }
    return !DateUtils.isSameDay(previousDate, currentDate);
  }

  Future<void> _sendText(String text) async {
    final nonce = _newClientNonce();
    _addPendingMessage(MessageModel(
      id: 'pending_$nonce',
      senderId: widget.currentUser.uid,
      senderEmail: widget.currentUser.email ?? '',
      receiverId: widget.peer.uid,
      text: text,
      imageUrl: '',
      timestamp: DateTime.now(),
      isRead: false,
      type: MessageType.text,
      deliveredTo: {widget.currentUser.uid: true},
      readBy: {widget.currentUser.uid: true},
      localStatus: LocalMessageStatus.sending,
      clientNonce: nonce,
    ));
    try {
      await ChatService.instance.sendMessage(
        currentUser: widget.currentProfile,
        peer: widget.peer,
        text: text,
        clientNonce: nonce,
      );
    } catch (error, stackTrace) {
      AppLogger.warn('Chat message send failed', error, stackTrace);
      _markPendingFailed(nonce);
      rethrow;
    }
    _scrollToBottom();
  }

  Future<void> _sendImage(
    File imageFile,
    ValueChanged<double> onProgress,
  ) async {
    final nonce = _newClientNonce();
    try {
      await ChatService.instance.sendImage(
        currentUser: widget.currentProfile,
        peer: widget.peer,
        imageFile: imageFile,
        clientNonce: nonce,
        onProgress: onProgress,
      );
    } catch (error, stackTrace) {
      AppLogger.warn('Chat image send failed', error, stackTrace);
      _markPendingFailed(nonce);
      rethrow;
    }
    _scrollToBottom();
  }

  void _setTyping(bool isTyping) {
    unawaited(ChatService.instance.setTyping(
      roomId: _roomId,
      userId: widget.currentUser.uid,
      isTyping: isTyping,
    ));
  }

  String _newClientNonce() {
    return '${widget.currentUser.uid}_${DateTime.now().microsecondsSinceEpoch}';
  }

  void _addPendingMessage(MessageModel message) {
    setState(() => _pendingMessages.add(message));
    _scrollToBottom();
  }

  void _markPendingFailed(String nonce) {
    setState(() {
      final index = _pendingMessages.indexWhere(
        (message) => message.clientNonce == nonce,
      );
      if (index == -1) {
        return;
      }
      _pendingMessages[index] = _pendingMessages[index].copyWith(
        localStatus: LocalMessageStatus.failed,
      );
    });
  }

  void _retryRoom() {
    _messagesSubscription?.cancel();
    setState(() {
      _roomError = null;
      _isLoadingMessages = true;
      _isLoadingOlder = false;
      _hasMoreOlder = true;
      _didInitialScroll = false;
      _olderMessages.clear();
      _pendingMessages.clear();
      _liveMessages = const [];
    });
    _startRoom();
  }
}

class _ChatAppBar extends StatelessWidget {
  const _ChatAppBar({
    required this.fallbackPeer,
    required this.onBack,
    required this.isSelfChat,
  });

  final ChatPeer fallbackPeer;
  final VoidCallback onBack;
  final bool isSelfChat;

  @override
  Widget build(BuildContext context) {
    if (fallbackPeer.uid.isEmpty) {
      return _ChatAppBarContent(
        peer: fallbackPeer,
        onBack: onBack,
        isSelfChat: isSelfChat,
      );
    }

    return StreamBuilder<UserProfile?>(
      stream: ProfileService.instance.watchUserProfileById(fallbackPeer.uid),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final peer = profile == null
            ? fallbackPeer
            : ChatPeer(
                uid: profile.uid,
                displayName: profile.displayName,
                email: profile.email,
                avatarUrl: profile.avatarUrl,
              );
        return _ChatAppBarContent(
          peer: peer,
          onBack: onBack,
          isSelfChat: isSelfChat,
        );
      },
    );
  }
}

class _ChatAppBarContent extends StatelessWidget {
  const _ChatAppBarContent({
    required this.peer,
    required this.onBack,
    required this.isSelfChat,
  });

  final ChatPeer peer;
  final VoidCallback onBack;
  final bool isSelfChat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 2, 14, 8),
      child: Row(
        children: [
          IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: peer.uid.isEmpty
                  ? null
                  : () => _openUserProfile(context, peer),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    AppAvatar(
                      displayName: peer.displayName,
                      imageUrl: peer.avatarUrl,
                      radius: 19,
                      backgroundColor: AppColors.text,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            peer.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            isSelfChat ? 'Notes to self' : 'Apsara chat',
                            style: const TextStyle(
                              color: AppColors.textLight,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openUserProfile(BuildContext context, ChatPeer peer) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PublicUserProfileScreen(
          userId: peer.uid,
          fallbackName: peer.displayName,
          fallbackAvatarUrl: peer.avatarUrl,
        ),
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date});

  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final value = date;
    if (value == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.soft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Text(
              _label(value),
              style: const TextStyle(color: AppColors.textLight, fontSize: 11),
            ),
          ),
        ),
      ),
    );
  }

  String _label(DateTime value) {
    final now = DateTime.now();
    if (DateUtils.isSameDay(now, value)) {
      return 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (DateUtils.isSameDay(yesterday, value)) {
      return 'Yesterday';
    }
    return DateFormat.yMMMd().format(value);
  }
}

class _ChatRoomLoading extends StatelessWidget {
  const _ChatRoomLoading();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.55, end: 1),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeInOut,
      builder: (context, opacity, child) {
        return Opacity(opacity: opacity, child: child);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 20, 14, 14),
        children: const [
          Align(
            alignment: Alignment.centerLeft,
            child: _LoadingBubble(width: 180),
          ),
          SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: _LoadingBubble(width: 226, isMine: true),
          ),
          SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: _LoadingBubble(width: 140),
          ),
        ],
      ),
    );
  }
}

class _LoadingBubble extends StatelessWidget {
  const _LoadingBubble({
    required this.width,
    this.isMine = false,
  });

  final double width;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMine ? AppColors.chatOutgoingSoft : AppColors.chatIncoming,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMine ? 18 : 5),
          bottomRight: Radius.circular(isMine ? 5 : 18),
        ),
        border: isMine ? null : Border.all(color: AppColors.chatIncomingBorder),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBar(widthFactor: 0.82, height: 9),
          SizedBox(height: 8),
          _SkeletonBar(widthFactor: 0.52, height: 9),
        ],
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({
    required this.widthFactor,
    this.height = 11,
  });

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.chatIncoming,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
