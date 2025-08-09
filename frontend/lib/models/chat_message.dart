import 'app_model.dart';

class ChatMessage extends AppModel {
  final String chatRoomId;
  final String senderId;
  final bool read;
  final String message;

  ChatMessage({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.chatRoomId,
    required this.senderId,
    required this.read,
    required this.message,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
      chatRoomId: json['chat_room_id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      read: json['read'] as bool? ?? false,
      message: json['content'] as String? ?? json['message'] as String? ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'chat_room_id': chatRoomId,
      'sender_id': senderId,
      'read': read,
      'message': message,
    });
    return json;
  }

  ChatMessage copyWith({
    String? id,
    String? createdAt,
    String? updatedAt,
    String? chatRoomId,
    String? senderId,
    bool? read,
    String? message,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      senderId: senderId ?? this.senderId,
      read: read ?? this.read,
      message: message ?? this.message,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage &&
        super == other &&
        other.chatRoomId == chatRoomId &&
        other.senderId == senderId &&
        other.read == read &&
        other.message == message;
  }

  @override
  int get hashCode {
    return Object.hash(
      super.hashCode,
      chatRoomId,
      senderId,
      read,
      message,
    );
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, chatRoomId: $chatRoomId, senderId: $senderId, read: $read)';
  }
}
