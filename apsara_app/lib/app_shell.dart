import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'models/art_post.dart';
import 'models/conversation.dart';
import 'models/user_profile.dart';
import 'screens/chat_screen.dart';
import 'screens/create_post_screen.dart';
import 'screens/home_screen.dart';
import 'screens/post_detail_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/saved_screen.dart';
import 'screens/search_screen.dart';
import 'services/auth_service.dart';
import 'services/engagement_service.dart';
import 'services/post_service.dart';
import 'services/profile_service.dart';
import 'services/saved_post_service.dart';
import 'theme/app_theme.dart';

class ApsaraShell extends StatefulWidget {
  const ApsaraShell({
    super.key,
    required this.user,
  });

  final User user;

  @override
  State<ApsaraShell> createState() => _ApsaraShellState();
}

class _ApsaraShellState extends State<ApsaraShell> {
  final _homeKey = GlobalKey<HomeScreenState>();
  int _tab = 0;
  List<ArtPost> _posts = const [];
  Set<String> _savedPostIds = const {};
  Set<String> _likedPostIds = const {};
  late UserProfile _profile;
  final List<Conversation> _conversations = [];
  StreamSubscription<List<ArtPost>>? _postsSubscription;
  StreamSubscription<Set<String>>? _savedPostsSubscription;
  StreamSubscription<Set<String>>? _likedPostsSubscription;
  StreamSubscription<UserProfile>? _profileSubscription;

  int get _currentSellerId => widget.user.uid.hashCode;

  String get _currentUserName => _profile.displayName;

  List<ArtPost> get _myPosts => _posts.where(_isOwnPost).toList();

  @override
  void initState() {
    super.initState();
    _profile = UserProfile.fromUser(widget.user);
    _postsSubscription = PostService.instance.watchPosts().listen((posts) {
      if (!mounted) {
        return;
      }
      setState(() => _posts = posts);
    });
    _savedPostsSubscription = SavedPostService.instance
        .watchSavedPostIds(widget.user.uid)
        .listen((ids) {
      if (!mounted) {
        return;
      }
      setState(() => _savedPostIds = ids);
    });
    _likedPostsSubscription = EngagementService.instance
        .watchLikedPostIds(widget.user.uid)
        .listen((ids) {
      if (!mounted) {
        return;
      }
      setState(() => _likedPostIds = ids);
    });
    _profileSubscription = ProfileService.instance
        .watchCurrentUserProfile(widget.user)
        .listen((profile) {
      if (!mounted) {
        return;
      }
      setState(() => _profile = profile);
    });
  }

  @override
  void dispose() {
    _postsSubscription?.cancel();
    _savedPostsSubscription?.cancel();
    _likedPostsSubscription?.cancel();
    _profileSubscription?.cancel();
    super.dispose();
  }

  bool _isOwnPost(ArtPost post) {
    return post.sellerUid == widget.user.uid ||
        post.sellerId == _currentSellerId;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        key: _homeKey,
        posts: _posts,
        onOpenPost: _openPost,
        onOpenSearch: _openSearch,
        onOpenPostTools: _openPostTools,
      ),
      SavedScreen(
        posts: _posts
            .where((post) => _savedPostIds.contains(post.storageId))
            .toList(),
        onOpenPost: _openPost,
      ),
      ChatScreen(
        conversations: _conversations,
        onSend: _sendMessage,
      ),
      ProfileScreen(
        profile: _profile,
        myPosts: _myPosts,
        onOpenPost: _openPost,
        onUpdateProfile: _updateProfile,
        onLogout: () async => AuthService.instance.signOut(),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _tab,
          children: pages,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: _tab,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFEDEDED),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.primary),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border_rounded),
            selectedIcon:
                Icon(Icons.bookmark_rounded, color: AppColors.primary),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.mode_comment_outlined),
            selectedIcon: Icon(Icons.mode_comment, color: AppColors.primary),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: '',
          ),
        ],
      ),
    );
  }

  void _selectTab(int index) {
    setState(() => _tab = index);

    if (index == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _homeKey.currentState?.scrollCurrentCategoryToTop();
      });
    }
  }

  void _openPost(ArtPost post) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return PostDetailSheet(
          post: post,
          isSaved: _savedPostIds.contains(post.storageId),
          isLiked: _likedPostIds.contains(post.storageId),
          isOwnPost: _isOwnPost(post),
          onSetSaved: _setSaved,
          onToggleLiked: _toggleLiked,
          onAddComment: _addComment,
          onSharePost: _sharePost,
          onMessageSeller: () {
            Navigator.pop(context);
            _openConversation(post.sellerId, post.seller);
          },
          onDelete: _isOwnPost(post)
              ? () {
                  Navigator.pop(context);
                  _deletePost(post.id);
                }
              : null,
        );
      },
    );
  }

  Future<void> _createPost(ArtPost post) async {
    await PostService.instance.createPost(
      sellerUid: widget.user.uid,
      sellerName: _currentUserName,
      title: post.title,
      description: post.description,
      category: post.category,
      condition: post.condition,
      location: post.location,
      price: post.price,
      imageUrl: post.imageUrl,
    );

    setState(() {
      _tab = 0;
    });
  }

  Future<void> _deletePost(int id) async {
    final post = _posts.where((post) => post.id == id).firstOrNull;
    if (post != null) {
      await PostService.instance.deletePost(
        post: post,
        currentUserId: widget.user.uid,
      );
    }

    setState(() {
      _posts = _posts.where((post) => post.id != id).toList();
      _savedPostIds =
          _savedPostIds.where((postId) => postId != post?.storageId).toSet();
      _likedPostIds =
          _likedPostIds.where((postId) => postId != post?.storageId).toSet();
    });
  }

  Future<void> _setSaved(ArtPost post, bool saved) async {
    setState(() {
      _savedPostIds = saved
          ? {..._savedPostIds, post.storageId}
          : _savedPostIds.where((id) => id != post.storageId).toSet();
    });

    try {
      await SavedPostService.instance.setSaved(
        userId: widget.user.uid,
        post: post,
        saved: saved,
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _savedPostIds = saved
              ? _savedPostIds.where((id) => id != post.storageId).toSet()
              : {..._savedPostIds, post.storageId};
        });
      }
      rethrow;
    }
  }

  Future<LikeUpdate> _toggleLiked(ArtPost post) async {
    final update = await EngagementService.instance.toggleLiked(
      userId: widget.user.uid,
      post: post,
    );

    if (mounted) {
      setState(() {
        _likedPostIds = update.isLiked
            ? {..._likedPostIds, post.storageId}
            : _likedPostIds.where((id) => id != post.storageId).toSet();
        _posts = _posts.map((item) {
          if (item.storageId != post.storageId) {
            return item;
          }

          return item.copyWith(likes: update.likeCount);
        }).toList();
      });
    }

    return update;
  }

  Future<void> _updateProfile({
    required String displayName,
    required String bio,
    String? avatarUrl,
  }) async {
    await ProfileService.instance.updateProfile(
      displayName: displayName,
      bio: bio,
      avatarUrl: avatarUrl,
    );
  }

  Future<void> _addComment(ArtPost post, String text) {
    return EngagementService.instance.addComment(
      userId: widget.user.uid,
      userName: _currentUserName,
      post: post,
      text: text,
    );
  }

  Future<void> _sharePost(ArtPost post) async {
    await SharePlus.instance.share(
      ShareParams(
        text:
            '${post.title}\n${post.priceLabel}\n${post.imageUrl}\n\nShared from Apsara',
      ),
    );
    await EngagementService.instance.recordShare(
      userId: widget.user.uid,
      post: post,
    );
  }

  void _openConversation(int sellerId, String sellerName) {
    final existing =
        _conversations.indexWhere((chat) => chat.sellerId == sellerId);
    setState(() {
      if (existing == -1) {
        _conversations.insert(
          0,
          Conversation(
            sellerId: sellerId,
            sellerName: sellerName,
            online: true,
            messages: const [],
          ),
        );
      }
      _tab = 2;
    });
  }

  void _sendMessage(Conversation conversation, String text) {
    setState(() {
      conversation.messages.add(
        ChatMessage(
          text: text,
          time: 'Now',
          isMe: true,
        ),
      );
    });
  }

  Future<void> _openPostTools() async {
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 240),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondaryAnimation) {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0) < -500) {
                Navigator.of(context).maybePop();
              }
            },
            child: Scaffold(
              backgroundColor: AppColors.surface,
              appBar: AppBar(
                toolbarHeight: 52,
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                elevation: 0,
                centerTitle: false,
                titleSpacing: 0,
              ),
              body: SafeArea(
                top: false,
                child: CreatePostScreen(
                  onCreatePost: _createPost,
                  sellerId: _currentSellerId,
                  sellerUid: widget.user.uid,
                  sellerName: _currentUserName,
                ),
              ),
            ),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
  }

  Future<void> _openSearch() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return SearchScreen(
            posts: _posts,
            onOpenPost: _openPost,
          );
        },
      ),
    );
  }
}
