import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Utility for picking an image from camera or gallery.
/// Returns the selected [File], or null if cancelled / error.
Future<File?> pickImageFromSource(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose From Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    ),
  );

  if (source == null || !context.mounted) return null;

  final picker = ImagePicker();
  final XFile? xFile = source == ImageSource.camera
      ? await picker.pickImage(source: ImageSource.camera, imageQuality: 85)
      : await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);

  if (xFile == null) return null;
  return File(xFile.path);
}
