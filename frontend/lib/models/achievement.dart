import 'enums.dart';

class Achievement {
  final String id;
  final String userId;
  final String date;
  final String sportId;
  final String tournament;
  final String description;
  final Level level;
  final dynamic stats;
  final String? certificateUrl;

  Achievement({
    required this.id,
    required this.userId,
    required this.date,
    required this.sportId,
    required this.tournament,
    required this.description,
    required this.level,
    required this.stats,
    this.certificateUrl,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: json['date'] as String,
      sportId: json['sport_id'] as String,
      tournament: json['tournament_title'] as String,
      description: json['description'] as String,
      level: Level.fromJson(json['level'] as String),
      stats: json['stats'],
      certificateUrl: json['certificate_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final json = toJson();
    json.addAll({
      'user_id': userId,
      'date': date,
      'sport_id': sportId,
      'tournament': tournament,
      'description': description,
      'level': level.toJson(),
      'stats': stats,
      'certificate_url': certificateUrl,
    });
    return json;
  }

  Achievement copyWith({
    String? id,
    String? createdAt,
    String? updatedAt,
    String? userId,
    String? date,
    String? sportId,
    String? tournament,
    String? description,
    Level? level,
    dynamic stats,
    String? certificateUrl,
  }) {
    return Achievement(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      sportId: sportId ?? this.sportId,
      tournament: tournament ?? this.tournament,
      description: description ?? this.description,
      level: level ?? this.level,
      stats: stats ?? this.stats,
      certificateUrl: certificateUrl ?? this.certificateUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Achievement &&
        super == other &&
        other.userId == userId &&
        other.date == date &&
        other.sportId == sportId &&
        other.tournament == tournament &&
        other.description == description &&
        other.level == level &&
        other.stats == stats &&
        other.certificateUrl == certificateUrl;
  }

  @override
  int get hashCode {
    return Object.hash(
      super.hashCode,
      userId,
      date,
      sportId,
      tournament,
      description,
      level,
      stats,
      certificateUrl,
    );
  }

  @override
  String toString() {
    return 'Achievement(id: $id, userId: $userId, tournament: $tournament, level: $level)';
  }
}
