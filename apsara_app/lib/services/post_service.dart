import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/art_post.dart';
import '../models/post_comment.dart';

class PostService {
  PostService._();

  static final PostService instance = PostService._();
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<ArtPost>> watchPosts() {
    return _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(_fromDocument).toList(),
        );
  }

  Stream<Set<String>> watchSavedPostIds(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('savedPosts')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }

  Stream<Set<String>> watchLikedPostIds(String userId) {
    return _db
        .collectionGroup('likes')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => _stringValue(doc.data()['postId']))
          .whereType<String>()
          .toSet();
    });
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

  Future<ArtPost> createPost({
    required String sellerUid,
    required String sellerName,
    required String title,
    required String description,
    required String category,
    required String condition,
    required String location,
    required double? price,
    required String imageUrl,
  }) async {
    final data = <String, Object?>{
      'title': title,
      'description': description,
      'category': category,
      'condition': condition,
      'location': location,
      'imageUrls': [imageUrl],
      'price': price,
      'currency': 'USD',
      'isForSale': price != null && price > 0,
      'sellerUid': sellerUid,
      'sellerIdHash': sellerUid.hashCode,
      'sellerName': sellerName,
      'likeCount': 0,
      'commentCount': 0,
      'shareCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final document = await _db.collection('posts').add(data);
    final snapshot = await document.get();
    return _fromDocument(snapshot);
  }

  Future<void> deletePost(ArtPost post) async {
    final documentId = post.documentId;
    if (documentId == null || documentId.isEmpty) {
      return;
    }

    await _db.collection('posts').doc(documentId).delete();
  }

  Future<void> setSaved({
    required String userId,
    required ArtPost post,
    required bool saved,
  }) async {
    final savedRef = _db
        .collection('users')
        .doc(userId)
        .collection('savedPosts')
        .doc(post.storageId);

    if (!saved) {
      await savedRef.delete();
      return;
    }

    await savedRef.set({
      'postId': post.storageId,
      'title': post.title,
      'imageUrl': post.imageUrl,
      'sellerName': post.seller,
      'category': post.category,
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setLiked({
    required String userId,
    required ArtPost post,
    required bool liked,
  }) async {
    final postRef = _db.collection('posts').doc(post.storageId);
    final likeRef = postRef.collection('likes').doc(userId);

    await _db.runTransaction((transaction) async {
      final likeSnapshot = await transaction.get(likeRef);
      final postSnapshot = await transaction.get(postRef);
      final currentCount = _intValue(postSnapshot.data()?['likeCount']);
      final currentShareCount = _intValue(postSnapshot.data()?['shareCount']);

      if (liked && !likeSnapshot.exists) {
        transaction.set(likeRef, {
          'userId': userId,
          'postId': post.storageId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.update(postRef, {
          'likeCount': currentCount + 1,
          'shareCount': currentShareCount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else if (!liked && likeSnapshot.exists) {
        transaction.delete(likeRef);
        transaction.update(postRef, {
          'likeCount': currentCount > 0 ? currentCount - 1 : 0,
          'shareCount': currentShareCount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
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

  ArtPost _fromDocument(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? <String, dynamic>{};
    final imageUrls = data['imageUrls'];
    final sellerUid =
        _stringValue(data['sellerUid']) ?? _stringValue(data['sellerId']);
    final sellerIdHash = data['sellerIdHash'];
    final sellerId = sellerIdHash is int
        ? sellerIdHash
        : (sellerUid ?? document.id).hashCode;

    return ArtPost(
      id: document.id.hashCode & 0x7fffffff,
      documentId: document.id,
      title: _stringValue(data['title']) ?? 'Untitled craft',
      seller: _stringValue(data['sellerName']) ??
          _stringValue(data['seller']) ??
          'Apsara seller',
      sellerId: sellerId,
      sellerUid: sellerUid,
      category: _stringValue(data['category']) ?? 'Others',
      condition: _stringValue(data['condition']) ?? 'Handmade',
      location: _stringValue(data['location']) ?? 'Cambodia',
      imageUrl: imageUrls is List && imageUrls.isNotEmpty
          ? imageUrls.first.toString()
          : _stringValue(data['imageUrl']) ?? '',
      description: _stringValue(data['description']) ??
          'Shared with love from Cambodia.',
      price: _doubleValue(data['price']),
      likes: _intValue(data['likeCount']),
      comments: _intValue(data['commentCount']),
      shares: _intValue(data['shareCount']),
    );
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

  double? _doubleValue(Object? value) {
    if (value == null) return null;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString());
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
