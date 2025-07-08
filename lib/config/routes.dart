import 'package:flutter/material.dart';
import 'package:homeconnect/presentation/homeowner/pages/homeowner_dashboard_screen.dart';
import 'package:homeconnect/presentation/service_provider/pages/service_provider_dashboard_screen.dart';
import 'package:homeconnect/presentation/auth/login_page.dart';
import 'package:homeconnect/presentation/auth/register_page.dart';
import 'package:homeconnect/presentation/auth/splash_screen.dart';
import 'package:homeconnect/presentation/homeowner/pages/service_provider_list_page.dart';
import 'package:homeconnect/presentation/homeowner/pages/service_provider_detail_page.dart';
import 'package:homeconnect/presentation/service_provider/pages/service_provider_profile.dart'; // Assuming ProfileCreationScreen is here

class AppRoutes {
  static const String splash = '/';
  static const String auth = '/auth';
  static const String login = '/login';
  static const String register = '/register';
  static const String homeownerDashboard = '/homeowner_dashboard';
  static const String serviceProviderDashboard = '/service_provider_dashboard';

  // ✅ New route constants for service provider pages
  static const String serviceProviderListPage = '/providerList';
  static const String serviceProviderDetailPage = '/providerDetail';
  static const String serviceProviderCreateProfile =
      '/service_provider_create_profile';

  static Map<String, WidgetBuilder> get routes {
    return {
      splash: (context) => const SplashScreen(),
      login: (context) => const LoginPage(),
      register: (context) => const RegisterPage(),
      homeownerDashboard: (context) => const HomeownerDashboardScreen(),
      serviceProviderDashboard:
          (context) => const ServiceProviderDashboardScreen(),
      serviceProviderCreateProfile:
          (context) =>
              const ProfileCreationScreen(), // Assuming this is correct
      // Note: No need to add serviceProviderListPage and serviceProviderDetailPage here since they’ll be handled by onGenerateRoute
    };
  }

  // ✅ New onGenerateRoute function to handle dynamic routing with arguments
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case serviceProviderListPage:
        final args = settings.arguments as Map<String, dynamic>;
        final category = args['category'] as String;
        return MaterialPageRoute(
          builder: (_) => ServiceProviderListPage(category: category),
        );

      case serviceProviderDetailPage:
        // Example — you can add arguments handling here if needed later
        return MaterialPageRoute(
          builder: (_) => const ServiceProviderDetailPage(),
        );

      default:
        return null; // If route not found here, fallback to static routes map or show error
    }
  }
}
