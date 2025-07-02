// lib/data/models/service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Service {
  final String id;
  final String name;
  final String description;
  final String assetImagePath;
  final bool isPopular;
  final int displayOrder;

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.assetImagePath,
    this.isPopular = false,
    this.displayOrder = 999,
  });

  factory Service.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Service(
      id: doc.id,
      name: data['name'] as String,
      description: data['description'] as String,
      assetImagePath: data['assetImagePath'] as String,
      isPopular: data['isPopular'] as bool? ?? false,
      displayOrder: (data['displayOrder'] as num?)?.toInt() ?? 999,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'assetImagePath': assetImagePath,
      'isPopular': isPopular,
      'displayOrder': displayOrder,
    };
  }
}
