enum Gender {
  male('male'),
  female('female'),
  other('other'),
  ratherNotSay('rather_not_say');

  const Gender(this.value);
  final String value;

  factory Gender.fromJson(String value) {
    return Gender.values.firstWhere(
      (gender) => gender.value == value,
      orElse: () => Gender.ratherNotSay,
    );
  }

  String toJson() => value;
}

enum Role {
  admin('admin'),
  player('player'),
  recruiter('recruiter');

  const Role(this.value);
  final String value;

  factory Role.fromJson(String value) {
    return Role.values.firstWhere(
      (role) => role.value == value,
      orElse: () => Role.player,
    );
  }

  String toJson() => value;
}

enum Level {
  district('district'),
  state('state'),
  country('country'),
  international('international'),
  personal('personal');

  const Level(this.value);
  final String value;

  factory Level.fromJson(String value) {
    return Level.values.firstWhere(
      (level) => level.value == value,
      orElse: () => Level.personal,
    );
  }

  String toJson() => value;
}

enum TournamentStatus {
  scheduled('scheduled'),
  started('started'),
  ended('ended'),
  cancelled('cancelled');

  const TournamentStatus(this.value);
  final String value;

  factory TournamentStatus.fromJson(String value) {
    return TournamentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TournamentStatus.scheduled,
    );
  }

  String toJson() => value;
}

enum ParticipationStatus {
  pending('pending'),
  accepted('accepted'),
  rejected('rejected');

  const ParticipationStatus(this.value);
  final String value;

  factory ParticipationStatus.fromJson(String value) {
    return ParticipationStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ParticipationStatus.pending,
    );
  }

  String toJson() => value;
}

enum OpeningStatus {
  open('open'),
  closed('closed');

  const OpeningStatus(this.value);
  final String value;

  factory OpeningStatus.fromJson(String value) {
    return OpeningStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => OpeningStatus.closed,
    );
  }

  String toJson() => value;
}
