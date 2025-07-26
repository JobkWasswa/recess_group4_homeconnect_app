import 'package:flutter/material.dart';
import 'package:homeconnect/config/routes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    debugPrint('🟡 Initializing Firebase with options:');
    debugPrint('  🔹 App ID: ${DefaultFirebaseOptions.currentPlatform.appId}');
    debugPrint(
      '  🔹 Project ID: ${DefaultFirebaseOptions.currentPlatform.projectId}',
    );
    debugPrint(
      '  🔹 API Key: ${DefaultFirebaseOptions.currentPlatform.apiKey}',
    );

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint('✅ Firebase initialized successfully!');
  } catch (e, stackTrace) {
    debugPrint('❌ Firebase initialization failed!');
    debugPrint('🔴 Error: $e');
    debugPrint('📄 Stacktrace:\n$stackTrace');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HomeFix App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
