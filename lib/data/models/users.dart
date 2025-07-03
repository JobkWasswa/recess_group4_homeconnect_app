class UserProfile {
  final String uid;
  final String email;
  final String userType;
  final String? location; // This remains nullable

  UserProfile({
    required this.uid,
    required this.email,
    required this.userType,
    this.location,
  });

  factory UserProfile.fromFirestore(Map<String, dynamic> data) {
    return UserProfile(
      uid: data['uid'] as String? ?? '', // Explicitly cast and provide default
      email:
          data['email'] as String? ?? '', // Explicitly cast and provide default
      userType:
          data['userType'] as String? ??
          '', // Explicitly cast and provide default
      location:
          data['location'] as String?, // Explicitly cast to nullable String
    );
  }
}
