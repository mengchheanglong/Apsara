import 'package:flutter/material.dart';

import '../models/art_post.dart';
import '../theme/app_theme.dart';
import '../widgets/post_grids.dart';

class SavedCategoryScreen extends StatelessWidget {
  const SavedCategoryScreen({
    super.key,
    required this.category,
    required this.posts,
    required this.onOpenPost,
  });

  final String category;
  final List<ArtPost> posts;
  final ValueChanged<ArtPost> onOpenPost;

  @override
  Widget build(BuildContext context) {
    final countLabel =
        '${posts.length} ${posts.length == 1 ? 'post' : 'posts'}';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              category,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              countLabel,
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            MasonryPostGrid(
              posts: posts,
              onOpenPost: onOpenPost,
              showMetadata: false,
            ),
          ],
        ),
      ),
    );
  }
}
