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
  ChatScreen({
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
  State<ChatScreen> createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  ChatPeer? _activePeer;
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final Map<String, ChatPeer> _cachedPeersByRoomId = {};
  StreamSubscription<List<ChatRoomPreview>>? _roomsSubscription;
  List<ChatRoomPreview> _rooms = [];
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
    _scrollController.dispose();
    _searchController.dispose();
    _roomsSubscription?.cancel();
    super.dispose();
  }

  bool handleSystemBack() {
    if (_activePeer == null) {
      return false;
    }
    setState(() => _activePeer = null);
    return true;
  }

  void refreshCurrentTab() {
    if (_activePeer != null) {
      setState(() => _activePeer = null);
      return;
    }

    if (_query.isNotEmpty || _searchController.text.isNotEmpty) {
      _searchController.clear();
      setState(() => _query = '');
    }

    _watchRooms();
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
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
      unawaited(_hydratePeers(rooms));
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

  Future<void> _hydratePeers(List<ChatRoomPreview> rooms) async {
    final peerIds = rooms
        .map((room) => room.otherParticipant(widget.currentUser.uid).uid)
        .where((id) => id.isNotEmpty && id != widget.currentUser.uid)
        .toSet();
    if (peerIds.isEmpty) {
      return;
    }

    final profiles = await ProfileService.instance.fetchProfilesByIds(peerIds);
    if (!mounted || profiles.isEmpty) {
      return;
    }

    setState(() {
      for (final room in rooms) {
        final fallbackPeer = room.otherParticipant(widget.currentUser.uid);
        final profile = profiles[fallbackPeer.uid];
        if (profile == null) {
          continue;
        }
        _cachedPeersByRoomId[room.id] = ChatPeer(
          uid: profile.uid,
          displayName: profile.displayName,
          email: profile.email,
          avatarUrl: profile.avatarUrl,
        );
      }
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
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(16, 18, 16, 96),
              children: [
                Text(
                  'Messages',
                  style: TextStyle(
                    color: context.appColors.primary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 14),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search people',
                    prefixIcon: Icon(
                      Icons.search,
                      color: context.appColors.textLight,
                    ),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: Icon(
                              Icons.close,
                              color: context.appColors.textLight,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 220),
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
        key: ValueKey('chat_rooms'),
        opacity: 1,
        duration: Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: Column(
          children: [
            for (final room in visibleRooms)
              _ProfileAwareChatListItem(
                room: room,
                currentUserId: widget.currentUser.uid,
                cachedPeer: _cachedPeersByRoomId[room.id],
                onPeerResolved: (peer) {
                  if (!mounted) {
                    return;
                  }
                  final existing = _cachedPeersByRoomId[room.id];
                  if (existing?.displayName == peer.displayName &&
                      existing?.avatarUrl == peer.avatarUrl &&
                      existing?.email == peer.email &&
                      existing?.uid == peer.uid) {
                    return;
                  }
                  setState(() {
                    _cachedPeersByRoomId[room.id] = peer;
                  });
                },
                onOpen: (peer) => setState(() => _activePeer = peer),
                onDelete: (peer) => _confirmDeleteChat(room, peer),
              ),
            if (_isLoadingRooms)
              Padding(
                padding: EdgeInsets.only(top: 10),
                child: _SoftLoadingLine(),
              ),
          ],
        ),
      );
    }

    if (_query.isNotEmpty && !_isLoadingRooms) {
      return EmptyState(
        key: ValueKey('chat_search_empty'),
        icon: Icons.search_off_rounded,
        title: 'No matching chats',
        subtitle: 'Try a different name',
      );
    }

    if (_isLoadingRooms) {
      return _ChatListLoading(key: ValueKey('chat_loading'));
    }

    if (_roomsError != null) {
      return Column(
        key: ValueKey('chat_error'),
        children: [
          EmptyState(
            icon: Icons.wifi_tethering_error_rounded,
            title: 'Messages are taking a moment',
            subtitle: 'Check your connection and try again',
          ),
          TextButton(
            onPressed: _watchRooms,
            child: Text('Retry'),
          ),
        ],
      );
    }

    return EmptyState(
      key: ValueKey('chat_empty'),
      icon: Icons.mode_comment_outlined,
      title: 'No messages yet',
      subtitle: 'Start a conversation from any post',
    );
  }

  Future<void> _confirmDeleteChat(ChatRoomPreview room, ChatPeer peer) async {
    final selectedDelete = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: context.appColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(8, 8, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.delete_outline,
                      color: context.appColors.primary),
                  title: Text('Delete chat'),
                  subtitle: Text('Remove it from your Messages list'),
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
          backgroundColor: context.appColors.surface,
          surfaceTintColor: context.appColors.surface,
          title: Text('Delete chat?'),
          content: Text(
            'This removes ${peer.displayName} from your Messages list until a new message appears.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                  foregroundColor: context.appColors.primary),
              child: Text('Delete'),
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
      final peer = _cachedPeersByRoomId[room.id] ??
          room.otherParticipant(widget.currentUser.uid);
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
      unreadCounts: {},
      typingUsers: {},
      hiddenFor: {},
    );
  }
}

class _ProfileAwareChatListItem extends StatelessWidget {
  _ProfileAwareChatListItem({
    required this.room,
    required this.currentUserId,
    required this.cachedPeer,
    required this.onPeerResolved,
    required this.onOpen,
    required this.onDelete,
  });

  final ChatRoomPreview room;
  final String currentUserId;
  final ChatPeer? cachedPeer;
  final ValueChanged<ChatPeer> onPeerResolved;
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
            ? (cachedPeer ?? fallbackPeer)
            : ChatPeer(
                uid: profile.uid,
                displayName: profile.displayName,
                email: profile.email,
                avatarUrl: profile.avatarUrl,
              );

        if (profile != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onPeerResolved(peer);
          });
        }

        return ChatListItem(
          room: room,
          currentUserId: currentUserId,
          peer: peer,
          onTap: () => onOpen(peer),
          onLongPress: () => onDelete(peer),
        );
      },
    );
  }
}

class _ChatListLoading extends StatelessWidget {
  _ChatListLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 220);
  }
}

class _SoftLoadingLine extends StatelessWidget {
  _SoftLoadingLine();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.35, end: 1),
      duration: Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      builder: (context, opacity, child) {
        return Opacity(opacity: opacity, child: child);
      },
      child: Container(
        width: 84,
        height: 3,
        decoration: BoxDecoration(
          color: context.appColors.chatOutgoingSoft,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
