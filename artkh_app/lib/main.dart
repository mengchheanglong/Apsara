import 'package:flutter/material.dart';

import 'data/mock_artkh_data.dart';
import 'models/art_post.dart';
import 'models/conversation.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ArtKhApp());
}

class ArtKhApp extends StatelessWidget {
  const ArtKhApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ArtKh',
      debugShowCheckedModeBanner: false,
      theme: buildArtKhTheme(),
      home: const ArtKhShell(),
    );
  }
}

class ArtKhShell extends StatefulWidget {
  const ArtKhShell({super.key});

  @override
  State<ArtKhShell> createState() => _ArtKhShellState();
}

class _ArtKhShellState extends State<ArtKhShell> {
  String? _userName;
  int _tab = 0;
  List<ArtPost> _posts = List.of(demoPosts);
  final Set<int> _savedIds = {1, 3, 4, 6};
  final List<Conversation> _conversations = List.of(demoConversations);

  List<ArtPost> get _myPosts => _posts.where((post) => post.sellerId == 999).toList();

  @override
  Widget build(BuildContext context) {
    if (_userName == null) {
      return LoginScreen(
        onLogin: (name) => setState(() => _userName = name),
      );
    }

    final pages = [
      HomeScreen(
        posts: _posts,
        savedIds: _savedIds,
        onOpenPost: _openPost,
        onOpenSearch: _openSearch,
        onOpenPostTools: _openPostTools,
      ),
      SavedScreen(
        posts: _posts.where((post) => _savedIds.contains(post.id)).toList(),
        onOpenPost: _openPost,
      ),
      ChatScreen(
        conversations: _conversations,
        onSend: _sendMessage,
      ),
      ProfileScreen(
        userName: _userName!,
        savedCount: _savedIds.length,
        postCount: _myPosts.length,
        chatCount: _conversations.length,
        myPosts: _myPosts,
        onOpenPost: _openPost,
        onLogout: () => setState(() => _userName = null),
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
        indicatorColor: AppColors.primary.withValues(alpha: 0.10),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.primary),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite, color: AppColors.primary),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble, color: AppColors.primary),
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

  void _openPost(ArtPost post) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return PostDetailSheet(
          post: post,
          isSaved: _savedIds.contains(post.id),
          isOwnPost: post.sellerId == 999,
          onToggleSaved: () => setState(() {
            _savedIds.contains(post.id) ? _savedIds.remove(post.id) : _savedIds.add(post.id);
          }),
          onMessageSeller: () {
            Navigator.pop(context);
            _openConversation(post.sellerId, post.seller);
          },
          onDelete: post.sellerId == 999
              ? () {
                  Navigator.pop(context);
                  _deletePost(post.id);
                }
              : null,
        );
      },
    );
  }

  void _createPost(ArtPost post) {
    setState(() {
      _posts = [post, ..._posts];
      _tab = 0;
    });
  }

  void _deletePost(int id) {
    setState(() {
      _posts = _posts.where((post) => post.id != id).toList();
      _savedIds.remove(id);
    });
  }

  void _openConversation(int sellerId, String sellerName) {
    final existing = _conversations.indexWhere((chat) => chat.sellerId == sellerId);
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
                  myPosts: _myPosts,
                  onDeletePost: _deletePost,
                ),
              ),
            ),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
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

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onLogin,
  });

  final ValueChanged<String> onLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController(text: 'Sokha Chea');
  final _emailController = TextEditingController(text: 'sokha@example.com');
  final _passwordController = TextEditingController(text: 'password');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F7),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/artkh_logo.png',
                    width: 88,
                    height: 88,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ArtKh',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Appreciate, Buy & Sell Authentic Khmer Crafts',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textLight, fontSize: 13),
                ),
                const SizedBox(height: 24),
                _LabeledField(label: 'Your name', controller: _nameController),
                const SizedBox(height: 14),
                _LabeledField(label: 'Email', controller: _emailController),
                const SizedBox(height: 14),
                _LabeledField(
                  label: 'Password',
                  controller: _passwordController,
                  obscureText: true,
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: () {
                    final name = _nameController.text.trim();
                    if (name.isNotEmpty) widget.onLogin(name);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  child: const Text('Get started', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 22),
                const Text.rich(
                  TextSpan(
                    text: 'Already have an account? ',
                    children: [
                      TextSpan(
                        text: 'Log in',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textLight, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.posts,
    required this.savedIds,
    required this.onOpenPost,
    required this.onOpenSearch,
    required this.onOpenPostTools,
  });

  final List<ArtPost> posts;
  final Set<int> savedIds;
  final ValueChanged<ArtPost> onOpenPost;
  final Future<void> Function() onOpenSearch;
  final Future<void> Function() onOpenPostTools;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _category = 'All';

  List<ArtPost> get _filteredPosts {
    return widget.posts.where((post) {
      final matchesCategory = _category == 'All' || post.category == _category;
      return matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final posts = _filteredPosts;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) > 500) {
          widget.onOpenPostTools();
        }
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 14, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onOpenPostTools,
                    icon: const Icon(Icons.add, color: AppColors.text),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.onOpenSearch,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.soft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: const Row(
                          children: [
                            Icon(Icons.search, color: AppColors.textLight, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Search art...',
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final selected = category == _category;
                  return ChoiceChip(
                    selected: selected,
                    label: Text(category),
                    showCheckmark: false,
                    selectedColor: AppColors.text,
                    backgroundColor: AppColors.soft,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onSelected: (_) => setState(() => _category = category),
                  );
                },
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
            sliver: SliverToBoxAdapter(
              child: MasonryPostGrid(
                posts: posts,
                onOpenPost: widget.onOpenPost,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    required this.posts,
    required this.onOpenPost,
  });

  final List<ArtPost> posts;
  final ValueChanged<ArtPost> onOpenPost;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const _suggestions = <String>[
    'Silk scarf',
    'Pottery',
    'Wood carving',
    'Apsara art',
    'Cambodian decor',
    'Jewelry',
  ];

  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final List<String> _recentSearches = ['Pottery', 'Silk & Textiles', 'Wood Art'];
  String _query = '';

  List<ArtPost> get _results {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const <ArtPost>[];
    return widget.posts.where((post) {
      return post.title.toLowerCase().contains(q) ||
          post.seller.toLowerCase().contains(q) ||
          post.category.toLowerCase().contains(q) ||
          post.location.toLowerCase().contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: InputDecoration(
                        hintText: 'Search art...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _controller.clear();
                                  setState(() => _query = '');
                                },
                                icon: const Icon(Icons.close, color: AppColors.textLight),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _query.trim().isEmpty ? _buildSuggestionView() : _buildResultView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        if (_recentSearches.isNotEmpty) ...[
          const Text(
            'Recent searches',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recentSearches.map((term) {
              return ActionChip(
                label: Text(term),
                backgroundColor: AppColors.soft,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                onPressed: () => _applySearch(term),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
        ],
        const Text(
          'Discover',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _suggestions.map((term) {
            return ActionChip(
              label: Text(term),
              backgroundColor: AppColors.soft,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              onPressed: () => _applySearch(term),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildResultView() {
    final results = _results;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        const SizedBox(height: 4),
        Text(
          '${results.length} results',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (results.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 80),
            child: Center(
              child: Text(
                'No matching posts found.',
                style: TextStyle(color: AppColors.textLight),
              ),
            ),
          )
        else
          MasonryPostGrid(
            posts: results,
            onOpenPost: (post) {
              widget.onOpenPost(post);
            },
          ),
      ],
    );
  }

  void _applySearch(String term) {
    _controller.text = term;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: term.length),
    );
    setState(() => _query = term);
  }
}

class MasonryPostGrid extends StatelessWidget {
  const MasonryPostGrid({
    super.key,
    required this.posts,
    required this.onOpenPost,
  });

  final List<ArtPost> posts;
  final ValueChanged<ArtPost> onOpenPost;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(child: Text('No posts found')),
      );
    }

    final left = <ArtPost>[];
    final right = <ArtPost>[];
    for (var i = 0; i < posts.length; i++) {
      (i.isEven ? left : right).add(posts[i]);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _PostColumn(posts: left, onOpenPost: onOpenPost, offset: 0)),
        const SizedBox(width: 10),
        Expanded(child: _PostColumn(posts: right, onOpenPost: onOpenPost, offset: 1)),
      ],
    );
  }
}

class _PostColumn extends StatelessWidget {
  const _PostColumn({
    required this.posts,
    required this.onOpenPost,
    required this.offset,
  });

  final List<ArtPost> posts;
  final ValueChanged<ArtPost> onOpenPost;
  final int offset;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < posts.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: PostCard(
              post: posts[i],
              imageHeight: 172 + (((i + offset) % 3) * 42),
              onTap: () => onOpenPost(posts[i]),
            ),
          ),
      ],
    );
  }
}

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.imageHeight,
    required this.onTap,
  });

  final ArtPost post;
  final double imageHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              post.imageUrl,
              height: imageHeight,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: imageHeight,
                color: AppColors.soft,
                alignment: Alignment.center,
                child: const Icon(Icons.image_not_supported_outlined),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            post.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, height: 1.15),
          ),
          const SizedBox(height: 3),
          Text(post.priceLabel, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Row(
            children: [
              CircleAvatar(
                radius: 10,
                backgroundColor: AppColors.text,
                child: Text(
                  _initial(post.seller),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  post.seller,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PostDetailSheet extends StatefulWidget {
  const PostDetailSheet({
    super.key,
    required this.post,
    required this.isSaved,
    required this.isOwnPost,
    required this.onToggleSaved,
    required this.onMessageSeller,
    this.onDelete,
  });

  final ArtPost post;
  final bool isSaved;
  final bool isOwnPost;
  final VoidCallback onToggleSaved;
  final VoidCallback onMessageSeller;
  final VoidCallback? onDelete;

  @override
  State<PostDetailSheet> createState() => _PostDetailSheetState();
}

class _PostDetailSheetState extends State<PostDetailSheet> {
  late bool _saved;
  var _liked = false;

  @override
  void initState() {
    super.initState();
    _saved = widget.isSaved;
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Stack(
            children: [
              ListView(
                controller: controller,
                padding: const EdgeInsets.only(bottom: 94),
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                    child: Image.network(
                      post.imageUrl,
                      height: 430,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 430,
                        color: AppColors.soft,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => setState(() => _liked = !_liked),
                              icon: Icon(_liked ? Icons.favorite : Icons.favorite_border),
                              color: _liked ? AppColors.primary : AppColors.text,
                            ),
                            Text('${post.likes + (_liked ? 1 : 0)}'),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.chat_bubble_outline),
                            ),
                            Text('${post.comments}'),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.ios_share),
                            ),
                            const Spacer(),
                            IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
                          ],
                        ),
                        Text(
                          post.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, height: 1.2),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          post.priceLabel,
                          style: TextStyle(
                            color: post.isForSale ? AppColors.primary : AppColors.textLight,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (post.isForSale)
                              const _Pill(
                                label: 'For sale',
                                background: AppColors.saleBg,
                                foreground: AppColors.saleText,
                              ),
                            _Pill(label: post.category),
                            _Pill(label: post.condition),
                          ],
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'DESCRIPTION',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          post.description,
                          style: const TextStyle(color: AppColors.textSecondary, height: 1.55),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.text,
                              child: Text(
                                _initial(post.seller),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(post.seller, style: const TextStyle(fontWeight: FontWeight.w800)),
                                  Text(
                                    post.location,
                                    style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            if (!widget.isOwnPost)
                              FilledButton(
                                onPressed: widget.onMessageSeller,
                                style: FilledButton.styleFrom(backgroundColor: AppColors.text),
                                child: const Text('Message'),
                              ),
                          ],
                        ),
                        if (!widget.isOwnPost) ...[
                          const SizedBox(height: 18),
                          const Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _OutlinePill(label: 'Is this still available?'),
                              _OutlinePill(label: "What's the lowest price?"),
                              _OutlinePill(label: "Where's pickup?"),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 12,
                right: 12,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () {
                            widget.onToggleSaved();
                            setState(() => _saved = !_saved);
                          },
                          icon: Icon(_saved ? Icons.bookmark : Icons.bookmark_border),
                          label: Text(_saved ? 'Saved' : 'Save'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: widget.isOwnPost ? widget.onDelete : widget.onMessageSeller,
                          style: FilledButton.styleFrom(
                            backgroundColor: widget.isOwnPost ? AppColors.text : AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(widget.isOwnPost ? 'Delete post' : 'Message seller'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({
    super.key,
    required this.onCreatePost,
    required this.myPosts,
    required this.onDeletePost,
  });

  final ValueChanged<ArtPost> onCreatePost;
  final List<ArtPost> myPosts;
  final ValueChanged<int> onDeletePost;

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _location = TextEditingController();
  String _category = 'Pottery';
  String _condition = 'New';

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
      children: [
        const Text(
          'Share your art with the community',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Add a photo, describe the piece, and publish it for buyers or collectors.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.35),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.soft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create listing',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: 4 / 3,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 2),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_camera_outlined, color: AppColors.textLight, size: 34),
                      SizedBox(height: 6),
                      Text('Add photo', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _LabeledField(label: 'Title', controller: _title, hint: 'e.g., Hand-carved Wooden Elephant'),
              const SizedBox(height: 10),
              _LabeledField(label: 'Description', controller: _description, hint: 'Describe your item...', maxLines: 4),
              const SizedBox(height: 10),
              _DropdownField(
                label: 'Category',
                value: _category,
                values: categories.where((item) => item != 'All').toList(),
                onChanged: (value) => setState(() => _category = value),
              ),
              const SizedBox(height: 10),
              _LabeledField(label: 'Price', controller: _price, hint: '\$ 0.00', keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              _DropdownField(
                label: 'Condition',
                value: _condition,
                values: const ['New', 'Like new', 'Handmade', 'Vintage'],
                onChanged: (value) => setState(() => _condition = value),
              ),
              const SizedBox(height: 10),
              _LabeledField(label: 'Location', controller: _location, hint: 'City or Region'),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  child: const Text('Publish listing', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Your posts',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        const Text(
          'Manage or remove the listings you have already published.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 8),
        if (widget.myPosts.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'You have not posted anything yet.',
              style: TextStyle(color: AppColors.textLight),
            ),
          )
        else
          for (final post in widget.myPosts)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(post.imageUrl, width: 54, height: 54, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(
                          '${post.category} · ${post.priceLabel}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => widget.onDeletePost(post.id),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  void _submit() {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    widget.onCreatePost(
      ArtPost(
        id: DateTime.now().millisecondsSinceEpoch,
        title: title,
        seller: 'Sokha Chea',
        sellerId: 999,
        category: _category,
        condition: _condition,
        location: _location.text.trim().isEmpty ? 'Cambodia' : _location.text.trim(),
        imageUrl: demoUploadImageUrl,
        description: _description.text.trim().isEmpty
            ? 'Shared with love from Cambodia.'
            : _description.text.trim(),
        price: double.tryParse(_price.text.trim()),
      ),
    );
    _title.clear();
    _description.clear();
    _price.clear();
    _location.clear();
  }
}

class SavedScreen extends StatelessWidget {
  const SavedScreen({
    super.key,
    required this.posts,
    required this.onOpenPost,
  });

  final List<ArtPost> posts;
  final ValueChanged<ArtPost> onOpenPost;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<ArtPost>>{};
    for (final post in posts) {
      grouped.putIfAbsent(post.category, () => []).add(post);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
      children: [
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Saved', style: TextStyle(color: AppColors.primary, fontSize: 17, fontWeight: FontWeight.w900)),
                Text('${posts.length} items', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (posts.isEmpty)
          const Center(child: Text('Nothing saved yet.'))
        else
          for (final entry in grouped.entries) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                _Pill(label: '${entry.value.length} items'),
              ],
            ),
            const SizedBox(height: 12),
            AlbumGrid(posts: entry.value, onOpenPost: onOpenPost),
            const SizedBox(height: 22),
          ],
      ],
    );
  }
}

class AlbumGrid extends StatelessWidget {
  const AlbumGrid({
    super.key,
    required this.posts,
    required this.onOpenPost,
  });

  final List<ArtPost> posts;
  final ValueChanged<ArtPost> onOpenPost;

  @override
  Widget build(BuildContext context) {
    final visiblePosts = posts.take(6).toList();
    final overflow = posts.length - visiblePosts.length;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visiblePosts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
      ),
      itemBuilder: (context, index) {
        final post = visiblePosts[index];
        final showOverflow = index == 5 && overflow > 0;
        return GestureDetector(
          onTap: () => onOpenPost(post),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(post.imageUrl, fit: BoxFit.cover),
                if (showOverflow)
                  Container(
                    color: Colors.black.withValues(alpha: 0.55),
                    alignment: Alignment.center,
                    child: Text(
                      '+$overflow more',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

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
                IconButton(onPressed: () => setState(() => _activeConversation = null), icon: const Icon(Icons.arrow_back)),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.text,
                  child: Text(_initial(active.sellerName), style: const TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(active.sellerName, style: const TextStyle(fontWeight: FontWeight.w900)),
                      Text(
                        active.online ? 'Active now' : 'Last seen recently',
                        style: TextStyle(color: active.online ? AppColors.success : AppColors.textLight, fontSize: 12),
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
                const Center(child: _Pill(label: 'Today, 10:42 AM')),
                const SizedBox(height: 12),
                for (final message in active.messages) MessageBubble(message: message),
                const Padding(
                  padding: EdgeInsets.only(left: 4, top: 6),
                  child: _TypingDots(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
            child: Row(
              children: [
                const Icon(Icons.add_circle_outline, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _message,
                    decoration: const InputDecoration(hintText: 'Type a message...'),
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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
      children: [
        Row(
          children: [
            const Text('Messages', style: TextStyle(color: AppColors.primary, fontSize: 17, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 14),
        const TextField(
          decoration: InputDecoration(
            hintText: 'Search messages...',
            prefixIcon: Icon(Icons.search, color: AppColors.textLight),
          ),
        ),
        const SizedBox(height: 14),
        for (final conversation in widget.conversations)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            onTap: () => setState(() => _activeConversation = conversation),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.text,
                  child: Text(_initial(conversation.sellerName), style: const TextStyle(color: Colors.white)),
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
            title: Text(conversation.sellerName, style: const TextStyle(fontWeight: FontWeight.w900)),
            subtitle: Text(
              conversation.messages.isEmpty ? 'Tap to start chatting' : conversation.messages.last.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              conversation.messages.isEmpty ? '' : conversation.messages.last.time,
              style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w800),
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
          style: TextStyle(color: message.isMe ? Colors.white : AppColors.text, height: 1.35),
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.userName,
    required this.savedCount,
    required this.postCount,
    required this.chatCount,
    required this.myPosts,
    required this.onOpenPost,
    required this.onLogout,
  });

  final String userName;
  final int savedCount;
  final int postCount;
  final int chatCount;
  final List<ArtPost> myPosts;
  final ValueChanged<ArtPost> onOpenPost;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            const Align(
              alignment: Alignment.center,
              child: Text(
                'Profile',
                style: TextStyle(color: AppColors.primary, fontSize: 17, fontWeight: FontWeight.w900),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () => _showSettingsSheet(context),
                icon: const Icon(Icons.settings_outlined),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 43,
                backgroundColor: AppColors.text,
                child: Text(
                  _initial(userName),
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 10),
              Text(userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              const Text('Art lover & collector · Cambodia', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: BorderSide.none,
                  backgroundColor: AppColors.soft,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                ),
                child: const Text('Edit profile', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Stat(value: savedCount, label: 'Saved'),
              _Stat(value: postCount, label: 'Posts'),
              _Stat(value: chatCount, label: 'Chats'),
            ],
          ),
        ),
        const Divider(),
        const SizedBox(height: 16),
        const Text('My Posts', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
        const SizedBox(height: 10),
        if (myPosts.isEmpty)
          const Text('No posts yet.', style: TextStyle(color: AppColors.textLight))
        else
          AlbumGrid(posts: myPosts, onOpenPost: onOpenPost),
      ],
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Settings',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout, color: AppColors.primary),
                  title: const Text(
                    'Log out',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onLogout();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    this.hint,
    this.obscureText = false,
    this.maxLines = 1,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscureText;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          maxLines: obscureText ? 1 : maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: values.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
          decoration: const InputDecoration(),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    this.background = AppColors.soft,
    this.foreground = AppColors.textSecondary,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(22)),
      child: Text(label, style: TextStyle(color: foreground, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}

class _OutlinePill extends StatelessWidget {
  const _OutlinePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    );
  }
}

class _TypingDots extends StatelessWidget {
  const _TypingDots();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(20)),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _Dot(),
          _Dot(),
          _Dot(),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return const CircleAvatar(radius: 3, backgroundColor: AppColors.textLight);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
  });

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}

String _initial(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
}
