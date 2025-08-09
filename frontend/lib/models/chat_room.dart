import 'app_model.dart';

class ChatRoom extends AppModel {
  final String user1;
  final String user2;
  final LastMessage? lastMessage;

  ChatRoom({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.user1,
    required this.user2,
    this.lastMessage,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    final lastMessageData = json['last_message_at'];
    return ChatRoom(
      id: json['id'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      user1: json['user_1'] as String,
      user2: json['user_2'] as String,
      lastMessage: lastMessageData != null
          ? LastMessage.fromJson(lastMessageData)
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'user_1': user1,
      'user_2': user2,
      'last_message_at': lastMessage?.toJson(),
    });
    return json;
  }

  ChatRoom copyWith({
    String? id,
    String? createdAt,
    String? updatedAt,
    String? user1,
    String? user2,
    LastMessage? lastMessage,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      user1: user1 ?? this.user1,
      user2: user2 ?? this.user2,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatRoom &&
        super == other &&
        other.user1 == user1 &&
        other.user2 == user2 &&
        other.lastMessage == lastMessage;
  }

  @override
  int get hashCode {
    return Object.hash(
      super.hashCode,
      user1,
      user2,
      lastMessage,
    );
  }

  @override
  String toString() {
    return 'ChatRoom(id: $id, user1: $user1, user2: $user2)';
  }
}

class LastMessage {
  final String timestamp;

  LastMessage({required this.timestamp});

  factory LastMessage.fromJson(Map<String, dynamic> json) {
    return LastMessage(
      timestamp: json['0'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '0': timestamp,
    };
  }
}
