import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart'; // For EmailService

class ContactFormScreen extends StatefulWidget {
  const ContactFormScreen({super.key});

  @override
  _ContactFormScreenState createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends State<ContactFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Contact Support',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1E3A8A).withOpacity(0.1),
                    const Color(0xFF3B82F6).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF1E3A8A).withOpacity(0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueGrey.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.contact_support,
                    size: 60,
                    color: const Color(0xFF1E3A8A),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Contact Our Support Team',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'We\'re here to help! Send us a message and we\'ll get back to you as soon as possible.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Contact Form
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E293B)
                        : Colors.grey[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade700
                          : Colors.grey.shade200,
                ),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Send us a Message',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Your Name',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _messageController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: 'Your Message',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your message';
                        }
                        if (value.length < 15) {
                          return 'Please provide more details (at least 15 characters)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            _isSubmitting
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Text(
                                  'Send Message',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      try {
        // 1. Save to Firestore (always)
        await FirebaseFirestore.instance.collection('support_queries').add({
          'name': _nameController.text,
          'email': _emailController.text,
          'message': _messageController.text,
          'timestamp': Timestamp.now(),
          'status': 'new',
        });

        // 2. Send email via EmailJS
        bool emailSent = false;

        // Show sending message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text('Sending your message...'),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );

        try {
          await EmailService.sendContactEmail(
            name: _nameController.text,
            email: _emailController.text,
            message: _messageController.text,
          );
          print('Contact email sent successfully to festoeventure@gmail.com');
          emailSent = true;
        } catch (e) {
          print('Failed to send contact email: $e');
          emailSent = false;
        }

        // Show appropriate message based on email success
        if (emailSent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Message sent successfully! We\'ll get back to you soon.',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Message saved! Email delivery failed, but we\'ll still review your request.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }

        _nameController.clear();
        _emailController.clear();
        _messageController.clear();
      } catch (e) {
        debugPrint('Full error details: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      } finally {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
