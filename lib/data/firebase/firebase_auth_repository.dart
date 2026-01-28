import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';

import '../../domain/models/auth_result.dart';
import '../../domain/models/user.dart' as domain;
import '../../domain/services/auth_repository.dart';

/// Firebase implementation of [AuthRepository] using Firebase Auth and Firestore.
///
/// Provides Google OAuth authentication, session management, and automatic
/// user profile synchronization with Firestore. Maintains legacy compatibility
/// with username/password and guest authentication through local storage.
class FirebaseAuthRepository implements AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final StreamController<domain.User?> _authStateController =
      StreamController<domain.User?>.broadcast();

  FirebaseAuthRepository({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance {
    // Listen to Firebase auth state changes and emit to our stream
    _firebaseAuth.authStateChanges().listen((firebaseUser) async {
      print('🔐 Auth state change: ${firebaseUser?.uid ?? "signed out"}');

      if (firebaseUser == null) {
        _authStateController.add(null);
      } else {
        // Emit user immediately (fast, from Firebase Auth cache)
        final quickUser = _mapFirebaseUserToDomainUser(firebaseUser);
        _authStateController.add(quickUser);

        // Sync to Firestore in background (non-blocking)
        _syncUserProfile(firebaseUser)
            .then((fullUser) {
              _authStateController.add(fullUser);
            })
            .catchError((e) {
              print('⚠️ Firestore sync failed: $e');
              // Keep the quick user if Firestore fails
            });
      }
    });

    print('🔐 FirebaseAuthRepository initialized');
    print('🔐 Current user: ${_firebaseAuth.currentUser?.uid ?? "none"}');
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    try {
      // Use Firebase Auth popup directly (faster, no COOP issues)
      final provider = firebase_auth.GoogleAuthProvider();
      provider.addScope('email');
      provider.addScope('profile');

      // Sign in with popup
      final firebase_auth.UserCredential userCredential = await _firebaseAuth
          .signInWithPopup(provider);

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return const AuthFailure('Authentication failed: no user returned');
      }

      // Return user immediately from Firebase Auth (fast)
      final user = _mapFirebaseUserToDomainUser(firebaseUser);

      // Sync to Firestore in background (non-blocking)
      _syncUserProfile(firebaseUser).catchError((e) {
        // Log but don't fail - Firestore sync is not critical for login
        if (kDebugMode) {
          debugPrint('Firestore sync failed: $e');
        }
      });

      return AuthSuccess(user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthFailure(_mapFirebaseAuthError(e));
    } catch (e) {
      return AuthFailure('Sign-in failed: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      _authStateController.add(null);
    } catch (e) {
      // Log error but don't throw - best effort sign out
      _authStateController.add(null);
    }
  }

  @override
  Future<domain.User?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    print('🔐 getCurrentUser called: ${firebaseUser?.uid ?? "no user"}');
    if (firebaseUser == null) {
      return null;
    }

    try {
      // Try to get user from Firestore first
      final doc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        return domain.User.fromJson(doc.data()!);
      }

      // Fallback: sync from Firebase Auth if not in Firestore
      return await _syncUserProfile(firebaseUser);
    } catch (e) {
      // Fallback to minimal user from Firebase Auth
      return _mapFirebaseUserToDomainUser(firebaseUser);
    }
  }

  @override
  Stream<domain.User?> authStateChanges() => _authStateController.stream;

  /// Syncs user profile to Firestore, creating or updating as needed.
  Future<domain.User> _syncUserProfile(firebase_auth.User firebaseUser) async {
    final userRef = _firestore.collection('users').doc(firebaseUser.uid);

    try {
      final doc = await userRef.get();
      final now = DateTime.now();

      if (doc.exists && doc.data() != null) {
        // User exists - update last login
        final existingUser = domain.User.fromJson(doc.data()!);
        final updatedUser = existingUser.copyWith(
          lastLoginAt: now,
          email: firebaseUser.email,
          displayName: firebaseUser.displayName,
          photoURL: firebaseUser.photoURL,
        );

        await userRef.update({
          'lastLoginAt': FieldValue.serverTimestamp(),
          if (firebaseUser.email != null) 'email': firebaseUser.email,
          if (firebaseUser.displayName != null)
            'displayName': firebaseUser.displayName,
          if (firebaseUser.photoURL != null) 'photoURL': firebaseUser.photoURL,
        });

        return updatedUser;
      } else {
        // New user - create profile
        final newUser = domain.User(
          id: firebaseUser.uid,
          username: firebaseUser.displayName ?? firebaseUser.email ?? 'User',
          createdAt: now,
          isGuest: false,
          uid: firebaseUser.uid,
          email: firebaseUser.email,
          displayName: firebaseUser.displayName,
          photoURL: firebaseUser.photoURL,
          totalStars: 0,
          lastLoginAt: now,
        );

        await userRef.set({
          'id': newUser.id,
          'username': newUser.username,
          'createdAt': FieldValue.serverTimestamp(),
          'isGuest': false,
          if (newUser.uid != null) 'uid': newUser.uid,
          if (newUser.email != null) 'email': newUser.email,
          if (newUser.displayName != null) 'displayName': newUser.displayName,
          if (newUser.photoURL != null) 'photoURL': newUser.photoURL,
          'totalStars': 0,
          'lastLoginAt': FieldValue.serverTimestamp(),
        });

        return newUser;
      }
    } catch (e) {
      // If Firestore fails, return minimal user from Firebase Auth
      return _mapFirebaseUserToDomainUser(firebaseUser);
    }
  }

  /// Maps Firebase Auth user to domain User model.
  domain.User _mapFirebaseUserToDomainUser(firebase_auth.User firebaseUser) {
    return domain.User(
      id: firebaseUser.uid,
      username: firebaseUser.displayName ?? firebaseUser.email ?? 'User',
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      isGuest: false,
      uid: firebaseUser.uid,
      email: firebaseUser.email,
      displayName: firebaseUser.displayName,
      photoURL: firebaseUser.photoURL,
      totalStars: 0,
      lastLoginAt: DateTime.now(),
    );
  }

  /// Maps Firebase Auth exceptions to user-friendly error messages.
  String _mapFirebaseAuthError(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method';
      case 'invalid-credential':
        return 'Invalid credentials. Please try again';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'user-not-found':
        return 'No account found with these credentials';
      case 'wrong-password':
        return 'Incorrect password';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      default:
        return 'Authentication failed: ${e.message ?? e.code}';
    }
  }

  // Legacy authentication methods (backward compatibility)
  // These are not implemented in Firebase version - use local auth repository

  @override
  Future<AuthResult> login(String username, String password) async {
    return const AuthFailure(
      'Username/password login not supported with Firebase. Use Google Sign-In or local auth repository.',
    );
  }

  @override
  Future<AuthResult> register(String username, String password) async {
    return const AuthFailure(
      'Username/password registration not supported with Firebase. Use Google Sign-In or local auth repository.',
    );
  }

  @override
  Future<void> logout() async {
    await signOut();
  }

  @override
  Future<AuthResult> loginAsGuest() async {
    return const AuthFailure(
      'Guest login not supported with Firebase. Use local auth repository.',
    );
  }

  /// Disposes resources held by this repository.
  void dispose() {
    _authStateController.close();
  }
}
