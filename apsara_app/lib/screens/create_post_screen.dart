import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/categories.dart';
import '../models/art_post.dart';
import '../services/cloudinary_media_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_logger.dart';
import '../widgets/form_fields.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({
    super.key,
    required this.onCreatePost,
    required this.sellerId,
    required this.sellerUid,
    required this.sellerName,
  });

  final Future<void> Function(ArtPost post) onCreatePost;
  final int sellerId;
  final String sellerUid;
  final String sellerName;

  @override
  State<CreatePostScreen> createState() => CreatePostScreenState();
}

class CreatePostScreenState extends State<CreatePostScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _location = TextEditingController();
  final _imagePicker = ImagePicker();
  String _category = 'Others';
  String _condition = 'Unknown';
  bool _isPublishing = false;
  String? _formError;
  XFile? _selectedImage;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> submitPost() => _submit();

  @override
  Widget build(BuildContext context) {
    final cardShadow = [
      BoxShadow(
        color: const Color(0xFF5B2F1E).withValues(alpha: 0.08),
        blurRadius: 22,
        offset: const Offset(0, 10),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
      children: [
        _SectionLabel('Cover image'),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: cardShadow,
          ),
          child: AspectRatio(
            aspectRatio: 1.12,
            child: InkWell(
              onTap: _isPublishing ? null : _pickImage,
              borderRadius: BorderRadius.circular(24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: ColoredBox(
                  color: Colors.white,
                  child: _selectedImage == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_camera_outlined,
                              color: AppColors.textLight,
                              size: 34,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Add cover photo',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              File(_selectedImage!.path),
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                            Positioned(
                              right: 14,
                              bottom: 14,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.42),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    'Replace',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        _SectionLabel('Post details'),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final useTwoColumns = constraints.maxWidth >= 320;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LabeledField(
                      label: 'Title',
                      controller: _title,
                    ),
                    const SizedBox(height: 12),
                    LabeledField(
                      label: 'Description',
                      controller: _description,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 12),
                    if (useTwoColumns)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownField(
                              label: 'Category',
                              value: _category,
                              values: categories
                                  .where((item) => item != 'All')
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _category = value),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownField(
                              label: 'Condition',
                              value: _condition,
                              values: const [
                                'Unknown',
                                'New',
                                'Like new',
                                'Handmade',
                                'Vintage'
                              ],
                              onChanged: (value) =>
                                  setState(() => _condition = value),
                            ),
                          ),
                        ],
                      )
                    else ...[
                      DropdownField(
                        label: 'Category',
                        value: _category,
                        values:
                            categories.where((item) => item != 'All').toList(),
                        onChanged: (value) => setState(() => _category = value),
                      ),
                      const SizedBox(height: 12),
                      DropdownField(
                        label: 'Condition',
                        value: _condition,
                        values: const [
                          'Unknown',
                          'New',
                          'Like new',
                          'Handmade',
                          'Vintage'
                        ],
                        onChanged: (value) =>
                            setState(() => _condition = value),
                      ),
                    ],
                    const SizedBox(height: 12),
                    LabeledField(
                      label: 'Price',
                      controller: _price,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      prefixText: '\$ ',
                    ),
                    const SizedBox(height: 12),
                    LabeledField(
                      label: 'Location',
                      controller: _location,
                      prefixIcon: Icons.place_outlined,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _isPublishing ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            child: Text(
              _isPublishing ? 'Posting...' : 'Post',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        if (_formError != null) ...[
          const SizedBox(height: 10),
          Text(
            _formError!,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _submit() async {
    final title = _title.text.trim();
    if (_selectedImage == null) {
      setState(() => _formError = 'Add a cover photo before posting.');
      return;
    }

    setState(() {
      _isPublishing = true;
      _formError = null;
    });

    try {
      final imageUrl = await CloudinaryMediaService.instance
          .uploadPostImage(_selectedImage!);
      await widget.onCreatePost(
        ArtPost(
          id: DateTime.now().millisecondsSinceEpoch,
          title: title,
          seller: widget.sellerName,
          sellerId: widget.sellerId,
          sellerUid: widget.sellerUid,
          category: _category,
          condition: _condition,
          location: _location.text.trim(),
          imageUrl: imageUrl,
          description: _description.text.trim().isEmpty
              ? 'No description'
              : _description.text.trim(),
          price: double.tryParse(_price.text.trim()),
        ),
      );
      _title.clear();
      _description.clear();
      _price.clear();
      _location.clear();
      _selectedImage = null;
      if (mounted) {
        Navigator.of(context).maybePop();
      }
    } on CloudinaryConfigException {
      AppLogger.warn('Cloudinary config missing for post upload');
      if (mounted) {
        setState(() =>
            _formError = 'Image upload is not configured for this build.');
      }
    } on CloudinaryUploadException catch (error) {
      AppLogger.warn('Post image upload failed', error);
      if (mounted) {
        setState(() => _formError = error.message);
      }
    } catch (error, stackTrace) {
      AppLogger.error('Post create failed', error, stackTrace);
      if (mounted) {
        setState(() => _formError = 'Unable to post right now. Try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (image == null || !mounted) {
      return;
    }

    setState(() {
      _selectedImage = image;
      _formError = null;
    });
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.text,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
