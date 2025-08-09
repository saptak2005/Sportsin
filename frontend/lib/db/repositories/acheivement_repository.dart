import 'dart:io';

import 'package:dio/dio.dart';
import 'package:sportsin/models/achievement.dart';
import 'package:sportsin/services/core/dio_client.dart';
import 'package:sportsin/services/db/db_exceptions.dart';

class AchievementRepository {
  static AchievementRepository? _instance;

  AchievementRepository._();

  static AchievementRepository get instance {
    _instance ??= AchievementRepository._();
    return _instance!;
  }

  factory AchievementRepository() => instance;

  /// Creates a new achievement
  Future<Achievement> createAcheivement(Achievement acheivement) async {
    try {
      if (acheivement.date.trim().isEmpty) {
        throw const DbInvalidInputException(
          message: 'Achievement date is required',
          details: 'Date cannot be empty',
        );
      }

      if (acheivement.sportId.trim().isEmpty) {
        throw const DbInvalidInputException(
          message: 'Sport ID is required',
          details: 'Sport ID cannot be empty',
        );
      }

      if (acheivement.tournament.trim().isEmpty) {
        throw const DbInvalidInputException(
          message: 'Tournament title is required',
          details: 'Tournament title cannot be empty',
        );
      }

      final Map<String, dynamic> requestBody = {};

      requestBody['date'] = acheivement.date.trim();
      requestBody['sport_id'] = acheivement.sportId;
      requestBody['tournament_title'] = acheivement.tournament.trim();

      if (acheivement.description.isNotEmpty) {
        requestBody['description'] = acheivement.description;
      }

      requestBody['level'] = acheivement.level.toJson();

      if (acheivement.stats != null) {
        requestBody['stats'] = acheivement.stats;
      }

      final response = await DioClient.instance.post(
        'achievements',
        data: requestBody,
      );

      if (response.statusCode == 201 && response.data != null) {
        final achievementData = response.data;

        if (achievementData is Map<String, dynamic>) {
          final createdAchievement = Achievement.fromJson(achievementData);
          return createdAchievement;
        } else {
          throw DbPostCreationException(
            message: 'Invalid response format',
            details:
                'Expected achievement object but received: ${achievementData.runtimeType}',
          );
        }
      } else {
        throw DbPostCreationException(
          message: 'Unexpected response status',
          details:
              'Status: ${response.statusCode}, Message: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      throw DbExceptions.handleDioException(e, 'creating achievement');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbPostCreationException(
        message: 'Unexpected error creating achievement',
        details: 'Error: $e',
      );
    }
  }

  /// Deletes an achievement by ID
  Future<void> deleteAchievement(String achievementId) async {
    try {
      if (achievementId.isEmpty) {
        throw const DbInvalidInputException(
          message: 'Achievement ID is required',
          details: 'Achievement ID cannot be empty',
        );
      }

      final response =
          await DioClient.instance.delete('achievements/$achievementId');

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
      throw DbExceptions.handleDioException(e, 'deleting achievement');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbDeleteException(
        message: 'Unexpected error deleting achievement',
        details: 'Error: $e',
      );
    }
  }

  /// Deletes an achievement certificate
  Future<void> deleteAchievementCertificate(String achievementId) async {
    try {
      if (achievementId.isEmpty) {
        throw const DbInvalidInputException(
          message: 'Achievement ID is required',
          details: 'Achievement ID cannot be empty',
        );
      }

      final response = await DioClient.instance
          .delete('achievements/$achievementId/certificate');

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
      throw DbExceptions.handleDioException(
          e, 'deleting achievement certificate');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbDeleteException(
        message: 'Unexpected error deleting achievement certificate',
        details: 'Error: $e',
      );
    }
  }

  /// Gets an achievement by ID
  Future<Achievement?> getAchievementById(String achievementId) async {
    try {
      if (achievementId.isEmpty) {
        throw const DbInvalidInputException(
          message: 'Achievement ID is required',
          details: 'Achievement ID cannot be empty',
        );
      }

      final response =
          await DioClient.instance.get('achievements/$achievementId');

      if (response.statusCode == 200 && response.data != null) {
        final achievementData = response.data;

        if (achievementData is Map<String, dynamic>) {
          final achievement = Achievement.fromJson(achievementData);
          return achievement;
        } else {
          throw DbQueryException(
            message: 'Invalid response format',
            details:
                'Expected achievement object but received: ${achievementData.runtimeType}',
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
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw DbExceptions.handleDioException(e, 'retrieving achievement by ID');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbQueryException(
        message: 'Unexpected error retrieving achievement by ID',
        details: 'Error: $e',
      );
    }
  }

  /// Gets user's achievements
  Future<List<Achievement>> getMyAchievements() async {
    try {
      final response = await DioClient.instance.get('achievements');

      if (response.statusCode == 200 && response.data != null) {
        final achievementsData = response.data;

        if (achievementsData is List) {
          final List<Achievement> achievements = achievementsData
              .where((e) => e != null && e is Map<String, dynamic>)
              .map((e) => Achievement.fromJson(e as Map<String, dynamic>))
              .toList();

          return achievements;
        } else {
          throw DbQueryException(
            message: 'Invalid response format',
            details:
                'Expected List but received: ${achievementsData.runtimeType}',
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
      throw DbExceptions.handleDioException(e, 'retrieving achievements');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbQueryException(
        message: 'Unexpected error retrieving achievements',
        details: 'Error: $e',
      );
    }
  }

  /// Updates an achievement
  Future<Achievement> updateAchievement(Achievement achievement) async {
    try {
      if (achievement.id.isEmpty) {
        throw const DbInvalidInputException(
          message: 'Achievement ID is required',
          details: 'Achievement ID cannot be empty',
        );
      }

      if (achievement.date.trim().isEmpty) {
        throw const DbInvalidInputException(
          message: 'Achievement date is required',
          details: 'Date cannot be empty',
        );
      }

      if (achievement.sportId.trim().isEmpty) {
        throw const DbInvalidInputException(
          message: 'Sport ID is required',
          details: 'Sport ID cannot be empty',
        );
      }

      if (achievement.tournament.trim().isEmpty) {
        throw const DbInvalidInputException(
          message: 'Tournament title is required',
          details: 'Tournament title cannot be empty',
        );
      }

      final Map<String, dynamic> requestBody = {};

      requestBody['date'] = achievement.date.trim();
      requestBody['sport_id'] = achievement.sportId;
      requestBody['tournament_title'] = achievement.tournament.trim();

      if (achievement.description.isNotEmpty) {
        requestBody['description'] = achievement.description;
      }

      requestBody['level'] = achievement.level.toJson();

      if (achievement.stats != null &&
          achievement.stats.toString().isNotEmpty) {
        requestBody['stats'] = achievement.stats.toString();
      }

      final response = await DioClient.instance.put(
        'achievements/${achievement.id}',
        data: requestBody,
      );

      if (response.statusCode == 200 && response.data != null) {
        final achievementData = response.data;

        if (achievementData is Map<String, dynamic>) {
          final updatedAchievement = Achievement.fromJson(achievementData);
          return updatedAchievement;
        } else {
          throw DbUpdateException(
            message: 'Invalid response format',
            details:
                'Expected achievement object but received: ${achievementData.runtimeType}',
          );
        }
      } else {
        throw DbUpdateException(
          message: 'Unexpected response status',
          details:
              'Status: ${response.statusCode}, Message: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      throw DbExceptions.handleDioException(e, 'updating achievement');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbUpdateException(
        message: 'Unexpected error updating achievement',
        details: 'Error: $e',
      );
    }
  }

  /// Uploads achievement certificate
  Future<Map<String, String>> uploadAchievementCertificate({
    required String achievementId,
    required File certificateFile,
  }) async {
    try {
      if (achievementId.isEmpty) {
        throw const DbInvalidInputException(
          message: 'Achievement ID is required',
          details: 'Achievement ID cannot be empty',
        );
      }

      if (!await certificateFile.exists()) {
        throw DbImageUploadException(
          message: 'Certificate file does not exist',
          details: 'File path: ${certificateFile.path}',
        );
      }

      final fileName = certificateFile.path.split('/').last.toLowerCase();

      final formData = FormData();

      formData.files.add(MapEntry(
        'file',
        await MultipartFile.fromFile(
          certificateFile.path,
          filename: fileName,
        ),
      ));

      final response = await DioClient.instance.post(
        'achievements/$achievementId/certificate',
        data: formData,
      );

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          final Map<String, String> result = {};

          if (responseData.containsKey('certificate_url')) {
            result['certificate_url'] =
                responseData['certificate_url'] as String;
          }

          if (responseData.containsKey('message')) {
            result['message'] = responseData['message'] as String;
          }

          return result;
        } else {
          throw DbImageUploadException(
            message: 'Invalid response format',
            details: 'Expected Map but received: ${responseData.runtimeType}',
          );
        }
      } else {
        throw DbImageUploadException(
          message: 'Unexpected response status',
          details:
              'Status: ${response.statusCode}, Message: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      throw DbExceptions.handleDioException(
          e, 'uploading achievement certificate');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbImageUploadException(
        message: 'Unexpected error uploading achievement certificate',
        details: 'Error: $e',
      );
    }
  }
}
