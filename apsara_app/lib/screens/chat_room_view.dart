import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
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
  ChatRoomView({
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
  List<MessageModel> _liveMessages = [];
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
    _restoreCachedRoom();
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
      _liveMessages = [];
      _isLoadingMessages = true;
      _roomError = null;
      _hasMoreOlder = true;
      _didInitialScroll = false;
      _messagesSubscription?.cancel();
      _restoreCachedRoom();
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

  void _restoreCachedRoom() {
    final cached = ChatService.instance.cachedRoomState(_roomId);
    if (cached == null || cached.messages.isEmpty) {
      return;
    }

    _olderMessages
      ..clear()
      ..addAll(cached.messages);
    _liveMessages = [];
    _isLoadingMessages = false;
    _roomError = null;
    _hasMoreOlder = cached.hasMoreOlder;
    _didInitialScroll = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _prefetchMessageImages(cached.messages);
      _scrollToBottom(delay: Duration.zero, animate: false);
    });
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
    _cacheCurrentRoomState();
    unawaited(_markRead());
    _prefetchMessageImages(messages);
    if (!_didInitialScroll) {
      _scrollToBottom(delay: Duration.zero, animate: false);
    } else if (_isNearBottom || !hadMessages) {
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
    return _scrollController.offset <= 220;
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
      _cacheCurrentRoomState();
      _prefetchMessageImages(older);
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
    if (_scrollController.position.maxScrollExtent - _scrollController.offset <=
        120) {
      unawaited(_loadOlderMessages());
    }
  }

  void _handleKeyboardFocus() {
    if (_focusNode.hasFocus) {
      _scrollToBottom(delay: const Duration(milliseconds: 220));
    }
  }

  void _scrollToBottom({
    Duration delay = const Duration(milliseconds: 40),
    bool animate = true,
  }) {
    Future<void>.delayed(delay, () {
      if (!_scrollController.hasClients || !mounted) {
        return;
      }
      final target = _scrollController.position.minScrollExtent;
      if (!animate) {
        _scrollController.jumpTo(target);
        return;
      }
      _scrollController.animateTo(
        target,
        duration: Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = _messages;
    return Column(
      children: [
        _ChatAppBar(
          fallbackPeer: widget.peer,
          onBack: widget.onBack,
        ),
        Divider(height: 1),
        Expanded(
          child: Container(
            color: context.appColors.chatCanvas,
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
                      Expanded(
                        child: EmptyState(
                          icon: Icons.wifi_tethering_error_rounded,
                          title: 'Chat is unavailable',
                          subtitle: 'Check your connection and try again',
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: TextButton(
                          onPressed: _retryRoom,
                          child: Text('Retry'),
                        ),
                      ),
                    ],
                  );
                }
                if (_isLoadingMessages && messages.isEmpty) {
                  return _ChatRoomLoading();
                }
                if (messages.isEmpty) {
                  return Column(
                    children: [
                      Expanded(
                        child: EmptyState(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'Start the conversation',
                          subtitle: 'Send a message or photo',
                        ),
                      ),
                      if (isTyping)
                        Padding(
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
                  reverse: true,
                  padding: EdgeInsets.fromLTRB(14, 12, 14, 14),
                  itemCount: messages.length +
                      (isTyping ? 1 : 0) +
                      (_isLoadingOlder ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (isTyping && index == 0) {
                      return Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: TypingDots(),
                        ),
                      );
                    }

                    final messageIndex = index - (isTyping ? 1 : 0);
                    if (_isLoadingOlder && messageIndex >= messages.length) {
                      return SizedBox(height: 12);
                    }

                    final reversedIndex = messages.length - 1 - messageIndex;
                    final message = messages[reversedIndex];
                    final previous =
                        reversedIndex == 0 ? null : messages[reversedIndex - 1];
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
          quickActions: [],
        ),
      ],
    );
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
    _cacheCurrentRoomState();
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
    _cacheCurrentRoomState();
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
      _liveMessages = [];
    });
    _startRoom();
  }

  void _cacheCurrentRoomState() {
    ChatService.instance.cacheRoomState(
      roomId: _roomId,
      messages: _messages,
      hasMoreOlder: _hasMoreOlder,
    );
  }

  void _prefetchMessageImages(List<MessageModel> messages) {
    for (final message in messages.where((item) =>
        item.type == MessageType.image && item.imageUrl.trim().isNotEmpty)) {
      unawaited(
        precacheImage(
          CachedNetworkImageProvider(message.imageUrl.trim()),
          context,
        ).catchError((_) {}),
      );
    }
  }
}

class _ChatAppBar extends StatelessWidget {
  _ChatAppBar({
    required this.fallbackPeer,
    required this.onBack,
  });

  final ChatPeer fallbackPeer;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    if (fallbackPeer.uid.isEmpty) {
      return _ChatAppBarContent(
        peer: fallbackPeer,
        onBack: onBack,
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
        );
      },
    );
  }
}

class _ChatAppBarContent extends StatelessWidget {
  _ChatAppBarContent({
    required this.peer,
    required this.onBack,
  });

  final ChatPeer peer;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(6, 2, 14, 8),
      child: Row(
        children: [
          IconButton(onPressed: onBack, icon: Icon(Icons.arrow_back)),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: peer.uid.isEmpty
                  ? null
                  : () => _openUserProfile(context, peer),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    AppAvatar(
                      displayName: peer.displayName,
                      imageUrl: peer.avatarUrl,
                      radius: 19,
                      backgroundColor: context.appColors.text,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        peer.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
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
  _DateSeparator({required this.date});

  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final value = date;
    if (value == null) {
      return SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.appColors.soft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Text(
              _label(value),
              style:
                  TextStyle(color: context.appColors.textLight, fontSize: 11),
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
    final yesterday = now.subtract(Duration(days: 1));
    if (DateUtils.isSameDay(yesterday, value)) {
      return 'Yesterday';
    }
    return DateFormat.yMMMd().format(value);
  }
}

class _ChatRoomLoading extends StatelessWidget {
  _ChatRoomLoading();

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand();
  }
}
