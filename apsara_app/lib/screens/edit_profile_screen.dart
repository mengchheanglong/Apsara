import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_profile.dart';
import '../services/cloudinary_media_service.dart';
import '../theme/app_theme.dart';
import '../utils/text_utils.dart';
import '../widgets/form_fields.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.profile,
    required this.onSave,
  });

  final UserProfile profile;
  final Future<void> Function({
    required String displayName,
    required String bio,
    String? avatarUrl,
  }) onSave;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _bio;
  final _imagePicker = ImagePicker();
  XFile? _selectedImage;
  var _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.displayName);
    _bio = TextEditingController(text: widget.profile.bio);
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = widget.profile.avatarUrl;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        centerTitle: true,
        title: const Text('Edit profile'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          children: [
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: AppColors.text,
                    backgroundImage: _selectedImage != null
                        ? FileImage(File(_selectedImage!.path))
                        : avatarUrl == null
                            ? null
                            : NetworkImage(avatarUrl) as ImageProvider,
                    child: _selectedImage == null && avatarUrl == null
                        ? Text(
                            initialFor(widget.profile.displayName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: IconButton.filled(
                      onPressed: _isSaving ? null : _pickProfileImage,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.text,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            LabeledField(
              label: 'Name',
              controller: _name,
              hint: 'Your display name',
            ),
            const SizedBox(height: 12),
            LabeledField(
              label: 'Bio',
              controller: _bio,
              hint: 'Tell people about your work or interests',
              maxLines: 4,
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 22),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.text,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(_isSaving ? 'Saving...' : 'Save changes'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );

    if (image == null || !mounted) {
      return;
    }

    setState(() => _selectedImage = image);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = 'Enter your name.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      String? avatarUrl = widget.profile.avatarUrl;
      if (_selectedImage != null) {
        avatarUrl = await CloudinaryMediaService.instance
            .uploadProfileImage(_selectedImage!);
      }

      await widget.onSave(
        displayName: name,
        bio: _bio.text.trim(),
        avatarUrl: avatarUrl,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } on CloudinaryConfigException {
      if (mounted) {
        setState(
            () => _errorText = 'Cloudinary is not configured for this build.');
      }
    } on CloudinaryUploadException catch (error) {
      if (mounted) {
        setState(() => _errorText = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorText = 'Unable to update profile.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
