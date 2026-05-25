import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/categories.dart';
import '../models/art_post.dart';
import '../services/cloudinary_media_service.dart';
import '../theme/app_theme.dart';
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
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _location = TextEditingController();
  final _imagePicker = ImagePicker();
  String _category = 'Pottery';
  String _condition = 'New';
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

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
      children: [
        const Text(
          'Share your piece',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Add a photo and details.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.soft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create listing',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: 4 / 3,
                child: InkWell(
                  onTap: _isPublishing ? null : _pickImage,
                  borderRadius: BorderRadius.circular(16),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    child: _selectedImage == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.photo_camera_outlined,
                                color: AppColors.textLight,
                                size: 34,
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Add photo',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(
                              File(_selectedImage!.path),
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                  ),
                ),
              ),
              if (_selectedImage != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _isPublishing ? null : _pickImage,
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
              ],
              const SizedBox(height: 14),
              LabeledField(
                label: 'Title',
                controller: _title,
                hint: 'e.g., Hand-carved Wooden Elephant',
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
                values: categories.where((item) => item != 'All').toList(),
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
                values: const ['New', 'Like new', 'Handmade', 'Vintage'],
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
                  onPressed: _isPublishing ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    _isPublishing ? 'Posting...' : 'Post',
                    style: const TextStyle(fontWeight: FontWeight.w600),
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
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _formError = 'Enter a title before publishing.');
      return;
    }
    if (_selectedImage == null) {
      setState(() => _formError = 'Add a photo before publishing.');
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
      if (mounted) {
        setState(
            () => _formError = 'Cloudinary is not configured for this build.');
      }
    } on CloudinaryUploadException catch (error) {
      if (mounted) {
        setState(() => _formError = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _formError = 'Unable to publish listing. Try again.');
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
