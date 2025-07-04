import 'package:flutter/material.dart';
import 'package:homeconnect/presentation/homeowner/pages/service_provider.dart';
import 'package:homeconnect/presentation/homeowner/widgets/service_card.dart';
import 'package:homeconnect/services/api_service.dart';
import 'package:homeconnect/services/location_service.dart';
import 'package:homeconnect/config/routes.dart';
import 'packages:homeconnect/presentation/homeowner/pages/service_provider_list_pages.dart';

class ServiceProviderListScreen extends StatefulWidget {
  final String? serviceCategory;
  final LatLng? userLocation;

  const ServiceProviderListScreen({
    super.key,
    this.serviceCategory,
    this.userLocation,
  });

  @override
  _ServiceProviderListScreenState createState() =>
      _ServiceProviderListScreenState();
}

class ServiceProviderListPage extends StatelessWidget {
  final String? searchQuery;
  final String? category;




  ServiceProviderListPage({super.key});class _ServiceProviderListScreenState extends State<ServiceProviderListScreen> {
  List<ServiceProvider> providers0 = [];
  bool isLoading = true;
  String? error;
  LatLng? currentUserLocation;


  @override
  void initState() {
    super.initState();
    initializeData();
  }

  Future<void> initializeData() async {
    await getUserLocation();
    await fetchServiceProviders();
  }

  Future<void> getUserLocation() async {
    final position = await LocationService.getCurrentLocation();
    if (position != null) {
      setState(() {
        currentUserLocation = LatLng(position.latitude, position.longitude);
      });
    }
  }

  Future<void> fetchServiceProviders() async {
    try {
      final filters = {
        'category': widget.serviceCategory,
        'location': currentUserLocation ?? widget.userLocation,
        'sortBy': 'rating',
        'availability': true,
      };

      final providers = await ApiService().getServiceProviders(filters);
      setState(() {
        providers0 = providers;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load service providers';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.serviceCategory ?? 'Recommended Service Providers'),
      ),
      body: buildBody(),

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final query = args != null ? args['query'] as String? : null;
    final category = args != null ? args['category'] as String? : null;
    final location = args != null ? args['location'] as String? : null;

    final searchValue = query ?? category;

    if (searchValue == null ||
        searchValue.isEmpty ||
        location == null ||
        location.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Missing search input or location.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Available Professionals')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: HomeownerFirestoreProvider().fetchProvidersBySkillAndLocation(
          skill: searchValue,
          location: location,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No service providers found.'));
          } else {
            final providers = snapshot.data!;
            return ListView.builder(
              itemCount: providers.length,
              itemBuilder: (context, index) {
                final provider = providers[index];
                return ListTile(
                  title: Text(provider['name'] ?? 'Unnamed'),
                  subtitle: Text(
                    provider['skills']?.join(', ') ?? 'No skills listed',
                  ),
                  trailing: Text('${provider['rating'] ?? 'N/A'} ⭐'),
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.serviceProviderDetailPage,
                      arguments: provider, // Pass full provider Map
                    );
                  },
                );
              },
            );
          }
        },
      ),

    );
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(child: Text(error!));
    }

    if (providers0.isEmpty) {
      return const Center(child: Text('No service providers found'));
    }

    return ListView.builder(
      itemCount: providers0.length,
      itemBuilder: (context, index) {
        return ServiceProviderCard(
          provider: providers0[index],
          userLocation: currentUserLocation ?? widget.userLocation,
          onBook: () => bookService(providers0[index]),
        );
      },
    );
  }

  void bookService(ServiceProvider provider) {
    // Implement booking logic
  }
}
