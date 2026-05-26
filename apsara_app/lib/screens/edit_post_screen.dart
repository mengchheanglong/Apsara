import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/categories.dart';
import '../models/art_post.dart';
import '../services/cloudinary_media_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_logger.dart';
import '../widgets/app_cached_media.dart';
import '../widgets/form_fields.dart';

class EditPostScreen extends StatefulWidget {
  const EditPostScreen({
    super.key,
    required this.post,
    required this.onUpdatePost,
  });

  final ArtPost post;
  final Future<void> Function({
    required String title,
    required String description,
    required String category,
    required String condition,
    required String location,
    required double? price,
    required String imageUrl,
  }) onUpdatePost;

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _location;
  final _imagePicker = ImagePicker();
  late String _category;
  late String _condition;
  XFile? _selectedImage;
  var _isSaving = false;
  String? _formError;

  static final _postCategories =
      categories.where((item) => item != 'All').toList();

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.post.title);
    _description = TextEditingController(
      text: widget.post.description == 'No description'
          ? ''
          : widget.post.description,
    );
    _price = TextEditingController(
      text: widget.post.price == null
          ? ''
          : widget.post.price!.toStringAsFixed(0),
    );
    _location = TextEditingController(text: widget.post.location);
    _category = _postCategories.contains(widget.post.category)
        ? widget.post.category
        : 'Others';
    _condition = _conditions.contains(widget.post.condition)
        ? widget.post.condition
        : 'Handmade';
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _location.dispose();
    super.dispose();
  }

  static const _conditions = ['New', 'Like new', 'Handmade', 'Vintage'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        toolbarHeight: 52,
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        centerTitle: true,
        title: const Text('Edit post'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.soft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: InkWell(
                      onTap: _isSaving ? null : _pickImage,
                      borderRadius: BorderRadius.circular(16),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: _selectedImage == null
                              ? AppCachedImage(
                                  imageUrl: widget.post.imageUrl,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorChild: const Center(
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                    ),
                                  ),
                                )
                              : Image.file(
                                  File(_selectedImage!.path),
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _isSaving ? null : _pickImage,
                      icon: const Icon(Icons.swap_horiz, size: 16),
                      label: const Text('Change photo'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  LabeledField(
                    label: 'Title',
                    controller: _title,
                    hint: 'Post title',
                  ),
                  const SizedBox(height: 10),
                  LabeledField(
                    label: 'Description',
                    controller: _description,
                    hint: 'Describe your item...',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 10),
                  DropdownField(
                    label: 'Category',
                    value: _category,
                    values: _postCategories,
                    onChanged: (value) => setState(() => _category = value),
                  ),
                  const SizedBox(height: 10),
                  LabeledField(
                    label: 'Price',
                    controller: _price,
                    hint: '\$ 0.00',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  DropdownField(
                    label: 'Condition',
                    value: _condition,
                    values: _conditions,
                    onChanged: (value) => setState(() => _condition = value),
                  ),
                  const SizedBox(height: 10),
                  LabeledField(
                    label: 'Location',
                    controller: _location,
                    hint: 'City or Region',
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(_isSaving ? 'Saving...' : 'Save changes'),
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
              ),
            ),
          ],
        ),
      ),
    );
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

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _formError = 'Enter a title.');
      return;
    }

    setState(() {
      _isSaving = true;
      _formError = null;
    });

    try {
      var imageUrl = widget.post.imageUrl;
      if (_selectedImage != null) {
        imageUrl = await CloudinaryMediaService.instance
            .uploadPostImage(_selectedImage!);
      }

      await widget.onUpdatePost(
        title: title,
        description: _description.text.trim().isEmpty
            ? 'No description'
            : _description.text.trim(),
        category: _category,
        condition: _condition,
        location: _location.text.trim(),
        price: double.tryParse(_price.text.trim()),
        imageUrl: imageUrl,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } on CloudinaryConfigException {
      AppLogger.warn('Cloudinary config missing for post update');
      if (mounted) {
        setState(
            () => _formError = 'Cloudinary is not configured for this build.');
      }
    } on CloudinaryUploadException catch (error) {
      AppLogger.warn('Post image upload failed', error);
      if (mounted) {
        setState(() => _formError = error.message);
      }
    } catch (error, stackTrace) {
      AppLogger.error('Post update failed', error, stackTrace);
      if (mounted) {
        setState(() => _formError = 'Unable to update post. Try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
