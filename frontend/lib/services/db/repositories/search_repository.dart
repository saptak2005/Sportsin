import 'package:dio/dio.dart';
import 'package:sportsin/models/models.dart';
import 'package:sportsin/services/core/dio_client.dart';
import 'package:sportsin/services/db/db_exceptions.dart';

class SearchRepository {
  static SearchRepository? _instance;

  SearchRepository._();

  static SearchRepository get instance {
    _instance ??= SearchRepository._();
    return _instance!;
  }

  factory SearchRepository() => instance;

  Future<List<UserSearchResult>> searchUsers(String query) async {
    try {
      final response = await DioClient.instance.get(
        'search/users',
        queryParameters: {
          'q': query,
        },
      );
      if (response.statusCode == 200) {
        if (response.data == null || response.data.isEmpty) {
          return [];
        }
        final List<dynamic> data = response.data;
        return data.map((json) => UserSearchResult.fromJson(json)).toList();
      } else {
        throw DbExceptions(
          message: 'Failed to search users',
          details: 'Unexpected response status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (DbExceptions.shouldReturnNullForPost(e)) {
        return [];
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
}
