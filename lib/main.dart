import 'package:flutter/material.dart';
import 'package:homeconnect/config/routes.dart'; // Import your AppRoutes

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HomeFix App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Define other global themes if needed
      ),
      initialRoute: AppRoutes.splash, // <--- THIS IS THE KEY LINE
      routes: AppRoutes.routes,
    );
  }
}
