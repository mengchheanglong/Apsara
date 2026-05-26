import 'package:flutter/material.dart';

import '../models/art_post.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';
import '../widgets/app_cached_media.dart';
import '../widgets/post_grids.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.profile,
    required this.myPosts,
    required this.onOpenPost,
    required this.onUpdateProfile,
    required this.onLogout,
  });

  final UserProfile profile;
  final List<ArtPost> myPosts;
  final ValueChanged<ArtPost> onOpenPost;
  final Future<void> Function({
    required String displayName,
    required String bio,
    String? avatarUrl,
  }) onUpdateProfile;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = profile.avatarUrl;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            const Align(
              alignment: Alignment.center,
              child: Text(
                'Profile',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () => _showSettingsSheet(context),
                icon: const Icon(Icons.settings_outlined),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Center(
          child: Column(
            children: [
              AppAvatar(
                displayName: profile.displayName,
                imageUrl: avatarUrl,
                radius: 43,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
              const SizedBox(height: 10),
              Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 42),
                      child: Text(
                        profile.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: IconButton(
                      onPressed: () => _openEditProfile(context),
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        minimumSize: const Size(34, 34),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                profile.bio.isEmpty ? 'No bio yet' : profile.bio,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),
        const Text('My Posts',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 10),
        if (myPosts.isEmpty)
          const Text('No posts yet.',
              style: TextStyle(color: AppColors.textLight))
        else
          AlbumGrid(posts: myPosts, onOpenPost: onOpenPost),
      ],
    );
  }

  Future<void> _openEditProfile(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return EditProfileScreen(
            profile: profile,
            onSave: onUpdateProfile,
          );
        },
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Settings',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout, color: AppColors.primary),
                  title: const Text(
                    'Log out',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onLogout();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
