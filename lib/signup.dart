import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'email_verification_service.dart';
import 'login.dart'; // For EmailService

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isEmailValid = false;

  // Email validation function
  bool _isValidEmail(String email) {
    // Basic email format validation
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  void _onEmailChanged(String value) {
    setState(() {
      _isEmailValid = _isValidEmail(value.trim());
    });
  }

  Future<void> addUserToFirestore(User user) async {
    final userDoc = FirebaseFirestore.instance
        .collection('currentUser')
        .doc(user.uid);
    final userData = {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName ?? '',
      'photoURL': user.photoURL ?? '',
      'isEmailVerified': user.emailVerified,
      'createdAt': FieldValue.serverTimestamp(),
    };
    await userDoc.set(userData, SetOptions(merge: true));
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // Enhanced email validation before signup
        final email = _emailController.text.trim();
        if (!_isValidEmail(email)) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a valid email address'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Check if email is real and accessible
        final isEmailReal =
            await EmailVerificationService.isEmailRealAndAccessible(email);
        if (!isEmailReal) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a real and accessible email address'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: email,
              password: _passwordController.text,
            );

        // Send verification email
        await userCredential.user!.sendEmailVerification();

        // Update display name
        await userCredential.user!.updateDisplayName(
          _nameController.text.trim(),
        );

        await addUserToFirestore(userCredential.user!);

        // Send welcome email via EmailJS (works on both web and mobile)
        bool welcomeEmailSent = false;
        try {
          await EmailService.sendWelcomeEmail(
            recipientEmail: userCredential.user!.email!,
          );
          print(
            'Welcome email sent successfully to ${userCredential.user!.email}',
          );
          welcomeEmailSent = true;
        } catch (e) {
          print('Failed to send welcome email: $e');
          welcomeEmailSent = false;
        }

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MainScreen(showSuccess: true),
          ),
        );
      } on FirebaseAuthException catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Registration failed')),
        );
      }
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      print('Starting Google Sign-up process...');

      // Initialize GoogleSignIn with client ID only for web
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId:
            kIsWeb
                ? '455542611420-oor09omint210uorsentkh6mvv8te3sg.apps.googleusercontent.com'
                : null,
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        print('Google Sign-in was canceled by user');
        setState(() => _isLoading = false);
        return;
      }

      print('Google user obtained: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      print('Google authentication completed');

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      print(
        'Firebase authentication completed. User: ${userCredential.user?.email}',
      );

      if (userCredential.additionalUserInfo!.isNewUser) {
        await userCredential.user!.updateDisplayName(googleUser.displayName);
        print('Updated display name for new user');

        // Send welcome email for new Google users
        bool welcomeEmailSent = false;
        try {
          await EmailService.sendWelcomeEmail(
            recipientEmail: userCredential.user!.email!,
          );
          print(
            'Welcome email sent successfully to ${userCredential.user!.email}',
          );
          welcomeEmailSent = true;
        } catch (e) {
          print('Failed to send welcome email: $e');
          welcomeEmailSent = false;
        }
      }

      await addUserToFirestore(userCredential.user!);

      if (!mounted) {
        print('Widget not mounted, cannot navigate');
        return;
      }

      print('Navigating to MainScreen...');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MainScreen(showSuccess: true),
        ),
      );
      print('Navigation completed');
    } on PlatformException catch (e) {
      print('PlatformException: ${e.message}');
      setState(() => _isLoading = false);
      if (e.code != 'sign_in_canceled') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in failed: ${e.message}')),
        );
      }
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.message}');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authentication failed: ${e.message}')),
      );
    } catch (e) {
      print('Unexpected error: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Animation
          Positioned.fill(
            child: Lottie.asset(
              'assets/Login Background.json',
              fit: BoxFit.cover,
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Center(
                    child: Lottie.asset(
                      'assets/Icon Login.json',
                      height: 200,
                      width: 200,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: ShaderMask(
                      shaderCallback:
                          (bounds) => const LinearGradient(
                            colors: [Color(0xFF1E3A8A), Color(0xFFD4AF37)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: ShaderMask(
                      shaderCallback:
                          (bounds) => const LinearGradient(
                            colors: [Color(0xFF1E3A8A), Color(0xFFD4AF37)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                      child: const Text(
                        'Create an account to access all features',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Form Container
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(
                                Icons.person,
                                color: Color(0xFF1E3A8A),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                                borderSide: BorderSide(
                                  color: Color(0xFF1E3A8A),
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: const Icon(
                                Icons.email,
                                color: Color(0xFF1E3A8A),
                              ),
                              suffixIcon:
                                  _emailController.text.isNotEmpty
                                      ? Icon(
                                        _isEmailValid
                                            ? Icons.check_circle
                                            : Icons.error,
                                        color:
                                            _isEmailValid
                                                ? Colors.green
                                                : Color(0xFF1E3A8A),
                                      )
                                      : null,
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                                borderSide: BorderSide(
                                  color: Color(0xFF1E3A8A),
                                  width: 2,
                                ),
                              ),
                            ),
                            onChanged: _onEmailChanged,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email address';
                              }
                              if (!_isValidEmail(value.trim())) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(
                                Icons.lock,
                                color: Color(0xFF1E3A8A),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed:
                                    () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                              ),
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                                borderSide: BorderSide(
                                  color: Color(0xFF1E3A8A),
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: const Icon(
                                Icons.lock,
                                color: Color(0xFF1E3A8A),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed:
                                    () => setState(
                                      () =>
                                          _obscureConfirmPassword =
                                              !_obscureConfirmPassword,
                                    ),
                              ),
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                                borderSide: BorderSide(
                                  color: Color(0xFF1E3A8A),
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3A8A),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                              child:
                                  _isLoading
                                      ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                      : const Text(
                                        'Create Account',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Text(
                                  'or sign up with',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 30),
                          Center(
                            child: IconButton(
                              onPressed: _isLoading ? null : _signUpWithGoogle,
                              icon: Container(
                                height: 50,
                                width: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Lottie.asset(
                                  'assets/google.json',
                                  height: 30,
                                  width: 30,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Already have an account?",
                                style: TextStyle(color: Colors.grey),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    color: Color(0xFF1E3A8A),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
