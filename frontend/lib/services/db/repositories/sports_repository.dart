import 'package:dio/dio.dart';
import 'package:sportsin/models/models.dart';
import 'package:sportsin/services/core/dio_client.dart';
import 'package:sportsin/services/db/db_exceptions.dart';

class SportsRepository {
  static SportsRepository? _instance;
  SportsRepository._();

  static SportsRepository get instance {
    _instance ??= SportsRepository._();
    return _instance!;
  }

  factory SportsRepository() => instance;

  Future<List<Sport>> getSports({int? limit, int? offset}) async {
    try {
      final queryParameters = <String, dynamic>{};
      if (limit != null) {
        queryParameters['limit'] = limit;
      }
      if (offset != null) {
        queryParameters['offset'] = offset;
      }

      final response = await DioClient.instance.get(
        'sports',
        queryParameters: queryParameters,
      );

      final List<dynamic> data = response.data['sports'];
      return data.map((json) => Sport.fromJson(json)).toList();
    } on DioException catch (e) {
      throw DbExceptions.handleDioException(e, 'fetching sports list');
    } catch (e) {
      throw DbQueryException(
        message: 'An unexpected error occurred while fetching sports.',
        details: 'Error: $e',
      );
    }
  }

  Future<Sport?> getSportByName(String name) async {
    try {
      final response = await DioClient.instance.get('sports/$name');

      return Sport.fromJson(response.data['sport']);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw DbExceptions.handleDioException(e, 'fetching sport by name');
    } catch (e) {
      throw DbQueryException(
        message: 'An unexpected error occurred while fetching sport by name.',
        details: 'Error: $e',
      );
    }
  }

  Future<Sport> createSport({
    required String name,
    String? description,
  }) async {
    try {
      final requestBody = <String, dynamic>{
        'name': name,
      };
      if (description != null) {
        requestBody['description'] = description;
      }

      final response = await DioClient.instance.post(
        'sports',
        data: requestBody,
      );

      return Sport.fromJson(response.data['sport']);
    } on DioException catch (e) {
      throw DbExceptions.handleDioException(e, 'creating a new sport');
    } catch (e) {
      throw DbQueryException(
        message: 'An unexpected error occurred while creating the sport.',
        details: 'Error: $e',
      );
    }
  }
}
