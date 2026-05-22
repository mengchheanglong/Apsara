import 'package:flutter/material.dart';

import '../models/art_post.dart';
import '../theme/app_theme.dart';
import '../widgets/post_grids.dart';

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
