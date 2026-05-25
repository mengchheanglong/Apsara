import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';
import 'profile_service.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Broadcasts login/logout changes so the app can switch screens reactively.
  Stream<User?> userChanges() => _auth.userChanges();

  // Exposes the current Firebase user for code paths that need it immediately.
  User? get currentUser => _auth.currentUser;

  // Normalizes how the app derives a display name from a Firebase user.
  String displayNameFor(User user) {
    return displayNameForUser(user);
  }

  // Password-based accounts must verify email before entering the app.
  bool requiresEmailVerification(User user) {
    final hasPasswordProvider = user.providerData.any(
      (provider) => provider.providerId == 'password',
    );

    return hasPasswordProvider && !user.emailVerified;
  }

  // Signs an existing user in with email/password.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Creates the auth account, stores the initial profile, then triggers verification.
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

  // Sends Firebase's password-reset email to the submitted address.
  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // Re-sends the verification email for the current signed-in user.
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.sendEmailVerification();
    }
  }

  // Refreshes the cached Firebase user so emailVerified and similar flags are up to date.
  Future<User?> reloadCurrentUser() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser;
  }

  // Ends the Firebase session; app.dart reacts through the auth stream.
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
