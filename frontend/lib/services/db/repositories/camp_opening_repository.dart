import 'package:dio/dio.dart';
import 'package:sportsin/models/camp_openning.dart';
import 'package:sportsin/models/applicant_response.dart';
import 'package:sportsin/services/core/dio_client.dart';
import 'package:sportsin/services/db/db_exceptions.dart';
import '../../../models/enums.dart';

class CampOpeningRepository {
  static CampOpeningRepository? _instance;

  CampOpeningRepository._();

  static CampOpeningRepository get instance {
    _instance ??= CampOpeningRepository._();
    return _instance!;
  }

  factory CampOpeningRepository() => instance;

  Future<void> applyToOpening(String openingId) async {
    try {
      if (openingId.isEmpty) {
        throw const DbInvalidInputException(
          message: 'Opening ID is required',
          details: 'Opening ID cannot be empty',
        );
      }

      final response = await DioClient.instance.post(
        'openings/$openingId/apply',
        data: {},
      );

      if (response.statusCode == 201) {
        return;
      } else {
        throw DbPostCreationException(
          message: 'Unexpected response status',
          details:
              'Status: ${response.statusCode}, Message: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      throw DbExceptions.handleDioException(e, 'applying to opening');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbPostCreationException(
        message: 'Unexpected error applying to opening',
        details: 'Error: $e',
      );
    }
  }

  Future<CampOpenning> createOpening(CampOpenning opening) async {
    try {
      if (opening.title.trim().isEmpty) {
        throw const DbInvalidInputException(
            message: 'Opening title is required');
      }
      if (opening.sportName.trim().isEmpty) {
        throw const DbInvalidInputException(message: 'Sport name is required');
      }
      if (opening.position.trim().isEmpty) {
        throw const DbInvalidInputException(message: 'Position is required');
      }
      if (opening.companyName.trim().isEmpty) {
        throw const DbInvalidInputException(
            message: 'Company name is required');
      }
      if (opening.address.country.trim().isEmpty ||
          opening.address.state.trim().isEmpty ||
          opening.address.city.trim().isEmpty) {
        throw const DbInvalidInputException(
            message: 'Complete address is required');
      }

      final response = await DioClient.instance.post(
        'openings',
        data: opening.toJson(),
      );

      if (response.statusCode == 201 && response.data != null) {
        final openingData = response.data['opening'];
        final createdOpening = CampOpenning.fromJson(openingData);
        return createdOpening;
      } else {
        throw DbPostCreationException(
          message: 'Unexpected response status',
          details:
              'Status: ${response.statusCode}, Message: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      throw DbExceptions.handleDioException(e, 'creating camp opening');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbPostCreationException(
        message: 'Unexpected error creating camp opening',
        details: 'Error: $e',
      );
    }
  }

  Future<void> deleteOpening(String openingId) async {
    try {
      if (openingId.isEmpty) {
        throw const DbInvalidInputException(
          message: 'Opening ID is required',
          details: 'Opening ID cannot be empty',
        );
      }

      final response = await DioClient.instance.delete('openings/$openingId');

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
      throw DbExceptions.handleDioException(e, 'deleting camp opening');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbDeleteException(
        message: 'Unexpected error deleting camp opening',
        details: 'Error: $e',
      );
    }
  }

  Future<List<CampOpenning>> getMyOpenings({int? limit, int? offset}) async {
    try {
      final Map<String, dynamic> queryParams = {};

      if (limit != null && limit > 0) {
        queryParams['limit'] = limit;
      }

      if (offset != null && offset >= 0) {
        queryParams['offset'] = offset;
      }

      final response = await DioClient.instance.get(
        'openings/my',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final responseMap = response.data;
        if (responseMap == null) {
          return [];
        }

        if (responseMap is Map<String, dynamic> &&
            responseMap.containsKey('openings') &&
            responseMap['openings'] is List) {
          final List<dynamic> openingsDataList = responseMap['openings'];

          final List<CampOpenning> openings = openingsDataList
              .where((e) => e != null && e is Map<String, dynamic>)
              .map((e) => CampOpenning.fromJson(e as Map<String, dynamic>))
              .toList();

          return openings;
        } else if (responseMap is List) {
          final List<CampOpenning> openings = responseMap
              .where((e) => e != null && e is Map<String, dynamic>)
              .map((e) => CampOpenning.fromJson(e as Map<String, dynamic>))
              .toList();

          return openings;
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
      throw DbExceptions.handleDioException(e, 'retrieving my camp openings');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbQueryException(
        message: 'Unexpected error retrieving my camp openings',
        details: 'Error: $e',
      );
    }
  }

  Future<List<ApplicantResponse>> getOpeningApplicants(String openingId) async {
    try {
      if (openingId.isEmpty) {
        throw const DbInvalidInputException(
          message: 'Opening ID is required',
          details: 'Opening ID cannot be empty',
        );
      }

      final response = await DioClient.instance.get(
        'openings/$openingId/applicants',
      );

      if (response.statusCode == 200 && response.data != null) {
        final applicantsData = response.data;

        if (applicantsData is Map<String, dynamic> &&
            applicantsData.containsKey('applicants')) {
          final List<dynamic> applicantsJson = applicantsData['applicants'];
          final List<ApplicantResponse> applicantsList = applicantsJson
              .where((e) => e != null && e is Map<String, dynamic>)
              .map((e) => ApplicantResponse.fromJson(e as Map<String, dynamic>))
              .toList();
          return applicantsList;
        } else {
          throw DbQueryException(
            message: 'Invalid response format',
            details:
                'Expected List or Map with applicants key but received: ${applicantsData.runtimeType}',
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
      throw DbExceptions.handleDioException(e, 'retrieving opening applicants');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbQueryException(
        message: 'Unexpected error retrieving opening applicants',
        details: 'Error: $e',
      );
    }
  }

  Future<CampOpenning?> getOpeningById(String openingId) async {
    try {
      if (openingId.isEmpty) {
        throw const DbInvalidInputException(
          message: 'Opening ID is required',
          details: 'Opening ID cannot be empty',
        );
      }

      final response = await DioClient.instance.get('openings/$openingId');

      if (response.statusCode == 200 && response.data != null) {
        final openingData = response.data['opening'];
        return CampOpenning.fromJson(openingData);
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
      throw DbExceptions.handleDioException(e, 'retrieving camp opening by ID');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbQueryException(
        message: 'Unexpected error retrieving camp opening by ID',
        details: 'Error: $e',
      );
    }
  }

  Future<List<CampOpenning>> getOpenings({
    int? limit,
    int? offset,
    String? recruiterId,
    String? sportName,
    String? country,
    bool? applied,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};

      if (limit != null && limit > 0) {
        queryParams['limit'] = limit;
      }

      if (offset != null && offset >= 0) {
        queryParams['offset'] = offset;
      }

      if (recruiterId != null && recruiterId.isNotEmpty) {
        queryParams['recruiter_id'] = recruiterId;
      }

      if (sportName != null && sportName.isNotEmpty) {
        queryParams['sport_name'] = sportName;
      }

      if (country != null && country.isNotEmpty) {
        queryParams['country_restriction'] = country;
      }

      if (applied != null) {
        queryParams['applied'] = applied;
      }

      final response = await DioClient.instance.get(
        'openings/filter',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data?['openings'] is List) {
        final List<dynamic> openingsDataList = response.data['openings'];
        return openingsDataList
            .map((e) => CampOpenning.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      throw DbExceptions.handleDioException(e, 'retrieving camp openings');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbQueryException(
        message: 'Unexpected error retrieving camp openings',
        details: 'Error: $e',
      );
    }
  }

  Future<void> acceptApplication(String openingId, String applicantId) async {
    await _updateApplicationAction(openingId, applicantId, 'accept');
  }

  Future<void> rejectApplication(String openingId, String applicantId) async {
    await _updateApplicationAction(openingId, applicantId, 'reject');
  }

  Future<void> withdrawApplication(String openingId, String applicantId) async {
    await _updateApplicationAction(openingId, applicantId, 'withdraw');
  }

  Future<void> _updateApplicationAction(
      String openingId, String applicantId, String action) async {
    try {
      if (openingId.isEmpty || applicantId.isEmpty) {
        throw const DbInvalidInputException(
            message: 'Opening and Applicant IDs are required');
      }

      final response = await DioClient.instance.patch(
        'openings/$openingId/applicants/$applicantId/$action',
      );

      if (response.statusCode == 200) {
        return;
      } else {
        throw DbUpdateException(
          message: 'Unexpected response status on action: $action',
          details:
              'Status: ${response.statusCode}, Message: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      throw DbExceptions.handleDioException(e, '$action application');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbUpdateException(
        message: 'Unexpected error on action: $action',
        details: 'Error: $e',
      );
    }
  }

  Future<CampOpenning> updateOpening(CampOpenning opening) async {
    try {
      if (opening.id.isEmpty) {
        throw const DbInvalidInputException(
          message: 'Opening ID is required',
          details: 'Opening ID cannot be empty',
        );
      }

      if (opening.title.trim().isEmpty) {
        throw const DbInvalidInputException(
          message: 'Opening title is required',
          details: 'Title cannot be empty',
        );
      }

      if (opening.sportName.trim().isEmpty) {
        throw const DbInvalidInputException(
          message: 'Sport name is required',
          details: 'Sport name cannot be empty',
        );
      }

      if (opening.position.trim().isEmpty) {
        throw const DbInvalidInputException(
          message: 'Position is required',
          details: 'Position cannot be empty',
        );
      }

      if (opening.companyName.trim().isEmpty) {
        throw const DbInvalidInputException(
          message: 'Company name is required',
          details: 'Company name cannot be empty',
        );
      }

      // Address validation
      if (opening.address.country.trim().isEmpty ||
          opening.address.state.trim().isEmpty ||
          opening.address.city.trim().isEmpty) {
        throw const DbInvalidInputException(
          message: 'Complete address is required',
          details: 'Country, state, and city are required',
        );
      }

      final response = await DioClient.instance.put(
        'openings/${opening.id}',
        data: opening.toJson(),
      );

      if (response.statusCode == 200 && response.data?['opening'] != null) {
        final openingData = response.data['opening'];
        return CampOpenning.fromJson(openingData);
      } else {
        throw DbUpdateException(
          message: 'Unexpected response status',
          details:
              'Status: ${response.statusCode}, Message: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      throw DbExceptions.handleDioException(e, 'updating camp opening');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbUpdateException(
        message: 'Unexpected error updating camp opening',
        details: 'Error: $e',
      );
    }
  }

  Future<CampOpenning> updateOpeningStatus({
    required String openingId,
    required OpeningStatus status,
  }) async {
    try {
      if (openingId.isEmpty) {
        throw const DbInvalidInputException(message: 'Opening ID is required');
      }

      final Map<String, dynamic> requestBody = {
        'status': status.toJson(),
      };

      final response = await DioClient.instance.patch(
        'openings/$openingId/status',
        data: requestBody,
      );

      if (response.statusCode == 200 && response.data?['opening'] != null) {
        final openingData = response.data['opening'];
        return CampOpenning.fromJson(openingData);
      } else {
        throw DbUpdateException(
          message: 'Unexpected response status',
          details:
              'Status: ${response.statusCode}, Message: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      throw DbExceptions.handleDioException(e, 'updating opening status');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbUpdateException(
        message: 'Unexpected error updating opening status',
        details: 'Error: $e',
      );
    }
  }
}
