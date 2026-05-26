import 'package:apsara_app/models/art_post.dart';
import 'package:apsara_app/screens/saved_screen.dart';
import 'package:apsara_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('saved screen renders empty state and count', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildApsaraTheme(),
        home: Scaffold(
          body: SavedScreen(
            posts: [],
            onOpenPost: _noopOpenPost,
          ),
        ),
      ),
    );

    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('0 posts'), findsOneWidget);
    expect(find.text('Nothing saved yet'), findsOneWidget);
    expect(find.text('Tap Save on any item'), findsOneWidget);
  });
}

void _noopOpenPost(ArtPost _) {}
