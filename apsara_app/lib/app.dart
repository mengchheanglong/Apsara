import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'firebase_options.dart';
import 'screens/auth_screens.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'utils/app_logger.dart';
import 'widgets/firebase_setup_screen.dart';

class ApsaraApp extends StatefulWidget {
  const ApsaraApp({super.key});

  @override
  State<ApsaraApp> createState() => _ApsaraAppState();
}

class _ApsaraAppState extends State<ApsaraApp> {
  final _themeController = ApsaraThemeController();
  late final Future<_FirebaseBootstrapState> _firebaseBootstrapFuture;

  @override
  void initState() {
    super.initState();
    _firebaseBootstrapFuture = _initializeFirebase();
    _themeController.load();
  }

  // Initializes Firebase once at startup and reports either ready or failed state.
  Future<_FirebaseBootstrapState> _initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return const _FirebaseBootstrapState.ready();
    } catch (error, stackTrace) {
      AppLogger.error('Firebase initialization failed', error, stackTrace);
      return _FirebaseBootstrapState.failed(error);
    }
  }

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  @override
  // Routes the user into login, verification, or the main app based on auth state.
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Apsara',
          debugShowCheckedModeBanner: false,
          theme: buildApsaraTheme(),
          darkTheme: buildApsaraTheme(brightness: Brightness.dark),
          themeMode: _themeController.mode,
          home: FutureBuilder<_FirebaseBootstrapState>(
            future: _firebaseBootstrapFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const _AppLoadingScreen();
              }

              final state = snapshot.data!;
              if (!state.isReady) {
                return _LightAuthTheme(
                  child: FirebaseSetupScreen(error: state.error),
                );
              }

              return StreamBuilder<User?>(
                stream: AuthService.instance.userChanges(),
                builder: (context, authSnapshot) {
                  if (authSnapshot.connectionState == ConnectionState.waiting) {
                    return const _AppLoadingScreen();
                  }

                  final user = authSnapshot.data;
                  if (user == null) {
                    return const _LightAuthTheme(child: LoginScreen());
                  }

                  if (AuthService.instance.requiresEmailVerification(user)) {
                    return _LightAuthTheme(
                      child: VerifyEmailScreen(user: user),
                    );
                  }

                  return ApsaraShell(
                    user: user,
                    isDarkMode: _themeController.isDark,
                    onDarkModeChanged: (enabled) {
                      _themeController.setDarkMode(enabled);
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _LightAuthTheme extends StatelessWidget {
  const _LightAuthTheme({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildApsaraTheme(),
      child: child,
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
  // Shared blocking loader used while Firebase or auth state is still unresolved.
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}
