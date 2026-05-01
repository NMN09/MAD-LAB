import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get currentUid => _auth.currentUser?.uid;
  String? get currentEmail => _auth.currentUser?.email;

  Stream<AppUser?> get user {
    late StreamController<AppUser?> controller;
    StreamSubscription? authSub;
    StreamSubscription? dbSub;
    controller = StreamController<AppUser?>(
      onListen: () {
        authSub = _auth.authStateChanges().listen((user) {
          dbSub?.cancel();
          if (user == null) { controller.add(null); }
          else {
            dbSub = _db.collection('users').doc(user.uid).snapshots().listen(
              (doc) {
                if (doc.exists) {
                  final data = doc.data() ?? {};
                  controller.add(AppUser(uid: user.uid, email: user.email ?? '', name: data['name'] ?? '', role: data['role'] ?? 'user', department: data['department'] ?? ''));
                } else {
                  _db.collection('users').doc(user.uid).set({'email': user.email, 'name': '', 'role': 'user', 'department': ''});
                  controller.add(AppUser(uid: user.uid, email: user.email ?? '', role: 'user'));
                }
              },
              onError: (_) => controller.add(AppUser(uid: user.uid, email: user.email ?? '', role: 'user')),
            );
          }
        });
      },
      onCancel: () { authSub?.cancel(); dbSub?.cancel(); },
    );
    return controller.stream;
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password.trim());
      final doc = await _db.collection('users').doc(result.user!.uid).get();
      if (!doc.exists) await _db.collection('users').doc(result.user!.uid).set({'email': email.trim(), 'name': '', 'role': 'user', 'department': ''});
    } catch (e) {
      throw _friendlyError(e);
    }
  }

  Future<void> registerWithEmail(String email, String password, String name) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password.trim());
      await _db.collection('users').doc(result.user!.uid).set({'email': email.trim(), 'name': name.trim(), 'role': 'user', 'department': ''});
    } catch (e) {
      throw _friendlyError(e);
    }
  }

  Future<void> updateProfile(String name, String newEmail) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        if (user.email != newEmail) {
          // Note: In newer Firebase versions, updateEmail is removed.
          // verifyBeforeUpdateEmail must be used, which requires email verification.
          await user.verifyBeforeUpdateEmail(newEmail);
        }
        await _db.collection('users').doc(user.uid).update({'name': name, 'email': newEmail});
      }
    } catch (e) {
      throw _friendlyError(e);
    }
  }

  Future<void> signOut() async => await _auth.signOut();

  /// Converts raw Firebase errors into user-friendly messages
  String _friendlyError(dynamic e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('invalid-credential') || msg.contains('wrong-password') || msg.contains('user-not-found') || msg.contains('invalid-login-credentials')) {
      return 'Invalid email or password. Please try again.';
    }
    if (msg.contains('email-already-in-use')) {
      return 'An account with this email already exists. Try signing in instead.';
    }
    if (msg.contains('weak-password')) {
      return 'Password is too weak. Use at least 6 characters with letters and numbers.';
    }
    if (msg.contains('invalid-email')) {
      return 'Please enter a valid email address (e.g. name@example.com).';
    }
    if (msg.contains('too-many-requests')) {
      return 'Too many attempts. Your account is temporarily locked. Try again in a few minutes.';
    }
    if (msg.contains('network-request-failed') || msg.contains('network')) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (msg.contains('user-disabled')) {
      return 'This account has been disabled. Contact support for help.';
    }
    if (msg.contains('operation-not-allowed')) {
      return 'This sign-in method is not enabled. Contact the administrator.';
    }
    if (msg.contains('requires-recent-login')) {
      return 'Please sign in again to complete this action.';
    }
    return 'Something went wrong. Please try again.';
  }
}
