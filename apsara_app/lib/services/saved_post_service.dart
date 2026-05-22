import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/art_post.dart';

class SavedPostService {
  SavedPostService._();

  static final SavedPostService instance = SavedPostService._();
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<Set<String>> watchSavedPostIds(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('savedPosts')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
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
}
