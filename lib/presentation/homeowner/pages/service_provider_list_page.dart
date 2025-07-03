import 'package:flutter/material.dart';
import 'package:homeconnect/presentation/homeowner/pages/service_provider.dart';
import 'package:homeconnect/presentation/homeowner/widgets/service_card.dart';
import 'package:homeconnect/services/api_service.dart';
import 'package:homeconnect/services/location_service.dart';

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

class _ServiceProviderListScreenState extends State<ServiceProviderListScreen> {
  List<ServiceProvider> _providers = [];
  bool _isLoading = true;
  String? _error;
  LatLng? _currentUserLocation;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _getUserLocation();
    await _fetchServiceProviders();
  }

  Future<void> _getUserLocation() async {
    final position = await LocationService.getCurrentLocation();
    if (position != null) {
      setState(() {
        _currentUserLocation = LatLng(position.latitude, position.longitude);
      });
    }
  }

  Future<void> _fetchServiceProviders() async {
    try {
      final filters = {
        'category': widget.serviceCategory,
        'location': _currentUserLocation ?? widget.userLocation,
        'sortBy': 'rating',
        'availability': true,
      };

      final providers = await ApiService().getServiceProviders(filters);
      setState(() {
        _providers = providers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load service providers';
        _isLoading = false;
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_providers.isEmpty) {
      return const Center(child: Text('No service providers found'));
    }

    return ListView.builder(
      itemCount: _providers.length,
      itemBuilder: (context, index) {
        return ServiceProviderCard(
          provider: _providers[index],
          userLocation: _currentUserLocation ?? widget.userLocation,
          onBook: () => _bookService(_providers[index]),
        );
      },
    );
  }

  void _bookService(ServiceProvider provider) {
    // Implement booking logic
  }
}
