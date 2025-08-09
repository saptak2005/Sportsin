import 'dart:io';
import 'package:dio/dio.dart';
import 'package:sportsin/services/core/dio_client.dart';

class ImageService {
  static ImageService? _instance;

  ImageService._();

  static ImageService get instance {
    _instance ??= ImageService._();
    return _instance!;
  }

  factory ImageService() => instance;

  Future<String> uploadProfilePicture(File imageFile) async {
    try {
      final fileName = imageFile.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      final response = await DioClient.instance.post(
        'image/upload',
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final imageUrl = response.data['image_url'] ??
            response.data['url'] ??
            response.data['imageUrl'] ??
            response.data['data']?['url'] ??
            '';

        if (imageUrl.isEmpty) {
          throw Exception('Server did not return a valid image URL');
        }

        return imageUrl;
      } else {
        throw Exception('Failed to upload image: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (e.response?.statusCode == 413) {
        throw Exception(
            'Image file is too large. Please choose a smaller image.');
      } else if (e.response?.statusCode == 400) {
        throw Exception(
            'Invalid image format. Please choose a valid image file.');
      } else if (e.response?.statusCode == 422) {
        throw Exception(
            'Invalid request. ${e.response?.data?['message'] ?? 'Please try again.'}');
      } else {
        throw Exception(
            'Upload failed: ${e.response?.data?['message'] ?? e.message ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  /// Get profile picture URL
  Future<String?> getProfilePictureUrl() async {
    try {
      final response = await DioClient.instance.get('image');

      if (response.statusCode == 200 && response.data != null) {
        return response.data['image_url'] ?? response.data['url'];
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<String?> getUserProfilePictureById({
    required String userId,
    String extension = '.jpg',
  }) async {
    try {
      final response = await DioClient.instance.get(
        'image',
        queryParameters: {
          'user_id': userId,
          'extension': extension,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data['image_url'] ?? response.data['url'];
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
