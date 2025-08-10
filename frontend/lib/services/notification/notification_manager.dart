import 'package:sportsin/services/notification/fcm_service.dart';
import 'package:sportsin/services/navigation/navigation_service.dart';
import 'package:sportsin/models/enums.dart';
import 'package:flutter/material.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._();
  static NotificationManager get instance => _instance;
  NotificationManager._();

  // Initialize notification services
  Future<void> initialize() async {
    await FcmService.instance.init();
    debugPrint('Notification Manager initialized');
  }

  // Subscribe to tournament-related topics
  Future<void> subscribeTournamentNotifications({
    required String userId,
    List<String>? sportIds,
    String? region,
  }) async {
    // Subscribe to user-specific notifications
    await FcmService.instance.subscribeToTopic('user_$userId');

    // Subscribe to sport-specific notifications
    if (sportIds != null) {
      for (String sportId in sportIds) {
        await FcmService.instance.subscribeToTopic('sport_$sportId');
      }
    }

    // Subscribe to region-specific notifications
    if (region != null) {
      await FcmService.instance.subscribeToTopic('region_$region');
    }

    // Subscribe to general tournament notifications
    await FcmService.instance.subscribeToTopic('tournaments');

    debugPrint('Subscribed to tournament notifications for user: $userId');
  }

  // Unsubscribe from tournament notifications
  Future<void> unsubscribeTournamentNotifications({
    required String userId,
    List<String>? sportIds,
    String? region,
  }) async {
    await FcmService.instance.unsubscribeFromTopic('user_$userId');

    if (sportIds != null) {
      for (String sportId in sportIds) {
        await FcmService.instance.unsubscribeFromTopic('sport_$sportId');
      }
    }

    if (region != null) {
      await FcmService.instance.unsubscribeFromTopic('region_$region');
    }

    await FcmService.instance.unsubscribeFromTopic('tournaments');

    debugPrint('Unsubscribed from tournament notifications for user: $userId');
  }

  // Subscribe to specific tournament updates
  Future<void> subscribeToTournament(String tournamentId) async {
    await FcmService.instance.subscribeToTopic('tournament_$tournamentId');
    debugPrint('Subscribed to tournament: $tournamentId');
  }

  // Unsubscribe from specific tournament
  Future<void> unsubscribeFromTournament(String tournamentId) async {
    await FcmService.instance.unsubscribeFromTopic('tournament_$tournamentId');
    debugPrint('Unsubscribed from tournament: $tournamentId');
  }

  // Subscribe to chat notifications
  Future<void> subscribeToChatNotifications(String userId) async {
    await FcmService.instance.subscribeToTopic('chat_$userId');
    debugPrint('Subscribed to chat notifications for user: $userId');
  }

  // Unsubscribe from chat notifications
  Future<void> unsubscribeFromChatNotifications(String userId) async {
    await FcmService.instance.unsubscribeFromTopic('chat_$userId');
    debugPrint('Unsubscribed from chat notifications for user: $userId');
  }

  // Show tournament status update notification
  void showTournamentStatusNotification({
    required String tournamentTitle,
    required TournamentStatus newStatus,
    required String tournamentId,
  }) {
    String title = 'Tournament Status Update';
    String message =
        'Tournament "$tournamentTitle" status changed to ${newStatus.name.toUpperCase()}';

    NavigationService.showNotificationDialog(
      title: title,
      message: message,
      actionText: 'View Tournament',
      onActionPressed: () {
        NavigationService.navigateToTournament(tournamentId);
      },
    );
  }

  // Show participation status update notification
  void showParticipationStatusNotification({
    required String tournamentTitle,
    required ParticipationStatus newStatus,
    required String tournamentId,
  }) {
    String title = 'Participation Update';
    String message;

    switch (newStatus) {
      case ParticipationStatus.accepted:
        message =
            'Congratulations! You have been accepted to "$tournamentTitle"';
        break;
      case ParticipationStatus.rejected:
        message = 'Your application to "$tournamentTitle" has been declined';
        break;
      case ParticipationStatus.pending:
        message = 'Your application to "$tournamentTitle" is under review';
        break;
    }

    NavigationService.showNotificationDialog(
      title: title,
      message: message,
      actionText: 'View Tournament',
      onActionPressed: () {
        NavigationService.navigateToTournament(tournamentId);
      },
    );
  }

  // Show new tournament notification
  void showNewTournamentNotification({
    required String tournamentTitle,
    required String sportName,
    required String tournamentId,
  }) {
    NavigationService.showNotificationDialog(
      title: 'New Tournament Available',
      message:
          'A new $sportName tournament "$tournamentTitle" is now open for registration!',
      actionText: 'View Details',
      onActionPressed: () {
        NavigationService.navigateToTournament(tournamentId);
      },
    );
  }

  // Show chat message notification
  void showChatMessageNotification({
    required String senderName,
    required String message,
    required String chatRoomId,
  }) {
    NavigationService.showNotificationDialog(
      title: 'New Message from $senderName',
      message: message,
      actionText: 'Reply',
      onActionPressed: () {
        NavigationService.navigateToChat(chatRoomId);
      },
    );
  }

  // Get current FCM token
  Future<String?> getCurrentToken() async {
    return await FcmService.instance.getToken();
  }

  // Send token to server
  Future<void> updateTokenOnServer() async {
    await FcmService.instance.sendTokenToServer();
  }
}
