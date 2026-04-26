import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/complaint.dart';
import '../models/app_user.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream of all complaints (for Admin)
  Stream<List<Complaint>> get allComplaints {
    return _db
        .collection('complaints')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Complaint.fromFirestore(doc))
            .toList());
  }

  // Stream of specific user complaints
  Stream<List<Complaint>> userComplaints(String userId) {
    return _db
        .collection('complaints')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Complaint.fromFirestore(doc))
            .toList());
  }

  // Update complaint status
  Future<void> updateComplaintStatus(String id, String status) async {
    await _db.collection('complaints').doc(id).update({'status': status});
  }

  // Submit new complaint with Base64 Image string
  Future<void> submitComplaint({
    required String title,
    required String description,
    required String category,
    required String imageBase64, // Accepting the full data URI
    required String userId,
  }) async {
    try {
      // Direct Firestore save - no Storage upload needed!
      await _db.collection('complaints').add({
        'title': title,
        'description': description,
        'category': category,
        'imageUrl': imageBase64, // Store the base64 string directly
        'status': 'Submitted',
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error submitting complaint: $e');
      throw e;
    }
  }

  // Stream of all users (for Super Admin)
  Stream<List<AppUser>> get allUsers {
    return _db.collection('users').snapshots().map((snapshot) => snapshot.docs
        .map((doc) => AppUser(
              uid: doc.id,
              email: doc.data()['email'] ?? '',
              role: doc.data()['role'] ?? 'user',
            ))
        .toList());
  }

  // Update user role
  Future<void> updateUserRole(String uid, String role) async {
    await _db.collection('users').doc(uid).update({'role': role});
  }
}
