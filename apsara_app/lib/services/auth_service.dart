import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';
import 'profile_service.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> userChanges() => _auth.userChanges();

  User? get currentUser => _auth.currentUser;

  String displayNameFor(User user) {
    return displayNameForUser(user);
  }

  bool requiresEmailVerification(User user) {
    final hasPasswordProvider = user.providerData.any(
      (provider) => provider.providerId == 'password',
    );

    return hasPasswordProvider && !user.emailVerified;
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user != null) {
      await user.updateDisplayName(name.trim());
      await ProfileService.instance.createInitialProfile(
        user: user,
        displayName: name.trim(),
      );
      await user.sendEmailVerification();
      await user.reload();
    }
  }

  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.sendEmailVerification();
    }
  }

  Future<User?> reloadCurrentUser() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
