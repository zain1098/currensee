class EmailService {
  static Future<void> sendContactEmail({
    required String name,
    required String email,
    required String message,
    String? subject,
  }) async {
    print('Email sent: ${subject ?? 'Contact Form'} from $email');
  }
}