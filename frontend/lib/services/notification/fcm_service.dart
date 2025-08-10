import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:sportsin/services/core/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:sportsin/services/db/db_exceptions.dart';
import 'package:sportsin/services/navigation/navigation_service.dart';
import 'package:sportsin/services/core/secure_storage.dart';

// Top-level function to handle notification taps
void _handleNotificationTap(Map<String, dynamic> data) {
  debugPrint("Notification Tapped. Data payload: $data");
  final String? chatRoomId = data['chat_room_id'];
  final String? tournamentId = data['tournament_id'];
  final String? postId = data['post_id'];
  final String? userId = data['user_id'];
  final String? notificationType = data['type'];

  try {
    if (chatRoomId != null) {
      // Navigate to chat room
      debugPrint("Navigate to chat room: $chatRoomId");
      NavigationService.navigateToChat(chatRoomId);
    } else if (tournamentId != null) {
      // Navigate to tournament
      debugPrint("Navigate to tournament: $tournamentId");
      NavigationService.navigateToTournament(tournamentId);
    } else if (postId != null) {
      // Navigate to post
      debugPrint("Navigate to post: $postId");
      NavigationService.navigateToPost(postId);
    } else if (userId != null) {
      // Navigate to user profile
      debugPrint("Navigate to user profile: $userId");
      NavigationService.navigateToProfile(userId);
    } else {
      // Show generic notification dialog
      final title = data['title'] ?? 'Notification';
      final body = data['body'] ?? 'You have a new notification';
      NavigationService.showNotificationDialog(
        title: title,
        message: body,
      );
    }

    debugPrint("Notification type: $notificationType");
  } catch (e) {
    debugPrint("Error handling notification tap: $e");
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
  _handleNotificationTap(message.data);
}

class FcmService {
  FcmService._();
  static final instance = FcmService._();

  final _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    final permission = await _requestPermissions();
    if (permission != AuthorizationStatus.authorized) {
      debugPrint('Notification permissions not granted');
      return;
    }

    // ⚠️ Note: Token refresh listener removed to prevent automatic token sending
    // Only send tokens after authentication via sendTokenToServer()

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Message received in foreground!');
      debugPrint('Data: ${message.data}');

      if (message.notification != null) {
        debugPrint(
            'Notification: ${message.notification?.title}, ${message.notification?.body}');
        _showForegroundNotification(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification tapped from background.');
      _handleNotificationTap(message.data);
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('Notification tapped from terminated state.');
        _handleNotificationTap(message.data);
      }
    });

    // ⚠️ Note: Initial token is NOT sent to server during init
    // Token should be sent only after user authentication via sendTokenToServer()
    debugPrint(
        "✅ FCM Service initialized. Call sendTokenToServer() after login.");
  }

  Future<AuthorizationStatus> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint(
        'Notification permission status: ${settings.authorizationStatus}');
    return settings.authorizationStatus;
  }

  void _showForegroundNotification(RemoteMessage message) {
    final title = message.notification?.title ?? 'New Notification';
    final body = message.notification?.body ?? 'You have a new notification';

    debugPrint('Showing foreground notification: $title');

    // Show an in-app notification dialog
    NavigationService.showNotificationDialog(
      title: title,
      message: body,
      actionText: 'View',
      onActionPressed: () {
        _handleNotificationTap(message.data);
      },
    );
  }

  Future<void> sendTokenToServer() async {
    try {
      // Check if user is authenticated before sending token
      final authToken = await SecureStorageService.instance.getToken();
      if (authToken == null) {
        debugPrint("❌ User not authenticated. Skipping FCM token upload.");
        return;
      }

      final String? fcmToken = await _messaging.getToken();
      if (fcmToken == null) {
        throw Exception("FCM token is null.");
      }

      debugPrint(
          "📱 Sending FCM Token to server for authenticated user: ${fcmToken.substring(0, 20)}...");

      await DioClient.instance.post(
        '/profile/device-token',
        data: {
          'device_token': fcmToken,
        },
      );

      debugPrint("✅ FCM token sent to server successfully.");
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        debugPrint("❌ User not authenticated. Cannot send FCM token.");
        return;
      }
      throw DbExceptions.handleDioException(e, 'sending FCM token to server');
    } catch (e) {
      debugPrint("❌ Error sending FCM token to server: $e");
    }
  }

  /// Call this method after successful login to register FCM token
  Future<void> onUserLogin() async {
    await sendTokenToServer();

    // Set up token refresh listener for authenticated users
    _messaging.onTokenRefresh.listen((_) => sendTokenToServer());
  }

  /// Call this method when user logs out to clean up FCM token
  Future<void> onUserLogout() async {
    try {
      final String? fcmToken = await _messaging.getToken();
      if (fcmToken == null) {
        debugPrint("⚠️ No FCM token found during logout.");
        return;
      }

      debugPrint("🚮 Removing FCM token from server during logout...");

      await DioClient.instance.delete(
        '/profile/device-token',
        data: {
          'device_token': fcmToken,
        },
      );

      debugPrint("✅ FCM token removed from server successfully.");
    } on DioException catch (e) {
      debugPrint("❌ Error removing FCM token during logout: ${e.message}");
      // Don't throw error during logout to avoid blocking logout flow
    } catch (e) {
      debugPrint("❌ Error removing FCM token during logout: $e");
    }
  }

  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint("Error getting FCM token: $e");
      return null;
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint("Subscribed to topic: $topic");
    } catch (e) {
      debugPrint("Error subscribing to topic $topic: $e");
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint("Unsubscribed from topic: $topic");
    } catch (e) {
      debugPrint("Error unsubscribing from topic $topic: $e");
    }
  }
}
