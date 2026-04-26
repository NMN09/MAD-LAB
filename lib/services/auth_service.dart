import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<AppUser?> get user {
    late StreamController<AppUser?> controller;
    StreamSubscription? authSub;
    StreamSubscription? dbSub;

    controller = StreamController<AppUser?>(
      onListen: () {
        authSub = _auth.authStateChanges().listen((user) {
          dbSub?.cancel(); // Immediately cancel any older listeners
          if (user == null) {
            controller.add(null);
          } else {
            if (user.email == 'superadmin@gmail.com') {
              controller.add(AppUser(uid: user.uid, email: user.email!, role: 'superadmin'));
            } else {
              dbSub = _db.collection('users').doc(user.uid).snapshots().listen((doc) {
                if (doc.exists) {
                  controller.add(AppUser(uid: user.uid, email: user.email!, role: doc.data()?['role'] ?? 'user'));
                } else {
                  controller.add(AppUser(uid: user.uid, email: user.email!, role: 'user'));
                }
              });
            }
          }
        });
      },
      onCancel: () {
        authSub?.cancel();
        dbSub?.cancel();
      },
    );

    return controller.stream;
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Auto-backfill for older users (so they show up in User Management tab)
      if (email != 'superadmin@gmail.com') {
        final doc = await _db.collection('users').doc(result.user!.uid).get();
        if (!doc.exists) {
          await _db.collection('users').doc(result.user!.uid).set({
            'email': email,
            'role': 'user',
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Sign In Error';
    } catch (e) {
      throw 'An unknown error occurred.';
    }
  }

  Future<void> registerWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      String role = email == 'superadmin@gmail.com' ? 'superadmin' : 'user';
      await _db.collection('users').doc(result.user!.uid).set({
        'email': email,
        'role': role,
      });

    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Registration Error';
    } catch (e) {
      throw 'An unknown error occurred.';
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign Out Error: $e');
    }
  }
}
