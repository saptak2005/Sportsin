import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sportsin/config/routes/route_names.dart';
import 'package:sportsin/config/theme/app_colors.dart';
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
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Container
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/variant_1.jpg',
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // App Name
            Text(
              'SportsIN',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.linkedInBlue,
                    letterSpacing: 1.2,
                  ),
            ),
            const SizedBox(height: 8),

            Text(
              'Recruit • Showcase • Excel',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.linkedInBlue),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Loading your sports world...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.darkSecondary,
                    fontWeight: FontWeight.w400,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
