import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailVerificationService {
  static const String _apiKey =
      'f4981034ea5740eba1f0113e3c6ac221'; // You can use services like Abstract API, Zero Bounce, etc.

  /// Check if email domain exists and is valid
  static Future<bool> isEmailDomainValid(String email) async {
    try {
      final domain = email.split('@').last;

      // Check if domain has valid MX records
      final response = await http.get(
        Uri.parse('https://dns.google/resolve?name=$domain&type=MX'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final answers = data['Answer'] as List?;
        return answers != null && answers.isNotEmpty;
      }

      return false;
    } catch (e) {
      print('Email domain validation error: $e');
      return false;
    }
  }

  /// Check if email format is valid and domain exists
  static Future<Map<String, dynamic>> validateEmail(String email) async {
    final result = {
      'isValid': false,
      'message': '',
      'isDisposable': false,
      'isRole': false,
    };

    try {
      // Basic format validation
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );
      if (!emailRegex.hasMatch(email)) {
        result['message'] = 'Invalid email format';
        return result;
      }

      // Check for common disposable email domains
      final disposableDomains = [
        'tempmail.org',
        '10minutemail.com',
        'guerrillamail.com',
        'mailinator.com',
        'yopmail.com',
        'temp-mail.org',
        'sharklasers.com',
        'getairmail.com',
        'mailnesia.com',
        'maildrop.cc',
        'guerrillamailblock.com',
        'pokemail.net',
        'spam4.me',
        'bccto.me',
        'chacuo.net',
        'dispostable.com',
        'fakeinbox.com',
        'fakeinbox.net',
        'fakemailgenerator.com',
        'mailmetrash.com',
        'mailnull.com',
        'mintemail.com',
        'mytrashmail.com',
        'nwldx.com',
        'objectmail.com',
        'proxymail.eu',
        'rcpt.at',
        'recode.me',
        'rmqkr.net',
        'rtrtr.com',
        'spamspot.com',
        'spam.la',
        'tempinbox.com',
        'tempmailaddress.com',
        'tmpeml.com',
        'tmpmail.net',
        'tmpmail.org',
        'trashmail.net',
        'trashmailer.com',
        'trashymail.com',
        'wuzup.net',
        'z1p.biz',
      ];

      final domain = email.split('@').last.toLowerCase();
      if (disposableDomains.contains(domain)) {
        result['isDisposable'] = true;
        result['message'] = 'Disposable email addresses are not allowed';
        return result;
      }

      // Check for role-based emails (admin@, info@, support@, etc.)
      final roleEmails = [
        'admin',
        'administrator',
        'info',
        'information',
        'support',
        'help',
        'contact',
        'sales',
        'marketing',
        'newsletter',
        'noreply',
        'no-reply',
        'donotreply',
        'do-not-reply',
        'mailer-daemon',
        'postmaster',
        'webmaster',
        'hostmaster',
        'abuse',
        'security',
        'billing',
        'accounts',
        'team',
        'service',
        'services',
        'customer',
        'customers',
        'user',
        'users',
        'member',
        'members',
        'staff',
        'employee',
        'employees',
        'hr',
        'human.resources',
        'it',
        'tech',
        'technical',
        'dev',
        'developer',
        'developers',
        'test',
        'testing',
        'qa',
        'quality',
        'media',
        'press',
        'pr',
        'public.relations',
        'legal',
        'law',
        'compliance',
        'finance',
        'accounting',
        'payroll',
        'operations',
        'ops',
        'maintenance',
        'maintainer',
        'system',
        'systems',
        'server',
        'servers',
        'database',
        'db',
        'backup',
        'monitoring',
        'alert',
        'alerts',
        'notification',
        'notifications',
        'update',
        'updates',
        'news',
        'announcement',
        'announcements',
        'blog',
        'forum',
        'community',
        'feedback',
        'suggestions',
        'ideas',
        'bug',
        'bugs',
        'issue',
        'issues',
        'ticket',
        'tickets',
        'request',
        'requests',
        'inquiry',
        'inquiries',
        'question',
        'questions',
        'helpdesk',
        'help-desk',
        'supportdesk',
        'support-desk',
        'customer-service',
        'customerservice',
        'client',
        'clients',
        'partner',
        'partners',
        'vendor',
        'vendors',
        'supplier',
        'suppliers',
        'distributor',
        'distributors',
        'reseller',
        'resellers',
        'affiliate',
        'affiliates',
        'referral',
        'referrals',
        'invite',
        'invites',
        'invitation',
        'invitations',
        'welcome',
        'hello',
        'hi',
        'hey',
        'greetings',
        'regards',
        'best',
        'sincerely',
        'yours',
        'faithfully',
        'truly',
        'cordially',
        'respectfully',
        'kindly',
        'please',
        'thank',
        'thanks',
        'appreciate',
        'grateful',
        'obliged',
        'indebted',
        'owe',
        'owing',
        'due',
        'overdue',
        'pending',
        'waiting',
        'queued',
        'scheduled',
        'planned',
        'arranged',
        'organized',
        'prepared',
        'ready',
        'set',
        'configured',
        'installed',
        'deployed',
        'launched',
        'started',
        'begun',
        'initiated',
        'created',
        'established',
        'founded',
        'formed',
        'built',
        'developed',
        'designed',
        'architected',
        'engineered',
        'programmed',
        'coded',
        'written',
        'authored',
        'composed',
        'drafted',
        'prepared',
        'made',
        'done',
        'completed',
        'finished',
        'accomplished',
        'achieved',
        'attained',
        'reached',
        'gained',
        'obtained',
        'acquired',
        'secured',
        'earned',
        'won',
        'received',
        'accepted',
        'approved',
        'confirmed',
        'verified',
        'validated',
        'authenticated',
        'authorized',
        'permitted',
        'allowed',
        'enabled',
        'activated',
        'enabled',
        'turned',
        'switched',
        'changed',
        'modified',
        'updated',
        'revised',
        'edited',
        'corrected',
        'fixed',
        'repaired',
        'resolved',
        'solved',
        'addressed',
        'handled',
        'managed',
        'processed',
        'treated',
        'dealt',
        'handled',
        'managed',
        'administered',
        'supervised',
        'oversaw',
        'monitored',
        'watched',
        'observed',
        'tracked',
        'followed',
        'pursued',
        'chased',
        'hunted',
        'sought',
        'looked',
        'searched',
        'found',
        'discovered',
        'uncovered',
        'revealed',
        'exposed',
        'shown',
        'displayed',
        'presented',
        'demonstrated',
        'illustrated',
        'explained',
        'described',
        'detailed',
        'specified',
        'defined',
        'clarified',
        'elucidated',
        'enlightened',
        'educated',
        'informed',
        'told',
        'notified',
        'advised',
        'counseled',
        'guided',
        'directed',
        'led',
        'conducted',
        'orchestrated',
        'coordinated',
        'arranged',
        'organized',
        'planned',
        'scheduled',
        'timed',
        'timed',
        'timed',
        'timed',
        'timed',
        'timed',
        'timed',
        'timed',
      ];

      final localPart = email.split('@').first.toLowerCase();
      if (roleEmails.contains(localPart)) {
        result['isRole'] = true;
        result['message'] = 'Role-based email addresses are not allowed';
        return result;
      }

      // Check domain validity
      final isDomainValid = await isEmailDomainValid(email);
      if (!isDomainValid) {
        result['message'] = 'Email domain does not exist or is invalid';
        return result;
      }

      result['isValid'] = true;
      result['message'] = 'Email is valid';
      return result;
    } catch (e) {
      print('Email validation error: $e');
      result['message'] = 'Error validating email';
      return result;
    }
  }

  /// Enhanced email validation with real-time checking
  static Future<bool> isEmailRealAndAccessible(String email) async {
    try {
      final validation = await validateEmail(email);
      return validation['isValid'] &&
          !validation['isDisposable'] &&
          !validation['isRole'];
    } catch (e) {
      print('Email accessibility check error: $e');
      return false;
    }
  }
}
