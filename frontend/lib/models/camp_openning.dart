import 'models.dart';

class CampOpenning extends AppModel {
  final String sportName;
  final String companyName;
  final OpeningStatus status;
  final String title;
  final String description;
  final String position;
  final Address address;
  final int? minAge;
  final int? maxAge;
  final String? minLevel;
  final int? minSalary;
  final int? maxSalary;
  final String? countryRestriction;
  final Map<String, dynamic>? stats;
  final ApplicationStatus? applicationStatus;
  final bool isApplied;

  CampOpenning({
    required this.sportName,
    required this.companyName,
    required this.status,
    required this.title,
    required this.description,
    required this.position,
    required this.address,
    this.minAge,
    this.maxAge,
    this.minLevel,
    this.minSalary,
    this.maxSalary,
    this.countryRestriction,
    this.stats,
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    this.applicationStatus,
    this.isApplied = false,
  });

  factory CampOpenning.fromJson(Map<String, dynamic> json) {
    return CampOpenning(
      id: json['id'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      sportName: json['sport_name'] as String,
      companyName: json['company_name'] as String,
      status: (json['status'] as String) == 'open'
          ? OpeningStatus.open
          : OpeningStatus.closed,
      title: json['title'] as String,
      description: json['description'] as String,
      position: json['position'] as String,
      address: Address.fromJson(json['address'] as Map<String, dynamic>),
      minAge: json['min_age'] as int?,
      maxAge: json['max_age'] as int?,
      minLevel: json['min_level'] as String?,
      minSalary: json['min_salary'] as int?,
      maxSalary: json['max_salary'] as int?,
      countryRestriction: json['country_restriction'] as String?,
      stats: json['stats'] as Map<String, dynamic>?,
      applicationStatus: json['application_status'] != null
          ? ApplicationStatus.fromJson(json['application_status'] as String)
          : null,
      isApplied: json['applied'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'sport_name': sportName,
      'company_name': companyName,
      'status': status.toJson(),
      'title': title,
      'description': description,
      'position': position,
      'address': address.toJson(),
      'min_age': minAge,
      'max_age': maxAge,
      'min_level': minLevel,
      'min_salary': minSalary,
      'max_salary': maxSalary,
      'country_restriction': countryRestriction,
      'stats': stats,
      'application_status': applicationStatus?.toJson(),
      'applied': isApplied,
    });
    return json;
  }

  CampOpenning copyWith({
    String? sportName,
    String? companyName,
    OpeningStatus? status,
    String? title,
    String? description,
    String? position,
    Address? address,
    int? minAge,
    int? maxAge,
    String? minLevel,
    int? minSalary,
    int? maxSalary,
    String? countryRestriction,
    Map<String, dynamic>? stats,
    ApplicationStatus? applicationStatus,
    bool? isApplied,
  }) {
    return CampOpenning(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      sportName: sportName ?? this.sportName,
      companyName: companyName ?? this.companyName,
      status: status ?? this.status,
      title: title ?? this.title,
      description: description ?? this.description,
      position: position ?? this.position,
      address: address ?? this.address,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      minLevel: minLevel ?? this.minLevel,
      minSalary: minSalary ?? this.minSalary,
      maxSalary: maxSalary ?? this.maxSalary,
      countryRestriction: countryRestriction ?? this.countryRestriction,
      stats: stats ?? this.stats,
      applicationStatus: applicationStatus ?? this.applicationStatus,
      isApplied: isApplied ?? this.isApplied,
    );
  }
}
