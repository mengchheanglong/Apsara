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
import '../utils/text_utils.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_list_item.dart';
import '../widgets/empty_state.dart';
import '../widgets/message_input.dart';
import '../widgets/typing_indicator.dart';
import 'public_user_profile_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.currentUser,
    required this.currentProfile,
    this.initialPeer,
    this.onInitialPeerConsumed,
  });

  final User currentUser;
  final UserProfile currentProfile;
  final ChatPeer? initialPeer;
  final VoidCallback? onInitialPeerConsumed;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  ChatPeer? _activePeer;
  final _searchController = TextEditingController();
  StreamSubscription<List<ChatRoomPreview>>? _roomsSubscription;
  List<ChatRoomPreview> _rooms = const [];
  bool _isLoadingRooms = true;
  Object? _roomsError;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _consumeInitialPeer();
    _watchRooms();
  }

  @override
  void didUpdateWidget(covariant ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentUser.uid != oldWidget.currentUser.uid) {
      _watchRooms();
    }
    if (widget.initialPeer?.uid != oldWidget.initialPeer?.uid) {
      _consumeInitialPeer();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _roomsSubscription?.cancel();
    super.dispose();
  }

  void _watchRooms() {
    _roomsSubscription?.cancel();
    setState(() {
      _isLoadingRooms = true;
      _roomsError = null;
    });
    _roomsSubscription = ChatService.instance
        .watchChatRooms(widget.currentUser.uid)
        .listen((rooms) {
      if (!mounted) {
        return;
      }
      setState(() {
        _rooms = rooms;
        _isLoadingRooms = false;
        _roomsError = null;
      });
    }, onError: (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _roomsError = error;
        _isLoadingRooms = false;
      });
    });
  }

  void _consumeInitialPeer() {
    final peer = widget.initialPeer;
    if (peer == null || peer.uid.isEmpty) {
      return;
    }
    _activePeer = peer;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onInitialPeerConsumed?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final peer = _activePeer;
    return PopScope<void>(
      canPop: _activePeer == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _activePeer != null) {
          setState(() => _activePeer = null);
        }
      },
      child: peer != null
          ? ChatRoomView(
              currentUser: widget.currentUser,
              currentProfile: widget.currentProfile,
              peer: peer,
              onBack: () => setState(() => _activePeer = null),
            )
          : ListView(
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
                const SizedBox(height: 14),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search people',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textLight,
                    ),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.textLight,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  child: _buildRoomContent(),
                ),
              ],
            ),
    );
  }

  Widget _buildRoomContent() {
    final visibleRooms = _visibleRooms;
    if (visibleRooms.isNotEmpty) {
      return AnimatedOpacity(
        key: const ValueKey('chat_rooms'),
        opacity: 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: Column(
          children: [
            for (final room in visibleRooms)
              _ProfileAwareChatListItem(
                room: room,
                currentUserId: widget.currentUser.uid,
                onOpen: (peer) => setState(() => _activePeer = peer),
                onDelete: (peer) => _confirmDeleteChat(room, peer),
              ),
            if (_isLoadingRooms)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: _SoftLoadingLine(),
              ),
          ],
        ),
      );
    }

    if (_query.isNotEmpty && !_isLoadingRooms) {
      return const EmptyState(
        key: ValueKey('chat_search_empty'),
        icon: Icons.search_off_rounded,
        title: 'No matching chats',
        subtitle: 'Try a different name',
      );
    }

    if (_isLoadingRooms) {
      return const _ChatListLoading(key: ValueKey('chat_loading'));
    }

    if (_roomsError != null) {
      return const EmptyState(
        key: ValueKey('chat_error'),
        icon: Icons.wifi_tethering_error_rounded,
        title: 'Messages are taking a moment',
        subtitle: 'Check your connection and try again',
      );
    }

    return const EmptyState(
      key: ValueKey('chat_empty'),
      icon: Icons.mode_comment_outlined,
      title: 'No messages yet',
      subtitle: 'Start a conversation from any post',
    );
  }

  Future<void> _confirmDeleteChat(ChatRoomPreview room, ChatPeer peer) async {
    final selectedDelete = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_outline,
                      color: AppColors.primary),
                  title: const Text('Delete chat'),
                  subtitle: const Text('Remove it from your Messages list'),
                  onTap: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (selectedDelete != true || !mounted) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          surfaceTintColor: AppColors.surface,
          title: const Text('Delete chat?'),
          content: Text(
            'This removes ${peer.displayName} from your Messages list until a new message appears.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (shouldDelete != true || !mounted) {
      return;
    }

    await ChatService.instance.hideChatForUser(
      roomId: room.id,
      userId: widget.currentUser.uid,
    );
  }

  List<ChatRoomPreview> get _visibleRooms {
    final query = _query.toLowerCase();
    if (query.isEmpty) {
      return _rooms;
    }
    final visibleRooms = _rooms.where((room) {
      final peer = room.otherParticipant(widget.currentUser.uid);
      final peerName = peer.displayName.toLowerCase();
      final nameEntries = room.participantIds.length == 1
          ? room.participantNames.entries
          : room.participantNames.entries
              .where((entry) => entry.key != widget.currentUser.uid);
      final participantNameMatch =
          nameEntries.any((entry) => entry.value.toLowerCase().contains(query));
      return peerName.contains(query) || participantNameMatch;
    }).toList();

    final selfChatMatches =
        widget.currentProfile.displayName.toLowerCase().contains(query);
    final hasSelfRoom = _rooms.any((room) {
      return room.participantIds.length == 1 &&
          room.participantIds.first == widget.currentUser.uid;
    });

    if (selfChatMatches && !hasSelfRoom) {
      visibleRooms.insert(0, _selfDraftRoom);
    }

    return visibleRooms;
  }

  ChatRoomPreview get _selfDraftRoom {
    return ChatRoomPreview(
      id: ChatService.instance
          .roomIdFor(widget.currentUser.uid, widget.currentUser.uid),
      participantIds: [widget.currentUser.uid],
      participantNames: {
        widget.currentUser.uid: widget.currentProfile.displayName,
      },
      participantAvatars: {
        widget.currentUser.uid: widget.currentProfile.avatarUrl ?? '',
      },
      lastMessage: '',
      lastMessageType: MessageType.text,
      lastSenderId: '',
      updatedAt: null,
      unreadCounts: const {},
      typingUsers: const {},
      hiddenFor: const {},
    );
  }
}

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
    await ChatService.instance.ensureRoom(
      currentUser: widget.currentProfile,
      peer: widget.peer,
    );
    if (!mounted) {
      return;
    }
    _messagesSubscription = ChatService.instance
        .getMessagesStream(_roomId)
        .listen(_handleLiveMessages, onError: (_) {
      if (mounted) {
        setState(() => _isLoadingMessages = false);
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
    return Column(
      children: [
        _ChatAppBar(
          fallbackPeer: widget.peer,
          onBack: widget.onBack,
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
    } catch (_) {
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
    } catch (_) {
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
}

class _ProfileAwareChatListItem extends StatelessWidget {
  const _ProfileAwareChatListItem({
    required this.room,
    required this.currentUserId,
    required this.onOpen,
    required this.onDelete,
  });

  final ChatRoomPreview room;
  final String currentUserId;
  final ValueChanged<ChatPeer> onOpen;
  final ValueChanged<ChatPeer> onDelete;

  @override
  Widget build(BuildContext context) {
    final fallbackPeer = room.otherParticipant(currentUserId);
    if (fallbackPeer.uid.isEmpty) {
      return ChatListItem(
        room: room,
        currentUserId: currentUserId,
        onTap: () {},
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
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeOutCubic,
          child: ChatListItem(
            key: ValueKey('${room.id}_${peer.displayName}_${peer.avatarUrl}'),
            room: room,
            currentUserId: currentUserId,
            peer: peer,
            onTap: () => onOpen(peer),
            onLongPress: () => onDelete(peer),
          ),
        );
      },
    );
  }
}

class _ChatAppBar extends StatelessWidget {
  const _ChatAppBar({
    required this.fallbackPeer,
    required this.onBack,
  });

  final ChatPeer fallbackPeer;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    if (fallbackPeer.uid.isEmpty) {
      return _ChatAppBarContent(peer: fallbackPeer, onBack: onBack);
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
        return _ChatAppBarContent(peer: peer, onBack: onBack);
      },
    );
  }
}

class _ChatAppBarContent extends StatelessWidget {
  const _ChatAppBarContent({
    required this.peer,
    required this.onBack,
  });

  final ChatPeer peer;
  final VoidCallback onBack;

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
                    CircleAvatar(
                      radius: 19,
                      backgroundColor: AppColors.text,
                      backgroundImage:
                          peer.avatarUrl == null || peer.avatarUrl!.isEmpty
                              ? null
                              : NetworkImage(peer.avatarUrl!),
                      child: peer.avatarUrl == null || peer.avatarUrl!.isEmpty
                          ? Text(
                              initialFor(peer.displayName),
                              style: const TextStyle(color: Colors.white),
                            )
                          : null,
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
                          const Text(
                            'Apsara chat',
                            style: TextStyle(
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

class _ChatListLoading extends StatelessWidget {
  const _ChatListLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.55, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, opacity, child) {
        return Opacity(opacity: opacity, child: child);
      },
      child: Column(
        children: [
          const _SoftLoadingLine(),
          const SizedBox(height: 18),
          const Text(
            'Loading messages',
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 18),
          ...List.generate(
            4,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  const _SkeletonCircle(),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SkeletonBar(
                          widthFactor: index.isEven ? 0.46 : 0.34,
                        ),
                        const SizedBox(height: 9),
                        _SkeletonBar(
                          widthFactor: index.isEven ? 0.72 : 0.58,
                          height: 9,
                        ),
                      ],
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

class _SoftLoadingLine extends StatelessWidget {
  const _SoftLoadingLine();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.35, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      builder: (context, opacity, child) {
        return Opacity(opacity: opacity, child: child);
      },
      child: Container(
        width: 84,
        height: 3,
        decoration: BoxDecoration(
          color: AppColors.chatOutgoingSoft,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _SkeletonCircle extends StatelessWidget {
  const _SkeletonCircle();

  @override
  Widget build(BuildContext context) {
    return const CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.chatIncoming,
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
