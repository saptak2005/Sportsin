import 'package:dio/dio.dart';
import 'package:sportsin/models/camp_openning.dart';
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

      final Map<String, dynamic> requestBody = {
        'opening_id': openingId,
      };

      final response = await DioClient.instance.post(
        'camp-openings/apply',
        data: requestBody,
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
          message: 'Opening title is required',
          details: 'Title cannot be empty',
        );
      }

      if (opening.sportId.trim().isEmpty) {
        throw const DbInvalidInputException(
          message: 'Sport ID is required',
          details: 'Sport ID cannot be empty',
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

      final Map<String, dynamic> requestBody = {};

      requestBody['title'] = opening.title.trim();
      requestBody['sport_id'] = opening.sportId;
      requestBody['position'] = opening.position;
      requestBody['company_name'] = opening.companyName;
      requestBody['recruiter_id'] = opening.recruiterId;
      requestBody['description'] = opening.description;
      requestBody['status'] = opening.status.toJson();

      if (opening.minAge != null && opening.minAge! > 0) {
        requestBody['min_age'] = opening.minAge!;
      }

      if (opening.maxAge != null && opening.maxAge! > 0) {
        requestBody['max_age'] = opening.maxAge!;
      }

      if (opening.minLevel != null && opening.minLevel!.isNotEmpty) {
        requestBody['min_level'] = opening.minLevel!;
      }

      if (opening.minSalary != null && opening.minSalary! > 0) {
        requestBody['min_salary'] = opening.minSalary!;
      }

      if (opening.maxSalary != null && opening.maxSalary! > 0) {
        requestBody['max_salary'] = opening.maxSalary!;
      }

      if (opening.countryRestriction != null && opening.countryRestriction!.isNotEmpty) {
        requestBody['country_restriction'] = opening.countryRestriction!;
      }

      if (opening.addressId != null && opening.addressId!.isNotEmpty) {
        requestBody['address_id'] = opening.addressId!;
      }

      final response = await DioClient.instance.post(
        'camp-openings',
        data: requestBody,
      );

      if (response.statusCode == 201 && response.data != null) {
        final openingData = response.data;
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

      final response = await DioClient.instance.delete('camp-openings/$openingId');

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
        'camp-openings/my-openings',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final responseMap = response.data;

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

  Future<List<dynamic>> getOpeningApplicants(String openingId) async {
    try {
      if (openingId.isEmpty) {
        throw const DbInvalidInputException(
          message: 'Opening ID is required',
          details: 'Opening ID cannot be empty',
        );
      }

      final response = await DioClient.instance.get(
        'camp-openings/$openingId/applicants',
      );

      if (response.statusCode == 200 && response.data != null) {
        final applicantsData = response.data;

        if (applicantsData is Map<String, dynamic> && 
            applicantsData.containsKey('applicants')) {
          final List<dynamic> applicantsList = applicantsData['applicants'];
          return applicantsList;
        } else if (applicantsData is List) {
          return applicantsData;
        } else {
          throw DbQueryException(
            message: 'Invalid response format',
            details: 'Expected List or Map with applicants key but received: ${applicantsData.runtimeType}',
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

      final response = await DioClient.instance.get('camp-openings/$openingId');

      if (response.statusCode == 200 && response.data != null) {
        final openingData = response.data;

        if (openingData is Map<String, dynamic>) {
          final opening = CampOpenning.fromJson(openingData);
          return opening;
        } else {
          throw DbQueryException(
            message: 'Invalid response format',
            details:
                'Expected opening object but received: ${openingData.runtimeType}',
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
    String? sportId,
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

      if (sportId != null && sportId.isNotEmpty) {
        queryParams['sport_id'] = sportId;
      }

      if (country != null && country.isNotEmpty) {
        queryParams['country_restriction'] = country;
      }

      if (applied != null) {
        queryParams['applied'] = applied;
      }

      final response = await DioClient.instance.get(
        'camp-openings',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final responseMap = response.data;

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

  Future<void> updateApplicationStatus({
    required String openingId,
    required String applicationId,
    required OpeningStatus status,
  }) async {
    try {
      if (openingId.isEmpty) {
        throw const DbInvalidInputException(
          message: 'Opening ID is required',
          details: 'Opening ID cannot be empty',
        );
      }

      if (applicationId.isEmpty) {
        throw const DbInvalidInputException(
          message: 'Application ID is required',
          details: 'Application ID cannot be empty',
        );
      }

      final Map<String, dynamic> requestBody = {
        'application_id': applicationId,
        'status': status.toJson(),
      };

      final response = await DioClient.instance.put(
        'camp-openings/$openingId/applications/status',
        data: requestBody,
      );

      if (response.statusCode == 200) {
        return;
      } else {
        throw DbUpdateException(
          message: 'Unexpected response status',
          details:
              'Status: ${response.statusCode}, Message: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      throw DbExceptions.handleDioException(e, 'updating application status');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbUpdateException(
        message: 'Unexpected error updating application status',
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

      if (opening.sportId.trim().isEmpty) {
        throw const DbInvalidInputException(
          message: 'Sport ID is required',
          details: 'Sport ID cannot be empty',
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

      final Map<String, dynamic> requestBody = {};

      requestBody['title'] = opening.title.trim();
      requestBody['sport_id'] = opening.sportId;
      requestBody['position'] = opening.position;
      requestBody['company_name'] = opening.companyName;
      requestBody['recruiter_id'] = opening.recruiterId;
      requestBody['description'] = opening.description;
      requestBody['status'] = opening.status.toJson();

      if (opening.minAge != null && opening.minAge! > 0) {
        requestBody['min_age'] = opening.minAge!;
      }

      if (opening.maxAge != null && opening.maxAge! > 0) {
        requestBody['max_age'] = opening.maxAge!;
      }

      if (opening.minLevel != null && opening.minLevel!.isNotEmpty) {
        requestBody['min_level'] = opening.minLevel!;
      }

      if (opening.minSalary != null && opening.minSalary! > 0) {
        requestBody['min_salary'] = opening.minSalary!;
      }

      if (opening.maxSalary != null && opening.maxSalary! > 0) {
        requestBody['max_salary'] = opening.maxSalary!;
      }

      if (opening.countryRestriction != null && opening.countryRestriction!.isNotEmpty) {
        requestBody['country_restriction'] = opening.countryRestriction!;
      }

      if (opening.addressId != null && opening.addressId!.isNotEmpty) {
        requestBody['address_id'] = opening.addressId!;
      }

      final response = await DioClient.instance.put(
        'camp-openings/${opening.id}',
        data: requestBody,
      );

      if (response.statusCode == 200 && response.data != null) {
        final openingData = response.data;
        final updatedOpening = CampOpenning.fromJson(openingData);
        return updatedOpening;
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
        throw const DbInvalidInputException(
          message: 'Opening ID is required',
          details: 'Opening ID cannot be empty',
        );
      }

      final Map<String, dynamic> requestBody = {
        'status': status.toJson(),
      };

      final response = await DioClient.instance.patch(
        'camp-openings/$openingId/status',
        data: requestBody,
      );

      if (response.statusCode == 200 && response.data != null) {
        final openingData = response.data;
        final updatedOpening = CampOpenning.fromJson(openingData);
        return updatedOpening;
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

  Future<void> withdrawApplication(String openingId, String applicationId) async {
    try {
      if (openingId.isEmpty) {
        throw const DbInvalidInputException(
          message: 'Opening ID is required',
          details: 'Opening ID cannot be empty',
        );
      }

      if (applicationId.isEmpty) {
        throw const DbInvalidInputException(
          message: 'Application ID is required',
          details: 'Application ID cannot be empty',
        );
      }

      final response = await DioClient.instance.delete(
        'camp-openings/$openingId/applications/$applicationId',
      );

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
      throw DbExceptions.handleDioException(e, 'withdrawing application');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbDeleteException(
        message: 'Unexpected error withdrawing application',
        details: 'Error: $e',
      );
    }
  }
}