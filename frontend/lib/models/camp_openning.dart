import 'package:flutter/foundation.dart';
import 'package:sportsin/models/models.dart';

class CampOpenning extends AppModel {
  final String sportId;
  final String recruiterId;
  final String companyName;
  final OpeningStatus status;
  final String title;
  final String description;
  final String position;
  final int? minAge;
  final int? maxAge;
  final String? minLevel;
  final int? minSalary;
  final int? maxSalary;
  final String? countryRestriction;
  final String? addressId;
  final Map<String, dynamic>? stats;

  CampOpenning({
    required this.sportId,
    required this.recruiterId,
    required this.companyName,
    required this.status,
    required this.title,
    required this.description,
    required this.position,
    required this.minAge,
    required this.maxAge,
    required this.minLevel,
    required this.minSalary,
    required this.maxSalary,
    required this.countryRestriction,
    required this.addressId,
    required this.stats,
    required super.id,
    required super.createdAt,
    required super.updatedAt,
  });

  factory CampOpenning.fromJson(Map<String, dynamic> json) {
    return CampOpenning(
      id: json['id'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      sportId: json['sport_id'] as String,
      recruiterId: json['recruiter_id'] as String,
      companyName: json['company_name'] as String,
      status: (json['status'] as String) == 'open'
          ? OpeningStatus.open
          : OpeningStatus.closed,
      title: json['title'] as String,
      description: json['description'] as String,
      position: json['position'] as String,
      minAge: json['min_age'] as int?,
      maxAge: json['max_age'] as int?,
      minLevel: json['min_level'] as String?,
      minSalary: json['min_salary'] as int?,
      maxSalary: json['max_salary'] as int?,
      countryRestriction: json['country_restriction'] as String?,
      addressId: json['address_id'] as String?,
      stats: json['stats'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'id': id,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'sport_id': sportId,
      'recruiter_id': recruiterId,
      'company_name': companyName,
      'status': status.toJson(),
      'title': title,
      'description': description,
      'position': position,
      'min_age': minAge,
      'max_age': maxAge,
      'min_level': minLevel,
      'min_salary': minSalary,
      'max_salary': maxSalary,
      'country_restriction': countryRestriction,
      'address_id': addressId,
      'stats': stats,
    });
    return json;
  }

  CampOpenning copyWith({
    String? sportId,
    String? recruiterId,
    String? companyName,
    OpeningStatus? status,
    String? title,
    String? description,
    String? position,
    int? minAge,
    int? maxAge,
    String? minLevel,
    int? minSalary,
    int? maxSalary,
    String? countryRestriction,
    String? addressId,
    Map<String, dynamic>? stats,
  }) {
    return CampOpenning(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      sportId: sportId ?? this.sportId,
      recruiterId: recruiterId ?? this.recruiterId,
      companyName: companyName ?? this.companyName,
      status: status ?? this.status,
      title: title ?? this.title,
      description: description ?? this.description,
      position: position ?? this.position,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      minLevel: minLevel ?? this.minLevel,
      minSalary: minSalary ?? this.minSalary,
      maxSalary: maxSalary ?? this.maxSalary,
      countryRestriction: countryRestriction ?? this.countryRestriction,
      addressId: addressId ?? this.addressId,
      stats: stats ?? this.stats,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CampOpenning &&
        other.id == id &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.sportId == sportId &&
        other.recruiterId == recruiterId &&
        other.companyName == companyName &&
        other.status == status &&
        other.title == title &&
        other.description == description &&
        other.position == position &&
        other.minAge == minAge &&
        other.maxAge == maxAge &&
        other.minLevel == minLevel &&
        other.minSalary == minSalary &&
        other.maxSalary == maxSalary &&
        other.countryRestriction == countryRestriction &&
        other.addressId == addressId &&
        mapEquals(other.stats, stats);
  }

  @override
  String toString() {
    return 'CampOpenning{id: $id, createdAt: $createdAt, updatedAt: $updatedAt, sportId: $sportId, recruiterId: $recruiterId, companyName: $companyName, status: $status, title: $title, description: $description, position: $position, minAge: $minAge, maxAge: $maxAge, minLevel: $minLevel, minSalary: $minSalary, maxSalary: $maxSalary, countryRestriction: $countryRestriction, addressId: $addressId, stats: $stats}';
  }

  @override
  int get hashCode => Object.hash(
        id,
        createdAt,
        updatedAt,
        sportId,
        recruiterId,
        companyName,
        status,
        title,
        description,
        position,
        minAge,
        maxAge,
        minLevel,
        minSalary,
        maxSalary,
        countryRestriction,
        addressId,
        stats,
      );
}
