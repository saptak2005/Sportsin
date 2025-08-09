import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:sportsin/config/constants/api_constants.dart';
import 'package:sportsin/models/models.dart';
import 'package:sportsin/services/core/dio_client.dart';
import 'package:sportsin/services/core/secure_storage.dart';
import 'package:sportsin/services/db/db_exceptions.dart';
import 'package:web_socket_channel/io.dart';

class ChatRepository {
  static ChatRepository? _instance;

  ChatRepository._();

  static ChatRepository get instance {
    _instance ??= ChatRepository._();
    return _instance!;
  }

  factory ChatRepository() => instance;

  IOWebSocketChannel? _channel;
  StreamController<ChatMessage>? _messageController;

  Future<void> connectToChat() async {
    if (_channel != null && _channel?.closeCode == null) {
      return;
    }
    final token = await SecureStorageService.instance.getToken();
    if (token == null) {
      throw DbAuthenticationException(
        message: 'User not authenticated',
        details: 'Authentication token is missing',
      );
    }
    try {
      final url = '${ApiConstants.webSocketBaseUrl}ws/chat';
      final headers = {'Authorization': 'Bearer $token'};

      _channel = IOWebSocketChannel.connect(Uri.parse(url), headers: headers);
      _messageController = StreamController<ChatMessage>.broadcast();

      _channel!.stream.listen(
        (data) {
          final message = ChatMessage.fromJson(jsonDecode(data));
          _messageController?.add(message);
        },
        onError: (error) {
          _messageController?.addError(error);
          disconnectFromChat();
        },
        onDone: () {
          _messageController?.close();
        },
      );
    } catch (e) {
      await disconnectFromChat();
      throw WebSocketConnectionException(
        message: 'Failed to connect to chat',
        details: e.toString(),
      );
    }
  }

  Future<void> disconnectFromChat() async {
    await _channel?.sink.close();
    await _messageController?.close();
    _channel = null;
    _messageController = null;
  }

  Future<List<ChatRoom>> getChatRooms() async {
    try {
      final response = await DioClient.instance.get('chat/rooms');
      if (response.statusCode == 200) {
        final data = response.data;

        if (data == null) {
          return [];
        }

        if (data.isEmpty) {
          return [];
        }

        return (data as List)
            .map((roomJson) =>
                ChatRoom.fromJson(roomJson as Map<String, dynamic>))
            .toList();
      } else {
        throw DbExceptions(
          message: 'Failed to fetch chat rooms',
          details: 'Unexpected response status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw DbExceptions.handleDioException(e, 'Fetching chat rooms');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbNotFoundException(
        message: 'An unexpected error occurred while fetching chat rooms',
        details: 'Error: $e',
      );
    }
  }

  Future<List<ChatMessage>> getMessagesForRoom(String roomId,
      {int? limit, int? offset}) async {
    if (roomId.isEmpty) {
      throw const DbInvalidInputException(
        message: 'Room ID cannot be empty',
        details: 'A valid room ID is required to fetch messages.',
      );
    }

    try {
      final queryParams = {
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
      };

      final response = await DioClient.instance
          .get('chat/rooms/$roomId/messages', queryParameters: queryParams);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((message) => ChatMessage.fromJson(message)).toList();
      } else {
        throw DbExceptions(
          message: 'Failed to fetch messages for room $roomId',
          details: 'Unexpected response status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw DbExceptions.handleDioException(
          e, 'Fetching messages for room $roomId');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbNotFoundException(
        message:
            'An unexpected error occurred while fetching messages for room $roomId',
        details: 'Error: $e',
      );
    }
  }

  Future<void> markRoomAsRead(String roomId) async {
    try {
      await DioClient.instance.post('chat/rooms/$roomId/read');
    } on DioException catch (e) {
      throw DbExceptions.handleDioException(e, 'Marking room $roomId as read');
    } on DbExceptions {
      rethrow;
    } catch (e) {
      throw DbNotFoundException(
        message:
            'An unexpected error occurred while marking room $roomId as read',
        details: 'Error: $e',
      );
    }
  }

  Stream<ChatMessage> get messagesStream {
    if (_messageController == null) {
      throw WebSocketConnectionException(
        message: 'Not connected to chat',
      );
    }
    return _messageController!.stream;
  }

  Future<void> sendMessage({
    required String recipientId,
    required String content,
  }) async {
    if (_channel == null || _channel?.closeCode != null) {
      throw WebSocketConnectionException(
        message: 'Not connected to chat',
      );
    }

    final payload = {
      'recipient_id': recipientId,
      'content': content,
    };

    try {
      _channel!.sink.add(jsonEncode(payload));
    } catch (e) {
      throw WebSocketConnectionException(
        message: 'Failed to send message',
        details: 'The connection is closed or in a bad state: ${e.toString()}',
      );
    }
  }
}
