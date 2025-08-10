import 'app_model.dart';
import 'sport.dart';
import 'enums.dart';

class Tournament extends AppModel {
  final String hostId;
  final String title;
  final String? description;
  final String location;
  final String sportId;
  final int? minAge;
  final int? maxAge;
  final Level? level;
  final Gender? gender;
  final String? country;
  final TournamentStatus? status;
  final String startDate;
  final String endDate;
  final String? bannerUrl;

  Tournament({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.hostId,
    required this.title,
    this.description,
    required this.location,
    required this.sportId,
    this.minAge,
    this.maxAge,
    this.level,
    this.gender,
    this.country,
    this.status,
    required this.startDate,
    required this.endDate,
    this.bannerUrl,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      hostId: json['host_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String,
      sportId: json['sport_id'] as String,
      minAge: json['min_age'] as int?,
      maxAge: json['max_age'] as int?,
      level: json['level'] != null
          ? Level.fromJson(json['level'] as String)
          : null,
      gender: json['gender'] != null
          ? Gender.fromJson(json['gender'] as String)
          : null,
      country: json['country'] as String?,
      status: json['status'] != null
          ? TournamentStatus.fromJson(json['status'] as String)
          : null,
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      bannerUrl: json['banner_url'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'host_id': hostId,
      'title': title,
      'description': description,
      'location': location,
      'sport_id': sportId,
      'min_age': minAge,
      'max_age': maxAge,
      'level': level?.toJson(),
      'gender': gender?.toJson(),
      'country': country,
      'status': status?.toJson(),
      'start_date': startDate,
      'end_date': endDate,
      'banner_url': bannerUrl,
    });
    return json;
  }

  Tournament copyWith({
    String? id,
    String? createdAt,
    String? updatedAt,
    String? hostId,
    String? title,
    String? description,
    String? location,
    String? sportId,
    int? minAge,
    int? maxAge,
    Level? level,
    Gender? gender,
    String? country,
    TournamentStatus? status,
    String? startDate,
    String? endDate,
    String? bannerUrl,
  }) {
    return Tournament(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      hostId: hostId ?? this.hostId,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      sportId: sportId ?? this.sportId,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      level: level ?? this.level,
      gender: gender ?? this.gender,
      country: country ?? this.country,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      bannerUrl: bannerUrl ?? this.bannerUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tournament &&
        super == other &&
        other.hostId == hostId &&
        other.title == title &&
        other.description == description &&
        other.location == location &&
        other.sportId == sportId &&
        other.minAge == minAge &&
        other.maxAge == maxAge &&
        other.level == level &&
        other.gender == gender &&
        other.country == country &&
        other.status == status &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.bannerUrl == bannerUrl;
  }

  @override
  int get hashCode {
    return Object.hash(
      super.hashCode,
      hostId,
      title,
      description,
      location,
      sportId,
      minAge,
      maxAge,
      level,
      gender,
      country,
      status,
      startDate,
      endDate,
      bannerUrl,
    );
  }

  @override
  String toString() {
    return 'Tournament(id: $id, title: $title, location: $location, status: $status)';
  }
}

class TournamentDetails {
  final Tournament tournament;
  final String hostName;
  final Sport? sport;
  final bool isEnrolled;
  final int participantsCount;
  final ParticipationStatus? participationStatus;

  TournamentDetails({
    required this.tournament,
    required this.hostName,
    this.sport,
    required this.isEnrolled,
    required this.participantsCount,
    this.participationStatus,
  });

  factory TournamentDetails.fromJson(Map<String, dynamic> json) {
    return TournamentDetails(
      tournament:
          Tournament.fromJson(json['tournament'] as Map<String, dynamic>),
      hostName: json['host_name'] as String,
      sport: json['sport'] != null
          ? Sport.fromJson(json['sport'] as Map<String, dynamic>)
          : null,
      isEnrolled: json['is_enrolled'] as bool,
      participantsCount: json['participants_count'] as int,
      participationStatus: json['participation_status'] != null
          ? ParticipationStatus.fromJson(json['participation_status'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tournament': tournament.toJson(),
      'host_name': hostName,
      'sport': sport?.toJson(),
      'is_enrolled': isEnrolled,
      'participants_count': participantsCount,
      'participation_status': participationStatus?.toJson(),
    };
  }

  TournamentDetails copyWith({
    Tournament? tournament,
    String? hostName,
    Sport? sport,
    bool? isEnrolled,
    int? participantsCount,
    ParticipationStatus? participationStatus,
  }) {
    return TournamentDetails(
      tournament: tournament ?? this.tournament,
      hostName: hostName ?? this.hostName,
      sport: sport ?? this.sport,
      isEnrolled: isEnrolled ?? this.isEnrolled,
      participantsCount: participantsCount ?? this.participantsCount,
      participationStatus: participationStatus ?? this.participationStatus,
    );
  }
}
