import 'user.dart';
import 'enums.dart';

class Player extends User {
  final Level level;
  final Level interestLevel;
  final String? interestCountry;

  Player({
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
    required this.level,
    required this.interestLevel,
    this.interestCountry,
    super.coins,
    super.referralCode,
    super.referredBy,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
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
      level: Level.fromJson(json['level'] as String),
      interestLevel: Level.fromJson(json['interest_level'] as String),
      interestCountry: json['interest_location'] as String?,
      coins: json['coins'] as int? ?? 0,
      referralCode: json['referal_code'] as String?,
      referredBy: json['reffered_by'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'level': level.toJson(),
      'interest_level': interestLevel.toJson(),
      'interest_location': interestCountry,
    });
    return json;
  }

  @override
  Player copyWith({
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
    Level? level,
    Level? interestLevel,
    String? interestCountry,
    int? coins,
    String? referralCode,
    String? referredBy,
  }) {
    return Player(
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
      level: level ?? this.level,
      interestLevel: interestLevel ?? this.interestLevel,
      interestCountry: interestCountry ?? this.interestCountry,
      coins: coins ?? this.coins,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Player &&
        super == other &&
        other.level == level &&
        other.interestLevel == interestLevel &&
        other.interestCountry == interestCountry;
  }

  @override
  int get hashCode {
    return Object.hash(
      super.hashCode,
      level,
      interestLevel,
      interestCountry,
    );
  }

  @override
  String toString() {
    return 'Player(id: $id, userName: $userName, level: $level, interestLevel: $interestLevel)';
  }
}
