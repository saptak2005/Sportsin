import 'app_model.dart';

class PostImage extends AppModel {
  final String postId;
  final String imageUrl;

  PostImage({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.postId,
    required this.imageUrl,
  });

  factory PostImage.fromJson(Map<String, dynamic> json) {
    return PostImage(
      id: json['id'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      postId: json['post_id'] as String,
      imageUrl: json['image_url'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'post_id': postId,
      'image_url': imageUrl,
    });
    return json;
  }

  PostImage copyWith({
    String? id,
    String? createdAt,
    String? updatedAt,
    String? postId,
    String? imageUrl,
  }) {
    return PostImage(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      postId: postId ?? this.postId,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostImage &&
        super == other &&
        other.postId == postId &&
        other.imageUrl == imageUrl;
  }

  @override
  int get hashCode {
    return Object.hash(
      super.hashCode,
      postId,
      imageUrl,
    );
  }

  @override
  String toString() {
    return 'PostImage(id: $id, postId: $postId, imageUrl: $imageUrl)';
  }
}
