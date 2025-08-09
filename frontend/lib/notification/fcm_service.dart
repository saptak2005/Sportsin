import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:sportsin/services/core/dio_client.dart';
import 'package:sportsin/services/db/db_exceptions.dart';

class FcmService {
  FcmService._();
  static final instance = FcmService._();

  final _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    await _messaging.requestPermission();

    _messaging.onTokenRefresh.listen((newToken) {
      sendTokenToServer();
    }).onError((error) {
      throw Exception("Error listening for token refresh: $error");
    });
  }

  Future<void> sendTokenToServer() async {
    try {
      final String? token = await _messaging.getToken();

      if (token == null) {
        throw Exception("FCM token is null. Cannot send to server.");
      }

      debugPrint("FCM Token retrieved: $token");

      final response = await DioClient.instance.post(
        'register-device-token',
        data: {
          'device_token': token,
          'sns_endpoint': 'fcm',
        },
      );

      if (response.statusCode == 200) {
        debugPrint("FCM token sent to server successfully.");
      } else {
        throw Exception(
          "Failed to send FCM token to server. Status code: ${response.statusCode}",
        );
      }
    } on DioException catch (e) {
      throw DbExceptions.handleDioException(e, 'sending FCM token to server');
    } catch (e) {
      throw Exception("Error sending FCM token to server: $e");
    }
  }
}
