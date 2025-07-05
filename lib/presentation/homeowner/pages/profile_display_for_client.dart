import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homeconnect/data/models/rating_review.dart'; // Still needed for displaying existing reviews
// import 'package:firebase_auth/firebase_auth.dart'; // No longer needed if no review submission

class ProfileDisplayScreenForClient extends StatefulWidget {
  final String serviceProviderId; // Renamed from userId for clarity

  const ProfileDisplayScreenForClient({
    super.key,
    required this.serviceProviderId,
  });

  @override
  State<ProfileDisplayScreenForClient> createState() =>
      _ProfileDisplayScreenForClientState();
}

class _ProfileDisplayScreenForClientState
    extends State<ProfileDisplayScreenForClient> {
  double _averageRating = 0.0;
  int _totalReviews = 0;
  List<RatingReview> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadRatingsAndReviews();
  }

  // Method to load existing ratings and reviews (still needed for display)
  Future<void> _loadRatingsAndReviews() async {
    if (!mounted) return;

    final profileSnapshot =
        await FirebaseFirestore.instance
            .collection('service_providers')
            .doc(widget.serviceProviderId)
            .get();

    if (!mounted) return;

    if (!profileSnapshot.exists) {
      setState(() {
        _averageRating = 0.0;
        _totalReviews = 0;
        _reviews = [];
      });
      return;
    }

    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('ratings_reviews')
            .where('serviceProviderId', isEqualTo: widget.serviceProviderId)
            .orderBy('timestamp', descending: true)
            .get();

    if (!mounted) return;

    double sumRatings = 0;
    List<RatingReview> fetchedReviews = [];

    for (var doc in querySnapshot.docs) {
      try {
        final ratingReview = RatingReview.fromFirestore(doc);
        sumRatings += ratingReview.rating;
        fetchedReviews.add(ratingReview);
      } catch (e) {
        print('Error parsing rating review document: $e');
      }
    }

    setState(() {
      _totalReviews = querySnapshot.docs.length;
      _averageRating = _totalReviews > 0 ? sumRatings / _totalReviews : 0.0;
      _reviews = fetchedReviews;
    });
  }

  // Removed the _submitReview method entirely as it's no longer needed on this screen.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Service Provider Profile',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future:
            FirebaseFirestore.instance
                .collection('service_providers')
                .doc(widget.serviceProviderId)
                .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Profile not found.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final data = snapshot.data!.data()!;
          final GeoPoint? location =
              data['location'] is GeoPoint ? data['location'] : null;
          final String address = data['address'] ?? 'N/A';
          final availability = data['availability'] ?? {};
          final categories = data['categories'] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.blue.shade100,
                    backgroundImage:
                        data['profilePhoto'] != null
                            ? NetworkImage(data['profilePhoto'])
                            : null,
                    child:
                        data['profilePhoto'] == null
                            ? Icon(
                              Icons.person,
                              size: 70,
                              color: Colors.blue.shade800,
                            )
                            : null,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    data['name'] ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    data['email'] ?? '',
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                  ),
                ),
                const SizedBox(height: 15),

                // Ratings Display (still needed to show existing ratings)
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        _averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '($_totalReviews reviews)',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),

                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    data['description'] ?? 'No description provided.',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Divider(height: 40, thickness: 1.5, color: Colors.grey),
                _buildSectionTitle(
                  context,
                  "Service Categories",
                  Icons.category,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children:
                      (categories as List<dynamic>).map((cat) {
                        return Chip(
                          label: Text(cat.toString()),
                          backgroundColor: Colors.lightBlue.shade100,
                          labelStyle: const TextStyle(color: Colors.blueAccent),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                        );
                      }).toList(),
                ),
                const Divider(height: 40, thickness: 1.5, color: Colors.grey),
                _buildSectionTitle(context, "Location", Icons.location_on),
                const SizedBox(height: 10),
                _buildProfileDetailRow("Address", address, Icons.pin_drop),
                _buildProfileDetailRow(
                  "Latitude",
                  location?.latitude.toString() ?? 'N/A',
                  Icons.map,
                ),
                _buildProfileDetailRow(
                  "Longitude",
                  location?.longitude.toString() ?? 'N/A',
                  Icons.map,
                ),
                const Divider(height: 40, thickness: 1.5, color: Colors.grey),
                _buildSectionTitle(context, "Availability", Icons.access_time),
                const SizedBox(height: 10),
                if (availability.isNotEmpty)
                  ...availability.entries.map((entry) {
                    final day = entry.key;
                    final times = entry.value as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 18,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "$day: ${times['start'] ?? 'N/A'} - ${times['end'] ?? 'N/A'}",
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList()
                else
                  const Text(
                    "No availability set.",
                    style: TextStyle(color: Colors.grey),
                  ),
                const Divider(height: 40, thickness: 1.5, color: Colors.grey),

                // Reviews Section (still needed to display existing reviews)
                _buildSectionTitle(context, "Reviews", Icons.reviews),
                const SizedBox(height: 10),
                if (_reviews.isEmpty)
                  const Center(
                    child: Text(
                      'No reviews yet.', // Changed text slightly
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _reviews.length,
                    itemBuilder: (context, index) {
                      final review = _reviews[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    review.clientName ?? 'Anonymous User',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Row(
                                    children: List.generate(5, (starIndex) {
                                      return Icon(
                                        starIndex < review.rating
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.amber,
                                        size: 18,
                                      );
                                    }),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                review
                                    .reviewText, // Assuming your RatingReview model has 'comment' or 'reviewText'
                                style: const TextStyle(fontSize: 14),
                              ),
                              if (review.timestamp != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'Reviewed on: ${review.timestamp!.toDate().toLocal().toString().split(' ')[0]}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
      // Removed the FloatingActionButton for "Rate & Review"
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () => _submitReview(context),
      //   label: const Text(
      //     'Rate & Review',
      //     style: TextStyle(color: Colors.white),
      //   ),
      //   icon: const Icon(Icons.rate_review, color: Colors.white),
      //   backgroundColor: Colors.deepPurple,
      // ),
    );
  }

  // Section Title Widget (unchanged)
  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple, size: 22),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }

  // Profile Detail Row (unchanged)
  Widget _buildProfileDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "$label: $value",
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
