import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;

import '../models/art_post.dart';
import '../models/user_profile.dart';
import '../services/engagement_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../utils/text_utils.dart';
import '../widgets/pills.dart';
import 'comments_screen.dart';
import 'public_user_profile_screen.dart';

class PostDetailSheet extends StatefulWidget {
  const PostDetailSheet({
    super.key,
    required this.post,
    required this.isSaved,
    required this.isLiked,
    required this.isOwnPost,
    required this.onSetSaved,
    required this.onToggleLiked,
    required this.onAddComment,
    required this.onSharePost,
    required this.onMessageSeller,
    this.onEdit,
    this.onDelete,
  });

  final ArtPost post;
  final bool isSaved;
  final bool isLiked;
  final bool isOwnPost;
  final Future<void> Function(ArtPost post, bool saved) onSetSaved;
  final Future<LikeUpdate> Function(ArtPost post) onToggleLiked;
  final Future<void> Function(ArtPost post, String text) onAddComment;
  final Future<void> Function(ArtPost post) onSharePost;
  final VoidCallback onMessageSeller;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  State<PostDetailSheet> createState() => _PostDetailSheetState();
}

class _PostDetailSheetState extends State<PostDetailSheet> {
  static const _menuTextStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
  );

  late bool _saved;
  late bool _liked;
  late int _likeCount;
  late int _commentCount;
  late int _shareCount;
  var _isSaving = false;
  var _isLiking = false;
  var _isSharing = false;
  var _isSavingImage = false;

  @override
  void initState() {
    super.initState();
    _saved = widget.isSaved;
    _liked = widget.isLiked;
    _likeCount = widget.post.likes;
    _commentCount = widget.post.comments;
    _shareCount = widget.post.shares;
  }

  @override
  void didUpdateWidget(covariant PostDetailSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.storageId != widget.post.storageId) {
      _saved = widget.isSaved;
      _liked = widget.isLiked;
      _likeCount = widget.post.likes;
      _commentCount = widget.post.comments;
      _shareCount = widget.post.shares;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Stack(
            children: [
              ListView(
                controller: controller,
                padding: const EdgeInsets.only(bottom: 94),
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(22)),
                    child: GestureDetector(
                      onTap: () => _openFullImage(context, post),
                      child: Hero(
                        tag: _postImageHeroTag(post),
                        child: Image.network(
                          post.imageUrl,
                          height: 430,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 430,
                            color: AppColors.soft,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: _toggleLiked,
                              icon: Icon(_liked
                                  ? Icons.favorite
                                  : Icons.favorite_border),
                              color:
                                  _liked ? AppColors.primary : AppColors.text,
                            ),
                            Text('$_likeCount'),
                            IconButton(
                              onPressed: _openComments,
                              icon:
                                  const Icon(Icons.chat_bubble_outline_rounded),
                            ),
                            Text('$_commentCount'),
                            IconButton(
                              onPressed: _isSharing ? null : _sharePost,
                              icon: const Icon(Icons.ios_share),
                            ),
                            Text('$_shareCount'),
                            const Spacer(),
                            Theme(
                              data: Theme.of(context).copyWith(
                                dividerColor: AppColors.border,
                                popupMenuTheme: const PopupMenuThemeData(
                                  color: AppColors.surface,
                                  surfaceTintColor: AppColors.surface,
                                  textStyle: _menuTextStyle,
                                ),
                              ),
                              child: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_horiz),
                                color: AppColors.surface,
                                surfaceTintColor: AppColors.surface,
                                onSelected: _handleMoreAction,
                                itemBuilder: _buildMoreActions,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          post.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          post.priceLabel,
                          style: TextStyle(
                            color: post.isForSale
                                ? AppColors.primary
                                : AppColors.textLight,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (post.isForSale)
                              const Pill(
                                label: 'For sale',
                                background: AppColors.saleBg,
                                foreground: AppColors.saleText,
                              ),
                            Pill(label: post.category),
                            Pill(label: post.condition),
                          ],
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'DESCRIPTION',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          post.description.trim().isEmpty
                              ? 'No description'
                              : post.description,
                          style: const TextStyle(
                              color: AppColors.textSecondary, height: 1.55),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'LOCATION',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          post.location.trim().isEmpty
                              ? 'No location'
                              : post.location,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 22),
                        _SellerRow(
                          post: post,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 12,
                right: 12,
                child: CircleAvatar(
                  backgroundColor: AppColors.surface,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: _toggleSaved,
                          icon: Icon(
                              _saved ? Icons.bookmark : Icons.bookmark_border),
                          label: Text(
                            _saved ? 'Saved' : 'Save',
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                _saved ? AppColors.soft : AppColors.surfaceWarm,
                            foregroundColor: _saved
                                ? AppColors.textSecondary
                                : AppColors.text,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 14,
                            ),
                            side: const BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: widget.isOwnPost && widget.onDelete != null
                              ? _confirmDeletePost
                              : widget.onMessageSeller,
                          style: FilledButton.styleFrom(
                            backgroundColor: widget.isOwnPost
                                ? AppColors.text
                                : AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                              widget.isOwnPost && widget.onDelete != null
                                  ? 'Delete post'
                                  : 'Message'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleSaved() async {
    if (_isSaving) {
      return;
    }

    final nextSaved = !_saved;
    setState(() {
      _saved = nextSaved;
      _isSaving = true;
    });

    try {
      await widget.onSetSaved(widget.post, nextSaved);
    } catch (_) {
      if (mounted) {
        setState(() => _saved = !nextSaved);
        _showMessage('Unable to update saved post.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _toggleLiked() async {
    if (_isLiking) {
      return;
    }

    final previousLiked = _liked;
    final previousCount = _likeCount;
    final optimisticLiked = !_liked;
    setState(() {
      _liked = optimisticLiked;
      _likeCount += optimisticLiked ? 1 : -1;
      if (_likeCount < 0) _likeCount = 0;
      _isLiking = true;
    });

    try {
      final update = await widget.onToggleLiked(widget.post);
      if (mounted) {
        setState(() {
          _liked = update.isLiked;
          _likeCount = update.likeCount;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _liked = previousLiked;
          _likeCount = previousCount;
        });
        _showMessage('Unable to update like.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLiking = false);
      }
    }
  }

  Future<void> _sharePost() async {
    setState(() => _isSharing = true);

    try {
      await widget.onSharePost(widget.post);
      if (mounted) {
        setState(() => _shareCount += 1);
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to share this post.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<void> _confirmDeletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          surfaceTintColor: AppColors.surface,
          title: const Text('Delete post?'),
          content: const Text(
            'This will remove the post from Apsara. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      widget.onDelete?.call();
    }
  }

  Future<void> _openComments() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return CommentsScreen(
            post: widget.post,
            onAddComment: (text) async {
              await widget.onAddComment(widget.post, text);
              if (mounted) {
                setState(() => _commentCount += 1);
              }
            },
          );
        },
      ),
    );
  }

  Future<void> _handleMoreAction(String action) async {
    switch (action) {
      case 'edit_post':
        widget.onEdit?.call();
        break;
      case 'delete_post':
        await _confirmDeletePost();
        break;
      case 'save_image':
        await _saveImageFromMenu();
        break;
      case 'copy_link':
        await Clipboard.setData(ClipboardData(text: widget.post.imageUrl));
        if (mounted) {
          _showMessage('Image link copied.');
        }
        break;
    }
  }

  List<PopupMenuEntry<String>> _buildMoreActions(BuildContext context) {
    return [
      if (widget.isOwnPost &&
          (widget.onEdit != null || widget.onDelete != null)) ...[
        if (widget.onEdit != null)
          const PopupMenuItem<String>(
            value: 'edit_post',
            child: Text('Edit post', style: _menuTextStyle),
          ),
        if (widget.onDelete != null)
          const PopupMenuItem<String>(
            value: 'delete_post',
            child: Text('Delete post', style: _menuTextStyle),
          ),
        const PopupMenuDivider(height: 1),
      ],
      PopupMenuItem<String>(
        value: 'save_image',
        enabled: !_isSavingImage,
        child: Text(
          _isSavingImage ? 'Saving image...' : 'Save image',
          style: _menuTextStyle,
        ),
      ),
      const PopupMenuItem<String>(
        value: 'copy_link',
        child: Text('Copy image link', style: _menuTextStyle),
      ),
    ];
  }

  Future<void> _saveImageFromMenu() async {
    if (_isSavingImage) {
      return;
    }

    setState(() => _isSavingImage = true);

    try {
      final uri = Uri.parse(widget.post.imageUrl);
      final response = await http.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Image download failed');
      }

      final fileName = 'apsara_${widget.post.storageId}';
      await Gal.putImageBytes(
        response.bodyBytes,
        album: 'Apsara',
        name: fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_'),
      );

      if (mounted) {
        _showMessage('Image saved to gallery.');
      }
    } on GalException catch (error) {
      if (mounted) {
        _showMessage(error.type.message);
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to save image.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingImage = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _openFullImage(BuildContext context, ArtPost post) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FullScreenPostImage(post: post);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

class FullScreenPostImage extends StatelessWidget {
  const FullScreenPostImage({
    super.key,
    required this.post,
  });

  final ArtPost post;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.pop(context),
          child: Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: Hero(
                tag: _postImageHeroTag(post),
                child: Image.network(
                  post.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.white70,
                    size: 42,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _postImageHeroTag(ArtPost post) {
  return 'post-image-${post.documentId ?? post.id}';
}

class _SellerRow extends StatelessWidget {
  const _SellerRow({
    required this.post,
  });

  final ArtPost post;

  @override
  Widget build(BuildContext context) {
    final sellerUid = post.sellerUid;
    return StreamBuilder<UserProfile?>(
      stream: sellerUid == null
          ? Stream.value(null)
          : ProfileService.instance.watchUserProfileById(sellerUid),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final displayName = profile?.displayName.trim().isNotEmpty == true
            ? profile!.displayName
            : post.seller;
        final avatarUrl = profile?.avatarUrl;

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: sellerUid == null
              ? null
              : () => _openSellerProfile(
                    context,
                    sellerUid,
                    displayName,
                    avatarUrl,
                  ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.text,
                  backgroundImage:
                      avatarUrl == null ? null : NetworkImage(avatarUrl),
                  child: avatarUrl == null
                      ? Text(
                          initialFor(displayName),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    displayName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openSellerProfile(
    BuildContext context,
    String sellerUid,
    String fallbackName,
    String? fallbackAvatarUrl,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return PublicUserProfileScreen(
            userId: sellerUid,
            fallbackName: fallbackName,
            fallbackAvatarUrl: fallbackAvatarUrl,
          );
        },
      ),
    );
  }
}
