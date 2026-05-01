import 'package:cloud_firestore/cloud_firestore.dart';

class Complaint {
  final String id;
  final String title;
  final String description;
  final String category;
  final String imageUrl;
  final String status;
  final String userId;
  final String userEmail;
  final String userName;
  final DateTime timestamp;
  final DateTime? resolvedAt;
  final List<String> upvotes; // list of UIDs who upvoted

  Complaint({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.status,
    required this.userId,
    this.userEmail = '',
    this.userName = '',
    required this.timestamp,
    this.resolvedAt,
    this.upvotes = const [],
  });

  int get upvoteCount => upvotes.length;

  factory Complaint.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Complaint(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      status: data['status'] ?? 'Submitted',
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userName: data['userName'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      upvotes: List<String>.from(data['upvotes'] ?? []),
    );
  }
}
