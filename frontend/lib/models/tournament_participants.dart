import 'package:sportsin/models/models.dart';

class TournamentParticipants extends AppModel {
  final String userId;
  final String tournamentId;
  final ParticipationStatus status;
  final User? user;

  TournamentParticipants({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.userId,
    required this.tournamentId,
    required this.status,
    this.user,
  });

  factory TournamentParticipants.fromJson(Map<String, dynamic> json) {
    return TournamentParticipants(
      id: json['id'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      userId: json['user_id'] as String,
      tournamentId: json['tournament_id'] as String,
      status: ParticipationStatus.fromJson(json['status'] as String),
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'user_id': userId,
      'tournament_id': tournamentId,
      'status': status.toJson(),
      'user': user?.toJson(),
    });
    return json;
  }

  TournamentParticipants copyWith({
    String? id,
    String? createdAt,
    String? updatedAt,
    String? userId,
    String? tournamentId,
    ParticipationStatus? status,
    User? user,
  }) {
    return TournamentParticipants(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      tournamentId: tournamentId ?? this.tournamentId,
      status: status ?? this.status,
      user: user ?? this.user,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TournamentParticipants &&
        super == other &&
        other.userId == userId &&
        other.tournamentId == tournamentId &&
        other.status == status &&
        other.user == user;
  }

  @override
  int get hashCode {
    return Object.hash(
      super.hashCode,
      userId,
      tournamentId,
      status,
      user,
    );
  }

  @override
  String toString() {
    return 'TournamentParticipants(id: $id, userId: $userId, tournamentId: $tournamentId, status: $status)';
  }
}
