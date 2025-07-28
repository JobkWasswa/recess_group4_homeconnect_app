// 📦 A simple model class to represent user profile data from Firestore
class UserProfile {
  final String uid; // 🔑 Unique user ID (usually from FirebaseAuth)
  final String email; // 📧 User's email address
  final String userType; // 🧑‍💼 Could be 'provider', 'homeowner', etc.
  final String? location; // 📍 Optional location field (e.g. city, coordinates)

  // 🛠️ Constructor to initialize the user profile fields
  UserProfile({
    required this.uid,
    required this.email,
    required this.userType,
    this.location,
  });

  // 🔁 Factory constructor to convert Firestore map data into a UserProfile instance
  factory UserProfile.fromFirestore(Map<String, dynamic> data) {
    return UserProfile(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      userType: data['userType'] ?? '',
      location: data['location'], // null-safe: location may not exist
    );
  }
}
