import 'package:firebase_auth/firebase_auth.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.bio,
    this.avatarUrl,
  });

  final String uid;
  final String displayName;
  final String email;
  final String bio;
  final String? avatarUrl;

  factory UserProfile.fromUser(User user) {
    return UserProfile(
      uid: user.uid,
      displayName: displayNameForUser(user),
      email: user.email ?? '',
      bio: 'No bio',
      avatarUrl: user.photoURL,
    );
  }
}

String displayNameForUser(User user) {
  final displayName = user.displayName?.trim();
  if (displayName != null && displayName.isNotEmpty) {
    return displayName;
  }

  final email = user.email?.trim();
  if (email != null && email.isNotEmpty) {
    return email.split('@').first;
  }

  return 'User';
}
