import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'models/art_post.dart';
import 'models/message_model.dart';
import 'models/user_profile.dart';
import 'screens/chat_screen.dart';
import 'screens/create_post_screen.dart';
import 'screens/edit_post_screen.dart';
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
import 'services/discovery_service.dart';
import 'theme/app_theme.dart';
import 'utils/app_logger.dart';

class ApsaraShell extends StatefulWidget {
  ApsaraShell({
    super.key,
    required this.user,
    required this.isDarkMode,
    required this.onDarkModeChanged,
  });

  final User user;
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  @override
  State<ApsaraShell> createState() => _ApsaraShellState();
}

class _ApsaraShellState extends State<ApsaraShell> {
  static int _lastSelectedTab = 0;

  final _homeKey = GlobalKey<HomeScreenState>();
  final _savedKey = GlobalKey<SavedScreenState>();
  final _chatKey = GlobalKey<ChatScreenState>();
  final _profileKey = GlobalKey<ProfileScreenState>();
  int _tab = _lastSelectedTab;
  List<ArtPost> _posts = [];
  bool _isLoadingPosts = true;
  Object? _postsError;
  Set<String> _savedPostIds = {};
  Set<String> _likedPostIds = {};
  late UserProfile _profile;
  ChatPeer? _initialChatPeer;
  StreamSubscription<List<ArtPost>>? _postsSubscription;
  StreamSubscription<Set<String>>? _savedPostsSubscription;
  StreamSubscription<Set<String>>? _likedPostsSubscription;
  StreamSubscription<UserProfile>? _profileSubscription;
  DateTime? _lastExitAttemptAt;

  int get _currentSellerId => widget.user.uid.hashCode;

  String get _currentUserName => _profile.displayName;

  List<ArtPost> get _myPosts => _posts.where(_isOwnPost).toList();

  List<ArtPost> get _rankedPosts => DiscoveryService.rankPosts(
        posts: _posts,
        likedPostIds: _likedPostIds,
        savedPostIds: _savedPostIds,
      );

  @override
  void initState() {
    super.initState();
    _profile = UserProfile.fromUser(widget.user);
    _watchPosts(showLoading: false);
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
        posts: _rankedPosts,
        isLoading: _isLoadingPosts,
        loadError: _postsError,
        onRetry: _watchPosts,
        onOpenPost: _openPost,
        onOpenSearch: _openSearch,
        onOpenPostTools: _openPostTools,
      ),
      SavedScreen(
        key: _savedKey,
        posts: _posts
            .where((post) => _savedPostIds.contains(post.storageId))
            .toList(),
        onOpenPost: _openPost,
      ),
      ChatScreen(
        key: _chatKey,
        currentUser: widget.user,
        currentProfile: _profile,
        initialPeer: _initialChatPeer,
        onInitialPeerConsumed: () {
          if (mounted) {
            setState(() => _initialChatPeer = null);
          }
        },
      ),
      ProfileScreen(
        key: _profileKey,
        profile: _profile,
        myPosts: _myPosts,
        onOpenPost: _openPost,
        onUpdateProfile: _updateProfile,
        onLogout: () async => AuthService.instance.signOut(),
        isDarkMode: widget.isDarkMode,
        onDarkModeChanged: widget.onDarkModeChanged,
      ),
    ];

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }
        if (_tab == 2 && (_chatKey.currentState?.handleSystemBack() ?? false)) {
          return;
        }

        final now = DateTime.now();
        final shouldExit = _lastExitAttemptAt != null &&
            now.difference(_lastExitAttemptAt!) <= Duration(seconds: 2);

        if (shouldExit) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          await SystemNavigator.pop();
          return;
        }

        _lastExitAttemptAt = now;
      },
      child: Scaffold(
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
          backgroundColor: context.appColors.surface,
          indicatorColor: context.appColors.soft,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          onDestinationSelected: _selectTab,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: context.appColors.primary),
              label: '',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmark_border_rounded),
              selectedIcon: Icon(
                Icons.bookmark_rounded,
                color: context.appColors.primary,
              ),
              label: '',
            ),
            NavigationDestination(
              icon: Icon(Icons.mode_comment_outlined),
              selectedIcon:
                  Icon(Icons.mode_comment, color: context.appColors.primary),
              label: '',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon:
                  Icon(Icons.person, color: context.appColors.primary),
              label: '',
            ),
          ],
        ),
      ),
    );
  }

  void _selectTab(int index) {
    if (index == _tab) {
      _refreshCurrentTab();
      return;
    }

    setState(() {
      _tab = index;
      _lastSelectedTab = index;
    });
  }

  void _refreshCurrentTab() {
    switch (_tab) {
      case 0:
        _homeKey.currentState?.scrollCurrentCategoryToTop();
      case 1:
        _savedKey.currentState?.refreshCurrentTab();
      case 2:
        _chatKey.currentState?.refreshCurrentTab();
      case 3:
        _profileKey.currentState?.refreshCurrentTab();
    }
  }

  Future<void> _openPost(ArtPost post) async {
    final postId = post.storageId;
    var isSaved = _savedPostIds.contains(postId);
    var isLiked = _likedPostIds.contains(postId);

    try {
      final results = await Future.wait([
        EngagementService.instance.fetchLikedPostIdsForPosts(
          userId: widget.user.uid,
          posts: [post],
        ),
        SavedPostService.instance.isSaved(
          userId: widget.user.uid,
          postId: postId,
        ),
      ]);
      final likedIds = results[0] as Set<String>;
      isLiked = likedIds.contains(postId);
      isSaved = results[1] as bool;
    } catch (_) {
      // Keep cached state on failure.
    }

    if (!mounted) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return PostDetailSheet(
          post: post,
          isSaved: isSaved,
          isLiked: isLiked,
          isOwnPost: _isOwnPost(post),
          onSetSaved: _setSaved,
          onSetLiked: _setLiked,
          onAddComment: _addComment,
          onSharePost: _sharePost,
          onMessageSeller: () {
            Navigator.pop(context);
            _openConversation(post);
          },
          onEdit: _isOwnPost(post)
              ? () {
                  Navigator.pop(context);
                  _openEditPost(post);
                }
              : null,
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
    try {
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
    } catch (error, stackTrace) {
      AppLogger.error('Post create failed', error, stackTrace);
      rethrow;
    }

    setState(() {
      _tab = 0;
      _lastSelectedTab = 0;
    });
  }

  Future<void> _updatePost(
    ArtPost post, {
    required String title,
    required String description,
    required String category,
    required String condition,
    required String location,
    required double? price,
    required String imageUrl,
  }) async {
    final normalizedLocation =
        location.trim().toLowerCase() == 'cambodia' ? '' : location.trim();

    try {
      await PostService.instance.updatePost(
        post: post,
        title: title,
        description: description,
        category: category,
        condition: condition,
        location: normalizedLocation,
        price: price,
        imageUrl: imageUrl,
      );
    } catch (error, stackTrace) {
      AppLogger.error('Post update failed', error, stackTrace);
      rethrow;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _posts = _posts.map((item) {
        if (item.storageId != post.storageId) {
          return item;
        }

        return ArtPost(
          id: item.id,
          documentId: item.documentId,
          title: title,
          seller: item.seller,
          sellerId: item.sellerId,
          sellerUid: item.sellerUid,
          category: category,
          condition: condition,
          location: normalizedLocation,
          imageUrl: imageUrl,
          description: description,
          price: price,
          likes: item.likes,
          comments: item.comments,
          shares: item.shares,
        );
      }).toList();
    });
  }

  Future<void> _deletePost(int id) async {
    final post = _posts.where((post) => post.id == id).firstOrNull;
    if (post != null) {
      try {
        await PostService.instance.deletePost(
          post: post,
          currentUserId: widget.user.uid,
        );
      } catch (error, stackTrace) {
        AppLogger.error('Post delete failed', error, stackTrace);
        rethrow;
      }
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
    } catch (error, stackTrace) {
      AppLogger.warn('Save toggle failed', error, stackTrace);
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

  Future<LikeUpdate> _setLiked(ArtPost post, bool liked) async {
    LikeUpdate update;
    try {
      update = await EngagementService.instance.setLiked(
        userId: widget.user.uid,
        post: post,
        liked: liked,
      );
    } catch (error, stackTrace) {
      AppLogger.warn('Like toggle failed', error, stackTrace);
      rethrow;
    }

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

  Future<void> _syncLikedPostsForVisiblePosts(List<ArtPost> posts) async {
    final likedIds = await EngagementService.instance.fetchLikedPostIdsForPosts(
      userId: widget.user.uid,
      posts: posts,
    );
    if (!mounted || likedIds.isEmpty) {
      return;
    }

    setState(() {
      _likedPostIds = {..._likedPostIds, ...likedIds};
    });
  }

  void _watchPosts({bool showLoading = true}) {
    _postsSubscription?.cancel();
    if (showLoading && mounted) {
      setState(() {
        _isLoadingPosts = true;
        _postsError = null;
      });
    } else {
      _isLoadingPosts = true;
      _postsError = null;
    }

    _postsSubscription = PostService.instance.watchPosts().listen((posts) {
      if (!mounted) {
        return;
      }
      setState(() {
        _posts = posts;
        _isLoadingPosts = false;
        _postsError = null;
      });
      unawaited(_syncLikedPostsForVisiblePosts(posts));
    }, onError: (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingPosts = false;
        _postsError = error;
      });
    });
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
    try {
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
    } catch (error, stackTrace) {
      AppLogger.warn('Share failed', error, stackTrace);
      rethrow;
    }
  }

  void _openConversation(ArtPost post) {
    final sellerUid = post.sellerUid;
    if (sellerUid == null || sellerUid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seller chat is unavailable.')),
      );
      return;
    }

    setState(() {
      _initialChatPeer = ChatPeer(
        uid: sellerUid,
        displayName: post.seller,
        email: '',
      );
      _tab = 2;
      _lastSelectedTab = 2;
    });
  }

  Future<void> _openPostTools() async {
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: Duration(milliseconds: 240),
        reverseTransitionDuration: Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondaryAnimation) {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0) < -500) {
                Navigator.of(context).maybePop();
              }
            },
            child: Scaffold(
              backgroundColor: context.appColors.surface,
              appBar: AppBar(
                toolbarHeight: 52,
                backgroundColor: context.appColors.surface,
                surfaceTintColor: context.appColors.surface,
                elevation: 0,
                centerTitle: false,
                title: Text('New post'),
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
            begin: Offset(-1, 0),
            end: Offset.zero,
          ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
  }

  Future<void> _openEditPost(ArtPost post) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return EditPostScreen(
            post: post,
            onUpdatePost: ({
              required title,
              required description,
              required category,
              required condition,
              required location,
              required price,
              required imageUrl,
            }) {
              return _updatePost(
                post,
                title: title,
                description: description,
                category: category,
                condition: condition,
                location: location,
                price: price,
                imageUrl: imageUrl,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openSearch() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return SearchScreen(
            posts: _rankedPosts,
            onOpenPost: _openPost,
          );
        },
      ),
    );
  }
}
