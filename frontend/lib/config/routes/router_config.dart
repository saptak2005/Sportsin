import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sportsin/models/post.dart';
import 'package:sportsin/screens/complete_update_profile/complete_or_update_profile_screen.dart';
import 'package:sportsin/screens/home/home_screen.dart';
import 'package:sportsin/screens/posts/post_creation_update_screen.dart';
import 'package:sportsin/screens/posts/tournament_creation_screen.dart';
import 'package:sportsin/screens/posts/opening_creation_screen.dart';
import 'package:sportsin/screens/profile/player_details.dart';
import 'package:sportsin/screens/profile/recruiter_details.dart';
import 'package:sportsin/screens/splash/splash_screen.dart';
import 'package:sportsin/screens/achievements/achievement_creation_screen.dart';
import 'package:sportsin/services/db/db_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/auth/email_verification_screen.dart';
import '../../screens/auth/password_reset_screen.dart';
import '../../screens/chat/chat_screen.dart';
import '../../services/auth/auth_service.dart';
import 'route_names.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

class AppRouter {
  static GoRouter get router => _router;

  static final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: AuthService.authStateNotifier,
    routes: [
      // Eta holo initial route
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      GoRoute(
        path: RouteNames.loginPath,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.registerPath,
        name: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteNames.forgotPasswordPath,
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
          path: RouteNames.profileCompletePath,
          name: RouteNames.profileComplete,
          builder: (context, state) {
            final authUser = AuthService.customProvider().getCurrentUser!;
            final dbModel = DbProvider.instance;
            return CompleteOrUpdateProfileScreen(
              authUser: authUser,
              dbModel: dbModel,
            );
          }),
      GoRoute(
          path: RouteNames.playerDetailsPath,
          name: RouteNames.playerDetails,
          builder: (context, state) {
            return const PlayerDetailsScreen();
          }),
      GoRoute(
          path: RouteNames.recruiterDetailsPath,
          name: RouteNames.recruiterDetails,
          builder: (context, state) {
            return const RecruiterDetailsScreen();
          }),
      GoRoute(
          path: RouteNames.editProfilePath,
          name: RouteNames.editProfile,
          builder: (context, state) {
            final authUser = AuthService.customProvider().getCurrentUser!;
            final dbModel = DbProvider.instance;
            return CompleteOrUpdateProfileScreen(
              authUser: authUser,
              dbModel: dbModel,
              isEditMode: true,
            );
          }),
      GoRoute(
        path: RouteNames.emailVerificationPath,
        name: RouteNames.emailVerification,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return EmailVerificationScreen(email: email);
        },
      ),
      GoRoute(
        path: RouteNames.passwordResetPath,
        name: RouteNames.passwordReset,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return PasswordResetScreen(email: email);
        },
      ),

      // Main App Routes (Shell Route for bottom navigation)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return Scaffold(
            body: child,
          );
        },
        routes: [
          GoRoute(
            path: RouteNames.homePath,
            name: RouteNames.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: RouteNames.chatScreenPath,
            name: RouteNames.chatScreen,
            builder: (context, state) {
              return const ChatScreen();
            },
          ),
          GoRoute(
            path: RouteNames.postCreationPath,
            name: RouteNames.postCreation,
            builder: (context, state) {
              final existingPost = state.extra as Post?;
              return PostCreationAndUpdateScreen(existingPost: existingPost);
            },
          ),
          GoRoute(
            path: RouteNames.achievementCreationPath,
            name: RouteNames.achievementCreation,
            builder: (context, state) {
              final achievementId = state.uri.queryParameters['achievementId'];
              return AchievementCreationScreen(achievementId: achievementId);
            },
          ),
          GoRoute(
            path: RouteNames.tournamentPath,
            name: RouteNames.tournament,
            builder: (context, state) => const TournamentCreationScreen(),
          ),
          GoRoute(
            path: RouteNames.jobCreationPath,
            name: RouteNames.jobCreation,
            builder: (context, state) => const OpeningCreationScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
    redirect: (BuildContext context, GoRouterState state) {
      final currentUser = AuthService.customProvider().getCurrentUser;
      final currentLocation = state.matchedLocation;

      final isOnAuthPage = currentLocation == RouteNames.loginPath ||
          currentLocation == RouteNames.registerPath ||
          currentLocation == RouteNames.forgotPasswordPath ||
          currentLocation.startsWith(RouteNames.emailVerificationPath) ||
          currentLocation.startsWith(RouteNames.passwordResetPath);

      final isOnSplashPage = currentLocation == '/';

      if (currentUser == null && !isOnAuthPage && !isOnSplashPage) {
        return RouteNames.loginPath;
      }

      if (currentUser != null &&
          !currentUser.isEmailVerified &&
          !currentLocation.startsWith(RouteNames.emailVerificationPath) &&
          !isOnSplashPage) {
        return '${RouteNames.emailVerificationPath}?email=${currentUser.email}';
      }

      if (currentUser != null &&
          currentUser.isEmailVerified &&
          currentLocation.startsWith(RouteNames.emailVerificationPath)) {
        return RouteNames.loginPath;
      }

      if (currentUser != null &&
          currentUser.isEmailVerified &&
          isOnAuthPage &&
          !currentLocation.startsWith(RouteNames.emailVerificationPath)) {
        return '/';
      }

      return null;
    },
  );
}
