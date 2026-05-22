import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'firebase_options.dart';
import 'screens/auth_screens.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'widgets/firebase_setup_screen.dart';

class ApsaraApp extends StatelessWidget {
  const ApsaraApp({super.key});

  Future<_FirebaseBootstrapState> _initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return const _FirebaseBootstrapState.ready();
    } catch (error) {
      return _FirebaseBootstrapState.failed(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Apsara',
      debugShowCheckedModeBanner: false,
      theme: buildApsaraTheme(),
      home: FutureBuilder<_FirebaseBootstrapState>(
        future: _initializeFirebase(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const _AppLoadingScreen();
          }

          final state = snapshot.data!;
          if (!state.isReady) {
            return FirebaseSetupScreen(error: state.error);
          }

          return StreamBuilder<User?>(
            stream: AuthService.instance.userChanges(),
            builder: (context, authSnapshot) {
              if (authSnapshot.connectionState == ConnectionState.waiting) {
                return const _AppLoadingScreen();
              }

              final user = authSnapshot.data;
              if (user == null) {
                return const LoginScreen();
              }

              if (AuthService.instance.requiresEmailVerification(user)) {
                return VerifyEmailScreen(user: user);
              }

              return ApsaraShell(user: user);
            },
          );
        },
      ),
    );
  }
}

class _FirebaseBootstrapState {
  const _FirebaseBootstrapState._({
    required this.isReady,
    this.error,
  });

  const _FirebaseBootstrapState.ready() : this._(isReady: true);

  const _FirebaseBootstrapState.failed(Object error)
      : this._(
          isReady: false,
          error: error,
        );

  final bool isReady;
  final Object? error;
}

class _AppLoadingScreen extends StatelessWidget {
  const _AppLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}
