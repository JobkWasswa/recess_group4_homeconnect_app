import 'package:flutter/material.dart';
import 'package:homeconnect/config/routes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('🟡 Initializing Firebase with options:');
    print('  🔹 App ID: ${DefaultFirebaseOptions.currentPlatform.appId}');
    print(
      '  🔹 Project ID: ${DefaultFirebaseOptions.currentPlatform.projectId}',
    );
    print('  🔹 API Key: ${DefaultFirebaseOptions.currentPlatform.apiKey}');

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    print('✅ Firebase initialized successfully!');
  } catch (e, stackTrace) {
    print('❌ Firebase initialization failed!');
    print('🔴 Error: $e');
    print('📄 Stacktrace:\n$stackTrace');
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
