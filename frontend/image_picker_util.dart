import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ImagePickerUtil {
  static final ImagePicker _picker = ImagePicker();

  static Future<File?> _compressAndGetFile(XFile file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempPath = tempDir.path;
      final targetFileName = '${DateTime.now().millisecondsSinceEpoch}.webp';
      final targetPath = '$tempPath/$targetFileName';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        format: CompressFormat.webp,
        quality: 85,
      );

      return result != null ? File(result.path) : null;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return null;
    }
  }

  static Future<File?> showImagePickerDialog(BuildContext context) async {
    return showDialog<File?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Profile Picture'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () async {
                  final file = await _pickImageFromCamera();
                  if (context.mounted) {
                    Navigator.of(context).pop(file);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  final file = await _pickImageFromGallery();
                  if (context.mounted) {
                    Navigator.of(context).pop(file);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  static Future<File?> _pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        return await _compressAndGetFile(pickedFile);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  static Future<File?> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        return await _compressAndGetFile(pickedFile);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  static Future<File?> pickImageFromCamera() async {
    return await _pickImageFromCamera();
  }

  static Future<File?> pickImageFromGallery() async {
    return await _pickImageFromGallery();
  }

  static Future<List<File>?> showMultipleImagePickerDialog(
      BuildContext context) async {
    return showDialog<List<File>?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Images'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose Multiple from Gallery'),
                onTap: () async {
                  final files = await _pickMultipleImagesFromGallery();
                  if (context.mounted) {
                    Navigator.of(context).pop(files);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () async {
                  final file = await _pickImageFromCamera();
                  if (context.mounted) {
                    context.pop(file != null ? [file] : null);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  static Future<List<File>?> _pickMultipleImagesFromGallery() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        return pickedFiles.map((xFile) => File(xFile.path)).toList();
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  static Future<List<File>?> pickMultipleImagesFromGallery() async {
    return await _pickMultipleImagesFromGallery();
  }
}
