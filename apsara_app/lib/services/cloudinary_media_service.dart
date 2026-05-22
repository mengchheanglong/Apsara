import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryConfigException implements Exception {
  const CloudinaryConfigException();
}

class CloudinaryUploadException implements Exception {
  const CloudinaryUploadException(this.message);

  final String message;
}

class CloudinaryMediaService {
  CloudinaryMediaService._();

  static final CloudinaryMediaService instance = CloudinaryMediaService._();

  static const _cloudName = String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
  static const _uploadPreset =
      String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET');
  static const _folder = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_FOLDER',
    defaultValue: 'apsara/posts',
  );

  bool get isConfigured => _cloudName.isNotEmpty && _uploadPreset.isNotEmpty;

  Future<String> uploadPostImage(XFile image) {
    return _uploadImage(image, folder: _folder);
  }

  Future<String> uploadProfileImage(XFile image) {
    return _uploadImage(image, folder: _folder);
  }

  Future<String> _uploadImage(
    XFile image, {
    required String folder,
  }) async {
    if (!isConfigured) {
      throw const CloudinaryConfigException();
    }

    final uri =
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = folder
      ..files.add(await http.MultipartFile.fromPath('file', image.path));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final payload = jsonDecode(responseBody) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CloudinaryUploadException(
        payload['error'] is Map<String, dynamic>
            ? payload['error']['message']?.toString() ?? 'Image upload failed.'
            : 'Image upload failed.',
      );
    }

    final secureUrl = payload['secure_url']?.toString();
    if (secureUrl == null || secureUrl.isEmpty) {
      throw const CloudinaryUploadException(
          'Cloudinary did not return an image URL.');
    }

    return secureUrl;
  }
}
