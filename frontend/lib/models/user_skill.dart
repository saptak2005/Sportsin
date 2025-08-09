import 'app_model.dart';

class UserSkill extends AppModel {
  final String userId;
  final String sportId;

  UserSkill({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.userId,
    required this.sportId,
  });

  factory UserSkill.fromJson(Map<String, dynamic> json) {
    return UserSkill(
      id: json['id'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      userId: json['user_id'] as String,
      sportId: json['sport_id'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'user_id': userId,
      'sport_id': sportId,
    });
    return json;
  }

  UserSkill copyWith({
    String? id,
    String? createdAt,
    String? updatedAt,
    String? userId,
    String? sportId,
  }) {
    return UserSkill(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      sportId: sportId ?? this.sportId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserSkill &&
        super == other &&
        other.userId == userId &&
        other.sportId == sportId;
  }

  @override
  int get hashCode {
    return Object.hash(
      super.hashCode,
      userId,
      sportId,
    );
  }

  @override
  String toString() {
    return 'UserSkill(id: $id, userId: $userId, sportId: $sportId)';
  }
}
