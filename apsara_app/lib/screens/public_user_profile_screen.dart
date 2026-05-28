import 'package:flutter/material.dart';

import '../models/art_post.dart';
import '../models/message_model.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/engagement_service.dart';
import '../services/post_service.dart';
import '../services/profile_service.dart';
import '../services/saved_post_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_cached_media.dart';
import '../widgets/post_grids.dart';
import 'chat_room_view.dart';
import 'post_detail_screen.dart';

class PublicUserProfileScreen extends StatelessWidget {
  PublicUserProfileScreen({
    super.key,
    required this.userId,
    required this.fallbackName,
    this.fallbackAvatarUrl,
  });

  final String userId;
  final String fallbackName;
  final String? fallbackAvatarUrl;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfile?>(
      stream: ProfileService.instance.watchUserProfileById(userId),
      builder: (context, profileSnapshot) {
        final profile = profileSnapshot.data;
        final displayName = profile?.displayName.trim().isNotEmpty == true
            ? profile!.displayName
            : fallbackName;
        final bio = profile?.bio.trim().isNotEmpty == true
            ? profile!.bio
            : 'No bio yet';
        final avatarUrl = profile?.avatarUrl ?? fallbackAvatarUrl;

        return Scaffold(
          backgroundColor: context.appColors.surface,
          appBar: AppBar(
            backgroundColor: context.appColors.surface,
            surfaceTintColor: context.appColors.surface,
            centerTitle: true,
            title: Text('Profile'),
            actions: [
              IconButton(
                onPressed: () => _openChat(
                  context,
                  displayName: displayName,
                  email: profile?.email ?? '',
                  avatarUrl: avatarUrl,
                ),
                icon: Icon(Icons.mode_comment_outlined),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                Center(
                  child: AppAvatar(
                    displayName: displayName,
                    imageUrl: avatarUrl,
                    radius: 43,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  bio,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.appColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 24),
                Divider(color: context.appColors.border),
                SizedBox(height: 16),
                Text(
                  'Posts',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
                SizedBox(height: 10),
                StreamBuilder<List<ArtPost>>(
                  stream: PostService.instance.watchPostsBySeller(userId),
                  builder: (context, postsSnapshot) {
                    final posts = postsSnapshot.data ?? <ArtPost>[];
                    if (posts.isEmpty) {
                      return Text(
                        'No posts yet.',
                        style: TextStyle(color: context.appColors.textLight),
                      );
                    }

                    return AlbumGrid(
                      posts: posts,
                      onOpenPost: (post) => _openPost(context, post),
                      limitToSix: false,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openChat(
    BuildContext context, {
    required String displayName,
    required String email,
    required String? avatarUrl,
  }) async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) {
      return;
    }

    UserProfile currentProfile;
    try {
      currentProfile = await ProfileService.instance
          .watchCurrentUserProfile(currentUser)
          .first;
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to start chat.')),
        );
      }
      return;
    }
    if (!context.mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: context.appColors.surface,
          body: SafeArea(
            bottom: false,
            child: ChatRoomView(
              currentUser: currentUser,
              currentProfile: currentProfile,
              peer: ChatPeer(
                uid: userId,
                displayName: displayName,
                email: email,
                avatarUrl: avatarUrl,
              ),
              onBack: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openPost(BuildContext context, ArtPost post) async {
    final user = AuthService.instance.currentUser;
    final userId = user?.uid ?? '';
    final isOwnPost = post.sellerUid == userId;
    final likedIds = await EngagementService.instance.fetchLikedPostIdsForPosts(
      userId: userId,
      posts: [post],
    );
    final isSaved = userId.isEmpty
        ? false
        : await SavedPostService.instance.isSaved(
            userId: userId,
            postId: post.storageId,
          );
    if (!context.mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return PostDetailSheet(
          post: post,
          isSaved: isSaved,
          isLiked: likedIds.contains(post.storageId),
          isOwnPost: isOwnPost,
          onSetSaved: (post, saved) {
            return SavedPostService.instance.setSaved(
              userId: userId,
              post: post,
              saved: saved,
            );
          },
          onSetLiked: (post, liked) {
            return EngagementService.instance.setLiked(
              userId: userId,
              post: post,
              liked: liked,
            );
          },
          onAddComment: (post, text) {
            return EngagementService.instance.addComment(
              userId: userId,
              userName: user == null
                  ? 'Apsara user'
                  : AuthService.instance.displayNameFor(user),
              post: post,
              text: text,
            );
          },
          onSharePost: (post) {
            return EngagementService.instance.recordShare(
              userId: userId,
              post: post,
            );
          },
          onMessageSeller: () => Navigator.pop(context),
          onDelete: null,
        );
      },
    );
  }
}
