import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static BuildContext? get context => navigatorKey.currentContext;

  static void navigateToChat(String chatRoomId) {
    if (context != null) {
      context!.push('/chat/$chatRoomId');
    }
  }

  static void navigateToTournament(String tournamentId) {
    if (context != null) {
      context!.push('/tournament/$tournamentId');
    }
  }

  static void navigateToPost(String postId) {
    if (context != null) {
      context!.push('/post/$postId');
    }
  }

  static void navigateToProfile(String userId) {
    if (context != null) {
      context!.push('/profile/$userId');
    }
  }

  static void showNotificationDialog({
    required String title,
    required String message,
    String? actionText,
    VoidCallback? onActionPressed,
  }) {
    if (context != null) {
      showDialog(
        context: context!,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Colors.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
            title: Text(
              title,
              style: const TextStyle(color: Colors.white),
            ),
            content: Text(
              message,
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Dismiss',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              if (actionText != null && onActionPressed != null)
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onActionPressed();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A66C2),
                  ),
                  child: Text(actionText),
                ),
            ],
          );
        },
      );
    }
  }
}
