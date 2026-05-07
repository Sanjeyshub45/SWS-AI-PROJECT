import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'core/services/fcm_service.dart';
import 'widgets/app_shell.dart';

// Background FCM handler — must be top-level
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Background FCM: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    const ProviderScope(
      child: SWSDocApp(),
    ),
  );
}

class SWSDocApp extends StatefulWidget {
  const SWSDocApp({super.key});

  @override
  State<SWSDocApp> createState() => _SWSDocAppState();
}

class _SWSDocAppState extends State<SWSDocApp> {
  @override
  void initState() {
    super.initState();
    FCMService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SWS AI Docs',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E6BFF),
          brightness: Brightness.light,
        ),
        fontFamily: 'Livvic',
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1A1A2E),
          elevation: 0,
          shadowColor: Color(0x1A000000),
        ),
        navigationBarTheme: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontFamily: 'Livvic',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E6BFF),
              );
            }
            return const TextStyle(
              fontFamily: 'Livvic',
              fontSize: 12,
              color: Color(0xFF9E9E9E),
            );
          }),
        ),
      ),
      home: const AppShell(),
    );
  }
}
