import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'email_verification_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;
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

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      setState(() {
        _isLoading = true;
        _emailSent = false;
        _errorMessage = null;
      });

      try {
        // Enhanced validation before sending email
        final email = _emailController.text.trim();
        if (!_isValidEmail(email)) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Please enter a valid email address';
          });
          return;
        }

        // Check if email is real and accessible
        final isEmailReal =
            await EmailVerificationService.isEmailRealAndAccessible(email);
        if (!isEmailReal) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Please enter a real and accessible email address';
          });
          return;
        }

        // Check if user exists in database and their status
        try {
          // First check in Firebase Auth
          final userQuery = await FirebaseAuth.instance
              .fetchSignInMethodsForEmail(email);
          if (userQuery.isEmpty) {
            setState(() {
              _isLoading = false;
              _errorMessage =
                  'No account found with this email address. Please sign up first.';
            });
            return;
          }

          // Additional check in Firestore for extra security and status
          final userDoc =
              await FirebaseFirestore.instance
                  .collection('currentUser')
                  .where('email', isEqualTo: email)
                  .get();

          if (userDoc.docs.isEmpty) {
            setState(() {
              _isLoading = false;
              _errorMessage =
                  'Account not found. Please sign up first or contact support.';
            });
            return;
          }

          // Check user status
          final userData = userDoc.docs.first.data();
          final status =
              userData['status'] ??
              'active'; // Default to active for existing users

          if (status == 'blocked') {
            setState(() {
              _isLoading = false;
              _errorMessage =
                  'Your account has been temporarily blocked by the CurrenSee Team. Please contact support for assistance.';
            });
            return;
          }

          print('User found in database: ${userDoc.docs.first.data()}');
        } catch (e) {
          print('Error checking user existence: $e');
          setState(() {
            _isLoading = false;
            _errorMessage = 'Error checking account. Please try again.';
          });
          return;
        }

        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

        setState(() {
          _isLoading = false;
          _emailSent = true;
        });
      } on FirebaseAuthException catch (e) {
        String message;
        switch (e.code) {
          case 'user-not-found':
            message = 'No account found for this email address';
            break;
          case 'invalid-email':
            message = 'Please enter a valid email address';
            break;
          case 'too-many-requests':
            message = 'Too many requests. Please try again later';
            break;
          case 'network-request-failed':
            message = 'Network error. Please check your internet connection';
            break;
          default:
            message = 'An error occurred. Please try again';
        }
        setState(() {
          _isLoading = false;
          _errorMessage = message;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An unexpected error occurred. Please try again';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            // Background Animation
            Positioned.fill(
              child: Lottie.asset(
                'assets/Login Background.json',
                height: 200,
                width: 200,
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
                        height: 150,
                        width: 150,
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
                        child: Text(
                          _emailSent ? 'Check Your Email' : 'Forgot Password',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ShaderMask(
                        shaderCallback:
                            (bounds) => const LinearGradient(
                              colors: [Color(0xFF1E3A8A), Color(0xFFD4AF37)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            _emailSent
                                ? 'We have sent password reset instructions to your email'
                                : 'Enter your email and we will send you a password reset link',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 24,
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 40),
                    // Form Container
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.98),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child:
                          _emailSent
                              ? Column(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    size: 80,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(height: 30),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF1E3A8A,
                                        ),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 3,
                                      ),
                                      child: const Text(
                                        'Back to Sign In',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                              : Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      style: const TextStyle(color: Colors.black87),
                                      decoration: InputDecoration(
                                        labelText: 'Email',
                                        labelStyle: const TextStyle(color: Colors.black54),
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
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: const OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(12),
                                          ),
                                          borderSide: BorderSide(color: Colors.grey),
                                        ),
                                        enabledBorder: const OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(12),
                                          ),
                                          borderSide: BorderSide(color: Colors.grey),
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
                                        errorBorder: const OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(12),
                                          ),
                                          borderSide: BorderSide(color: Colors.red),
                                        ),
                                        focusedErrorBorder: const OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(12),
                                          ),
                                          borderSide: BorderSide(color: Colors.red, width: 2),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your email address';
                                        }
                                        if (!_isValidEmail(value.trim())) {
                                          return 'Please enter a valid email address';
                                        }
                                        return null;
                                      },
                                      onChanged: _onEmailChanged,
                                    ),
                                    const SizedBox(height: 30),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed:
                                            _isLoading ? null : _resetPassword,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF1E3A8A,
                                          ),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          elevation: 3,
                                        ),
                                        child:
                                            _isLoading
                                                ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                )
                                                : const Text(
                                                  'Reset Password',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                      ),
                                    ),
                                    const SizedBox(height: 30),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text(
                                        'Remembered your password? Sign In',
                                        style: TextStyle(
                                          color: Color(0xFF1E3A8A),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
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
      ),
    );
  }
}
