import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../contact_form_screen.dart';

class UserStatusService {
  static StreamSubscription<DocumentSnapshot>? _statusSubscription;
  static bool _isInitialized = false;

  // Initialize real-time status monitoring
  static void initializeStatusMonitoring(BuildContext context) {
    if (_isInitialized) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _statusSubscription = FirebaseFirestore.instance
        .collection('currentUser')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            final userData = snapshot.data();
            final status = userData?['status'] ?? 'active';

            if (status == 'blocked') {
              _handleUserBlocked(context);
            }
          }
        });

    _isInitialized = true;
  }

  // Handle user blocking
  static void _handleUserBlocked(BuildContext context) async {
    // Sign out the user
    await FirebaseAuth.instance.signOut();

    // Show blocked dialog
    if (context.mounted) {
      _showBlockedUserDialog(context);
    }
  }

  // Show blocked user dialog
  static void _showBlockedUserDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E3A8A), Color(0xFFD4AF37)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(Icons.block, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Account Blocked',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'The CurrenSee Team has temporarily blocked your account for security reasons.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Text(
                  'You have been logged out. If you believe this is an error, please contact our support team.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ContactFormScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1E3A8A),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Contact Support',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Dispose the subscription
  static void dispose() {
    _statusSubscription?.cancel();
    _statusSubscription = null;
    _isInitialized = false;
  }

  // Check if user is currently blocked
  static Future<bool> isUserBlocked(String uid) async {
    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('currentUser')
              .doc(uid)
              .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final status = userData?['status'] ?? 'active';
        return status == 'blocked';
      }
      return false;
    } catch (e) {
      print('Error checking user blocked status: $e');
      return false;
    }
  }
}
