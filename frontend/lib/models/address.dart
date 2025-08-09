import 'app_model.dart';

class Address extends AppModel {
  final String userId;
  final String country;
  final String state;
  final String city;
  final String street;
  final String building;
  final String postalCode;

  Address({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.userId,
    required this.country,
    required this.state,
    required this.city,
    required this.street,
    required this.building,
    required this.postalCode,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      userId: json['user_id'] as String,
      country: json['country'] as String,
      state: json['state'] as String,
      city: json['city'] as String,
      street: json['street'] as String,
      building: json['building'] as String,
      postalCode: json['postal_code'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'user_id': userId,
      'country': country,
      'state': state,
      'city': city,
      'street': street,
      'building': building,
      'postal_code': postalCode,
    });
    return json;
  }

  Address copyWith({
    String? id,
    String? createdAt,
    String? updatedAt,
    String? userId,
    String? country,
    String? state,
    String? city,
    String? street,
    String? building,
    String? postalCode,
  }) {
    return Address(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      street: street ?? this.street,
      building: building ?? this.building,
      postalCode: postalCode ?? this.postalCode,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Address &&
        super == other &&
        other.userId == userId &&
        other.country == country &&
        other.state == state &&
        other.city == city &&
        other.street == street &&
        other.building == building &&
        other.postalCode == postalCode;
  }

  @override
  int get hashCode {
    return Object.hash(
      super.hashCode,
      userId,
      country,
      state,
      city,
      street,
      building,
      postalCode,
    );
  }

  @override
  String toString() {
    return 'Address(id: $id, userId: $userId, country: $country, city: $city)';
  }
}
