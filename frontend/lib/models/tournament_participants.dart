import 'app_model.dart';
import 'enums.dart';

class TournamentParticipants extends AppModel {
  final String userId;
  final String tournamentId;
  final ParticipationStatus status;

  TournamentParticipants({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.userId,
    required this.tournamentId,
    required this.status,
  });

  factory TournamentParticipants.fromJson(Map<String, dynamic> json) {
    return TournamentParticipants(
      id: json['id'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      userId: json['user_id'] as String,
      tournamentId: json['tournament_id'] as String,
      status: ParticipationStatus.fromJson(json['status'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'user_id': userId,
      'tournament_id': tournamentId,
      'status': status.toJson(),
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
  }) {
    return TournamentParticipants(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      tournamentId: tournamentId ?? this.tournamentId,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TournamentParticipants &&
        super == other &&
        other.userId == userId &&
        other.tournamentId == tournamentId &&
        other.status == status;
  }

  @override
  int get hashCode {
    return Object.hash(
      super.hashCode,
      userId,
      tournamentId,
      status,
    );
  }

  @override
  String toString() {
    return 'TournamentParticipants(id: $id, userId: $userId, tournamentId: $tournamentId, status: $status)';
  }
}
