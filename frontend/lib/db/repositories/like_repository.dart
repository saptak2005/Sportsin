import 'package:dio/dio.dart';
import 'package:sportsin/services/core/dio_client.dart';
import 'package:sportsin/services/db/db_exceptions.dart';

class LikeRepository {
  static LikeRepository? _instance;

  LikeRepository._();
  static LikeRepository get instance {
    _instance ??= LikeRepository._();
    return _instance!;
  }

  factory LikeRepository() => instance;

  Future<void> likePost(String postId) async {
    if (postId.isEmpty) {
      throw const DbInvalidInputException(
        message: 'Post ID cannot be empty',
        details: 'A valid post ID is required to like a post.',
      );
    }

    try {
      final response = await DioClient.instance.post(
        'posts/$postId/like',
      );

      if (response.statusCode == 200) {
        return;
      } else {
        throw DbExceptions(
          message: 'Failed to like post',
          details: 'Unexpected response status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw DbExceptions.handleDioException(e, 'liking post');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbNotFoundException(
        message: 'An unexpected error occurred while liking the post',
        details: 'Error: $e',
      );
    }
  }

  Future<void> unlikePost(String postId) async {
    if (postId.isEmpty) {
      throw const DbInvalidInputException(
        message: 'Post ID cannot be empty',
        details: 'A valid post ID is required to like a post.',
      );
    }

    try {
      final response = await DioClient.instance.delete(
        'posts/$postId/like',
      );

      if (response.statusCode == 200) {
        return;
      } else {
        throw DbExceptions(
          message: 'Failed to unlike post',
          details: 'Unexpected response status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw DbExceptions.handleDioException(e, 'unliking post');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbNotFoundException(
        message: 'An unexpected error occurred while unliking the post',
        details: 'Error: $e',
      );
    }
  }
}
