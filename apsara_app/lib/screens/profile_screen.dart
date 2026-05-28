import 'package:flutter/material.dart';

import '../models/art_post.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';
import '../widgets/app_cached_media.dart';
import '../widgets/post_grids.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  ProfileScreen({
    super.key,
    required this.profile,
    required this.myPosts,
    required this.onOpenPost,
    required this.onUpdateProfile,
    required this.onLogout,
    required this.isDarkMode,
    required this.onDarkModeChanged,
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
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void refreshCurrentTab() {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      0,
      duration: Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = widget.profile.avatarUrl;
    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(16, 10, 16, 96),
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.center,
              child: Text(
                'Profile',
                style: TextStyle(
                    color: context.appColors.primary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () => _showSettingsSheet(context),
                icon: Icon(Icons.settings_outlined),
              ),
            ),
          ],
        ),
        SizedBox(height: 18),
        Center(
          child: Column(
            children: [
              AppAvatar(
                displayName: widget.profile.displayName,
                imageUrl: avatarUrl,
                radius: 43,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
              SizedBox(height: 10),
              Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 42),
                      child: Text(
                        widget.profile.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
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
                        minimumSize: Size(34, 34),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: Icon(
                        Icons.edit_outlined,
                        color: context.appColors.textSecondary,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                widget.profile.bio.isEmpty ? 'No bio yet' : widget.profile.bio,
                style: TextStyle(
                    color: context.appColors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        SizedBox(height: 36),
        Text('My Posts',
            style: TextStyle(
                color: context.appColors.text,
                fontWeight: FontWeight.w700,
                fontSize: 15)),
        SizedBox(height: 10),
        if (widget.myPosts.isEmpty)
          Text('No posts yet.',
              style: TextStyle(color: context.appColors.textLight))
        else
          AlbumGrid(
            posts: widget.myPosts,
            onOpenPost: widget.onOpenPost,
            limitToSix: false,
          ),
      ],
    );
  }

  Future<void> _openEditProfile(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return EditProfileScreen(
            profile: widget.profile,
            onSave: widget.onUpdateProfile,
          );
        },
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    var darkMode = widget.isDarkMode;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final sheetTheme = buildApsaraTheme(
              brightness: darkMode ? Brightness.dark : Brightness.light,
            );
            final colors = darkMode ? ApsaraPalette.dark : ApsaraPalette.light;

            return Theme(
              data: sheetTheme,
              child: SafeArea(
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: colors.border,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        SizedBox(height: 18),
                        Text(
                          'Settings',
                          style: TextStyle(
                            color: colors.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          secondary: Icon(
                            darkMode
                                ? Icons.dark_mode_outlined
                                : Icons.light_mode_outlined,
                            color: colors.textSecondary,
                          ),
                          title: Text(
                            'Dark mode',
                            style: TextStyle(
                              color: colors.text,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          value: darkMode,
                          thumbColor: WidgetStateProperty.resolveWith(
                            (states) {
                              if (states.contains(WidgetState.selected)) {
                                return colors.primary;
                              }
                              return darkMode
                                  ? colors.textSecondary
                                  : colors.surface;
                            },
                          ),
                          trackColor: WidgetStateProperty.resolveWith(
                            (states) {
                              if (states.contains(WidgetState.selected)) {
                                return colors.primary.withValues(
                                  alpha: darkMode ? 0.42 : 0.26,
                                );
                              }
                              return colors.soft;
                            },
                          ),
                          trackOutlineColor: WidgetStateProperty.all(
                            colors.border,
                          ),
                          onChanged: (value) {
                            setSheetState(() => darkMode = value);
                            widget.onDarkModeChanged(value);
                          },
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.logout, color: colors.primary),
                          title: Text(
                            'Log out',
                            style: TextStyle(
                              color: colors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            widget.onLogout();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
