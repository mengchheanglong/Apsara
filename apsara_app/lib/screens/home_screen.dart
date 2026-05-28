import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../models/art_post.dart';
import '../theme/app_theme.dart';
import '../widgets/post_grids.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({
    super.key,
    required this.posts,
    required this.isLoading,
    required this.loadError,
    required this.onRetry,
    required this.onOpenPost,
    required this.onOpenSearch,
    required this.onOpenPostTools,
  });

  final List<ArtPost> posts;
  final bool isLoading;
  final Object? loadError;
  final VoidCallback onRetry;
  final ValueChanged<ArtPost> onOpenPost;
  final Future<void> Function() onOpenSearch;
  final Future<void> Function() onOpenPostTools;

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  static const _postSwipeMinimumDistance = 120.0;
  static const _postSwipeMinimumVelocity = 450.0;

  final _scrollController = ScrollController();
  String _category = 'All';
  double _postSwipeOffset = 0;

  List<ArtPost> get _filteredPosts {
    return widget.posts.where((post) {
      final matchesCategory = _category == 'All' || post.category == _category;
      return matchesCategory;
    }).toList();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void scrollCurrentCategoryToTop() {
    if (!_scrollController.hasClients) {
      return;
    }

    _scrollController.animateTo(
      0,
      duration: Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final posts = _filteredPosts;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) => _postSwipeOffset = 0,
      onHorizontalDragUpdate: (details) {
        _postSwipeOffset += details.primaryDelta ?? 0;
      },
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        final hasEnoughDistance = _postSwipeOffset > _postSwipeMinimumDistance;
        final hasEnoughVelocity = velocity > _postSwipeMinimumVelocity;

        if (hasEnoughDistance && hasEnoughVelocity) {
          widget.onOpenPostTools();
        }

        _postSwipeOffset = 0;
      },
      onHorizontalDragCancel: () {
        _postSwipeOffset = 0;
      },
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, 4, 14, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onOpenPostTools,
                    icon: Icon(Icons.add, color: context.appColors.text),
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.onOpenSearch,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: context.appColors.soft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            Icon(Icons.search,
                                color: context.appColors.textLight, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Search posts or users...',
                              style: TextStyle(
                                color: context.appColors.textLight,
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
                padding: EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final selected = category == _category;
                  return ChoiceChip(
                    selected: selected,
                    label: Text(category),
                    showCheckmark: false,
                    selectedColor: context.appColors.primary,
                    backgroundColor: context.appColors.soft,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : context.appColors.text,
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                    ),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    onSelected: (_) => setState(() => _category = category),
                  );
                },
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 96),
            sliver: SliverToBoxAdapter(
              child: _HomeBody(
                posts: posts,
                category: _category,
                isLoading: widget.isLoading,
                loadError: widget.loadError,
                onRetry: widget.onRetry,
                onOpenPost: widget.onOpenPost,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  _HomeBody({
    required this.posts,
    required this.category,
    required this.isLoading,
    required this.loadError,
    required this.onRetry,
    required this.onOpenPost,
  });

  final List<ArtPost> posts;
  final String category;
  final bool isLoading;
  final Object? loadError;
  final VoidCallback onRetry;
  final ValueChanged<ArtPost> onOpenPost;

  @override
  Widget build(BuildContext context) {
    if (isLoading && posts.isEmpty) {
      return _HomeLoadingState();
    }
    if (loadError != null && posts.isEmpty) {
      return _HomeErrorState(onRetry: onRetry);
    }
    if (posts.isEmpty) {
      return _HomeEmptyState(category: category);
    }
    return MasonryPostGrid(
      posts: posts,
      onOpenPost: onOpenPost,
      showMetadata: false,
    );
  }
}

class _HomeEmptyState extends StatelessWidget {
  _HomeEmptyState({
    required this.category,
  });

  final String category;

  @override
  Widget build(BuildContext context) {
    final isFiltered = category != 'All';
    return SizedBox(
      width: double.infinity,
      height: MediaQuery.sizeOf(context).height * 0.48,
      child: Align(
        alignment: Alignment(0, -0.18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_outlined,
              color: context.appColors.textLight,
              size: 34,
            ),
            SizedBox(height: 10),
            Text(
              isFiltered ? 'No $category posts yet' : 'No posts yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeLoadingState extends StatelessWidget {
  _HomeLoadingState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: MediaQuery.sizeOf(context).height * 0.48,
      child: Align(
        alignment: Alignment(0, -0.18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: context.appColors.primary,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Loading posts...',
              style: TextStyle(
                color: context.appColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeErrorState extends StatelessWidget {
  _HomeErrorState({
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: MediaQuery.sizeOf(context).height * 0.48,
      child: Align(
        alignment: Alignment(0, -0.18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_tethering_error_rounded,
              color: context.appColors.textLight,
              size: 34,
            ),
            SizedBox(height: 10),
            Text(
              'Unable to load posts',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Check your connection and try again',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.appColors.textSecondary,
                fontSize: 12,
              ),
            ),
            SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
