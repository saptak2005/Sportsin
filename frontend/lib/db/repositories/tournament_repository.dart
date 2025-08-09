import 'dart:io';

import 'package:dio/dio.dart';
import 'package:sportsin/models/enums.dart';
import 'package:sportsin/models/tournament.dart';
import 'package:sportsin/models/tournament_participants.dart';
import 'package:sportsin/services/core/dio_client.dart';
import 'package:sportsin/services/db/db_exceptions.dart';

class TournamentRepository {
  static TournamentRepository? _instance;

  TournamentRepository._();

  static TournamentRepository get instance {
    _instance ??= TournamentRepository._();
    return _instance!;
  }

  factory TournamentRepository() => instance;

  Future<Tournament> createTournament(Tournament tournament, File image) async {
    try {
      if (tournament.title.trim().isEmpty) {
        throw const DbInvalidInputException(
          message: 'Tournament title is required',
          details: 'Title cannot be empty',
        );
      }

      if (tournament.location.trim().isEmpty) {
        throw const DbInvalidInputException(
          message: 'Tournament location is required',
          details: 'Location cannot be empty',
        );
      }

      if (tournament.sportId.trim().isEmpty) {
        throw const DbInvalidInputException(
          message: 'Sport ID is required',
          details: 'Sport ID cannot be empty',
        );
      }

      if (tournament.startDate.trim().isEmpty) {
        throw const DbInvalidInputException(
          message: 'Start date is required',
          details: 'Start date cannot be empty',
        );
      }

      if (tournament.endDate.trim().isEmpty) {
        throw const DbInvalidInputException(
          message: 'End date is required',
          details: 'End date cannot be empty',
        );
      }

      final formData = FormData();

      formData.fields.add(MapEntry('title', tournament.title.trim()));
      formData.fields.add(MapEntry('location', tournament.location.trim()));
      formData.fields.add(MapEntry('sport_id', tournament.sportId));
      formData.fields.add(MapEntry('start_date', tournament.startDate));
      formData.fields.add(MapEntry('end_date', tournament.endDate));

      if (tournament.description != null &&
          tournament.description!.isNotEmpty) {
        formData.fields.add(MapEntry('description', tournament.description!));
      }

      if (tournament.minAge != null && tournament.minAge! > 0) {
        formData.fields.add(MapEntry('min_age', tournament.minAge.toString()));
      }

      if (tournament.maxAge != null && tournament.maxAge! > 0) {
        formData.fields.add(MapEntry('max_age', tournament.maxAge.toString()));
      }

      if (tournament.level != null) {
        formData.fields.add(MapEntry('level', tournament.level!.toJson()));
      }

      if (tournament.gender != null) {
        formData.fields.add(MapEntry('gender', tournament.gender!.toJson()));
      }

      if (tournament.status != null) {
        formData.fields.add(MapEntry('status', tournament.status!.toJson()));
      }

      if (tournament.country != null && tournament.country!.isNotEmpty) {
        formData.fields.add(MapEntry('country', tournament.country!));
      }

      if (await image.exists()) {
        final fileName = image.path.split('/').last;
        formData.files.add(MapEntry(
          'banner',
          await MultipartFile.fromFile(
            image.path,
            filename: fileName,
          ),
        ));
      } else {
        throw DbImageUploadException(
          message: 'Banner image file does not exist',
          details: 'File path: ${image.path}',
        );
      }

      final response = await DioClient.instance.post(
        'tournaments',
        data: formData,
      );

      if (response.statusCode == 201 && response.data != null) {
        final tournamentData = response.data;
        final createdTournament = Tournament.fromJson(tournamentData);
        return createdTournament;
      } else {
        throw DbPostCreationException(
          message: 'Unexpected response status',
          details:
              'Status: ${response.statusCode}, Message: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      throw DbExceptions.handleDioException(e, 'creating tournament');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbPostCreationException(
        message: 'Unexpected error creating tournament',
        details: 'Error: $e',
      );
    }
  }

  /// Deletes a tournament by ID
  Future<void> deleteTournament(String tournamentId) async {
    try {
      if (tournamentId.isEmpty) {
        throw const DbInvalidInputException(
          message: 'Tournament ID is required',
          details: 'Tournament ID cannot be empty',
        );
      }

      final response =
          await DioClient.instance.delete('tournaments/$tournamentId');

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
      throw DbExceptions.handleDioException(e, 'deleting tournament');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbDeleteException(
        message: 'Unexpected error deleting tournament',
        details: 'Error: $e',
      );
    }
  }

  /// Gets a tournament by ID
  Future<Tournament?> getTournamentById(String tournamentId) async {
    try {
      if (tournamentId.isEmpty) {
        throw const DbInvalidInputException(
          message: 'Tournament ID is required',
          details: 'Tournament ID cannot be empty',
        );
      }

      final response =
          await DioClient.instance.get('tournaments/$tournamentId');

      if (response.statusCode == 200 && response.data != null) {
        final tournamentData = response.data;

        if (tournamentData is Map<String, dynamic>) {
          final tournament = Tournament.fromJson(tournamentData);
          return tournament;
        } else {
          throw DbQueryException(
            message: 'Invalid response format',
            details:
                'Expected tournament object but received: ${tournamentData.runtimeType}',
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
      throw DbExceptions.handleDioException(e, 'retrieving tournament by ID');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbQueryException(
        message: 'Unexpected error retrieving tournament by ID',
        details: 'Error: $e',
      );
    }
  }

  /// Gets participants for a tournament
  Future<List<TournamentParticipants>> getTournamentParticipants(
      String tournamentId,
      {String? status}) async {
    try {
      if (tournamentId.isEmpty) {
        throw const DbInvalidInputException(
          message: 'Tournament ID is required',
          details: 'Tournament ID cannot be empty',
        );
      }

      final Map<String, dynamic> queryParams = {};

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final response = await DioClient.instance.get(
        'tournaments/$tournamentId/participants',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> participantsList = response.data['participants'];

        final List<TournamentParticipants> participants = participantsList
            .whereType<Map<String, dynamic>>()
            .map((itemMap) => TournamentParticipants.fromJson(itemMap))
            .toList();
        if (participants.isEmpty) {
          return [];
        }
        return participants;
      } else {
        throw DbQueryException(
          message: 'Unexpected response status',
          details:
              'Status: ${response.statusCode}, Message: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      throw DbExceptions.handleDioException(
          e, 'retrieving tournament participants');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbQueryException(
        message: 'Unexpected error retrieving tournament participants',
        details: 'Error: $e',
      );
    }
  }

  Future<List<Tournament>> getTournaments({
    String? hostId,
    String? sportId,
    String? status,
    int? page,
    int? limit,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};

      if (hostId != null && hostId.isNotEmpty) {
        queryParams['host_id'] = hostId;
      }

      if (sportId != null && sportId.isNotEmpty) {
        queryParams['sport_id'] = sportId;
      }

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      if (page != null && page > 0) {
        queryParams['page'] = page;
      }

      if (limit != null && limit > 0) {
        queryParams['limit'] = limit;
      }

      final response = await DioClient.instance.get(
        'tournaments',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> responseMap = response.data;

        if (responseMap.containsKey('tournaments') &&
            responseMap['tournaments'] is List) {
          final List<dynamic> tournamentsDataList = responseMap['tournaments'];

          final List<Tournament> tournaments = tournamentsDataList
              .where((e) => e != null && e is Map<String, dynamic>)
              .map((e) => Tournament.fromJson(e as Map<String, dynamic>))
              .toList();

          return tournaments;
        } else {
          return [];
        }
      } else {
        throw DbQueryException(
          message: 'Unexpected response status',
          details:
              'Status: ${response.statusCode}, Message: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      throw DbExceptions.handleDioException(e, 'retrieving tournaments');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbQueryException(
        message: 'Unexpected error retrieving tournaments',
        details: 'Error: $e',
      );
    }
  }

  /// Joins a tournament
  Future<String> joinTournament(String tournamentId) async {
    try {
      if (tournamentId.isEmpty) {
        throw const DbInvalidInputException(
          message: 'Tournament ID is required',
          details: 'Tournament ID cannot be empty',
        );
      }

      final Map<String, dynamic> requestBody = {
        'tournament_id': tournamentId,
      };

      final response = await DioClient.instance.post(
        'tournaments/join',
        data: requestBody,
      );

      if (response.statusCode == 201 && response.data != null) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('message')) {
          return responseData['message'] as String;
        } else {
          return 'Successfully joined tournament';
        }
      } else {
        throw DbPostCreationException(
          message: 'Unexpected response status',
          details:
              'Status: ${response.statusCode}, Message: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      throw DbExceptions.handleDioException(e, 'joining tournament');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbPostCreationException(
        message: 'Unexpected error joining tournament',
        details: 'Error: $e',
      );
    }
  }

  /// Leaves a tournament
  Future<String> leaveTournament(String tournamentId) async {
    try {
      if (tournamentId.isEmpty) {
        throw const DbInvalidInputException(
          message: 'Tournament ID is required',
          details: 'Tournament ID cannot be empty',
        );
      }

      final response =
          await DioClient.instance.delete('tournaments/$tournamentId/leave');

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('message')) {
          return responseData['message'] as String;
        } else {
          return 'Successfully left tournament';
        }
      } else {
        throw DbDeleteException(
          message: 'Unexpected response status',
          details:
              'Status: ${response.statusCode}, Message: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      throw DbExceptions.handleDioException(e, 'leaving tournament');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbDeleteException(
        message: 'Unexpected error leaving tournament',
        details: 'Error: $e',
      );
    }
  }

  /// Updates a tournament
  Future<Tournament> updateTournament(Tournament tournament) async {
    try {
      if (tournament.id.isEmpty) {
        throw const DbInvalidInputException(
          message: 'Tournament ID is required',
          details: 'Tournament ID cannot be empty',
        );
      }

      if (tournament.title.trim().isEmpty) {
        throw const DbInvalidInputException(
          message: 'Tournament title is required',
          details: 'Title cannot be empty',
        );
      }

      if (tournament.location.trim().isEmpty) {
        throw const DbInvalidInputException(
          message: 'Tournament location is required',
          details: 'Location cannot be empty',
        );
      }

      if (tournament.sportId.trim().isEmpty) {
        throw const DbInvalidInputException(
          message: 'Sport ID is required',
          details: 'Sport ID cannot be empty',
        );
      }

      if (tournament.startDate.trim().isEmpty) {
        throw const DbInvalidInputException(
          message: 'Start date is required',
          details: 'Start date cannot be empty',
        );
      }

      if (tournament.endDate.trim().isEmpty) {
        throw const DbInvalidInputException(
          message: 'End date is required',
          details: 'End date cannot be empty',
        );
      }

      final Map<String, dynamic> requestBody = {};

      requestBody['title'] = tournament.title.trim();
      requestBody['location'] = tournament.location.trim();
      requestBody['sport_id'] = tournament.sportId;
      requestBody['start_date'] = tournament.startDate;
      requestBody['end_date'] = tournament.endDate;

      if (tournament.description != null &&
          tournament.description!.isNotEmpty) {
        requestBody['description'] = tournament.description!;
      }

      if (tournament.minAge != null && tournament.minAge! > 0) {
        requestBody['min_age'] = tournament.minAge!;
      }

      if (tournament.maxAge != null && tournament.maxAge! > 0) {
        requestBody['max_age'] = tournament.maxAge!;
      }

      if (tournament.level != null) {
        requestBody['level'] = tournament.level!.toJson();
      }

      if (tournament.gender != null) {
        requestBody['gender'] = tournament.gender!.toJson();
      }

      if (tournament.status != null) {
        requestBody['status'] = tournament.status!.toJson();
      }

      if (tournament.country != null && tournament.country!.isNotEmpty) {
        requestBody['country'] = tournament.country!;
      }

      if (tournament.bannerUrl != null && tournament.bannerUrl!.isNotEmpty) {
        requestBody['banner_url'] = tournament.bannerUrl!;
      }

      final response = await DioClient.instance.put(
        'tournaments/${tournament.id}',
        data: requestBody,
      );

      if (response.statusCode == 200 && response.data != null) {
        final tournamentData = response.data;
        final updatedTournament = Tournament.fromJson(tournamentData);
        return updatedTournament;
      } else {
        throw DbUpdateException(
          message: 'Unexpected response status',
          details:
              'Status: ${response.statusCode}, Message: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      throw DbExceptions.handleDioException(e, 'updating tournament');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbUpdateException(
        message: 'Unexpected error updating tournament',
        details: 'Error: $e',
      );
    }
  }

  /// Updates tournament participation status
  Future<String> updateTournamentParticipationStatus({
    required String tournamentId,
    required String userId,
    required ParticipationStatus status,
  }) async {
    try {
      if (tournamentId.isEmpty) {
        throw const DbInvalidInputException(
          message: 'Tournament ID is required',
          details: 'Tournament ID cannot be empty',
        );
      }

      if (userId.isEmpty) {
        throw const DbInvalidInputException(
          message: 'User ID is required',
          details: 'User ID cannot be empty',
        );
      }

      final Map<String, dynamic> requestBody = {
        'user_id': userId,
        'status': status.toJson(),
      };

      final response = await DioClient.instance.put(
        'tournaments/$tournamentId/participants/status',
        data: requestBody,
      );

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('message')) {
          return responseData['message'] as String;
        } else {
          return 'Successfully updated participation status';
        }
      } else {
        throw DbUpdateException(
          message: 'Unexpected response status',
          details:
              'Status: ${response.statusCode}, Message: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      throw DbExceptions.handleDioException(
          e, 'updating tournament participant status');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbUpdateException(
        message: 'Unexpected error updating tournament participant status',
        details: 'Error: $e',
      );
    }
  }

  /// Gets user's participated tournaments
  Future<List<TournamentParticipants>> getMyParticipatedTournaments({
    ParticipationStatus? status,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};

      if (status != null) {
        queryParams['status'] = status.toJson();
      }

      final response = await DioClient.instance.get(
        'tournaments/my-tournaments',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final participationsData = response.data;

        if (participationsData is List) {
          final List<TournamentParticipants> participations = participationsData
              .where((e) => e != null && e is Map<String, dynamic>)
              .map((e) =>
                  TournamentParticipants.fromJson(e as Map<String, dynamic>))
              .toList();

          return participations;
        } else {
          throw DbQueryException(
            message: 'Invalid response format',
            details:
                'Expected List but received: ${participationsData.runtimeType}',
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
      throw DbExceptions.handleDioException(
          e, 'retrieving my tournament participations');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbQueryException(
        message: 'Unexpected error retrieving my tournament participations',
        details: 'Error: $e',
      );
    }
  }
}
