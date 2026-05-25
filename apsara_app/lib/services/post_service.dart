import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/art_post.dart';

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

  Stream<List<ArtPost>> watchPostsBySeller(String sellerUid) {
    return watchPosts().map((posts) {
      return posts.where((post) => post.sellerUid == sellerUid).toList();
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
      'location': _normalizedLocation(location),
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

  Future<void> updatePost({
    required ArtPost post,
    required String title,
    required String description,
    required String category,
    required String condition,
    required String location,
    required double? price,
    required String imageUrl,
  }) async {
    final documentId = post.documentId;
    if (documentId == null || documentId.isEmpty) {
      return;
    }

    await _db.collection('posts').doc(documentId).update({
      'title': title,
      'description': description,
      'category': category,
      'condition': condition,
      'location': _normalizedLocation(location),
      'imageUrls': [imageUrl],
      'imageUrl': imageUrl,
      'price': price,
      'currency': 'USD',
      'isForSale': price != null && price > 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePost({
    required ArtPost post,
    required String currentUserId,
  }) async {
    final documentId = post.documentId;
    if (documentId == null || documentId.isEmpty) {
      return;
    }

    await _db
        .collection('users')
        .doc(currentUserId)
        .collection('savedPosts')
        .doc(post.storageId)
        .delete();
    await _db.collection('posts').doc(documentId).delete();
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
      location: _normalizedLocation(_stringValue(data['location']) ?? ''),
      imageUrl: imageUrls is List && imageUrls.isNotEmpty
          ? imageUrls.first.toString()
          : _stringValue(data['imageUrl']) ?? '',
      description: _stringValue(data['description']) ?? 'No description',
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

  String _normalizedLocation(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return '';
    }
    if (normalized.toLowerCase() == 'cambodia') {
      return '';
    }
    return normalized;
  }
}
