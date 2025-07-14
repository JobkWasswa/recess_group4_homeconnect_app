import 'package:flutter/material.dart';
import 'package:homeconnect/presentation/homeowner/pages/homeowner_dashboard_screen.dart';
import 'package:homeconnect/presentation/service_provider/pages/service_provider_dashboard_screen.dart';
import 'package:homeconnect/presentation/auth/login_page.dart';
import 'package:homeconnect/presentation/auth/register_page.dart';
import 'package:homeconnect/presentation/auth/splash_screen.dart';
import 'package:homeconnect/presentation/homeowner/pages/service_provider_list_page.dart';
import 'package:homeconnect/presentation/homeowner/pages/service_provider_detail_page.dart';
import 'package:homeconnect/presentation/service_provider/pages/service_provider_profile.dart'; // Assuming ProfileCreationScreen is here
import 'package:homeconnect/presentation/service_provider/pages/provider_maps_screen.dart'; // Import the new screen

class AppRoutes {
  static const String splash = '/';
  static const String auth = '/auth'; // This is the route name
  static const String login = '/login';
  static const String register = '/register';
  static const String homeownerDashboard = '/homeowner_dashboard';
  static const String serviceProviderDashboard = '/service_provider_dashboard';
  static const String providerMaps = '/provider_maps'; // <--- ADDED THIS ROUTE

  // ✅ New route constants for service provider pages
  static const String serviceProviderListPage = '/providerList';
  static const String serviceProviderDetailPage = '/providerDetail';
  static const String serviceProviderCreateProfile =
      '/service_provider_create_profile';

  static Map<String, WidgetBuilder> get routes {
    return {
      splash: (context) => const SplashScreen(),
      // ★ ADD THIS LINE ★
      auth:
          (context) =>
              const LoginPage(), // When /auth is called, show LoginPage
      login: (context) => const LoginPage(),
      register: (context) => const RegisterPage(),
      homeownerDashboard: (context) => const HomeownerDashboardScreen(),
      serviceProviderDashboard:
          (context) => const ServiceProviderDashboardScreen(),
      serviceProviderCreateProfile:
          (context) =>
              const ProfileCreationScreen(), // Assuming this is correct
      providerMaps:
          (context) =>
              const ProviderMapsScreen(), // <--- ADDED THE WIDGET BUILDER
      // Note: No need to add serviceProviderListPage and serviceProviderDetailPage here since they’ll be handled by onGenerateRoute
    };
  }

  // ✅ New onGenerateRoute function to handle dynamic routing with arguments
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case serviceProviderListPage:
        final args = settings.arguments as Map<String, dynamic>;
        // Assuming userLocation is passed as a GeoPoint, but ServiceProviderListPage expects it as GeoPoint
        // You might need to cast or convert args['location'] to GeoPoint if it's coming from outside this route definition
        // For now, let's assume 'category' is the primary argument based on your previous code
        final category = args['category'] as String;
        // If userLocation is also a required argument, you'll need to retrieve it:
        // final userLocation = args['userLocation'] as GeoPoint; // Make sure to import cloud_firestore for GeoPoint
        return MaterialPageRoute(
          builder:
              (_) => ServiceProviderListPage(
                category: category,
                // If userLocation is mandatory for this page's constructor:
                // userLocation: userLocation, // Pass it here
              ),
        );

      case serviceProviderDetailPage:
        return MaterialPageRoute(
          builder: (_) => const ServiceProviderDetailPage(),
        );

      default:
        return null; // If route not found here, fallback to static routes map or show error
    }
  }
}
