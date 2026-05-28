import 'package:flutter/material.dart';

import '../models/art_post.dart';
import '../theme/app_theme.dart';
import 'app_cached_media.dart';

class MasonryPostGrid extends StatelessWidget {
  MasonryPostGrid({
    super.key,
    required this.posts,
    required this.onOpenPost,
    this.showMetadata = true,
  });

  final List<ArtPost> posts;
  final ValueChanged<ArtPost> onOpenPost;
  final bool showMetadata;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return Padding(
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
          child: _PostColumn(
            posts: left,
            onOpenPost: onOpenPost,
            offset: 0,
            showMetadata: showMetadata,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _PostColumn(
            posts: right,
            onOpenPost: onOpenPost,
            offset: 1,
            showMetadata: showMetadata,
          ),
        ),
      ],
    );
  }
}

class _PostColumn extends StatelessWidget {
  _PostColumn({
    required this.posts,
    required this.onOpenPost,
    required this.offset,
    required this.showMetadata,
  });

  final List<ArtPost> posts;
  final ValueChanged<ArtPost> onOpenPost;
  final int offset;
  final bool showMetadata;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < posts.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: 18),
            child: PostCard(
              post: posts[i],
              imageHeight: 172 + (((i + offset) % 3) * 42),
              onTap: () => onOpenPost(posts[i]),
              showMetadata: showMetadata,
            ),
          ),
      ],
    );
  }
}

class PostCard extends StatelessWidget {
  PostCard({
    super.key,
    required this.post,
    required this.imageHeight,
    required this.onTap,
    this.showMetadata = true,
  });

  final ArtPost post;
  final double imageHeight;
  final VoidCallback onTap;
  final bool showMetadata;

  @override
  Widget build(BuildContext context) {
    final hasCaption = showMetadata &&
        post.title.trim().isNotEmpty &&
        post.title.trim() != 'Untitled craft';

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
              color: context.appColors.soft,
              alignment: Alignment.center,
              child: Icon(Icons.image_not_supported_outlined),
            ),
          ),
          if (hasCaption) ...[
            SizedBox(height: 7),
            RichText(
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(
                  color: context.appColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
                children: [
                  TextSpan(text: post.title),
                  if (post.isForSale) ...[
                    TextSpan(
                      text: ' · ',
                      style: TextStyle(color: context.appColors.textLight),
                    ),
                    TextSpan(
                      text: post.priceLabel,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AlbumGrid extends StatelessWidget {
  AlbumGrid({
    super.key,
    required this.posts,
    required this.onOpenPost,
    this.limitToSix = true,
    this.onOverflowTap,
  });

  final List<ArtPost> posts;
  final ValueChanged<ArtPost> onOpenPost;
  final bool limitToSix;
  final VoidCallback? onOverflowTap;

  @override
  Widget build(BuildContext context) {
    final visiblePosts = limitToSix ? posts.take(6).toList() : posts;
    final overflow = posts.length - visiblePosts.length;
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: visiblePosts.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
      ),
      itemBuilder: (context, index) {
        final post = visiblePosts[index];
        final showOverflow = limitToSix && index == 5 && overflow > 0;
        return GestureDetector(
          onTap: () {
            if (showOverflow && onOverflowTap != null) {
              onOverflowTap!();
              return;
            }
            onOpenPost(post);
          },
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
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
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
