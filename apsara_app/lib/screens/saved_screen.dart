import 'package:flutter/material.dart';

import '../models/art_post.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/post_grids.dart';

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
    final savedCountLabel =
        '${posts.length} ${posts.length == 1 ? 'post' : 'posts'}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 96),
      children: [
        const Text(
          'Saved',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          savedCountLabel,
          style: const TextStyle(
            color: AppColors.textLight,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 24),
        if (posts.isEmpty)
          const EmptyState(
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
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
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
