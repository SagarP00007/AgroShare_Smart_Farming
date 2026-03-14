import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// Handles file uploads to Firebase Storage.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  final FirebaseStorage _storage = FirebaseStorage.instanceFor(bucket: 'gs://agroshare-f1f57.appspot.com');

  /// Uploads an equipment image to equipment_images/{timestamp}.jpg
  /// and returns the download URL.
  Future<String> uploadEquipmentImage(File file) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref().child('equipment_images/$timestamp.jpg');
    await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }

  /// Uploads a profile image to profile_images/{userId}.jpg
  /// and returns the download URL.
  Future<String> uploadProfileImage(File file, String userId) async {
    final ref = _storage.ref().child('profile_images/$userId.jpg');
    await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }
}
