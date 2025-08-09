import 'package:dio/dio.dart';
import 'package:sportsin/models/comment_model.dart';
import 'package:sportsin/services/core/dio_client.dart';
import 'package:sportsin/services/db/db_exceptions.dart';

class CommentRepository {
  static CommentRepository? _instance;

  CommentRepository._();

  static CommentRepository get instance {
    _instance ??= CommentRepository._();
    return _instance!;
  }

  factory CommentRepository() => instance;

  Future<Comment> createComment({
    required String postId,
    required String content,
    String? parentCommentId,
  }) async {
    if (postId.isEmpty || content.isEmpty) {
      throw const DbInvalidInputException(
        message: 'Post ID and content cannot be empty',
        details: 'Both post ID and content are required to create a comment.',
      );
    }
    try {
      final Map<String, dynamic> requestBody = {
        'post_id': postId,
        'content': content,
      };

      if (parentCommentId != null) {
        requestBody['parent_id'] = parentCommentId;
      }
      final response = await DioClient.instance.post(
        'comments',
        data: requestBody,
      );
      if (response.statusCode == 201) {
        return Comment.fromJson(response.data);
      } else {
        throw DbExceptions(
          message: 'Failed to create comment',
          details: 'Unexpected response status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw DbExceptions.handleDioException(e, 'Creating comment');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbNotFoundException(
        message: 'An unexpected error occurred while creating the comment',
        details: 'Error: $e',
      );
    }
  }

  Future<void> deleteComment(String commentId) async {
    if (commentId.isEmpty) {
      throw const DbInvalidInputException(
        message: 'Comment ID cannot be empty',
        details: 'A valid comment ID is required to delete a comment.',
      );
    }
    try {
      final response = await DioClient.instance.delete('comments/$commentId');
      if (response.statusCode == 200) {
        return;
      } else {
        throw DbExceptions(
          message: 'Failed to delete comment',
          details: 'Unexpected response status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw DbExceptions.handleDioException(e, 'Deleting comment');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbNotFoundException(
        message: 'An unexpected error occurred while deleting the comment',
        details: 'Error: $e',
      );
    }
  }

  Future<List<CommentResponse>> getCommentsByPostId({
    required String postId,
    int? limit,
    int? offset,
  }) async {
    if (postId.isEmpty) {
      throw const DbInvalidInputException(
        message: 'Post ID cannot be empty',
        details: 'A valid post ID is required to fetch comments.',
      );
    }
    try {
      final response = await DioClient.instance.get(
        'posts/$postId/comments',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((comment) => CommentResponse.fromJson(comment))
            .toList();
      } else {
        throw DbExceptions(
          message: 'Failed to fetch comments',
          details: 'Unexpected response status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw DbExceptions.handleDioException(e, 'Fetching comments');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbNotFoundException(
        message: 'An unexpected error occurred while fetching comments',
        details: 'Error: $e',
      );
    }
  }

  Future<CommentResponse?> getCommentById({
    required String commentId,
    int? replyLimit,
    int? replyOffset,
  }) async {
    if (commentId.isEmpty) {
      throw const DbInvalidInputException(
        message: 'Comment ID cannot be empty',
        details: 'A valid comment ID is required to fetch a comment.',
      );
    }
    try {
      final response = await DioClient.instance.get(
        'comments/$commentId',
        queryParameters: {
          'reply_limit': replyLimit,
          'reply_offset': replyOffset,
        },
      );
      if (response.statusCode == 200) {
        return CommentResponse.fromJson(response.data);
      } else {
        throw DbExceptions(
          message: 'Failed to fetch comment',
          details: 'Unexpected response status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw DbExceptions.handleDioException(e, 'Fetching comment');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbNotFoundException(
        message: 'An unexpected error occurred while fetching the comment',
        details: 'Error: $e',
      );
    }
  }

  Future<void> updateComment({
    required String commentId,
    required String content,
  }) async {
    if (commentId.isEmpty || content.isEmpty) {
      throw const DbInvalidInputException(
        message: 'Comment ID and content cannot be empty',
        details:
            'Both comment ID and content are required to update a comment.',
      );
    }
    try {
      final response = await DioClient.instance.put(
        'comments/$commentId',
        data: {'content': content},
      );
      if (response.statusCode == 200) {
        return;
      } else {
        throw DbExceptions(
          message: 'Failed to update comment',
          details: 'Unexpected response status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw DbExceptions.handleDioException(e, 'Updating comment');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbNotFoundException(
        message: 'An unexpected error occurred while updating the comment',
        details: 'Error: $e',
      );
    }
  }
}
