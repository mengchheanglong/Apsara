import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/message_model.dart';
import '../models/user_profile.dart';
import '../services/chat_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_list_item.dart';
import '../widgets/empty_state.dart';
import 'chat_room_view.dart';

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
      return Column(
        key: const ValueKey('chat_error'),
        children: [
          const EmptyState(
            icon: Icons.wifi_tethering_error_rounded,
            title: 'Messages are taking a moment',
            subtitle: 'Check your connection and try again',
          ),
          TextButton(
            onPressed: _watchRooms,
            child: const Text('Retry'),
          ),
        ],
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
