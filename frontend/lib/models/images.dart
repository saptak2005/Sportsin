import 'app_model.dart';

class Images extends AppModel {
  final String linkId;
  final String imageUrl;

  Images({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.linkId,
    required this.imageUrl,
  });

  factory Images.fromJson(Map<String, dynamic> json) {
    return Images(
      id: json['id'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      linkId: json['link_id'] as String,
      imageUrl: json['image_url'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'link_id': linkId,
      'image_url': imageUrl,
    });
    return json;
  }

  Images copyWith({
    String? id,
    String? createdAt,
    String? updatedAt,
    String? linkId,
    String? imageUrl,
  }) {
    return Images(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      linkId: linkId ?? this.linkId,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Images &&
        super == other &&
        other.linkId == linkId &&
        other.imageUrl == imageUrl;
  }

  @override
  int get hashCode {
    return Object.hash(
      super.hashCode,
      linkId,
      imageUrl,
    );
  }

  @override
  String toString() {
    return 'Images(id: $id, linkId: $linkId, imageUrl: $imageUrl)';
  }
}
