import 'package:cloud_firestore/cloud_firestore.dart';

class HomeownerFirestoreProvider {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchProvidersBySkillAndLocation({
    required String skill,
    required String location,
  }) async {
    final querySnapshot = await _firestore
      .collection('service_providers')
      .where('skills', arrayContains: skill)
      .where('location', isEqualTo: location)
      .get();

    return querySnapshot.docs.map((doc) => doc.data()).toList();
    }

}