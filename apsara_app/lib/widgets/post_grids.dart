import 'package:flutter/material.dart';

import '../models/art_post.dart';
import '../theme/app_theme.dart';
import 'app_cached_media.dart';

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
        Expanded(
            child: _PostColumn(posts: left, onOpenPost: onOpenPost, offset: 0)),
        const SizedBox(width: 10),
        Expanded(
            child:
                _PostColumn(posts: right, onOpenPost: onOpenPost, offset: 1)),
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
          AppCachedImage(
            imageUrl: post.imageUrl,
            height: imageHeight,
            width: double.infinity,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(16),
            errorChild: Container(
              height: imageHeight,
              color: AppColors.soft,
              alignment: Alignment.center,
              child: const Icon(Icons.image_not_supported_outlined),
            ),
          ),
          const SizedBox(height: 7),
          RichText(
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
              children: [
                TextSpan(text: post.title),
                if (post.isForSale) ...[
                  const TextSpan(
                    text: ' · ',
                    style: TextStyle(color: AppColors.textLight),
                  ),
                  TextSpan(
                    text: post.priceLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
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
                AppCachedImage(
                  imageUrl: post.imageUrl,
                  fit: BoxFit.cover,
                ),
                if (showOverflow)
                  Container(
                    color: Colors.black.withValues(alpha: 0.55),
                    alignment: Alignment.center,
                    child: Text(
                      '+$overflow more',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w900),
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
