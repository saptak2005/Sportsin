import 'user.dart';
import 'enums.dart';

class Recruiter extends User {
  final String organizationName;
  final String organizationId;
  final String phoneNumber;
  final String position;

  Recruiter({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required super.userName,
    super.profilePicture,
    required super.email,
    required super.role,
    required super.name,
    super.middleName,
    required super.surname,
    required super.dob,
    required super.gender,
    super.about,
    required this.organizationName,
    required this.organizationId,
    required this.phoneNumber,
    required this.position,
    super.coins,
    super.referralCode,
    super.referredBy,
  });

  factory Recruiter.fromJson(Map<String, dynamic> json) {
    return Recruiter(
      id: json['id'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      userName: json['user_name'] as String,
      profilePicture: json['profile_picture'] as String?,
      email: json['email'] as String,
      role: Role.fromJson(json['role'] as String),
      name: json['name'] as String,
      middleName: json['middle_name'] as String?,
      surname: json['surname'] as String,
      dob: json['dob'] as String,
      gender: Gender.fromJson(json['gender'] as String),
      about: json['about'] as String?,
      organizationName: json['organization_name'] as String,
      organizationId: json['organization_id'] as String,
      phoneNumber: json['phone_number'] as String,
      position: json['position'] as String,
      coins: json['coins'] as int? ?? 0,
      referralCode: json['referal_code'] as String?,
      referredBy: json['reffered_by'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'organization_name': organizationName,
      'organization_id': organizationId,
      'phone_number': phoneNumber,
      'position': position,
    });
    return json;
  }

  @override
  Recruiter copyWith({
    String? id,
    String? createdAt,
    String? updatedAt,
    String? userName,
    String? profilePicture,
    String? email,
    Role? role,
    String? name,
    String? middleName,
    String? surname,
    String? dob,
    Gender? gender,
    String? about,
    String? organizationName,
    String? organizationId,
    String? phoneNumber,
    String? position,
    int? coins,
    String? referralCode,
    String? referredBy,
  }) {
    return Recruiter(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
      profilePicture: profilePicture ?? this.profilePicture,
      email: email ?? this.email,
      role: role ?? this.role,
      name: name ?? this.name,
      middleName: middleName ?? this.middleName,
      surname: surname ?? this.surname,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      about: about ?? this.about,
      organizationName: organizationName ?? this.organizationName,
      organizationId: organizationId ?? this.organizationId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      position: position ?? this.position,
      coins: coins ?? this.coins,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Recruiter &&
        super == other &&
        other.organizationName == organizationName &&
        other.organizationId == organizationId &&
        other.phoneNumber == phoneNumber &&
        other.position == position;
  }

  @override
  int get hashCode {
    return Object.hash(
      super.hashCode,
      organizationName,
      organizationId,
      phoneNumber,
      position,
    );
  }

  @override
  String toString() {
    return 'Recruiter(id: $id, userName: $userName, organizationName: $organizationName, position: $position)';
  }
}
