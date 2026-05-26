import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/art_post.dart';
import '../models/post_comment.dart';

class LikeUpdate {
  const LikeUpdate({
    required this.isLiked,
    required this.likeCount,
  });

  final bool isLiked;
  final int likeCount;
}

class EngagementService {
  EngagementService._();

  static final EngagementService instance = EngagementService._();
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<Set<String>> watchLikedPostIds(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('likedPosts')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }

  Future<Set<String>> fetchLikedPostIdsForPosts({
    required String userId,
    required List<ArtPost> posts,
  }) async {
    if (userId.isEmpty || posts.isEmpty) {
      return const {};
    }

    final likedIds = <String>{};
    await Future.wait(posts.map((post) async {
      final snapshot = await _db
          .collection('posts')
          .doc(post.storageId)
          .collection('likes')
          .doc(userId)
          .get();
      if (snapshot.exists) {
        likedIds.add(post.storageId);
      }
    }));
    return likedIds;
  }

  Stream<List<PostComment>> watchComments(ArtPost post) {
    return _db
        .collection('posts')
        .doc(post.storageId)
        .collection('comments')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((document) {
        final data = document.data();
        return PostComment(
          id: document.id,
          userId: _stringValue(data['userId']) ?? '',
          userName: _stringValue(data['userName']) ?? 'Apsara user',
          text: _stringValue(data['text']) ?? '',
          timeLabel: _timeLabel(data['createdAt']),
        );
      }).toList();
    });
  }

  Future<LikeUpdate> setLiked({
    required String userId,
    required ArtPost post,
    required bool liked,
  }) async {
    final postRef = _db.collection('posts').doc(post.storageId);
    final likeRef = postRef.collection('likes').doc(userId);
    final userLikeRef = _db
        .collection('users')
        .doc(userId)
        .collection('likedPosts')
        .doc(post.storageId);

    return _db.runTransaction<LikeUpdate>((transaction) async {
      final likeSnapshot = await transaction.get(likeRef);
      final postSnapshot = await transaction.get(postRef);
      final currentCount = _intValue(postSnapshot.data()?['likeCount']);

      if (liked && likeSnapshot.exists) {
        return LikeUpdate(isLiked: true, likeCount: currentCount);
      }
      if (!liked && !likeSnapshot.exists) {
        return LikeUpdate(isLiked: false, likeCount: currentCount);
      }

      if (!liked) {
        final nextCount = currentCount > 0 ? currentCount - 1 : 0;
        transaction.delete(likeRef);
        transaction.delete(userLikeRef);
        transaction.update(postRef, {
          'likeCount': nextCount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return LikeUpdate(isLiked: false, likeCount: nextCount);
      }

      final nextCount = currentCount + 1;
      transaction.set(likeRef, {
        'userId': userId,
        'postId': post.storageId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.set(userLikeRef, {
        'postId': post.storageId,
        'title': post.title,
        'imageUrl': post.imageUrl,
        'sellerName': post.seller,
        'category': post.category,
        'likedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(postRef, {
        'likeCount': nextCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return LikeUpdate(isLiked: true, likeCount: nextCount);
    });
  }

  Future<void> addComment({
    required String userId,
    required String userName,
    required ArtPost post,
    required String text,
  }) async {
    final postRef = _db.collection('posts').doc(post.storageId);
    final commentRef = postRef.collection('comments').doc();
    final batch = _db.batch();

    batch.set(commentRef, {
      'userId': userId,
      'userName': userName,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(postRef, {
      'commentCount': FieldValue.increment(1),
      'shareCount': FieldValue.increment(0),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> recordShare({
    required String userId,
    required ArtPost post,
  }) async {
    final postRef = _db.collection('posts').doc(post.storageId);
    final shareRef = postRef.collection('shares').doc();
    final batch = _db.batch();

    batch.set(shareRef, {
      'userId': userId,
      'postId': post.storageId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(postRef, {
      'shareCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  String? _stringValue(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  int _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _timeLabel(Object? value) {
    if (value is! Timestamp) {
      return 'Now';
    }

    final difference = DateTime.now().difference(value.toDate());
    if (difference.inMinutes < 1) return 'Now';
    if (difference.inHours < 1) return '${difference.inMinutes}m';
    if (difference.inDays < 1) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    return '${value.toDate().month}/${value.toDate().day}';
  }
}
