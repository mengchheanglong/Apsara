import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FirebaseSetupScreen extends StatelessWidget {
  const FirebaseSetupScreen({
    super.key,
    this.error,
  });

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Firebase setup required',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Authentication is wired into the app, but Firebase could not initialize for this build.',
                    style: TextStyle(color: AppColors.textSecondary, height: 1.45),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.soft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const SelectableText(
                      'Make sure FlutterFire configuration completed successfully, '
                      '`android/app/google-services.json` exists, and the Firebase project has Android Auth enabled.',
                      style: TextStyle(height: 1.45),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      'Init error: $error',
                      style: const TextStyle(color: AppColors.primary, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
