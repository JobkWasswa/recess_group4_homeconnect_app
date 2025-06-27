import 'package:flutter/material.dart';
import 'package:homeconnect/config/routes.dart'; // Import your AppRoutes
import 'package:firebase_core/firebase_core.dart'; // Firebase core
import 'package:firebase_analytics/firebase_analytics.dart'; // Firebase Analytics (optional)
import 'firebase_options.dart'; // <-- Import generated Firebase options
import 'package:homeconnect/presentation/service_provider/pages/service_provider_profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Use the generated config
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // Optional: Create a FirebaseAnalytics instance if you want to use Analytics
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HomeFix App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ProfileCreationScreen(), // 👈 shows only the profile screen
    );
  }
}
