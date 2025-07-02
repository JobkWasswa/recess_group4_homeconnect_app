class UserProfile {
    final String uid;
    final String email;
    final String userType;
    final String? location;

    UserProfile({
      required this.uid,
      required this.email,
      required this.userType,
      this.location,
    });

    factory UserProfile.fromFirestore(Map<String, dynamic> data) {
      return UserProfile(
        uid: data['uid'] ?? '',
        email: data['email'] ?? '',
        userType: data['userType'] ?? '',
        location: data['location'],
      );
    }
  }