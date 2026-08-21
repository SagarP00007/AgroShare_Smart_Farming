import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Handles file uploads to Cloudinary (free tier, no credit card needed).
/// Replaces Firebase Storage which requires the paid Blaze plan.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const String _cloudName = 'bl6cxq4f';
  static const String _uploadPreset = 'agroshare_unsigned';
  static const String _uploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  /// Uploads an equipment image to Cloudinary under the
  /// `equipment_images` folder and returns the secure download URL.
  Future<String> uploadEquipmentImage(File file) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return _upload(file, folder: 'equipment_images', publicId: 'eq_$timestamp');
  }

  /// Uploads a profile image to Cloudinary under the
  /// `profile_images` folder and returns the secure download URL.
  Future<String> uploadProfileImage(File file, String userId) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return _upload(
      file,
      folder: 'profile_images',
      publicId: '${userId}_$timestamp',
    );
  }

  /// Uploads pre/post rental equipment condition inspection photo to Cloudinary
  /// under the `condition_images` folder and returns secure download URL.
  Future<String> uploadConditionImage(
    File file,
    String bookingId,
    String stage,
  ) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeBookingId = bookingId.replaceAll(' ', '_');
    return _upload(
      file,
      folder: 'condition_images',
      publicId: 'cond_${stage}_${safeBookingId}_$timestamp',
    );
  }

  /// Core unsigned-upload helper.
  Future<String> _upload(
    File file, {
    required String folder,
    String? publicId,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl))
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = folder;

    if (publicId != null) {
      request.fields['public_id'] = publicId;
    }

    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception(
        'Cloudinary upload failed (${response.statusCode}): '
        '${response.body}',
      );
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    return data['secure_url'] as String;
  }
}
