import 'package:flutter/material.dart';
// import 'package:myhome/presentation/auth/auth_screen.dart'; // You can remove this import if AuthScreen is no longer used anywhere else
import 'package:homeconnect/presentation/homeowner/pages/homeowner_dashboard_screen.dart';
import 'package:homeconnect/presentation/service_provider/pages/service_provider_dashboard_screen.dart';
import 'package:homeconnect/presentation/auth/login_page.dart';
import 'package:homeconnect/presentation/auth/register_page.dart';
import 'package:homeconnect/presentation/auth/splash_screen.dart';

class AppRoutes {
  static const String splash =
      '/'; // This makes the SplashScreen the app's entry point
  static const String auth =
      '/auth'; // This route can remain, but won't be used for initial navigation
  static const String login =
      '/login'; // This is the direct target after splash
  static const String register = '/register';
  static const String homeownerDashboard = '/homeowner_dashboard';
  static const String serviceProviderDashboard = '/service_provider_dashboard';

  static Map<String, WidgetBuilder> get routes {
    return {
      splash:
          (context) => const SplashScreen(), // Maps '/' to your SplashScreen
      // auth:
      //     (context) =>
      //         const AuthScreen(), // If AuthScreen is truly not needed, you can remove this line and the import
      login: (context) => const LoginPage(), // Maps '/login' to your LoginPage
      register: (context) => const RegisterPage(),
      homeownerDashboard: (context) => const HomeownerDashboardScreen(),
      serviceProviderDashboard:
          (context) => const ServiceProviderDashboardScreen(),
    };
  }
}
