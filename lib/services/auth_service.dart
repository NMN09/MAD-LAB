import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
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
                  
                  // Auto-heal: If Firestore email differs from the real Auth email due to a past edit, fix it.
                  if (user.email != null && data['email'] != user.email) {
                    _db.collection('users').doc(user.uid).update({'email': user.email});
                  }

                  // Auto-heal photoUrl
                  if (user.photoURL != null && data['photoUrl'] != user.photoURL) {
                    _db.collection('users').doc(user.uid).update({'photoUrl': user.photoURL});
                  }

                  // Auto-heal name
                  if (user.displayName != null && (data['name'] == null || data['name'].isEmpty)) {
                    _db.collection('users').doc(user.uid).update({'name': user.displayName});
                  }
                  
                  controller.add(AppUser(
                    uid: user.uid,
                    email: user.email ?? '',
                    name: data['name'] ?? user.displayName ?? '',
                    role: data['role'] ?? 'user',
                    department: data['department'] ?? '',
                    photoUrl: data['photoUrl'] ?? user.photoURL ?? '',
                  ));
                } else {
                  final defaultName = user.displayName ?? '';
                  final defaultPhoto = user.photoURL ?? '';
                  _db.collection('users').doc(user.uid).set({
                    'email': user.email,
                    'name': defaultName,
                    'role': 'user',
                    'department': '',
                    'photoUrl': defaultPhoto,
                  });
                  controller.add(AppUser(
                    uid: user.uid,
                    email: user.email ?? '',
                    name: defaultName,
                    role: 'user',
                    photoUrl: defaultPhoto,
                  ));
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

  Future<void> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        await _auth.signInWithPopup(googleProvider);
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          throw Exception('Google sign-in was cancelled.');
        }
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await _auth.signInWithCredential(credential);
      }
    } catch (e, stack) {
      print('Google sign in error: $e');
      print(stack);
      throw _friendlyError(e);
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password.trim());
    } catch (e, stack) {
      print('Sign in error: $e');
      print(stack);
      throw _friendlyError(e);
    }
  }

  Future<void> registerWithEmail(String email, String password, String name) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password.trim());
      await _db.collection('users').doc(result.user!.uid).set({'email': email.trim(), 'name': name.trim(), 'role': 'user', 'department': ''});
    } catch (e, stack) {
      print('Register error: $e');
      print(stack);
      throw _friendlyError(e);
    }
  }

  Future<String> updateProfile(String name) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // 1. Update the user's profile
        await _db.collection('users').doc(user.uid).update({'name': name});
        
        // 2. Cascade the name update to all of their past complaints
        final complaintsQuery = await _db.collection('complaints').where('userId', isEqualTo: user.uid).get();
        if (complaintsQuery.docs.isNotEmpty) {
          final batch = _db.batch();
          for (var doc in complaintsQuery.docs) {
            batch.update(doc.reference, {'userName': name});
          }
          await batch.commit();
        }
        
        return 'Profile updated successfully!';
      }
      return 'User not found.';
    } catch (e) {
      throw _friendlyError(e);
    }
  }

  Future<void> signOut() async => await _auth.signOut();

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e, stack) {
      print('Password reset error: $e');
      print(stack);
      throw _friendlyError(e);
    }
  }

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
