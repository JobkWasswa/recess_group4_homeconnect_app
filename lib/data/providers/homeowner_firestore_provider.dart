import 'package:cloud_firestore/cloud_firestore.dart';

class HomeownerFirestoreProvider {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchProvidersBySkillOrCategory(String searchValue) async {
    final querySnapshot = await _firestore
        .collection('service_providers')
        .where('skills', arrayContains: searchValue)
        .get();

    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }
}
