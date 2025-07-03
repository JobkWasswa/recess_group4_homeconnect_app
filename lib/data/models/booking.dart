class JobRequest {
  final String id;
  final String homeownerId;
  final String? serviceProviderId;
  final String serviceType;
  final String description;
  final String location;
  final double budget;
  final String status; // 'pending', 'accepted', 'completed', 'rejected'
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? homeownerName;
  final String? serviceProviderName;
  final DateTime? completionDate;
  final double? finalPrice;
  final double? homeownerRating;
  final String? rejectionReason;

  JobRequest({
    required this.id,
    required this.homeownerId,
    this.serviceProviderId,
    required this.serviceType,
    required this.description,
    required this.location,
    required this.budget,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.homeownerName,
    this.serviceProviderName,
    this.completionDate,
    this.finalPrice,
    this.homeownerRating,
    this.rejectionReason,
  });

  factory JobRequest.fromJson(Map<String, dynamic> json) {
    return JobRequest(
      id: json['id'] as String,
      homeownerId: json['homeownerId'] as String,
      serviceProviderId: json['serviceProviderId'] as String?,
      serviceType: json['serviceType'] as String,
      description: json['description'] as String,
      location: json['location'] as String,
      budget: (json['budget'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      homeownerName: json['homeownerName'] as String?,
      serviceProviderName: json['serviceProviderName'] as String?,
      completionDate:
          json['completionDate'] != null
              ? DateTime.parse(json['completionDate'] as String)
              : null,
      finalPrice:
          json['finalPrice'] != null
              ? (json['finalPrice'] as num).toDouble()
              : null,
      homeownerRating:
          json['homeownerRating'] != null
              ? (json['homeownerRating'] as num).toDouble()
              : null,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'homeownerId': homeownerId,
      'serviceProviderId': serviceProviderId,
      'serviceType': serviceType,
      'description': description,
      'location': location,
      'budget': budget,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'homeownerName': homeownerName,
      'serviceProviderName': serviceProviderName,
      'completionDate': completionDate?.toIso8601String(),
      'finalPrice': finalPrice,
      'homeownerRating': homeownerRating,
      'rejectionReason': rejectionReason,
    };
  }
}
