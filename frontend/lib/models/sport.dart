import 'app_model.dart';

class Sport extends AppModel {
  final String name;
  final String description;

  Sport({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.name,
    required this.description,
  });

  factory Sport.fromJson(Map<String, dynamic> json) {
    return Sport(
      id: json['id'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'name': name,
      'description': description,
    });
    return json;
  }

  Sport copyWith({
    String? id,
    String? createdAt,
    String? updatedAt,
    String? name,
    String? description,
  }) {
    return Sport(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Sport &&
        super == other &&
        other.name == name &&
        other.description == description;
  }

  @override
  int get hashCode {
    return Object.hash(
      super.hashCode,
      name,
      description,
    );
  }

  @override
  String toString() {
    return 'Sport(id: $id, name: $name, description: $description)';
  }
}
