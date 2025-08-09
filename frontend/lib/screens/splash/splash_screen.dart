import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sportsin/config/routes/route_names.dart';
import 'package:sportsin/services/auth/auth_service.dart';
import 'package:sportsin/services/db/db_provider.dart';
import 'package:sportsin/services/notification/fcm_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      await AuthService.refreshAuthState();

      final currentUser = AuthService.customProvider().getCurrentUser;
      debugPrint(
          '🔍 SplashScreen: Current user after refresh: ${currentUser?.email}, Role: ${currentUser?.role.value}');

      if (currentUser == null) {
        if (mounted) {
          context.go(RouteNames.loginPath);
        }
        return;
      }

      if (!currentUser.isEmailVerified) {
        if (mounted) {
          context.go(
              '${RouteNames.emailVerificationPath}?email=${currentUser.email}');
        }
        return;
      }

      await _checkProfileCompletion(currentUser.id);
    } catch (e) {
      if (mounted) {
        context.go(RouteNames.loginPath);
      }
    }
  }

  Future<void> _checkProfileCompletion(String userId) async {
    try {
      await DbProvider.instance.init();

      final user = DbProvider.instance.user;

      if (!mounted) return;

      if (user == null) {
        context.go(RouteNames.profileCompletePath);
      } else {
        try {
          await FcmService.instance.sendTokenToServer();
        } catch (e) {
          debugPrint('Failed to send FCM token to server: $e');
        }

        if (mounted) {
          context.go(RouteNames.homePath);
        }
      }
    } catch (e) {
      if (mounted) {
        context.go(RouteNames.profileCompletePath);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.sports,
                size: 60,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 30),

            // App Name
            Text(
              'SportsIN',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
            ),
            const SizedBox(height: 10),

            const CircularProgressIndicator(),
            const SizedBox(height: 20),

            Text(
              'Initializing...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
