import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sportsin/firebase_options.dart';
import 'package:sportsin/services/notification/fcm_service.dart';
import 'config/routes/router_config.dart';
import 'config/theme/theme.dart';
import 'services/auth/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FcmService.instance.init();

  await AuthService.refreshAuthState();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SportsIN',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
    );
  }
}
