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
        bio: _bioValue(data['bio'], fallback: 'No bio'),
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
        bio: _bioValue(data['bio']),
        avatarUrl: _stringValue(data['avatarUrl']),
      );
    });
  }

  Stream<List<UserProfile>> watchProfiles() {
    return _db.collection('users').snapshots().map((snapshot) {
      final profiles = snapshot.docs
          .map((doc) => UserProfile(
                uid: doc.id,
                displayName:
                    _stringValue(doc.data()['displayName']) ?? 'Apsara user',
                email: _stringValue(doc.data()['email']) ?? '',
                bio: _bioValue(doc.data()['bio']),
                avatarUrl: _stringValue(doc.data()['avatarUrl']),
              ))
          .toList();
      profiles.sort(
        (a, b) => a.displayName.toLowerCase().compareTo(
              b.displayName.toLowerCase(),
            ),
      );
      return profiles;
    });
  }

  Future<Map<String, UserProfile>> fetchProfilesByIds(
      Iterable<String> userIds) async {
    final ids =
        userIds.map((id) => id.trim()).where((id) => id.isNotEmpty).toSet();
    if (ids.isEmpty) {
      return const {};
    }

    final result = <String, UserProfile>{};
    final allIds = ids.toList();
    for (var i = 0; i < allIds.length; i += 10) {
      final chunk = allIds.skip(i).take(10).toList();
      final snapshot = await _db
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snapshot.docs) {
        result[doc.id] = UserProfile(
          uid: doc.id,
          displayName: _stringValue(doc.data()['displayName']) ?? 'Apsara user',
          email: _stringValue(doc.data()['email']) ?? '',
          bio: _bioValue(doc.data()['bio']),
          avatarUrl: _stringValue(doc.data()['avatarUrl']),
        );
      }
    }

    return result;
  }

  Future<void> createInitialProfile({
    required User user,
    required String displayName,
  }) {
    return _upsertUserProfile(
      user: user,
      displayName: displayName,
      bio: 'No bio',
      avatarUrl: null,
      includeCreatedAt: true,
    );
  }

  Future<void> ensureProfileExists(User user) async {
    final profileRef = _db.collection('users').doc(user.uid);
    final snapshot = await profileRef.get();
    if (snapshot.exists) {
      return;
    }

    await _upsertUserProfile(
      user: user,
      displayName: displayNameForUser(user),
      bio: 'No bio',
      avatarUrl: user.photoURL,
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
    final normalizedAvatarUrl = avatarUrl?.trim();
    final currentName = user.displayName?.trim() ?? '';
    final currentAvatarUrl = user.photoURL?.trim() ?? '';

    final authUpdates = <Future<void>>[];
    if (cleanName != currentName) {
      authUpdates.add(user.updateDisplayName(cleanName));
    }
    if (normalizedAvatarUrl != null &&
        normalizedAvatarUrl != currentAvatarUrl) {
      authUpdates.add(user.updatePhotoURL(normalizedAvatarUrl));
    }
    if (authUpdates.isNotEmpty) {
      await Future.wait(authUpdates);
    }

    await _upsertUserProfile(
      user: user,
      displayName: cleanName,
      bio: cleanBio,
      avatarUrl: normalizedAvatarUrl ?? user.photoURL,
    );
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

  String _bioValue(Object? value, {String fallback = ''}) {
    final text = _stringValue(value);
    if (text == null) {
      return fallback;
    }

    return text.toLowerCase().startsWith('art lover') ? 'No bio' : text;
  }
}
