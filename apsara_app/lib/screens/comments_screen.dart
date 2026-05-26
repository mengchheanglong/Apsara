import 'package:flutter/material.dart';

import '../models/art_post.dart';
import '../models/post_comment.dart';
import '../models/user_profile.dart';
import '../services/engagement_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_cached_media.dart';
import 'public_user_profile_screen.dart';

class CommentsScreen extends StatefulWidget {
  const CommentsScreen({
    super.key,
    required this.post,
    required this.onAddComment,
  });

  final ArtPost post;
  final Future<void> Function(String text) onAddComment;

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _controller = TextEditingController();
  var _isSubmitting = false;
  var _isRetrying = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        title: const Text('Comments'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<PostComment>>(
                stream: EngagementService.instance.watchComments(widget.post),
                builder: (context, snapshot) {
                  final comments = snapshot.data ?? const <PostComment>[];
                  if (snapshot.hasError && comments.isEmpty) {
                    return _CommentsError(onRetry: _retryComments);
                  }
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      comments.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    );
                  }
                  if (comments.isEmpty) {
                    return const Center(
                      child: Text(
                        'No comments yet',
                        style: TextStyle(color: AppColors.textLight),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: comments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return _CommentRow(comment: comment);
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        hintText: 'Add a comment',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isSubmitting ? null : _submit,
                    style:
                        IconButton.styleFrom(backgroundColor: AppColors.text),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.arrow_upward, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.onAddComment(text);
      _controller.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to post comment.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _retryComments() {
    if (_isRetrying) {
      return;
    }
    setState(() => _isRetrying = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isRetrying = false);
      }
    });
  }
}

class _CommentsError extends StatelessWidget {
  const _CommentsError({
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.wifi_tethering_error_rounded,
            color: AppColors.textLight,
            size: 32,
          ),
          const SizedBox(height: 10),
          const Text(
            'Unable to load comments',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Check your connection and try again',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({
    required this.comment,
  });

  final PostComment comment;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfile?>(
      stream: ProfileService.instance.watchUserProfileById(comment.userId),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final displayName = profile?.displayName.trim().isNotEmpty == true
            ? profile!.displayName
            : comment.userName;
        final avatarUrl = profile?.avatarUrl;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: comment.userId.isEmpty
                  ? null
                  : () => _openUserProfile(context, displayName, avatarUrl),
              child: AppAvatar(
                displayName: displayName,
                imageUrl: avatarUrl,
                radius: 17,
                backgroundColor: AppColors.soft,
                foregroundColor: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: comment.userId.isEmpty
                              ? null
                              : () => _openUserProfile(
                                    context,
                                    displayName,
                                    avatarUrl,
                                  ),
                          child: Text(
                            displayName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        comment.timeLabel,
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    comment.text,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _openUserProfile(
    BuildContext context,
    String fallbackName,
    String? fallbackAvatarUrl,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return PublicUserProfileScreen(
            userId: comment.userId,
            fallbackName: fallbackName,
            fallbackAvatarUrl: fallbackAvatarUrl,
          );
        },
      ),
    );
  }
}
