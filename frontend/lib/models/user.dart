import 'app_model.dart';
import 'enums.dart';

class User extends AppModel {
  final String userName;
  final String? profilePicture;
  final String email;
  final Role role;
  final String name;
  final String? middleName;
  final String surname;
  final String dob;
  final Gender gender;
  final String? about;
  final String? referralCode;
  final String? referredBy;
  final int? coins;

  User({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.userName,
    this.profilePicture,
    required this.email,
    required this.role,
    required this.name,
    this.middleName,
    required this.surname,
    required this.dob,
    required this.gender,
    this.about,
    this.referralCode,
    this.referredBy,
    this.coins,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
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
      referralCode: json['referal_code'] as String?,
      referredBy: json['reffered_by'] as String?,
      coins: json['coins'] as int? ?? 0,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'user_name': userName,
      'profile_picture': profilePicture,
      'email': email,
      'role': role.toJson(),
      'name': name,
      'middle_name': middleName,
      'surname': surname,
      'dob': dob,
      'gender': gender.toJson(),
      'about': about,
      'referal_code': referralCode,
      'reffered_by': referredBy,
      'coins': coins,
    });
    return json;
  }

  User copyWith({
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
    String? referralCode,
    String? referredBy,
    int? coins,
  }) {
    return User(
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
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      coins: coins ?? this.coins,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.userName == userName &&
        other.profilePicture == profilePicture &&
        other.email == email &&
        other.role == role &&
        other.name == name &&
        other.middleName == middleName &&
        other.surname == surname &&
        other.dob == dob &&
        other.gender == gender &&
        other.about == about &&
        other.referralCode == referralCode &&
        other.referredBy == referredBy &&
        other.coins == coins;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      createdAt,
      updatedAt,
      userName,
      profilePicture,
      email,
      role,
      name,
      middleName,
      surname,
      dob,
      gender,
      about,
      referralCode,
      referredBy,
      coins,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, userName: $userName, email: $email, role: $role, name: $name $surname, referralCode: $referralCode, referredBy: $referredBy, coins: $coins)';
  }
}
