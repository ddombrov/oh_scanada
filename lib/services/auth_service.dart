import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthService {
  final int testMode =
      0; // Change to 1 for test mode (anyone can login as guest) or 0 for regular

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? currentUser;

  String? _mockUserId;
  String? _mockUserEmail;
  String? _mockUserName;
  String _lastErrorMessage = '';
  String get lastErrorMessage => _lastErrorMessage;

  // Initialize the auth service
  Future<void> initialize() async {
    try {
      if (testMode == 0) {

        // Get current user if already logged in
        currentUser = _auth.currentUser;

        if (currentUser != null) {

          // Fetch Firestore profile to see if it exists
          try {
            DocumentSnapshot doc = await _firestore
                .collection('users')
                .doc(currentUser!.uid)
                .get();
            if (doc.exists) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            }
          } catch (e) {
            print('Error fetching profile: $e');
          }
        }
      } else {
        // Test mode - reset mock user
        _mockUserId = null;
        _mockUserEmail = null;
        _mockUserName = null;
      }
      _lastErrorMessage = '';
    } catch (e) {
      print('Error initializing auth service: $e');
    }
  }

  String? get userId => testMode == 0 ? currentUser?.uid : _mockUserId;
  String? get userEmail => testMode == 0 ? currentUser?.email : _mockUserEmail;
  String? get userName =>
      testMode == 0 ? currentUser?.displayName : _mockUserName;
  bool get isLoggedIn =>
      testMode == 0 ? currentUser != null : _mockUserId != null;

  // Firebase login
  Future<bool> verifyCredentials(String email, String password) async {
    _lastErrorMessage = '';

    if (testMode == 1) {
      _mockUserId = 'test-user-${DateTime.now().millisecondsSinceEpoch}';
      _mockUserEmail = email;
      _mockUserName = 'Test User';

      await Future.delayed(const Duration(milliseconds: 300));
      return true;
    }

    // Normal mode
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Small delay
      await Future.delayed(const Duration(milliseconds: 100));

      // Handle post-authentication
      await _handleSuccessfulAuth(userCredential);

      // Check if user profile exists in Firestore
      if (currentUser != null) {
        try {
          DocumentSnapshot doc =
              await _firestore.collection('users').doc(currentUser!.uid).get();
          if (!doc.exists) {
            // Create a basic profile if one doesn't exist
            await _firestore.collection('users').doc(currentUser!.uid).set({
              'name': userCredential.user?.displayName ?? 'User',
              'email': email,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        } catch (e) {
          print('Error checking/creating profile after login: $e');
        }
      }

      return currentUser != null;
    } on FirebaseAuthException catch (e) {
      _lastErrorMessage = _handleAuthException(e);
      return false;
    } catch (e) {
      _lastErrorMessage = 'Login failed. Please try again.';
      return false;
    }
  }

  // Handle successful authentication
  Future<void> _handleSuccessfulAuth(UserCredential credential) async {
    try {
      currentUser = credential.user;

      if (currentUser != null) {
        print('Null');
      }
    } catch (e) {
      print('Error in post-authentication: $e');
    }
  }

  // Register a new user
// Register a new user
Future<bool> registerUser(String email, String password,
    {required String name}) async {
  _lastErrorMessage = '';

  if (testMode == 1) {
    // Test mode
    _mockUserId = 'test-user-${DateTime.now().millisecondsSinceEpoch}';
    _mockUserEmail = email;
    _mockUserName = name;

    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  // Normal mode
  try {
    // Create the user
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Small delay
    await Future.delayed(const Duration(milliseconds: 100));

    // Update the current user
    currentUser = userCredential.user;

    // Store additional user data
    if (currentUser != null) {
      try {
        await _firestore.collection('users').doc(currentUser!.uid).set({
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Update display name in Firebase Auth
        await currentUser!.updateDisplayName(name);

        // Force refresh token to make sure display name is updated
        await currentUser!.reload();
        currentUser = _auth.currentUser;

        return true;
      } catch (firestoreError) {
        print('Error creating user profile: $firestoreError');
        _lastErrorMessage = 'Failed to create user profile.';
        // Still return true since the auth part succeeded
        return true;
      }
    }

    _lastErrorMessage = 'Failed to create user profile.';
    return false;
  } on FirebaseAuthException catch (e) {
    try {
      _lastErrorMessage = _handleAuthException(e);
    } catch (innerError) {
      _lastErrorMessage = 'Registration failed. Please try again.';
      print('Error handling auth exception: $innerError');
    }
    return false;
  } catch (e) {
    _lastErrorMessage = 'Registration failed: ${e.toString().substring(0, 100)}';
    print('Unexpected error during registration: $e');
    return false;
  }
}
  // Handle Firebase auth exceptions and return appropriate error message
// Handle Firebase auth exceptions and return appropriate error message
String _handleAuthException(FirebaseAuthException e) {
  String errorMessage;

  try {
    switch (e.code) {
      case 'user-not-found':
        errorMessage = 'No user found with this email address.';
        break;
      case 'wrong-password':
        errorMessage = 'Incorrect password. Please try again.';
        break;
      case 'email-already-in-use':
        errorMessage =
            'This email is already registered. Please log in or use a different email.';
        break;
      case 'weak-password':
        errorMessage =
            'Password is too weak. Please use at least 6 characters.';
        break;
      case 'invalid-email':
        errorMessage =
            'Invalid email format. Please enter a valid email address.';
        break;
      case 'user-disabled':
        errorMessage =
            'This account has been disabled. Please contact support.';
        break;
      case 'too-many-requests':
        errorMessage = 'Too many attempts. Please try again later.';
        break;
      case 'network-request-failed':
        errorMessage =
            'Network error. Please check your connection and try again.';
        break;
      default:
        errorMessage = 'Authentication error: ${e.message ?? e.code}';
    }
  } catch (innerError) {
    // Fallback if there's an error processing the exception
    errorMessage = 'Authentication failed. Please try again.';
    print('Error processing FirebaseAuthException: $innerError');
  }

  // You can log the error for debugging
  print('Firebase Auth Error: ${e.code} - $errorMessage');

  return errorMessage;
}
  // Sign out user
  Future<void> signOut() async {
    if (testMode == 1) {
      _mockUserId = null;
      _mockUserEmail = null;
      _mockUserName = null;
      return;
    }

    try {
      await _auth.signOut();
      currentUser = null;
    } catch (e) {
      print('Error during sign out: $e');
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _lastErrorMessage = '';

    if (testMode == 1) {
      await Future.delayed(const Duration(milliseconds: 300));
      return true;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      _lastErrorMessage =
          'Failed to send password reset email. Please try again.';
      return false;
    }
  }

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {

    if (testMode == 1) {
      if (_mockUserId != null) {
        await Future.delayed(const Duration(milliseconds: 200));
        return {
          'name': _mockUserName ?? 'Test User',
          'email': _mockUserEmail ?? 'test@example.com',
          'createdAt': DateTime.now(),
        };
      }
      return null;
    }

    if (currentUser != null) {
      try {
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(currentUser!.uid).get();

        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return data;
        } else {

          // If no document exists, create one from auth data
          Map<String, dynamic> fallbackProfile = {
            'name': currentUser!.displayName ?? 'User',
            'email': currentUser!.email ?? '',
            'createdAt': FieldValue.serverTimestamp(),
          };

          // Try to save profile
          try {
            await _firestore
                .collection('users')
                .doc(currentUser!.uid)
                .set(fallbackProfile);
          } catch (e) {
            print('Error creating fallback profile: $e');
          }

          return fallbackProfile;
        }
      } catch (e) {

        // Return basic profile from Auth data as fallback
        return {
          'name': currentUser!.displayName ?? 'User',
          'email': currentUser!.email ?? '',
        };
      }
    }
    return null;
  }

  // Update user profile
  Future<bool> updateUserProfile(Map<String, dynamic> data) async {
    if (testMode == 1) {
      if (_mockUserId != null) {

        // If name is being updated, update mock name
        if (data.containsKey('name')) {
          _mockUserName = data['name'];
        }

        // If email is being updated, update mock email
        if (data.containsKey('email')) {
          _mockUserEmail = data['email'];
        }

        await Future.delayed(const Duration(milliseconds: 300));
        return true;
      }
      return false;
    }

    // Normal mode
    if (currentUser != null) {
      try {

        // Check if document exists first
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(currentUser!.uid).get();

        if (doc.exists) {
          await _firestore
              .collection('users')
              .doc(currentUser!.uid)
              .update(data);
        } else {
          
          // Create the document if it doesn't exist
          Map<String, dynamic> fullData = {
            'email': currentUser!.email,
            'createdAt': FieldValue.serverTimestamp(),
            ...data
          };
          await _firestore
              .collection('users')
              .doc(currentUser!.uid)
              .set(fullData);
        }

        // If name is being updated, also update in Firebase Auth
        if (data.containsKey('name')) {
          await currentUser!.updateDisplayName(data['name']);

          // Force refresh to make sure the display name update takes effect
          await currentUser!.reload();
          currentUser = _auth.currentUser;
        }

        return true;
      } catch (e) {
        _lastErrorMessage = 'Failed to update profile. Please try again.';
        return false;
      }
    }
    _lastErrorMessage = 'You must be logged in to update your profile.';
    return false;
  }
}
