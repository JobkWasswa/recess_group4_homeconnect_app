import 'package:flutter/material.dart';

import 'package:homeconnect/config/routes.dart'; // Import your AppRoutes
import 'package:firebase_core/firebase_core.dart'; // Firebase core
import 'package:firebase_analytics/firebase_analytics.dart'; // Firebase Analytics (optional)
import 'firebase_options.dart'; // <-- Import generated Firebase options

void main() async {
  // Ensure proper binding initialization
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with error handling
  try {
    // 🔍 Print the Firebase options in use
    print('Using Firebase options:');
    print('App ID: ${DefaultFirebaseOptions.currentPlatform.appId}');
    print('Project ID: ${DefaultFirebaseOptions.currentPlatform.projectId}');
    print('API Key: ${DefaultFirebaseOptions.currentPlatform.apiKey}');
    print('Project ID: ${DefaultFirebaseOptions.currentPlatform.projectId}');

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e, stack) {
    print('Firebase initialization failed: $e');
    print(stack);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Optional: Create a FirebaseAnalytics instance if you want to use Analytics
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HomeFix App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Add visual scaffold to prevent black screen
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: AppRoutes.splash, // Your app’s initial route
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
