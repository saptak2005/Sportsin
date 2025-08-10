import 'app_model.dart';
import 'enums.dart';

class ApplicantResponse extends AppModel {
  final ApplicationStatus status;
  final String openingId;
  final String username;
  final String email;
  final String role;
  final String userName;
  final String? profilePicture;
  final String name;
  final String? middleName;
  final String surname;
  final String dob;
  final String gender;
  final String? about;
  final String level;
  final String interestLevel;
  final String? interestCountry;

  ApplicantResponse({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.status,
    required this.openingId,
    required this.username,
    required this.email,
    required this.role,
    required this.userName,
    this.profilePicture,
    required this.name,
    this.middleName,
    required this.surname,
    required this.dob,
    required this.gender,
    this.about,
    required this.level,
    required this.interestLevel,
    this.interestCountry,
  });

  factory ApplicantResponse.fromJson(Map<String, dynamic> json) {
    return ApplicantResponse(
      id: json['id'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      status: ApplicationStatus.fromJson(json['status'] as String),
      openingId: json['opening_id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      userName: json['user_name'] as String,
      profilePicture: json['profile_picture'] as String?,
      name: json['name'] as String,
      middleName: json['middle_name'] as String?,
      surname: json['surname'] as String,
      dob: json['dob'] as String,
      gender: json['gender'] as String,
      about: json['about'] as String?,
      level: json['level'] as String,
      interestLevel: json['interest_level'] as String,
      interestCountry: json['interest_country'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'status': status.toJson(),
      'opening_id': openingId,
      'username': username,
      'email': email,
      'role': role,
      'user_name': userName,
      'profile_picture': profilePicture,
      'name': name,
      'middle_name': middleName,
      'surname': surname,
      'dob': dob,
      'gender': gender,
      'about': about,
      'level': level,
      'interest_level': interestLevel,
      'interest_country': interestCountry,
    });
    return json;
  }

  ApplicantResponse copyWith({
    String? id,
    String? createdAt,
    String? updatedAt,
    ApplicationStatus? status,
    String? openingId,
    String? username,
    String? email,
    String? role,
    String? userName,
    String? profilePicture,
    String? name,
    String? middleName,
    String? surname,
    String? dob,
    String? gender,
    String? about,
    String? level,
    String? interestLevel,
    String? interestCountry,
  }) {
    return ApplicantResponse(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      openingId: openingId ?? this.openingId,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      userName: userName ?? this.userName,
      profilePicture: profilePicture ?? this.profilePicture,
      name: name ?? this.name,
      middleName: middleName ?? this.middleName,
      surname: surname ?? this.surname,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      about: about ?? this.about,
      level: level ?? this.level,
      interestLevel: interestLevel ?? this.interestLevel,
      interestCountry: interestCountry ?? this.interestCountry,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ApplicantResponse &&
        other.id == id &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.status == status &&
        other.openingId == openingId &&
        other.username == username &&
        other.email == email &&
        other.role == role &&
        other.userName == userName &&
        other.profilePicture == profilePicture &&
        other.name == name &&
        other.middleName == middleName &&
        other.surname == surname &&
        other.dob == dob &&
        other.gender == gender &&
        other.about == about &&
        other.level == level &&
        other.interestLevel == interestLevel &&
        other.interestCountry == interestCountry;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      createdAt,
      updatedAt,
      status,
      openingId,
      username,
      email,
      role,
      userName,
      profilePicture,
      name,
      middleName,
      surname,
      dob,
      gender,
      about,
      level,
      interestLevel,
      interestCountry,
    );
  }

  @override
  String toString() {
    return 'ApplicantResponse(id: $id, status: $status, name: $name $surname, email: $email, level: $level)';
  }
}
