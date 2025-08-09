import 'app_model.dart';
import 'package:flutter/foundation.dart';

@immutable
class Comment extends AppModel {
  final String userId;
  final String postId;
  final String? parentCommentId;
  final String content;

  Comment({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.userId,
    required this.postId,
    required this.content,
    this.parentCommentId,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      userId: json['user_id'] as String,
      postId: json['post_id'] as String,
      content: json['content'] as String,
      parentCommentId: json['parent_id'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'user_id': userId,
      'post_id': postId,
      'content': content,
      'parent_id': parentCommentId,
    });
    json.removeWhere((key, value) => key == 'parent_id' && value == null);
    return json;
  }

  Comment copyWith({
    String? id,
    String? createdAt,
    String? updatedAt,
    String? userId,
    String? postId,
    String? content,
    String? parentCommentId,
  }) {
    return Comment(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      postId: postId ?? this.postId,
      content: content ?? this.content,
      parentCommentId: parentCommentId ?? this.parentCommentId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Comment &&
        super == other &&
        other.userId == userId &&
        other.postId == postId &&
        other.parentCommentId == parentCommentId &&
        other.content == content;
  }

  @override
  int get hashCode => Object.hash(
        super.hashCode,
        userId,
        postId,
        parentCommentId,
        content,
      );

  @override
  String toString() {
    return 'Comment(id: $id, userId: $userId, postId: $postId, parentId: $parentCommentId)';
  }
}

@immutable
class CommentResponse {
  final Comment comment;
  final List<Comment> replies;
  final int replyCount;
  final int totalReplyCount;

  const CommentResponse({
    required this.comment,
    required this.replies,
    required this.replyCount,
    required this.totalReplyCount,
  });

  factory CommentResponse.fromJson(Map<String, dynamic> json) {
    return CommentResponse(
      comment: Comment.fromJson(json['comment'] as Map<String, dynamic>),
      replies: (json['replies'] as List<dynamic>?)
              ?.map((e) => Comment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      replyCount: json['reply_count'] as int,
      totalReplyCount: json['total_reply_count'] as int,
    );
  }
}
