import 'package:dio/dio.dart';
import 'package:sportsin/models/user.dart';
import 'package:sportsin/models/player.dart';
import 'package:sportsin/models/recruiter.dart';
import 'package:sportsin/services/db/db_exceptions.dart';
import 'package:sportsin/services/core/dio_client.dart';

class UserRepository {
  static UserRepository? _instance;
  User? _cachedUser;

  UserRepository._();

  static UserRepository get instance {
    _instance ??= UserRepository._();
    return _instance!;
  }

  factory UserRepository() => instance;

  User? get cachedUser => _cachedUser;

  void clearCache() {
    _cachedUser = null;
  }

  void updateCachedUser(User user) {
    _cachedUser = user;
  }

  Future<User?> refreshUserCache() async {
    _cachedUser = null;
    return await getUser();
  }

  Future<User?> _handleUserResponse(Response response) async {
    if (response.statusCode == 200 && response.data != null) {
      final profileData = response.data['profile'];
      if (profileData == null) {
        return null;
      }

      final role = profileData['role'] as String?;
      if (role == null) {
        throw DbNotFoundException(
          message: 'User role not found in profile data',
          details: 'Profile data: $profileData',
        );
      }

      User? user;
      switch (role.toLowerCase()) {
        case 'player':
          user = Player.fromJson(profileData);
          break;
        case 'recruiter':
          user = Recruiter.fromJson(profileData);
          break;
        default:
          user = User.fromJson(profileData);
      }

      return user;
    } else {
      throw DbNotFoundException(
        message: 'Unexpected response status',
        details: 'Status: ${response.statusCode}, Data: ${response.data}',
      );
    }
  }

  Future<T> createUser<T extends User>(T user) async {
    try {
      final Map<String, dynamic> requestBody = {};

      requestBody['name'] = user.name;
      requestBody['surname'] = user.surname;
      requestBody['dob'] = user.dob;
      requestBody['gender'] = user.gender.toJson();
      requestBody['role'] = user.role.toJson();
      requestBody['user_name'] = user.userName;

      if (user.middleName != null && user.middleName!.isNotEmpty) {
        requestBody['middle_name'] = user.middleName;
      }

      if (user.profilePicture != null && user.profilePicture!.isNotEmpty) {
        requestBody['profile_picture'] = user.profilePicture;
      }

      if (user.about != null && user.about!.isNotEmpty) {
        requestBody['about'] = user.about;
      }

      if (user.referralCode != null && user.referralCode!.isNotEmpty) {
        requestBody['referal_code'] = user.referralCode;
      }

      if (user is Player) {
        requestBody['level'] = user.level.toJson();
        requestBody['interest_level'] = user.interestLevel.toJson();
        if (user.interestCountry != null && user.interestCountry!.isNotEmpty) {
          requestBody['interest_country'] = user.interestCountry;
        }
      } else if (user is Recruiter) {
        requestBody['organization_name'] = user.organizationName;
        requestBody['organization_id'] = user.organizationId;
        requestBody['phone_number'] = user.phoneNumber;
        requestBody['position'] = user.position;
      }

      final response = await DioClient.instance.post(
        'profile',
        data: requestBody,
      );

      if (response.statusCode == 201) {
        _cachedUser = user;
        return user;
      } else {
        throw Exception('Unexpected response status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw DbExceptions.handleDioException(e, 'creating user');
    } catch (e) {
      throw Exception('Error creating user: $e');
    }
  }

  Future<User?> getUser() async {
    try {
      final response = await DioClient.instance.get('profile/me');

      final user = await _handleUserResponse(response);
      _cachedUser = user;
      return user;
    } on DioException catch (e) {
      if (DbExceptions.shouldReturnNullForUser(e)) {
        return null;
      }
      throw DbExceptions.handleDioException(e, 'getting user');
    } catch (e) {
      if (e.toString().contains('User role not found')) {
        rethrow;
      }
      throw Exception('Error getting user: $e');
    }
  }

  Future<T> updateUser<T extends User>(T user) async {
    try {
      final currentUser = await getUser();
      if (currentUser == null) {
        throw Exception('User not found');
      }

      final Map<String, dynamic> requestBody = {};

      requestBody['name'] = user.name;
      requestBody['surname'] = user.surname;
      requestBody['dob'] = user.dob;
      requestBody['gender'] = user.gender.toJson();

      requestBody['middle_name'] = user.middleName ?? '';

      if (user.profilePicture != null && user.profilePicture!.isNotEmpty) {
        requestBody['profile_picture'] = user.profilePicture;
      }

      requestBody['about'] = user.about ?? '';

      if (user is Player) {
        requestBody['level'] = user.level.toJson();
        requestBody['interest_level'] = user.interestLevel.toJson();

        requestBody['interest_country'] = user.interestCountry ?? '';
      } else if (user is Recruiter) {
        requestBody['organization_name'] = user.organizationName;
        requestBody['organization_id'] = user.organizationId;
        requestBody['phone_number'] = user.phoneNumber;
        requestBody['position'] = user.position;
      }

      final response = await DioClient.instance.put(
        'profile',
        data: requestBody,
      );

      if (response.statusCode == 200) {
        _cachedUser = user;
        return user;
      } else {
        // This should not happen as Dio throws DioException for error status codes
        throw Exception('Unexpected response status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw DbExceptions.handleDioException(e, 'updating user');
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }

  Future<User?> getUserById(String uid) async {
    try {
      if (uid.isEmpty) {
        throw Exception('User ID is required');
      }

      final response = await DioClient.instance.get('profile/$uid');

      if (response.statusCode == 200 && response.data != null) {
        final profileData = response.data['profile'];
        if (profileData == null) {
          return null;
        }

        final role = profileData['role'] as String?;
        if (role == null) {
          throw DbNotFoundException(
            message: 'User role not found in profile data',
            details: 'Profile data: $profileData',
          );
        }

        User? user;
        switch (role.toLowerCase()) {
          case 'player':
            user = Player.fromJson(profileData);
            break;
          case 'recruiter':
            user = Recruiter.fromJson(profileData);
            break;
          default:
            user = User.fromJson(profileData);
        }

        return user;
      } else {
        throw DbNotFoundException(
          message: 'Unexpected response status',
          details: 'Status: ${response.statusCode}, Data: ${response.data}',
        );
      }
    } on DioException catch (e) {
      if (DbExceptions.shouldReturnNullForUser(e)) {
        return null;
      }
      throw DbExceptions.handleDioException(e, 'getting user by ID');
    } catch (e) {
      if (e.toString().contains('User ID is required')) {
        rethrow;
      }
      throw Exception('Error getting user by ID: $e');
    }
  }

  Future<String> getMyReferralCode() async {
    try {
      final response = await DioClient.instance.get('/profile/referal');

      final responseData = response.data as Map<String, dynamic>;

      final String? code = responseData['referal_code'] as String?;

      if (code != null && code.isNotEmpty) {
        return code;
      } else {
        throw DbExceptions(
          message: 'Failed to retrieve referral code',
          details: 'Server response did not contain a valid code.',
        );
      }
    } on DioException catch (e) {
      throw DbExceptions.handleDioException(e, 'Getting referral code');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbNotFoundException(
        message:
            'An unexpected error occurred while fetching your referral code.',
        details: 'Error: $e',
      );
    }
  }
}
