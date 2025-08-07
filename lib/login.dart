import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emailjs/emailjs.dart';
import 'package:http/http.dart' as http;
import 'email_verification_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class EmailService {
  static const String _serviceId = 'service_ih5ns2r';
  static const String _welcomeTemplateId = 'template_v08t4va';
  static const String _contactTemplateId = 'template_dxxjw09';
  static const String _userId = 'AvgkUbQFSsE27b003';
  static const String _accessToken = 'MI_orvD-Qi96ykAmp3zIF';

  // Add initialization in EmailService class

  static Future<void> sendWelcomeEmail({required String recipientEmail}) async {
    try {
      if (recipientEmail.isEmpty || !recipientEmail.contains('@')) {
        throw Exception('Invalid recipient email: $recipientEmail');
      }

      // Enhanced HTML email template with better design
      final htmlContent = '''
      <!DOCTYPE html>
      <html>
      <head>
        <title>Welcome to CurrenSee Pro!</title>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
          body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f8f9fa;
          }
          .container {
            background-color: #ffffff;
            border-radius: 15px;
            overflow: hidden;
            box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
          }
          .header {
            background: linear-gradient(135deg, #1E3A8A 0%, #D4AF37 100%);
            padding: 40px 20px;
            text-align: center;
          }
          .logo {
            font-size: 36px;
            font-weight: bold;
            color: white;
            text-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
            letter-spacing: 1.5px;
            margin-bottom: 10px;
          }
          .subtitle {
            color: rgba(255, 255, 255, 0.9);
            font-size: 16px;
            font-weight: 300;
          }
          .content {
            padding: 40px 30px;
          }
          h1 {
            color: #1E3A8A;
            margin-top: 0;
            font-size: 28px;
            font-weight: bold;
          }
          .welcome-text {
            font-size: 18px;
            color: #4a5568;
            margin-bottom: 25px;
          }
          .features {
            margin: 30px 0;
            padding-left: 25px;
          }
          .features li {
            margin-bottom: 15px;
            font-size: 16px;
            color: #2d3748;
            position: relative;
          }
          .features li:before {
            content: "✓";
            color: #10B981;
            font-weight: bold;
            position: absolute;
            left: -20px;
          }
          .cta-section {
            text-align: center;
            margin: 35px 0;
            padding: 25px;
            background: linear-gradient(135deg, #f7fafc 0%, #edf2f7 100%);
            border-radius: 12px;
            border: 1px solid #e2e8f0;
          }
          .cta-button {
            display: inline-block;
            background: linear-gradient(to right, #1E3A8A, #3b5998);
            color: white !important;
            text-decoration: none;
            padding: 15px 35px;
            border-radius: 30px;
            font-weight: bold;
            font-size: 16px;
            margin: 20px 0;
            text-align: center;
            transition: transform 0.3s, box-shadow 0.3s;
            box-shadow: 0 4px 15px rgba(30, 58, 138, 0.3);
          }
          .cta-button:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(30, 58, 138, 0.4);
          }
          .footer {
            text-align: center;
            padding: 30px 20px;
            color: #6c757d;
            font-size: 14px;
            border-top: 1px solid #eaeaea;
            background-color: #f8f9fa;
          }
          .social-links {
            margin: 15px 0;
          }
          .social-links a {
            color: #1E3A8A;
            text-decoration: none;
            margin: 0 10px;
            font-weight: 500;
          }
          .social-links a:hover {
            text-decoration: underline;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <div class="logo">CurrenSee Pro</div>
            <div class="subtitle">Your Ultimate Currency Companion</div>
          </div>
          
          <div class="content">
            <h1>🎉 Welcome Aboard!</h1>
            <p class="welcome-text">Hi there,</p>
            
            <p class="welcome-text">We're absolutely thrilled to welcome you to <strong>CurrenSee Pro</strong>! You've just joined thousands of smart travelers, investors, and global citizens who trust us for their currency conversion needs.</p>
            
            <p class="welcome-text">Here's what you can do with CurrenSee Pro:</p>
            <ul class="features">
              <li>Get real-time exchange rates for 150+ currencies worldwide</li>
              <li>Track historical currency performance with interactive charts</li>
              <li>Set personalized currency alerts for your target rates</li>
              <li>Access offline conversion capabilities when traveling</li>
              <li>Enjoy zero fees and no hidden charges ever</li>
              <li>Chat with our AI assistant for instant currency help</li>
            </ul>
            
            <div class="cta-section">
              <p style="font-size: 18px; font-weight: 600; color: #1E3A8A; margin-bottom: 20px;">Ready to start converting?</p>
              <a href="https://www.currenseepro.com/app" class="cta-button">
                🚀 Launch the App
              </a>
            </div>
            
            <p style="font-size: 16px; color: #4a5568; margin-top: 30px;">
              Need help getting started? Our support team is here for you 24/7. 
              Just reply to this email or visit our <a href="https://www.currenseepro.com/support" style="color: #1E3A8A; font-weight: 600;">support center</a>.
            </p>
            
            <p style="font-size: 16px; color: #4a5568; margin-top: 20px;">
              Happy converting!<br>
              <strong>The CurrenSee Pro Team</strong> 💙
            </p>
          </div>
          
          <div class="footer">
            <p style="margin-bottom: 10px;"><strong>CurrenSee Pro</strong></p>
            <p style="margin-bottom: 15px;">Your trusted partner for global currency conversion</p>
            <div class="social-links">
              <a href="https://www.currenseepro.com">Website</a> | 
              <a href="https://twitter.com/currenseepro">Twitter</a> | 
              <a href="https://facebook.com/currenseepro">Facebook</a>
            </div>
            <p style="margin-top: 15px; font-size: 12px; color: #9ca3af;">
              © 2025 CurrenSee Pro. All rights reserved.<br>
              <a href="https://www.currenseepro.com/unsubscribe" style="color: #9ca3af;">Unsubscribe</a>
            </p>
          </div>
        </div>
      </body>
      </html>
      ''';

      // Try EmailJS first
      try {
        final response = await EmailJS.send(_serviceId, _welcomeTemplateId, {
          'to_email': recipientEmail,
          'from_name': 'CurrenSee Pro Team',
          'reply_to': 'festoeventure@gmail.com',
          'message':
              'Welcome to CurrenSee Pro! We\'re excited to have you on board.',
          'html_body': htmlContent,
          'year': DateTime.now().year.toString(),
        }, Options(publicKey: _userId));

        if (kDebugMode) {
          print('EmailJS response status: ${response.status}');
          print('Welcome email sent to $recipientEmail');
        }

        if (response.status != 200) {
          throw Exception('Failed to send email: ${response.text}');
        }

        return; // Success, exit early
      } catch (emailjsError) {
        if (kDebugMode) {
          print('EmailJS failed, trying fallback: $emailjsError');
        }
        // Continue to fallback method
      }

      // Fallback: Try direct HTTP API call
      try {
        final response = await http.post(
          Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'service_id': _serviceId,
            'template_id': _welcomeTemplateId,
            'user_id': _userId,
            'accessToken': _accessToken,
            'template_params': {
              'to_email': recipientEmail,
              'from_name': 'CurrenSee Pro Team',
              'reply_to': 'festoeventure@gmail.com',
              'message':
                  'Welcome to CurrenSee Pro! We\'re excited to have you on board.',
              'html_body': htmlContent,
              'year': DateTime.now().year.toString(),
            },
          }),
        );

        if (kDebugMode) {
          print('HTTP API response status: ${response.statusCode}');
          print('HTTP API response body: ${response.body}');
        }

        if (response.statusCode != 200) {
          throw Exception(
            'HTTP API failed: ${response.statusCode} - ${response.body}',
          );
        }

        return; // Success, exit early
      } catch (httpError) {
        if (kDebugMode) {
          print('HTTP API also failed: $httpError');
        }
        // Continue to final error handling
      }

      // If both methods failed, throw the original error
      throw Exception('All email sending methods failed');
    } catch (error) {
      if (kDebugMode) {
        print('Failed to send welcome email: $error');
      }
      rethrow;
    }
  }

  static Future<void> sendContactEmail({
    required String name,
    required String email,
    required String message,
  }) async {
    try {
      // Create a more detailed email template for contact form
      final htmlContent = '''
      <!DOCTYPE html>
      <html>
      <head>
        <title>New Support Request - CurrenSee Pro</title>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
          body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f8f9fa;
          }
          .container {
            background-color: #ffffff;
            border-radius: 10px;
            overflow: hidden;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
          }
          .header {
            background: linear-gradient(135deg, #1E3A8A 0%, #D4AF37 100%);
            padding: 30px 20px;
            text-align: center;
          }
          .logo {
            font-size: 32px;
            font-weight: bold;
            color: white;
            text-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
            letter-spacing: 1px;
          }
          .content {
            padding: 30px;
          }
          h1 {
            color: #1E3A8A;
            margin-top: 0;
          }
          .message-box {
            background-color: #f8f9fa;
            border-left: 4px solid #1E3A8A;
            padding: 15px;
            margin: 20px 0;
            border-radius: 0 8px 8px 0;
          }
          .detail-row {
            margin-bottom: 15px;
            padding-bottom: 15px;
            border-bottom: 1px solid #e2e8f0;
          }
          .detail-label {
            font-weight: bold;
            color: #1E3A8A;
            display: block;
            margin-bottom: 5px;
          }
          .footer {
            text-align: center;
            padding: 20px;
            color: #6c757d;
            font-size: 14px;
            border-top: 1px solid #eaeaea;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <div class="logo">CurrenSee Pro</div>
          </div>
          
          <div class="content">
            <h1>New Support Request</h1>
            <p>You've received a new support request from your currency converter app.</p>
            
            <div class="detail-row">
              <span class="detail-label">From:</span>
              <span>$name ($email)</span>
            </div>

            <div class="detail-row">
              <span class="detail-label">Received at:</span>
              <span>${DateTime.now().toString()}</span>
            </div>

            <div class="message-box">
              <span class="detail-label">Message:</span>
              <p>$message</p>
            </div>
          </div>
          
          <div class="footer">
            <p>This is an automated message from your app's support system.</p>
            <p>© ${DateTime.now().year} CurrenSee Pro. All rights reserved.</p>
          </div>
        </div>
      </body>
      </html>
      ''';

      // Try EmailJS first
      try {
        final response = await EmailJS.send(_serviceId, _contactTemplateId, {
          'name': name,
          'email': email,
          'message': message,
          'to_email': 'festoeventure@gmail.com',
          'reply_to': email,
          'html_body': htmlContent,
          'year': DateTime.now().year.toString(),
        }, Options(publicKey: _userId));

        if (kDebugMode) {
          print('EmailJS response status: ${response.status}');
          print('Contact email sent from $email');
        }

        if (response.status != 200) {
          throw Exception('Failed to send email: ${response.text}');
        }

        return; // Success, exit early
      } catch (emailjsError) {
        if (kDebugMode) {
          print('EmailJS failed, trying fallback: $emailjsError');
        }
        // Continue to fallback method
      }

      // Fallback: Try direct HTTP API call
      try {
        final response = await http.post(
          Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'service_id': _serviceId,
            'template_id': _contactTemplateId,
            'user_id': _userId,
            'accessToken': _accessToken,
            'template_params': {
              'name': name,
              'email': email,
              'message': message,
              'to_email': 'festoeventure@gmail.com',
              'reply_to': email,
              'html_body': htmlContent,
              'year': DateTime.now().year.toString(),
            },
          }),
        );

        if (kDebugMode) {
          print('HTTP API response status: ${response.statusCode}');
          print('HTTP API response body: ${response.body}');
        }

        if (response.statusCode != 200) {
          throw Exception(
            'HTTP API failed: ${response.statusCode} - ${response.body}',
          );
        }

        return; // Success, exit early
      } catch (httpError) {
        if (kDebugMode) {
          print('HTTP API also failed: $httpError');
        }
        // Continue to final error handling
      }

      // If both methods failed, throw the original error
      throw Exception('All email sending methods failed');
    } catch (error) {
      if (kDebugMode) {
        print('Failed to send contact email: $error');
      }
      rethrow;
    }
  }
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
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

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // Enhanced email validation before signin
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

        final userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: email,
              password: _passwordController.text,
            );

        // Check if this is a new user
        final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

        await addUserToFirestore(userCredential.user!);

        // Send welcome email for new users
        if (isNewUser) {
          final userEmail = userCredential.user?.email;
          if (userEmail != null &&
              userEmail.isNotEmpty &&
              userEmail.contains('@')) {
            bool welcomeEmailSent = false;
            try {
              await EmailService.sendWelcomeEmail(recipientEmail: userEmail);
              print('Welcome email sent successfully to $userEmail');
              welcomeEmailSent = true;
            } catch (e) {
              print('Welcome email failed: $e');
              welcomeEmailSent = false;
            }
          }
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
          SnackBar(content: Text(e.message ?? 'Authentication failed')),
        );
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      print('Starting Google Sign-in process...');
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId:
            kIsWeb
                ? '455542611420-oor09omint210uorsentkh6mvv8te3sg.apps.googleusercontent.com'
                : null,
        scopes: ['email', 'profile'],
      );
      await googleSignIn.signOut();
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

      final isNewUser = userCredential.additionalUserInfo!.isNewUser;

      if (isNewUser) {
        await userCredential.user!.updateDisplayName(googleUser.displayName);
        print('Updated display name for new user');

        // Send welcome email for new Google sign-in users
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
          SnackBar(
            content: Text('Google sign-in failed: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.message}');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Authentication failed: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      print('Unexpected error: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
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
                  const SizedBox(height: 30),
                  Center(
                    child: Lottie.asset(
                      'assets/Icon Login.json',
                      height: 170,
                      width: 170,
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
                        'Welcome',
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
                        'Sign in to continue to CurrenSee Pro',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(
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
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed:
                                  () => Navigator.pushNamed(context, '/forgot'),
                              child: const Text('Forgot Password?'),
                            ),
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _signIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
                                      'Sign In',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
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
                                  'or continue with',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 30),
                          Center(
                            child: IconButton(
                              onPressed: _isLoading ? null : _signInWithGoogle,
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
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Don't have an account?"),
                              TextButton(
                                onPressed:
                                    () =>
                                        Navigator.pushNamed(context, '/signup'),
                                child: const Text('Sign Up'),
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
