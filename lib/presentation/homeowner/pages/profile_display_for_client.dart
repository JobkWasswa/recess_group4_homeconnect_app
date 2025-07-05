import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homeconnect/data/models/rating_review.dart'; // Make sure this path is correct
// import 'package:homeconnect/data/models/users.dart'; // Only import if you actually use it
import 'package:firebase_auth/firebase_auth.dart'; // To get the current client's UID

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

  // Renamed the method to make it private and clearly indicate it's part of the state
  Future<void> _loadRatingsAndReviews() async {
    // Check if the widget is still mounted before performing async operations
    if (!mounted) return;

    // Fetch profile data first (existing logic)
    final profileSnapshot =
        await FirebaseFirestore.instance
            .collection('service_providers')
            .doc(widget.serviceProviderId)
            .get();

    if (!mounted) return; // Check again after await

    if (!profileSnapshot.exists) {
      // Handle case where profile doesn't exist
      setState(() {
        _averageRating = 0.0;
        _totalReviews = 0;
        _reviews = [];
      });
      return;
    }

    // Fetch all ratings and reviews for this service provider
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('ratings_reviews')
            .where('serviceProviderId', isEqualTo: widget.serviceProviderId)
            .orderBy('timestamp', descending: true) // Order by latest reviews
            .get();

    if (!mounted) return; // Check again after await

    double sumRatings = 0;
    List<RatingReview> fetchedReviews = [];

    // This section might be where you need to fetch client names if they are not
    // stored directly in the 'ratings_reviews' document.
    // For now, I'm assuming your RatingReview.fromFirestore *can* get clientName
    // or you accept 'Anonymous User'. If not, you'll need additional async calls here.
    for (var doc in querySnapshot.docs) {
      try {
        final ratingReview = RatingReview.fromFirestore(doc);

        // --- IMPORTANT: If clientName is not stored in the review document,
        // --- you need to fetch it here. Example:
        // if (ratingReview.clientName == null) {
        //   final clientDoc = await FirebaseFirestore.instance.collection('clients').doc(ratingReview.clientId).get();
        //   if (clientDoc.exists) {
        //     ratingReview.clientName = clientDoc.data()?['name'] ?? 'Anonymous User';
        //   }
        // }
        // --- End of IMPORTANT section

        sumRatings += ratingReview.rating;
        fetchedReviews.add(ratingReview);
      } catch (e) {
        print('Error parsing rating review document: $e');
        // Optionally, show a snackbar or log more detailed error
      }
    }

    setState(() {
      _totalReviews = querySnapshot.docs.length;
      _averageRating = _totalReviews > 0 ? sumRatings / _totalReviews : 0.0;
      _reviews = fetchedReviews;
    });
  }

  Future<void> _submitReview(BuildContext dialogContext) async {
    // Use a new context for the dialog
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        // Ensure widget is still in tree before showing snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to submit a review.'),
          ),
        );
      }
      return;
    }

    // You would typically navigate to a new screen or show a dialog for review submission
    final result = await showDialog<Map<String, dynamic>>(
      context: dialogContext, // Use the passed dialogContext for the dialog
      builder: (BuildContext innerDialogContext) {
        // Use a new context for the builder
        double currentRating = 3.0; // Default rating
        TextEditingController reviewController = TextEditingController();

        return AlertDialog(
          title: const Text('Submit a Review'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Overall Rating:'),
                StatefulBuilder(
                  builder: (context, setStateSB) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < currentRating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 30,
                          ),
                          onPressed: () {
                            setStateSB(() {
                              currentRating = (index + 1).toDouble();
                            });
                          },
                        );
                      }),
                    );
                  },
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: reviewController,
                  decoration: const InputDecoration(
                    labelText: 'Your Review',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(innerDialogContext).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(innerDialogContext).pop({
                  'rating': currentRating,
                  'reviewText': reviewController.text.trim(),
                });
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (!mounted)
      return; // Check if the widget is still mounted after dialog closes

    if (result != null) {
      final double rating = result['rating'];
      final String reviewText = result['reviewText'];

      if (reviewText.isEmpty && rating == 0.0) {
        // Allow submitting rating without reviewText
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please provide a rating or a reviewText.'),
            ),
          );
        }
        return;
      }

      // Check if the user has already reviewed this service provider
      final existingReviews =
          await FirebaseFirestore.instance
              .collection('ratings_reviews')
              .where('serviceProviderId', isEqualTo: widget.serviceProviderId)
              .where('clientId', isEqualTo: currentUser.uid)
              .get();

      if (!mounted) return; // Check again after async operation

      if (existingReviews.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'You have already submitted a review for this provider.',
              ),
            ),
          );
        }
        return;
      }

      try {
        await FirebaseFirestore.instance.collection('ratings_reviews').add({
          'serviceProviderId': widget.serviceProviderId,
          'clientId': currentUser.uid,
          'rating': rating,
          'reviewText': reviewText,
          'timestamp': FieldValue.serverTimestamp(),
          // You might want to store client's name/photo for display in reviews
          // To avoid extra reads for every review, it's often better to denormalize
          // the client's name here.
          'clientName': currentUser.displayName, // Assuming displayName is set
          // 'clientPhotoUrl': currentUser.photoURL,
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!')),
        );
        _loadRatingsAndReviews(); // Reload to update displayed average and reviews
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit review: $e')));
      }
    }
  }

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

                // Ratings Display
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        _averageRating.toStringAsFixed(
                          1,
                        ), // Display average rating
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '($_totalReviews reviews)', // Display total reviews
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

                // Reviews Section
                _buildSectionTitle(context, "Reviews", Icons.reviews),
                const SizedBox(height: 10),
                if (_reviews.isEmpty)
                  const Center(
                    child: Text(
                      'No reviews yet. Be the first to review!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(), // To prevent nested scrolling issues
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
                                  // Display client name if available, otherwise 'Anonymous'
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
                                review.reviewText,
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
      floatingActionButton: FloatingActionButton.extended(
        // Pass the context from the build method to _submitReview
        onPressed: () => _submitReview(context),
        label: const Text(
          'Rate & Review',
          style: TextStyle(color: Colors.white),
        ),
        icon: const Icon(Icons.rate_review, color: Colors.white),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }

  // Section Title Widget
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

  // Profile Detail Row
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
