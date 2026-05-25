import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/complaint.dart';
import '../models/app_user.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ===== COMPLAINTS =====

  Stream<List<Complaint>> get allComplaints {
    return _db.collection('complaints').orderBy('timestamp', descending: true)
        .snapshots().map((s) => s.docs.map((d) => Complaint.fromFirestore(d)).toList());
  }

  Stream<List<Complaint>> userComplaints(String userId) {
    return _db.collection('complaints').where('userId', isEqualTo: userId)
        .snapshots().map((s) {
      final list = s.docs.map((d) => Complaint.fromFirestore(d)).toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  Stream<Complaint> complaintStream(String id) {
    return _db.collection('complaints').doc(id).snapshots().map((d) => Complaint.fromFirestore(d));
  }

  Future<void> submitComplaint({required String title, required String description, required String category, required String imageBase64, required String userId, required String userEmail, required String userName}) async {
    await _db.collection('complaints').add({
      'title': title, 'description': description, 'category': category,
      'imageUrl': imageBase64, 'status': 'Submitted', 'userId': userId,
      'userEmail': userEmail, 'userName': userName, 'upvotes': [], 'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateComplaintStatus(String id, String status) async {
    Map<String, dynamic> update = {'status': status};
    if (status == 'Resolved') update['resolvedAt'] = FieldValue.serverTimestamp();
    await _db.collection('complaints').doc(id).update(update);
  }

  // Student requests cancellation
  Future<void> requestCancellation(String id) async {
    await _db.collection('complaints').doc(id).update({'status': 'CancelRequested'});
  }

  // Admin approves cancellation
  Future<void> approveCancellation(String id) async {
    await _db.collection('complaints').doc(id).update({'status': 'Cancelled'});
  }

  Future<void> deleteComplaint(String id) async {
    final msgs = await _db.collection('complaints').doc(id).collection('messages').get();
    for (var doc in msgs.docs) { await doc.reference.delete(); }
    await _db.collection('complaints').doc(id).delete();
  }

  // ===== UPVOTES =====

  Future<void> toggleUpvote(String complaintId, String userId) async {
    final ref = _db.collection('complaints').doc(complaintId);
    final doc = await ref.get();
    if (!doc.exists) return;
    final upvotes = List<String>.from(doc.data()?['upvotes'] ?? []);
    if (upvotes.contains(userId)) { upvotes.remove(userId); } else { upvotes.add(userId); }
    await ref.update({'upvotes': upvotes});
  }

  // ===== RATE LIMITING =====

  Future<bool> canUserSubmit(String userId, {int maxPerHour = 3}) async {
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    final snap = await _db.collection('complaints').where('userId', isEqualTo: userId).get();
    final recentCount = snap.docs.where((doc) {
      final ts = (doc.data()['timestamp'] as Timestamp?)?.toDate();
      return ts != null && ts.isAfter(oneHourAgo);
    }).length;
    return recentCount < maxPerHour;
  }

  // ===== CHAT =====

  Stream<List<Map<String, dynamic>>> getMessages(String complaintId) {
    return _db.collection('complaints').doc(complaintId).collection('messages')
        .orderBy('timestamp', descending: false).snapshots()
        .map((s) => s.docs.map((d) {
          final data = d.data();
          return {'id': d.id, 'text': data['text'] ?? '', 'senderId': data['senderId'] ?? '', 'senderEmail': data['senderEmail'] ?? '', 'senderRole': data['senderRole'] ?? 'user', 'timestamp': (data['timestamp'] as Timestamp?)?.toDate()};
        }).toList());
  }

  Future<void> sendMessage({required String complaintId, required String text, required String senderId, required String senderEmail, required String senderRole}) async {
    await _db.collection('complaints').doc(complaintId).collection('messages').add({
      'text': text, 'senderId': senderId, 'senderEmail': senderEmail, 'senderRole': senderRole, 'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unsendMessage(String complaintId, String messageId) async {
    await _db.collection('complaints').doc(complaintId).collection('messages').doc(messageId).delete();
  }

  // ===== USERS =====

  Stream<List<AppUser>> get allUsers {
    return _db.collection('users').snapshots().map((s) => s.docs.map((d) {
      final data = d.data();
      return AppUser(
        uid: d.id,
        email: data['email'] ?? '',
        name: data['name'] ?? '',
        role: data['role'] ?? 'user',
        department: data['department'] ?? '',
        photoUrl: data['photoUrl'] ?? '',
      );
    }).toList());
  }

  Future<void> updateUserRole(String uid, String role, {String department = ''}) async {
    await _db.collection('users').doc(uid).update({'role': role, 'department': department});
  }

  // ===== DB HEALING =====
  
  Future<void> healAllComplaints() async {
    final usersSnap = await _db.collection('users').get();
    Map<String, String> userNames = {};
    for (var doc in usersSnap.docs) {
      userNames[doc.id] = doc.data()['name'] ?? '';
    }
    
    final complaintsSnap = await _db.collection('complaints').get();
    final batch = _db.batch();
    int updates = 0;
    
    for (var doc in complaintsSnap.docs) {
      final data = doc.data();
      final uid = data['userId'] as String?;
      if (uid != null && userNames.containsKey(uid)) {
        final correctName = userNames[uid]!;
        if (data['userName'] != correctName) {
          batch.update(doc.reference, {'userName': correctName});
          updates++;
        }
      }
    }
    
    if (updates > 0) {
      await batch.commit();
      print('Healed $updates complaints with outdated usernames.');
    }
  }
}
