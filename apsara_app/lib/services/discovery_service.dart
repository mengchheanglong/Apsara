import '../models/art_post.dart';

class DiscoveryService {
  const DiscoveryService._();

  static List<ArtPost> rankPosts({
    required List<ArtPost> posts,
    required Set<String> likedPostIds,
    required Set<String> savedPostIds,
  }) {
    if (posts.length < 2) {
      return posts;
    }

    final categoryWeights = _categoryWeights(
      posts: posts,
      likedPostIds: likedPostIds,
      savedPostIds: savedPostIds,
    );

    final indexed = posts.indexed.map((entry) {
      final index = entry.$1;
      final post = entry.$2;
      return _RankedPost(
        post: post,
        index: index,
        score: _scorePost(
          post: post,
          index: index,
          total: posts.length,
          categoryWeights: categoryWeights,
          likedPostIds: likedPostIds,
          savedPostIds: savedPostIds,
        ),
      );
    }).toList();

    indexed.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      final indexCompare = a.index.compareTo(b.index);
      if (indexCompare != 0) {
        return indexCompare;
      }
      return a.post.title.compareTo(b.post.title);
    });

    return indexed.map((entry) => entry.post).toList();
  }

  static Map<String, int> _categoryWeights({
    required List<ArtPost> posts,
    required Set<String> likedPostIds,
    required Set<String> savedPostIds,
  }) {
    final weights = <String, int>{};
    for (final post in posts) {
      if (likedPostIds.contains(post.storageId)) {
        weights.update(post.category, (value) => value + 3, ifAbsent: () => 3);
      }
      if (savedPostIds.contains(post.storageId)) {
        weights.update(post.category, (value) => value + 2, ifAbsent: () => 2);
      }
    }
    return weights;
  }

  static int _scorePost({
    required ArtPost post,
    required int index,
    required int total,
    required Map<String, int> categoryWeights,
    required Set<String> likedPostIds,
    required Set<String> savedPostIds,
  }) {
    final affinity = categoryWeights[post.category] ?? 0;
    final engagement = (post.likes * 3) + (post.comments * 2) + post.shares;
    final recencyBias = total - index;
    final savedBoost = savedPostIds.contains(post.storageId) ? 4 : 0;
    final likedBoost = likedPostIds.contains(post.storageId) ? 3 : 0;
    final saleBoost = post.isForSale ? 1 : 0;
    return affinity +
        engagement +
        recencyBias +
        savedBoost +
        likedBoost +
        saleBoost;
  }
}

class _RankedPost {
  const _RankedPost({
    required this.post,
    required this.index,
    required this.score,
  });

  final ArtPost post;
  final int index;
  final int score;
}
