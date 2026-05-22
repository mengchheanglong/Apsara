import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';

class ProfileService {
  ProfileService._();

  static final ProfileService instance = ProfileService._();
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<UserProfile> watchCurrentUserProfile(User user) {
    return _db.collection('users').doc(user.uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        return UserProfile.fromUser(user);
      }

      return UserProfile(
        uid: user.uid,
        displayName:
            _stringValue(data['displayName']) ?? displayNameForUser(user),
        email: _stringValue(data['email']) ?? user.email ?? '',
        bio: _stringValue(data['bio']) ?? 'Art lover & collector · Cambodia',
        avatarUrl: _stringValue(data['avatarUrl']) ?? user.photoURL,
      );
    });
  }

  Stream<UserProfile?> watchUserProfileById(String userId) {
    if (userId.trim().isEmpty) {
      return Stream.value(null);
    }

    return _db.collection('users').doc(userId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        return null;
      }

      return UserProfile(
        uid: userId,
        displayName: _stringValue(data['displayName']) ?? 'Apsara user',
        email: _stringValue(data['email']) ?? '',
        bio: _stringValue(data['bio']) ?? '',
        avatarUrl: _stringValue(data['avatarUrl']),
      );
    });
  }

  Future<void> createInitialProfile({
    required User user,
    required String displayName,
  }) {
    return _upsertUserProfile(
      user: user,
      displayName: displayName,
      bio: 'Art lover & collector · Cambodia',
      avatarUrl: null,
      includeCreatedAt: true,
    );
  }

  Future<void> updateProfile({
    required String displayName,
    required String bio,
    String? avatarUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    final cleanName = displayName.trim();
    final cleanBio = bio.trim();
    await user.updateDisplayName(cleanName);
    if (avatarUrl != null) {
      await user.updatePhotoURL(avatarUrl);
    }

    await _upsertUserProfile(
      user: user,
      displayName: cleanName,
      bio: cleanBio,
      avatarUrl: avatarUrl ?? user.photoURL,
    );
    await user.reload();
  }

  Future<void> _upsertUserProfile({
    required User user,
    required String displayName,
    required String bio,
    required String? avatarUrl,
    bool includeCreatedAt = false,
  }) async {
    await _db.collection('users').doc(user.uid).set({
      'displayName': displayName,
      'email': user.email,
      'bio': bio,
      if (avatarUrl != null && avatarUrl.trim().isNotEmpty)
        'avatarUrl': avatarUrl,
      'updatedAt': FieldValue.serverTimestamp(),
      if (includeCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String? _stringValue(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
