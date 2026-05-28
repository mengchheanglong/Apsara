import 'package:flutter/material.dart';

import '../models/art_post.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/post_grids.dart';
import 'saved_category_screen.dart';

class SavedScreen extends StatefulWidget {
  SavedScreen({
    super.key,
    required this.posts,
    required this.onOpenPost,
  });

  final List<ArtPost> posts;
  final ValueChanged<ArtPost> onOpenPost;

  @override
  State<SavedScreen> createState() => SavedScreenState();
}

class SavedScreenState extends State<SavedScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void refreshCurrentTab() {
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
    final grouped = <String, List<ArtPost>>{};
    for (final post in widget.posts) {
      grouped.putIfAbsent(post.category, () => []).add(post);
    }
    final savedCountLabel =
        '${widget.posts.length} ${widget.posts.length == 1 ? 'post' : 'posts'}';

    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(16, 18, 16, 96),
      children: [
        Text(
          'Saved',
          style: TextStyle(
            color: context.appColors.primary,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 2),
        Text(
          savedCountLabel,
          style: TextStyle(
            color: context.appColors.textLight,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 24),
        if (widget.posts.isEmpty)
          EmptyState(
            icon: Icons.bookmark_border_rounded,
            title: 'Nothing saved yet',
            subtitle: 'Tap Save on any item',
          )
        else
          for (final entry in grouped.entries) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(entry.key,
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ],
            ),
            SizedBox(height: 12),
            AlbumGrid(
              posts: entry.value,
              onOpenPost: widget.onOpenPost,
              onOverflowTap: () => _openCategory(
                context,
                category: entry.key,
                posts: entry.value,
              ),
            ),
            SizedBox(height: 22),
          ],
      ],
    );
  }

  Future<void> _openCategory(
    BuildContext context, {
    required String category,
    required List<ArtPost> posts,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SavedCategoryScreen(
          category: category,
          posts: posts,
          onOpenPost: widget.onOpenPost,
        ),
      ),
    );
  }
}
