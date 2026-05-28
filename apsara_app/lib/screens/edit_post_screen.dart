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
  EditPostScreen({
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
        : 'Unknown';
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _location.dispose();
    super.dispose();
  }

  static const _conditions = [
    'Unknown',
    'New',
    'Like new',
    'Handmade',
    'Vintage',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.surface,
      appBar: AppBar(
        toolbarHeight: 52,
        backgroundColor: context.appColors.surface,
        surfaceTintColor: context.appColors.surface,
        centerTitle: true,
        title: Text('Edit post'),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            _SectionCard(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeading(title: 'Cover image'),
                  SizedBox(height: 10),
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: InkWell(
                      onTap: _isSaving ? null : _pickImage,
                      borderRadius: BorderRadius.circular(16),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: context.appColors.surfaceWarm,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: context.appColors.border, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: _selectedImage == null
                              ? AppCachedImage(
                                  imageUrl: widget.post.imageUrl,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorChild: Center(
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
                  SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _isSaving ? null : _pickImage,
                      icon: Icon(Icons.swap_horiz, size: 16),
                      label: Text('Replace photo'),
                      style: TextButton.styleFrom(
                        foregroundColor: context.appColors.textSecondary,
                        textStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeading(title: 'Post details'),
                  SizedBox(height: 10),
                  LabeledField(
                    label: 'Title',
                    controller: _title,
                  ),
                  SizedBox(height: 10),
                  LabeledField(
                    label: 'Description',
                    controller: _description,
                    maxLines: 4,
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownField(
                          label: 'Category',
                          value: _category,
                          values: _postCategories,
                          onChanged: (value) =>
                              setState(() => _category = value),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: DropdownField(
                          label: 'Condition',
                          value: _condition,
                          values: _conditions,
                          onChanged: (value) =>
                              setState(() => _condition = value),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: LabeledField(
                          label: 'Price',
                          controller: _price,
                          hint: 'Leave blank if not for sale',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: LabeledField(
                          label: 'Location',
                          controller: _location,
                          hint: 'City or province',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 14),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: context.appColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: context.appColors.soft,
                        disabledForegroundColor: context.appColors.textLight,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(_isSaving ? 'Saving...' : 'Save post'),
                    ),
                  ),
                  if (_formError != null) ...[
                    SizedBox(height: 10),
                    Text(
                      _formError!,
                      style: TextStyle(
                        color: context.appColors.primary,
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
        setState(() =>
            _formError = 'Image upload is not configured for this build.');
      }
    } on CloudinaryUploadException catch (error) {
      AppLogger.warn('Post image upload failed', error);
      if (mounted) {
        setState(() => _formError = error.message);
      }
    } catch (error, stackTrace) {
      AppLogger.error('Post update failed', error, stackTrace);
      if (mounted) {
        setState(() => _formError = 'Unable to save changes right now.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _SectionCard extends StatelessWidget {
  _SectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.appColors.soft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

class _SectionHeading extends StatelessWidget {
  _SectionHeading({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
