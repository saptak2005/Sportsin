import 'dart:io';
import 'package:dio/dio.dart';
import 'package:sportsin/models/post.dart';
import 'package:sportsin/services/db/db_exceptions.dart';
import 'package:sportsin/services/core/dio_client.dart';

class PostRepository {
  static PostRepository? _instance;

  PostRepository._();

  static PostRepository get instance {
    _instance ??= PostRepository._();
    return _instance!;
  }

  factory PostRepository() => instance;

  Future<Post> createPost({
    required String content,
    List<String>? tags,
    required List<File> images,
  }) async {
    try {
      if (content.trim().isEmpty) {
        throw const DbPostValidationException(
          message: 'Content is required',
          details: 'Post content cannot be empty',
        );
      }

      final formData = FormData();

      formData.fields.add(MapEntry('content', content.trim()));

      if (tags != null && tags.isNotEmpty) {
        formData.fields.add(MapEntry('tags', tags.join(',')));
      }

      if (images.isNotEmpty) {
        for (int i = 0; i < images.length; i++) {
          final file = images[i];
          if (await file.exists()) {
            final fileName = file.path.split('/').last;

            formData.files.add(MapEntry(
              'images',
              await MultipartFile.fromFile(
                file.path,
                filename: fileName,
              ),
            ));
          } else {
            throw DbImageUploadException(
              message: 'Image file does not exist',
              details: 'File path: ${file.path}',
            );
          }
        }
      }

      final response = await DioClient.instance.post(
        'posts',
        data: formData,
      );

      if (response.statusCode == 201 && response.data != null) {
        final postData = response.data;
        final post = Post.fromJson(postData);
        return post;
      } else {
        throw DbPostCreationException(
          message: 'Unexpected response status',
          details:
              'Status: ${response.statusCode}, Message: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      throw DbExceptions.handleDioException(e, 'creating post');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbPostCreationException(
        message: 'Unexpected error creating post',
        details: 'Error: $e',
      );
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      if (postId.isEmpty) {
        throw const DbInvalidInputException(
          message: 'Post ID is required',
          details: 'Post ID cannot be empty',
        );
      }

      final response = await DioClient.instance.delete('posts/$postId');

      if (response.statusCode == 200) {
        return;
      } else {
        throw DbDeleteException(
          message: 'Unexpected response status',
          details:
              'Status: ${response.statusCode}, Message: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      throw DbExceptions.handleDioException(e, 'deleting post');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbDeleteException(
        message: 'Unexpected error deleting post',
        details: 'Error: $e',
      );
    }
  }

  Future<List<Post>> getMyPosts({int? limit, int? offset}) async {
    try {
      final Map<String, dynamic> queryParams = {};

      if (limit != null) {
        queryParams['limit'] = limit;
      }

      if (offset != null) {
        queryParams['offset'] = offset;
      }

      final response = await DioClient.instance.get(
        'my-posts',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final postsData = response.data;

        // Ensure postsData is a List and cast it properly
        if (postsData is List) {
          final List<Post> posts = postsData
              .where((e) => e != null && e is Map<String, dynamic>)
              .map((e) => Post.fromJson(e as Map<String, dynamic>))
              .toList();

          return posts;
        } else {
          throw DbQueryException(
            message: 'Invalid response format',
            details: 'Expected List but received: ${postsData.runtimeType}',
          );
        }
      } else {
        throw DbQueryException(
          message: 'Unexpected response status',
          details:
              'Status: ${response.statusCode}, Message: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      throw DbExceptions.handleDioException(e, 'retrieving posts');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbQueryException(
        message: 'Unexpected error retrieving posts',
        details: 'Error: $e',
      );
    }
  }

  Future<Post?> getPostById(String postId) async {
    try {
      if (postId.isEmpty) {
        throw const DbInvalidInputException(
          message: 'Post ID is required',
          details: 'Post ID cannot be empty',
        );
      }

      final response = await DioClient.instance.get('posts/$postId');

      if (response.statusCode == 200 && response.data != null) {
        final postData = response.data;

        if (postData is Map<String, dynamic>) {
          final post = Post.fromJson(postData);
          return post;
        } else {
          throw DbQueryException(
            message: 'Invalid response format',
            details:
                'Expected post object but received: ${postData.runtimeType}',
          );
        }
      } else {
        throw DbQueryException(
          message: 'Unexpected response status',
          details:
              'Status: ${response.statusCode}, Message: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      if (DbExceptions.shouldReturnNullForPost(e)) {
        return null;
      }
      throw DbExceptions.handleDioException(e, 'retrieving post');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbQueryException(
        message: 'Unexpected error retrieving post',
        details: 'Error: $e',
      );
    }
  }

  Future<List<Post>> getPostWithPagination({
    String? userId,
    int? limit,
    int? offset,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};

      if (userId != null && userId.isNotEmpty) {
        queryParams['user_id'] = userId;
      }

      if (limit != null) {
        queryParams['limit'] = limit;
      }

      if (offset != null) {
        queryParams['offset'] = offset;
      }

      final response = await DioClient.instance.get(
        'posts/with-comments',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final dynamic responseData = response.data;
        List<dynamic> postsList;
        if (responseData is List) {
          postsList = responseData;
        } else {
          throw Exception('Unexpected API response format.');
        }
        final List<Post> posts = postsList
            .where((postJson) =>
                postJson != null && postJson is Map<String, dynamic>)
            .map((postJson) => Post.fromJson(postJson as Map<String, dynamic>))
            .toList();

        return posts;
      } else {
        throw DbQueryException(
          message: 'Unexpected response status',
          details:
              'Status: ${response.statusCode}, Message: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      throw DbExceptions.handleDioException(
          e, 'retrieving posts with pagination');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbQueryException(
        message: 'Unexpected error retrieving posts',
        details: 'Error: $e',
      );
    }
  }

  Future<Post> updatePost(
    Post post, {
    List<File>? newImages,
    bool replaceImages = false,
  }) async {
    try {
      if (post.id.isEmpty) {
        throw const DbInvalidInputException(
          message: 'Post ID is required',
          details: 'Post ID cannot be empty',
        );
      }

      if (post.content.trim().isEmpty) {
        throw const DbPostValidationException(
          message: 'Content is required',
          details: 'Post content cannot be empty',
        );
      }

      // Use FormData for multipart/form-data
      final formData = FormData();

      formData.fields.add(MapEntry('content', post.content.trim()));

      if (post.tags.isNotEmpty) {
        // Backend expects comma-separated tags
        formData.fields.add(MapEntry('tags', post.tags.join(',')));
      }

      formData.fields
          .add(MapEntry('replace_images', replaceImages ? 'true' : 'false'));

      if (newImages != null && newImages.isNotEmpty) {
        for (var image in newImages) {
          formData.files.add(MapEntry(
            'images',
            await MultipartFile.fromFile(image.path,
                filename: image.uri.pathSegments.last),
          ));
        }
      }

      final response = await DioClient.instance.put(
        'posts/${post.id}',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return Post.fromJson(response.data);
      } else {
        throw DbUpdateException(
          message: 'Unexpected response status',
          details:
              'Status: ${response.statusCode}, Message: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      throw DbExceptions.handleDioException(e, 'updating post');
    } catch (e) {
      throw DbUpdateException(
        message: 'Unexpected error updating post',
        details: 'Error: $e',
      );
    }
  }
}
