import 'package:flutter/material.dart';

import '../models/art_post.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_cached_media.dart';
import '../widgets/post_grids.dart';
import 'public_user_profile_screen.dart';

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
  final List<String> _recentSearches = [
    'Pottery',
    'Silk & Textiles',
    'Wood Art'
  ];
  String _query = '';

  List<_SearchUserMatch> get _userResults {
    final q = _normalize(_query);
    if (q.isEmpty) {
      return const <_SearchUserMatch>[];
    }

    final byUserId = <String, _SearchUserMatch>{};
    for (final post in widget.posts) {
      final sellerName = post.seller.trim();
      final sellerUid = post.sellerUid?.trim();
      if (sellerName.isEmpty ||
          !_normalize(sellerName).contains(q) ||
          sellerUid == null ||
          sellerUid.isEmpty) {
        continue;
      }
      byUserId.putIfAbsent(
        sellerUid,
        () => _SearchUserMatch(
          userId: sellerUid,
          fallbackName: sellerName,
        ),
      );
    }
    return byUserId.values.toList()
      ..sort((a, b) => a.fallbackName.compareTo(b.fallbackName));
  }

  List<ArtPost> get _results {
    final q = _normalize(_query);
    if (q.isEmpty) return const <ArtPost>[];
    final terms = q.split(RegExp(r'\s+')).where((term) => term.isNotEmpty);
    return widget.posts.where((post) {
      final fields = [
        _normalize(post.title),
        _normalize(post.seller),
        _normalize(post.category),
        _normalize(post.condition),
        _normalize(post.location),
        _normalize(post.description),
      ];
      return terms.every(
        (term) => fields.any((field) => field.contains(term)),
      );
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
      backgroundColor: AppColors.surface,
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
                        hintText: 'Search posts or users...',
                        prefixIcon: const Icon(Icons.search,
                            color: AppColors.textLight),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _controller.clear();
                                  setState(() => _query = '');
                                },
                                icon: const Icon(Icons.close,
                                    color: AppColors.textLight),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _query.trim().isEmpty
                  ? _buildSuggestionView()
                  : _buildResultView(),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22)),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22)),
              onPressed: () => _applySearch(term),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildResultView() {
    final results = _results;
    final users = _userResults;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        const SizedBox(height: 4),
        Text(
          '${users.length + results.length} results',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (users.isEmpty && results.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 80),
            child: Center(
              child: Text(
                'No matching posts or users found.',
                style: TextStyle(color: AppColors.textLight),
              ),
            ),
          )
        else ...[
          if (users.isNotEmpty) ...[
            const Text(
              'Users',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            for (final user in users)
              _SearchUserTile(
                match: user,
              ),
            const SizedBox(height: 22),
          ],
          if (results.isNotEmpty) ...[
            const Text(
              'Posts',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            MasonryPostGrid(
              posts: results,
              onOpenPost: (post) {
                widget.onOpenPost(post);
              },
            ),
          ],
        ],
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

  String _normalize(String value) => value.trim().toLowerCase();
}

class _SearchUserMatch {
  const _SearchUserMatch({
    required this.userId,
    required this.fallbackName,
  });

  final String userId;
  final String fallbackName;
}

class _SearchUserTile extends StatelessWidget {
  const _SearchUserTile({
    required this.match,
  });

  final _SearchUserMatch match;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfile?>(
      stream: ProfileService.instance.watchUserProfileById(match.userId),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final displayName = profile?.displayName.trim().isNotEmpty == true
            ? profile!.displayName
            : match.fallbackName;
        final avatarUrl = profile?.avatarUrl;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PublicUserProfileScreen(
                  userId: match.userId,
                  fallbackName: displayName,
                  fallbackAvatarUrl: avatarUrl,
                ),
              ),
            );
          },
          leading: AppAvatar(
            displayName: displayName,
            imageUrl: avatarUrl,
            radius: 22,
            backgroundColor: AppColors.secondary,
          ),
          title: Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: const Text(
            'View profile',
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 12,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: AppColors.textLight,
          ),
        );
      },
    );
  }
}
