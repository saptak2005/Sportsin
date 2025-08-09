import 'app_model.dart';
import 'post_image.dart';

class Post extends AppModel {
  final String userId;
  final String content;
  final List<String> tags;
  final List<PostImage> images;
  final int likeCount;
  final int commentCount;
  final bool isLiked;

  Post({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.userId,
    required this.content,
    required this.tags,
    this.likeCount = 0,
    this.commentCount = 0,
    this.images = const [],
    this.isLiked = false,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    List<String> tags = [];
    if (json['tags'] is List) {
      tags = (json['tags'] as List).map((e) => e.toString()).toList();
    }

    return Post(
      id: json['id'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      userId: json['user_id'] as String,
      likeCount: json['like_count'] as int? ?? 0,
      commentCount: json['total_comments'] as int? ?? 0,
      content: json['content'] as String,
      tags: tags,
      images: json['images'] != null
          ? List<PostImage>.from(
              (json['images'] as List).map((x) => PostImage.fromJson(x)))
          : [],
      isLiked: json['user_liked'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'user_id': userId,
      'content': content,
      'tags': tags,
      'like_count': likeCount,
      'total_comments': commentCount,
      'user_liked': isLiked,
      'images': images.map((x) => x.toJson()).toList(),
    });
    return json;
  }

  Post copyWith({
    String? id,
    String? createdAt,
    String? updatedAt,
    String? userId,
    int? commentCount,
    String? content,
    List<String>? tags,
    List<PostImage>? images,
    int? likeCount,
    bool? isLiked,
  }) {
    return Post(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      commentCount: commentCount ?? this.commentCount,
      tags: tags ?? this.tags,
      isLiked: isLiked ?? this.isLiked,
      likeCount: likeCount ?? this.likeCount,
      images: images ?? this.images,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Post &&
        super == other &&
        other.userId == userId &&
        other.content == content &&
        other.tags.length == tags.length &&
        other.tags.every((tag) => tags.contains(tag)) &&
        other.images.length == images.length &&
        other.images.every((image) => images.contains(image)) &&
        other.likeCount == likeCount &&
        other.commentCount == commentCount &&
        other.isLiked == isLiked;
  }

  @override
  int get hashCode {
    return Object.hash(
      super.hashCode,
      userId,
      content,
      Object.hashAll(tags),
      Object.hashAll(images),
    );
  }

  @override
  String toString() {
    return 'Post(id: $id, userId: $userId, content: ${content.length > 50 ? '${content.substring(0, 50)}...' : content})';
  }
}
