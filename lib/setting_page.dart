import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'main.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:share_plus/share_plus.dart';
import 'support_help_screen.dart';
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'services/connectivity_service.dart';
import 'services/currency_service.dart';
import 'services/alert_history_service.dart';
import 'services/version_history_service.dart';
import 'services/firestore_index_service.dart';
import 'services/task_service.dart';
import 'services/app_version_service.dart';
import 'app_theme.dart';

// Add ShineText widget for animated gradient text
class ShineText extends StatefulWidget {
  final String text;
  final TextStyle textStyle;
  const ShineText({super.key, required this.text, required this.textStyle});

  @override
  State<ShineText> createState() => _ShineTextState();
}

class _ShineTextState extends State<ShineText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _alignAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _alignAnimation = Tween<Alignment>(
      begin: const Alignment(-1.5, 0),
      end: const Alignment(1.5, 0),
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                Colors.white,
                const Color(0xFFD4AF37),
                Colors.white,
                const Color(0xFFD4AF37),
                Colors.white,
              ],
              stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
              begin: _alignAnimation.value,
              end: _alignAnimation.value + const Alignment(0.3, 0),
            ).createShader(bounds);
          },
          child: Text(widget.text, style: widget.textStyle),
        );
      },
    );
  }
}

class SettingsPage extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final Function(int) onDecimalChanged;
  final Function(String) onBaseCurrencyChanged;
  final Function(bool) onAutoUpdateChanged;
  final Function(bool) onBiometricChanged;
  final Function(bool) onVibrationChanged;
  final Function(bool) onCalculatorChanged;

  const SettingsPage({
    super.key,
    required this.onThemeChanged,
    required this.onDecimalChanged,
    required this.onBaseCurrencyChanged,
    required this.onAutoUpdateChanged,
    required this.onBiometricChanged,
    required this.onVibrationChanged,
    required this.onCalculatorChanged,
  });

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImage = false;
  bool _darkMode = false;
  int _decimalPlaces = 2;
  String _baseCurrency = 'USD';
  bool _autoUpdateRates = true;
  bool _biometricAuth = false;
  bool _hapticFeedback = true;
  bool _showCalculator = true;
  bool _historicalData = false;
  bool _offlineMode = false;
  String _selectedLanguage = 'English';
  String _selectedAppearance = 'System';
  String _notificationSound = ''; // Default sound (set in _loadAvailableSounds)
  List<String> _availableSounds = [];
  AudioPlayer? _audioPlayer; // For sound preview
  String? _playingSound;

  // User profile variables
  String _userName = '';
  String _userEmail = '';
  String _userPhotoUrl = '';
  bool _isEditingProfile = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isUpdatingPassword = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // Version update variables
  Map<String, dynamic>? _currentAppVersion;
  Map<String, dynamic>? _latestAppVersion;
  bool _isUpdateAvailable = false;
  bool _isCheckingUpdate = false;
  List<Map<String, dynamic>> _updateNotifications = [];
  DateTime? _lastCheckTime;

  // Favorite currencies variables
  List<Currency> _allCurrencies = [];
  List<Currency> _favoriteCurrencies = [];
  bool _isLoadingCurrencies = false;

  final List<String> _languages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Hindi',
    'Arabic',
  ];
  final List<String> _appearanceOptions = ['System', 'Light', 'Dark'];
  final List<String> _currencies = [
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'INR',
    'PKR',
    'CAD',
    'AUD',
  ];

  // Lottie animation composition
  late Future<LottieComposition> _animationComposition;
  List<Map<String, dynamic>> _notificationHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadUserProfile();
    _animationComposition = _loadAnimation();
    _loadNotificationHistory();
    _loadAvailableSounds();
    _clearOldDefaultPairsOnLoad();
    _loadCurrentAppVersion();
    _loadUpdateNotifications();
    _loadCurrencies();

    // Auto-check for updates after a short delay to ensure UI is ready
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _checkForAppUpdate();
      }
    });

    // Start periodic version check
    _startPeriodicVersionCheck();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh user profile when page is accessed
    _loadUserProfile();
  }

  @override
  void dispose() {
    // Cancel any ongoing timers when widget is disposed
    super.dispose();
  }

  Future<LottieComposition> _loadAnimation() async {
    var assetData = await rootBundle.load('assets/user-profile.json');
    return await LottieComposition.fromByteData(assetData);
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('currentUser')
                .doc(user.uid)
                .get();

        setState(() {
          _userName = userDoc.data()?['displayName'] ?? user.displayName ?? '';
          _userEmail = user.email ?? '';
          _userPhotoUrl = userDoc.data()?['photoURL'] ?? user.photoURL ?? '';
          _nameController.text = _userName;
        });

        print('User profile loaded - Photo URL: $_userPhotoUrl');
      } catch (e) {
        print('Error loading user profile: $e');
        // Fallback to Firebase Auth user data
        setState(() {
          _userName = user.displayName ?? '';
          _userEmail = user.email ?? '';
          _userPhotoUrl = user.photoURL ?? '';
          _nameController.text = _userName;
        });
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      if (Platform.isIOS) {
        await Permission.photos.request();
        if (!await Permission.photos.isGranted) {
          throw Exception('Photo library permission not granted');
        }
      }

      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
      );

      if (pickedFile == null) return;

      setState(() => _isUploadingImage = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final String fileName = path.basename(pickedFile.path);
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('user_profile_images')
          .child(user.uid)
          .child(fileName);

      final UploadTask uploadTask = storageRef.putFile(File(pickedFile.path));
      final TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      await user.updatePhotoURL(downloadUrl);
      await FirebaseFirestore.instance
          .collection('currentUser')
          .doc(user.uid)
          .update({'photoURL': downloadUrl});

      setState(() {
        _userPhotoUrl = downloadUrl;
        _isUploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated successfully!')),
      );
    } catch (e) {
      setState(() => _isUploadingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: ${e.toString()}')),
      );
    }
  }

  Future<void> _removeProfilePicture() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      setState(() => _isUploadingImage = true);

      await user.updatePhotoURL(null);
      await FirebaseFirestore.instance
          .collection('currentUser')
          .doc(user.uid)
          .update({'photoURL': null});

      setState(() {
        _userPhotoUrl = '';
        _isUploadingImage = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile picture removed')));
    } catch (e) {
      setState(() => _isUploadingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove profile picture: $e')),
      );
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final appSettings = Provider.of<AppSettings>(context, listen: false);

    setState(() {
      _darkMode = appSettings.darkMode;
      _decimalPlaces = appSettings.decimalPlaces;
      _baseCurrency = appSettings.baseCurrency;
      _autoUpdateRates = appSettings.autoUpdateRates;
      _biometricAuth = appSettings.biometricAuth;
      _hapticFeedback = appSettings.hapticFeedback;
      _showCalculator = appSettings.showCalculator;
      _historicalData = appSettings.historicalData;
      _offlineMode = appSettings.offlineMode;
      _selectedLanguage = appSettings.selectedLanguage;
      _selectedAppearance = appSettings.selectedAppearance;
    });
  }

  // Clear any old default pairs when settings page loads
  Future<void> _clearOldDefaultPairsOnLoad() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check for old default pairs
      List<String> pairs = prefs.getStringList('watchlist_pairs') ?? [];
      String? flutterPairsString = prefs.getString('flutter.watchlist_pairs');

      final oldDefaults = ['USD/PKR', 'USD/INR', 'USD/AED'];
      final hasOldDefaults = pairs.any((pair) => oldDefaults.contains(pair));

      if (hasOldDefaults ||
          (flutterPairsString != null &&
              flutterPairsString.contains('USD/PKR'))) {
        print('Found old default pairs in settings page load, clearing them');

        // Clear all pairs
        await prefs.remove('watchlist_pairs');
        await prefs.remove('flutter.watchlist_pairs');

        // Clear any cached rates for these pairs
        for (String defaultPair in oldDefaults) {
          await prefs.remove('${defaultPair}_previous');
          await prefs.remove('${defaultPair}_current');
          await prefs.remove('${defaultPair}_base');
          await prefs.remove('${defaultPair}_change');
        }

        print('Cleared old default pairs during settings page load');

        // Refresh the UI to show "No pairs configured"
        setState(() {});
      }
    } catch (e) {
      print('Error clearing old default pairs on settings load: $e');
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await user.updateDisplayName(_nameController.text);
          await FirebaseFirestore.instance
              .collection('currentUser')
              .doc(user.uid)
              .update({'displayName': _nameController.text});

          setState(() {
            _userName = _nameController.text;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update profile: $e')),
          );
        }
      }
    }
  }

  Future<void> _updatePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isUpdatingPassword = true);
      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email;

      if (user != null && email != null) {
        try {
          final credential = EmailAuthProvider.credential(
            email: email,
            password: _currentPasswordController.text,
          );

          await user.reauthenticateWithCredential(credential);
          await user.updatePassword(_newPasswordController.text);

          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password updated successfully')),
          );

          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/signin',
            (Route<dynamic> route) => false,
          );
        } on FirebaseAuthException catch (e) {
          String errorMessage = 'Failed to update password';
          if (e.code == 'wrong-password') {
            errorMessage = 'Current password is incorrect';
          } else if (e.code == 'weak-password') {
            errorMessage = 'New password is too weak';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$errorMessage: ${e.message}')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update password: $e')),
          );
        } finally {
          setState(() => _isUpdatingPassword = false);
        }
      }
    }
  }

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Delete Account'),
            content: const Text(
              'Are you sure you want to delete your account? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _performAccountDeletion(user);
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _performAccountDeletion(User user) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Deleting account...'),
              ],
            ),
          );
        },
      );

      // 1. Get user data before deletion
      final userDoc =
          await FirebaseFirestore.instance
              .collection('currentUser')
              .doc(user.uid)
              .get();

      final userData = userDoc.data() ?? {};

      // 2. Save to deleted accounts collection
      await FirebaseFirestore.instance
          .collection('deletedAccounts')
          .doc(user.uid)
          .set({
            'uid': user.uid,
            'email': user.email,
            'displayName': user.displayName ?? '',
            'photoURL': user.photoURL ?? '',
            'isEmailVerified': user.emailVerified,
            'createdAt': userData['createdAt'],
            'deletedAt': FieldValue.serverTimestamp(),
            'deletionReason': 'User requested account deletion',
            'originalData': userData, // Keep original data for reference
          });

      // 3. Delete from current users collection
      await FirebaseFirestore.instance
          .collection('currentUser')
          .doc(user.uid)
          .delete();

      // 4. Delete user authentication
      await user.delete();

      // 5. Clear local data
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // 6. Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // 7. Navigate to login page
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/signin',
        (Route<dynamic> route) => false,
      );

      // 8. Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete account: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadNotificationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('notification_history') ?? [];
    setState(() {
      _notificationHistory =
          history.map((e) => Map<String, dynamic>.from(jsonDecode(e))).toList();
    });
  }

  Future<void> _addNotificationToHistory(
    String title,
    String body, [
    String? sound,
  ]) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final entry = {
      'title': title,
      'body': body,
      'timestamp': now.toIso8601String(),
      if (sound != null) 'sound': sound,
    };
    _notificationHistory.insert(0, entry);
    // Keep only last 50 notifications
    if (_notificationHistory.length > 50) {
      _notificationHistory = _notificationHistory.sublist(0, 50);
    }
    await prefs.setStringList(
      'notification_history',
      _notificationHistory.map((e) => jsonEncode(e)).toList(),
    );
    if (mounted) setState(() {}); // Ensure UI updates instantly
  }

  // Only clear history when user does it from settings, not on alert delete.
  Future<void> _clearNotificationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notification_history');
    setState(() {
      _notificationHistory.clear();
    });
  }

  Future<void> _loadAvailableSounds() async {
    // For Android, only show sounds present in res/raw/
    List<String> rawSounds = [
      'zapsplat_multimedia_notification_bell_chime_ring_alert_001_41155.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_002_41156.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_003_41157.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_004_41158.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_005_41159.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_006_41160.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_007_41161.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_008_41162.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_009_41163.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_010_41164.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_011_41165.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_012_41166.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_013_41167.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_014_41168.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_015_41169.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_016_41170.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_017_41171.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_018_41181.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_019_41182.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_020_41183.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_021_41184.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_022_41185.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_023_41186.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_024_41187.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_025_41188.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_026_41189.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_027_41190.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_028_41172.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_029_41173.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_030_41191.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_031_41192.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_032_41193.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_033_41194.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_034_41195.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_001_41174.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_002_41175.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_003_41196.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_004_41197.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_005_41198.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_006_41199.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_007_41200.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_008_41201.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_009_41202.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_010_41203.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_011_41204.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_012_41205.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_013_41206.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_014_41207.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_015_41208.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_016_41209.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_017_41210.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_018_41211.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_019_41212.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_020_41213.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_021_41214.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_022_41215.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_023_41216.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_024_41217.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_025_41218.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_026_41219.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_027_41220.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_028_41221.mp3',
      'notification.mp3',
    ];
    // Only show sounds that are present in res/raw/ (for Android)
    _availableSounds = rawSounds;
    final prefs = await SharedPreferences.getInstance();
    String? savedSound = prefs.getString('notificationSound');
    if (!_availableSounds.contains(savedSound)) {
      savedSound = _availableSounds.isNotEmpty ? _availableSounds.first : '';
      await prefs.setString('notificationSound', savedSound);
    }
    setState(() {
      _notificationSound = savedSound!;
    });
  }

  Future<void> _saveNotificationSound(String sound) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notificationSound', sound);
    setState(() {
      _notificationSound = sound;
    });
  }

  void _deleteNotificationFromHistory(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationHistory.removeAt(index);
    });
    await prefs.setStringList(
      'notification_history',
      _notificationHistory.map((e) => jsonEncode(e)).toList(),
    );
  }

  Future<void> _playSound(String sound) async {
    try {
      print('Attempting to play sound: sounds/$sound');
      _audioPlayer?.stop();
      _audioPlayer = AudioPlayer();
      setState(() => _playingSound = sound);
      await _audioPlayer!.play(AssetSource('sounds/$sound'));
      _audioPlayer!.onPlayerComplete.listen((event) {
        setState(() => _playingSound = null);
      });
      print('Sound played successfully: $sound');
    } catch (e) {
      setState(() => _playingSound = null);
      print('Error playing sound: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to play sound: $e')));
      }
    }
  }

  // Helper to check if selected sound is available in res/raw/ for Android notifications
  bool _isSoundAvailableForNotification(String sound) {
    // Only check for Android, as iOS uses bundled assets differently
    // This is a static check; in real app, you may want to check at build time
    const availableRawSounds = [
      'zapsplat_multimedia_notification_bell_chime_ring_alert_001_41155.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_002_41156.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_003_41157.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_004_41158.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_005_41159.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_006_41160.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_007_41161.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_008_41162.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_009_41163.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_010_41164.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_011_41165.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_012_41166.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_013_41167.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_014_41168.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_015_41169.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_016_41170.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_017_41171.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_018_41181.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_019_41182.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_020_41183.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_021_41184.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_022_41185.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_023_41186.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_024_41187.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_025_41188.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_026_41189.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_027_41190.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_028_41172.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_029_41173.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_030_41191.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_031_41192.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_032_41193.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_033_41194.mp3',
      'zapsplat_multimedia_notification_bell_chime_ring_alert_034_41195.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_001_41174.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_002_41175.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_003_41196.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_004_41197.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_005_41198.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_006_41199.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_007_41200.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_008_41201.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_009_41202.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_010_41203.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_011_41204.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_012_41205.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_013_41206.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_014_41207.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_015_41208.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_016_41209.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_017_41210.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_018_41211.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_019_41212.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_020_41213.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_021_41214.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_022_41215.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_023_41216.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_024_41217.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_025_41218.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_026_41219.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_027_41220.mp3',
      'zapsplat_multimedia_notification_bell_glassy_chime_028_41221.mp3',
      'notification.mp3',
    ];
    return availableRawSounds.contains(sound);
  }

  // Version Update Methods
  Future<void> _loadCurrentAppVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();

      setState(() {
        _currentAppVersion = {
          'version': packageInfo.version, // Dynamic version from package info
          'buildNumber': packageInfo.buildNumber,
          'platform': kIsWeb ? 'Web' : (Platform.isAndroid ? 'Android' : 'iOS'),
        };
      });

      print(
        '📱 Current app version: ${packageInfo.version} (${packageInfo.buildNumber})',
      );
    } catch (e) {
      print('❌ Error loading app version: $e');
      // Fallback - try to get version again
      final fallbackVersion = await AppVersionService.getAppVersion();
      setState(() {
        _currentAppVersion = {
          'version': fallbackVersion, // Dynamic version
          'buildNumber': '1',
          'platform': kIsWeb ? 'Web' : (Platform.isAndroid ? 'Android' : 'iOS'),
        };
      });
    }
  }

  // Manual version check (with UI updates and loading state)
  Future<void> _checkForAppUpdate() async {
    setState(() => _isCheckingUpdate = true);

    try {
      print('🔍 Manual version check...');

      // Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check internet connectivity first
      final isConnected = await ConnectivityService().checkConnectivity();
      if (!isConnected) {
        throw Exception('No internet connection available');
      }

      // Try to create app_versions collection if it doesn't exist
      await _ensureAppVersionsCollection();

      // Get latest version from Firestore (using existing 'current' document)
      final versionDoc =
          await FirebaseFirestore.instance
              .collection('app_versions')
              .doc('current')
              .get();

      if (versionDoc.exists) {
        final latestVersion = versionDoc.data()!;
        print('📱 Latest version from database: ${latestVersion['version']}');

        setState(() {
          _latestAppVersion = latestVersion;
        });

        // Compare versions
        final currentVersion = await AppVersionService.getAppVersion();
        final latestVersionStr = latestVersion['version'];

        print(
          '📊 Comparing versions: Current=$currentVersion, Latest=$latestVersionStr',
        );

        if (_compareVersions(latestVersionStr, currentVersion) > 0) {
          print('✅ Update available!');
          setState(() {
            _isUpdateAvailable = true;
          });

          // Send notification to user
          await _sendUpdateNotification(latestVersion);

          // Show detailed update message for manual check
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.system_update, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Update Available!',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Current: v$currentVersion → Latest: v$latestVersionStr',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          print('✅ App is up to date');
          setState(() {
            _isUpdateAvailable = false;
          });

          // Show detailed success message for manual check
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'App is Up to Date!',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Current version: v$currentVersion',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        print('❌ No version document found in database');
        setState(() {
          _isUpdateAvailable = false;
        });

        // Show error message for manual check
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.warning, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No update information available. Please try again later.',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error checking for app update: $e');
      setState(() {
        _isUpdateAvailable = false;
      });

      // Show user-friendly error message for manual check
      if (mounted) {
        String errorMessage = 'Could not check for updates. Please try again.';

        if (e.toString().contains('permission-denied')) {
          errorMessage =
              'Access denied. Please check your internet connection.';
        } else if (e.toString().contains('not-found')) {
          errorMessage = 'Update service temporarily unavailable.';
        } else if (e.toString().contains('unavailable')) {
          errorMessage = 'Service temporarily unavailable. Please try again.';
        } else if (e.toString().contains('No internet connection')) {
          errorMessage =
              'No internet connection. Please check your network and try again.';
        } else if (e.toString().contains('User not authenticated')) {
          errorMessage = 'Please login to check for updates.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isCheckingUpdate = false;
        _lastCheckTime = DateTime.now();
      });
    }
  }

  // Ensure app_versions collection exists
  Future<void> _ensureAppVersionsCollection() async {
    try {
      // Check if the 'current' document exists in app_versions collection
      final currentDoc =
          await FirebaseFirestore.instance
              .collection('app_versions')
              .doc('current')
              .get();

      if (currentDoc.exists) {
        print('✅ App versions collection verified - current document exists');
      } else {
        print(
          '⚠️ App versions collection exists but current document not found',
        );
      }
    } catch (e) {
      print('⚠️ Could not verify app_versions collection: $e');
      // Continue anyway, the main check will handle the error
    }
  }

  int _compareVersions(String version1, String version2) {
    // Remove 'v' prefix if present and clean version strings
    final cleanVersion1 = version1.replaceAll(RegExp(r'^v'), '');
    final cleanVersion2 = version2.replaceAll(RegExp(r'^v'), '');

    final v1Parts = cleanVersion1.split('.').map(int.parse).toList();
    final v2Parts = cleanVersion2.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      final v1 = i < v1Parts.length ? v1Parts[i] : 0;
      final v2 = i < v2Parts.length ? v2Parts[i] : 0;

      if (v1 > v2) return 1;
      if (v1 < v2) return -1;
    }
    return 0;
  }

  // Start periodic version check
  void _startPeriodicVersionCheck() {
    Timer.periodic(const Duration(seconds: 15), (timer) async {
      if (mounted) {
        print('🔄 Silent periodic version check triggered (every 15 seconds)');
        await _checkForAppUpdateInBackground();
      } else {
        timer.cancel();
      }
    });
  }

  // Background version check (with notifications and in-app messages)
  Future<void> _checkForAppUpdateInBackground() async {
    try {
      print('🔍 Background version check...');

      // Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ User not authenticated for background check');
        return;
      }

      // Check internet connectivity first
      final isConnected = await ConnectivityService().checkConnectivity();
      if (!isConnected) {
        print('❌ No internet connection for background check');
        return;
      }

      // Get latest version from Firestore (using existing 'current' document)
      final versionDoc =
          await FirebaseFirestore.instance
              .collection('app_versions')
              .doc('current')
              .get();

      if (versionDoc.exists) {
        final latestVersion = versionDoc.data()!;
        final currentVersion = await AppVersionService.getAppVersion();
        final latestVersionStr = latestVersion['version'];

        print(
          '📊 Background check - Current=$currentVersion, Latest=$latestVersionStr',
        );

        if (_compareVersions(latestVersionStr, currentVersion) > 0) {
          print('✅ Background check: Update available!');

          // Update state without UI refresh
          _isUpdateAvailable = true;
          _latestAppVersion = latestVersion;

          // Send push notification to user
          await _sendUpdateNotification(latestVersion);

          // Show in-app message for 3 seconds
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.system_update, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'New version ${latestVersion['version']} available!',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }

          print('📱 Background update notification and in-app message sent');
        } else {
          print('✅ Background check: App is up to date');
          _isUpdateAvailable = false;
        }
      } else {
        print('❌ No version document found in background check');
      }

      // Update last check time silently
      _lastCheckTime = DateTime.now();
    } catch (e) {
      print('❌ Error in background version check: $e');
      // Don't show any UI messages for background errors
    }
  }

  Future<void> _sendUpdateNotification(Map<String, dynamic> versionData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Check if notification already exists
      final existingNotification =
          await FirebaseFirestore.instance
              .collection('update_notifications')
              .where('userId', isEqualTo: user.uid)
              .where('version', isEqualTo: versionData['version'])
              .get();

      if (existingNotification.docs.isNotEmpty) return; // Already notified

      // Get user data
      final userDoc =
          await FirebaseFirestore.instance
              .collection('currentUser')
              .doc(user.uid)
              .get();

      final userData = userDoc.data() ?? {};

      // Create notification
      final notificationData = {
        'userId': user.uid,
        'userEmail': user.email ?? '',
        'userDisplayName': user.displayName ?? userData['displayName'] ?? '',
        'userPhotoURL': user.photoURL ?? userData['photoURL'] ?? '',
        'userEmailVerified': user.emailVerified,
        'userCreatedAt': userData['createdAt'],
        'userLastLoginAt': userData['lastLoginAt'],
        'version': versionData['version'],
        'buildNumber': versionData['buildNumber'],
        'updateTitle': versionData['title'] ?? 'App Update Available',
        'updateDescription':
            '${versionData['description'] ?? 'A new version is available'}\n\n📱 Click the Download APK button to get the latest version directly!',
        'downloadUrl': versionData['downloadUrl'] ?? '',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': kIsWeb ? 'Web' : (Platform.isAndroid ? 'Android' : 'iOS'),
      };

      // Save to update_notifications collection
      await FirebaseFirestore.instance
          .collection('update_notifications')
          .add(notificationData);

      // Save to notification_history for admin
      await FirebaseFirestore.instance.collection('notification_history').add({
        ...notificationData,
        'type': 'app_update',
        'status': 'sent',
      });

      // Add to local notification history
      await _addNotificationToHistory(
        notificationData['updateTitle'],
        '${notificationData['updateDescription']}\n\n📱 Click the Download APK button to get the latest version directly!',
      );

      // Show mobile notification
      await _showAppUpdateNotification(notificationData);

      setState(() {});
    } catch (e) {
      print('Error sending update notification: $e');
    }
  }

  Future<void> _showAppUpdateNotification(
    Map<String, dynamic> notificationData,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String selectedSound =
          prefs.getString('notificationSound') ?? 'notification.mp3';

      String soundName = selectedSound.replaceAll('.mp3', '');
      String channelId = 'app_updates_$soundName';

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            channelId,
            'App Updates',
            importance: Importance.high,
            priority: Priority.high,
            ticker: 'ticker',
            sound: RawResourceAndroidNotificationSound(soundName),
            icon: '@mipmap/ic_launcher',
          );

      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentSound: true,
        sound: selectedSound,
      );

      final NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final title = notificationData['updateTitle'] ?? 'App Update Available';
      final body =
          'Version ${notificationData['version']} is available. Open app to download directly!';

      await FlutterLocalNotificationsPlugin().show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        platformDetails,
      );

      print('App update notification shown: $title');
    } catch (e) {
      print('Error showing app update notification: $e');
    }
  }

  Future<void> _loadUpdateNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final notificationsSnapshot =
          await FirebaseFirestore.instance
              .collection('update_notifications')
              .where('userId', isEqualTo: user.uid)
              .orderBy('timestamp', descending: true)
              .get();

      setState(() {
        _updateNotifications =
            notificationsSnapshot.docs.map((doc) => doc.data()).toList();
      });
    } catch (e) {
      print('Error loading update notifications: $e');
    }
  }

  Future<void> _deleteUpdateNotification(String notificationId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get notification data before deletion
      final notificationDoc =
          await FirebaseFirestore.instance
              .collection('update_notifications')
              .doc(notificationId)
              .get();

      if (notificationDoc.exists) {
        final notificationData = notificationDoc.data()!;

        // Save to notification_history before deletion
        await FirebaseFirestore.instance
            .collection('notification_history')
            .add({
              ...notificationData,
              'type': 'app_update',
              'status': 'deleted_by_user',
              'deletedAt': FieldValue.serverTimestamp(),
            });

        // Delete from update_notifications
        await FirebaseFirestore.instance
            .collection('update_notifications')
            .doc(notificationId)
            .delete();

        // Refresh notifications
        await _loadUpdateNotifications();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Update notification deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error deleting update notification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Downloads the latest APK version
  ///
  /// This function handles APK downloads in two ways:
  /// 1. If a downloadUrl is set in Firebase database, it uses that URL
  /// 2. Otherwise, it uses the default GitHub release link
  ///
  /// For future updates:
  /// - Upload new APK to GitHub releases with the same filename (app-latest.apk)
  /// - The link will automatically work without code changes
  /// - Or set a specific downloadUrl in Firebase for more control
  Future<void> _downloadLatestVersion() async {
    try {
      String downloadUrl;

      // Check if we have a download URL from Firebase, otherwise use GitHub
      if (_latestAppVersion != null &&
          _latestAppVersion!['downloadUrl'] != null &&
          _latestAppVersion!['downloadUrl'].toString().isNotEmpty) {
        // Use the download URL from Firebase database
        downloadUrl = _latestAppVersion!['downloadUrl'];
        print('📥 Using download URL from database: $downloadUrl');
      } else {
        // Use your GitHub release link for direct APK download
        // This will always point to the latest version you upload
        downloadUrl =
            'https://github.com/Zain1098/CurrenSee-APK-Update/releases/download/v1.0.0/app-latest.apk';
        print('📥 Using default GitHub download URL: $downloadUrl');
      }

      // Validate URL format
      if (!downloadUrl.startsWith('http://') &&
          !downloadUrl.startsWith('https://')) {
        throw Exception('Invalid URL format: $downloadUrl');
      }

      print('🔗 Attempting to open URL: $downloadUrl');

      final Uri url = Uri.parse(downloadUrl);

      // First, try to check if the URL is accessible
      try {
        final response = await http.head(url);
        print('🌐 URL accessibility check: ${response.statusCode}');
        if (response.statusCode != 200) {
          print('⚠️ URL returned status code: ${response.statusCode}');
        }
      } catch (e) {
        print('⚠️ URL accessibility check failed: $e');
        // Continue anyway, as the URL might still be valid
      }

      // Check if URL can be launched
      final canLaunch = await canLaunchUrl(url);
      print('🔍 Can launch URL: $canLaunch');

      if (canLaunch) {
        // Try to launch the URL
        final launched = await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );

        print('🚀 Launch result: $launched');

        if (launched) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Opening download link in browser...'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          // Launch failed
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to open download link. Please try again.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Cannot launch URL - try alternative approach
        print('⚠️ Cannot launch URL directly, trying alternative method');

        // Try to open in browser with different mode
        try {
          final launched = await launchUrl(
            url,
            mode: LaunchMode.platformDefault,
          );

          if (launched) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Opening download link...'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            throw Exception('Failed to launch URL');
          }
        } catch (e) {
          print('❌ Alternative launch method failed: $e');

          // Show detailed error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Could not open download link. Please check your internet connection and try again.',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Copy Link',
                onPressed: () {
                  // Copy link to clipboard
                  Clipboard.setData(ClipboardData(text: downloadUrl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Download link copied to clipboard'),
                      backgroundColor: Colors.blue,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error in _downloadLatestVersion: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening download link: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _openDownloadLink(String downloadUrl) async {
    try {
      final Uri url = Uri.parse(downloadUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open download link'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error opening download link: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening link: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildAppUpdateSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status indicator
            Row(
              children: [
                const Icon(Icons.system_update, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Version & Updates',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Spacer(),
                if (_isCheckingUpdate) ...[
                  const Text(
                    'Checking...',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Compact version info and status
            Row(
              children: [
                // Current version
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.blue,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Current',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              FutureBuilder<String>(
                                future: AppVersionService.getAppVersion(),
                                builder: (context, snapshot) {
                                  return Text(
                                    snapshot.data ?? '1.0.6',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 11,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Status indicator
                Expanded(child: _buildStatusIndicator()),
              ],
            ),

            const SizedBox(height: 12),

            // Check for Updates Button
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton.icon(
                onPressed: _isCheckingUpdate ? null : _checkForAppUpdate,
                icon:
                    _isCheckingUpdate
                        ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.refresh, size: 16),
                label: Text(
                  _isCheckingUpdate ? 'Checking...' : 'Check for Updates',
                  style: const TextStyle(fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),

            // Update Notifications (compact)
            if (_updateNotifications.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ..._updateNotifications.map((notification) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.new_releases,
                            color: Colors.blue,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Version ${notification['version']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  notification['timestamp'] != null
                                      ? _formatTimestamp(
                                        notification['timestamp'],
                                      )
                                      : '',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 18,
                            ),
                            onPressed:
                                () => _deleteUpdateNotification(
                                  notification['id'],
                                ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Direct Download Button
                      SizedBox(
                        width: double.infinity,
                        height: 32,
                        child: ElevatedButton.icon(
                          onPressed: () => _downloadLatestVersion(),
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text(
                            'Download APK',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    if (_isUpdateAvailable && _latestAppVersion != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.new_releases, color: Colors.green, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Available',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'v${_latestAppVersion!['version']}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Download button in status indicator
            SizedBox(
              width: double.infinity,
              height: 28,
              child: ElevatedButton.icon(
                onPressed: _downloadLatestVersion,
                icon: const Icon(Icons.download, size: 14),
                label: const Text(
                  'Download Now',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (_isCheckingUpdate) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 6),
            const Text(
              'Checking',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.orange,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.blue, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Up to date',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                      fontSize: 12,
                    ),
                  ),
                  if (_lastCheckTime != null)
                    Text(
                      'Last: ${_lastCheckTime!.toString().substring(11, 16)}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      if (timestamp is Timestamp) {
        final dateTime = timestamp.toDate();
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ShineText(
          text: 'Settings',
          textStyle: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.0,
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('User Profile'),
            _buildUserProfileSection(),
            const SizedBox(height: 20),

            if (_isEditingProfile) ...[
              _buildSectionHeader('Update Password'),
              _buildPasswordUpdateSection(),
              const SizedBox(height: 20),
            ],

            _buildSectionHeader('Appearance'),
            _buildAppearanceSection(),
            const SizedBox(height: 20),

            _buildSectionHeader('Favorite Currencies'),
            _buildFavoriteCurrenciesSection(),
            const SizedBox(height: 20),

            _buildSectionHeader('Features'),
            _buildToggleSetting(
              'Auto-update exchange rates',
              _autoUpdateRates,
              (value) {
                setState(() => _autoUpdateRates = value);
                _saveSetting('autoUpdateRates', value);
                widget.onAutoUpdateChanged(value);
                Provider.of<AppSettings>(
                  context,
                  listen: false,
                ).setAutoUpdateRates(value);
              },
            ),
            _buildToggleSetting('Show calculator button', _showCalculator, (
              value,
            ) {
              setState(() => _showCalculator = value);
              _saveSetting('showCalculator', value);
              widget.onCalculatorChanged(value);
              Provider.of<AppSettings>(
                context,
                listen: false,
              ).setShowCalculator(value);
            }),
            _buildToggleSetting(
              'Offline mode (use cached rates)',
              _offlineMode,
              (value) {
                setState(() => _offlineMode = value);
                _saveSetting('offlineMode', value);
                Provider.of<AppSettings>(
                  context,
                  listen: false,
                ).setOfflineMode(value);
              },
            ),
            const SizedBox(height: 20),

            // --- Notification Settings Section (moved up, always visible) ---
            _buildSectionHeader('Notification Settings'),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.music_note, color: Colors.blue),
                      title: const Text(
                        'Notification Sound',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle:
                          _availableSounds.isEmpty
                              ? const Center(child: CircularProgressIndicator())
                              : DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value:
                                      _availableSounds.contains(
                                            _notificationSound,
                                          )
                                          ? _notificationSound
                                          : _availableSounds.first,
                                  isExpanded: true,
                                  icon: const Icon(Icons.arrow_drop_down),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                  dropdownColor: Colors.white,
                                  items:
                                      _availableSounds.map((sound) {
                                        return DropdownMenuItem<String>(
                                          value: sound,
                                          child: Row(
                                            children: [
                                              IconButton(
                                                icon: Icon(
                                                  _playingSound == sound
                                                      ? Icons.stop_circle
                                                      : Icons.play_circle_fill,
                                                  color:
                                                      _playingSound == sound
                                                          ? Colors.red
                                                          : Colors.blueGrey,
                                                  size: 24,
                                                ),
                                                onPressed: () {
                                                  if (_playingSound == sound) {
                                                    _audioPlayer?.stop();
                                                    setState(
                                                      () =>
                                                          _playingSound = null,
                                                    );
                                                  } else {
                                                    _playSound(sound);
                                                  }
                                                },
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  sound.replaceAll('.mp3', ''),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      _saveNotificationSound(value);
                                    }
                                  },
                                ),
                              ),
                    ),
                    const SizedBox(height: 16),
                    _buildNotificationHistorySection(),
                    const SizedBox(height: 16),
                    _buildResetAndClearSection(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- Security Section (now after Notification Settings) ---
            _buildSectionHeader('Security'),
            _buildToggleSetting('Biometric authentication', _biometricAuth, (
              value,
            ) {
              setState(() => _biometricAuth = value);
              _saveSetting('biometricAuth', value);
              widget.onBiometricChanged(value);
              Provider.of<AppSettings>(
                context,
                listen: false,
              ).setBiometricAuth(value);
            }),
            const SizedBox(height: 20),

            // --- App Updates Section ---
            _buildSectionHeader('App Updates'),
            _buildAppUpdateSection(),
            const SizedBox(height: 20),

            // Widget sections removed - simplified implementation
            const SizedBox(height: 20),

            _buildSectionHeader('About'),
            _buildAboutSection(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfileSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildProfileImage(),
            const SizedBox(height: 16),
            Text(
              _userName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _userEmail,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            _isEditingProfile
                ? Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isEditingProfile = false;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: _updateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text('Save Profile'),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isEditingProfile = true;
                          _currentPasswordController.clear();
                          _newPasswordController.clear();
                          _confirmPasswordController.clear();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('Edit Profile'),
                    ),
                    ElevatedButton(
                      onPressed: _deleteAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('Delete Account'),
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: _isEditingProfile ? _pickAndUploadImage : null,
      child:
          _isUploadingImage
              ? const CircularProgressIndicator()
              : Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipOval(
                  child:
                      _userPhotoUrl.isNotEmpty
                          ? Image.network(
                            _userPhotoUrl,
                            fit: BoxFit.cover,
                            width: 120,
                            height: 120,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 120,
                                height: 120,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 120,
                                height: 120,
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.blue,
                                ),
                              );
                            },
                          )
                          : Container(
                            width: 120,
                            height: 120,
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.blue,
                            ),
                          ),
                ),
              ),
    );
  }

  Widget _buildPasswordUpdateSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          child: Column(
            children: [
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrentPassword,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrentPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureCurrentPassword = !_obscureCurrentPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your new password';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUpdatingPassword ? null : _updatePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child:
                      _isUpdatingPassword
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Update Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildAppearanceSection() {
    final theme = Theme.of(context);
    final settings = Provider.of<AppSettings>(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: AppTheme.getGradientDecoration(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with current theme indicator
              Row(
                children: [
                  Icon(
                    Icons.palette_outlined,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Appearance',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      settings.effectiveDarkMode ? 'Dark' : 'Light',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Theme Options with improved design
              Row(
                children: [
                  Expanded(
                    child: _buildThemeOption(
                      'System',
                      Icons.brightness_auto,
                      settings.selectedAppearance == 'System',
                      () => settings.setSelectedAppearance('System'),
                      theme,
                      const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildThemeOption(
                      'Light',
                      Icons.light_mode,
                      settings.selectedAppearance == 'Light',
                      () => settings.setSelectedAppearance('Light'),
                      theme,
                      const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildThemeOption(
                      'Dark',
                      Icons.dark_mode,
                      settings.selectedAppearance == 'Dark',
                      () => settings.setSelectedAppearance('Dark'),
                      theme,
                      const LinearGradient(
                        colors: [Color(0xFF1F2937), Color(0xFF374151)],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Theme description
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getThemeDescription(settings.selectedAppearance),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getThemeDescription(String appearance) {
    switch (appearance) {
      case 'System':
        return 'Follows your device\'s system theme setting';
      case 'Light':
        return 'Always uses light theme regardless of system setting';
      case 'Dark':
        return 'Always uses dark theme regardless of system setting';
      default:
        return 'Follows your device\'s system theme setting';
    }
  }

  Widget _buildThemeOption(
    String title,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
    ThemeData theme,
    LinearGradient gradient,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    isSelected ? theme.colorScheme.primary : theme.dividerColor,
                width: isSelected ? 2 : 1,
              ),
              gradient: isSelected ? gradient : null,
              color: isSelected ? null : theme.cardColor,
              boxShadow:
                  isSelected
                      ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                      : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color:
                        isSelected
                            ? Colors.white
                            : theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDecimalPrecisionSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Decimal places for conversion results'),
        Slider(
          value: _decimalPlaces.toDouble(),
          min: 0,
          max: 6,
          divisions: 6,
          label: _decimalPlaces.toString(),
          onChanged: (value) {
            setState(() => _decimalPlaces = value.toInt());
            _saveSetting('decimalPlaces', value.toInt());
            widget.onDecimalChanged(value.toInt());
          },
        ),
      ],
    );
  }

  Widget _buildBaseCurrencySetting() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Default base currency'),
        DropdownButton<String>(
          value: _baseCurrency,
          items:
              _currencies.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              setState(() => _baseCurrency = newValue);
              _saveSetting('baseCurrency', newValue);
              widget.onBaseCurrencyChanged(newValue);
            }
          },
        ),
      ],
    );
  }

  Widget _buildLanguageSetting() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('App language'),
        DropdownButton<String>(
          value: _selectedLanguage,
          items:
              _languages.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              setState(() => _selectedLanguage = newValue);
              _saveSetting('selectedLanguage', newValue);
              Provider.of<AppSettings>(
                context,
                listen: false,
              ).setSelectedLanguage(newValue);
            }
          },
        ),
      ],
    );
  }

  Widget _buildToggleSetting(
    String title,
    bool value,
    Function(bool) onChanged, {
    IconData? icon,
  }) {
    // Special handling for biometric authentication
    if (title == 'Biometric authentication') {
      bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
      return SwitchListTile(
        title: Text(title),
        value: value,
        onChanged:
            isMobile
                ? (enabled) async {
                  if (enabled) {
                    final localAuth = LocalAuthentication();
                    bool canCheck = await localAuth.canCheckBiometrics;
                    bool isDeviceSupported =
                        await localAuth.isDeviceSupported();
                    List<BiometricType> available =
                        await localAuth.getAvailableBiometrics();
                    if (!canCheck || !isDeviceSupported || available.isEmpty) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Biometric authentication is not available or not set up on this device.',
                            ),
                          ),
                        );
                      }
                      setState(() => _biometricAuth = false);
                      Provider.of<AppSettings>(
                        context,
                        listen: false,
                      ).setBiometricAuth(false);
                      return;
                    }
                    try {
                      final didAuthenticate = await localAuth.authenticate(
                        localizedReason:
                            'Enable biometric lock for CurrenSee Pro',
                        options: const AuthenticationOptions(
                          biometricOnly: true,
                          stickyAuth: false,
                        ),
                      );
                      if (didAuthenticate) {
                        setState(() => _biometricAuth = true);
                        _saveSetting('biometricAuth', true);
                        widget.onBiometricChanged(true);
                        Provider.of<AppSettings>(
                          context,
                          listen: false,
                        ).setBiometricAuth(true);
                      } else {
                        setState(() => _biometricAuth = false);
                        _saveSetting('biometricAuth', false);
                        widget.onBiometricChanged(false);
                        Provider.of<AppSettings>(
                          context,
                          listen: false,
                        ).setBiometricAuth(false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Authentication failed or cancelled. Biometric lock not enabled.',
                              ),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      setState(() => _biometricAuth = false);
                      _saveSetting('biometricAuth', false);
                      widget.onBiometricChanged(false);
                      Provider.of<AppSettings>(
                        context,
                        listen: false,
                      ).setBiometricAuth(false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${e.toString()}')),
                        );
                      }
                    }
                  } else {
                    setState(() => _biometricAuth = false);
                    _saveSetting('biometricAuth', false);
                    widget.onBiometricChanged(false);
                    Provider.of<AppSettings>(
                      context,
                      listen: false,
                    ).setBiometricAuth(false);
                  }
                }
                : null,
        subtitle:
            isMobile ? null : const Text('Only available on mobile devices'),
        contentPadding: EdgeInsets.zero,
      );
    }
    // Default toggle
    return ListTile(
      leading:
          icon != null
              ? Icon(icon, color: Theme.of(context).colorScheme.primary)
              : null,
      title: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Theme.of(context).colorScheme.primary,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Future<void> _loadCurrencies() async {
    setState(() {
      _isLoadingCurrencies = true;
    });

    try {
      final currencies = await CurrencyService.loadCurrencies();
      final settings = Provider.of<AppSettings>(context, listen: false);
      final favoriteCodes = settings.favoriteCurrencies;

      setState(() {
        _allCurrencies = currencies;
        _favoriteCurrencies =
            currencies
                .where((currency) => favoriteCodes.contains(currency.code))
                .toList();
        _isLoadingCurrencies = false;
      });
    } catch (e) {
      print('Error loading currencies: $e');
      setState(() {
        _isLoadingCurrencies = false;
      });
    }
  }

  Widget _buildFavoriteCurrenciesSection() {
    final theme = Theme.of(context);
    final settings = Provider.of<AppSettings>(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.star, color: theme.colorScheme.primary, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Favorite Currencies',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Select up to 3 currencies to appear at the top of all dropdowns',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoadingCurrencies)
                const Center(child: CircularProgressIndicator())
              else if (_allCurrencies.isEmpty)
                Center(
                  child: Text(
                    'No currencies available',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    // Show current favorites
                    if (_favoriteCurrencies.isNotEmpty) ...[
                      Text(
                        'Current Favorites:',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            _favoriteCurrencies.map((currency) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: theme.colorScheme.primary,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      currency.flag,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      currency.code,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () {
                                        settings.removeFavoriteCurrency(
                                          currency.code,
                                        );
                                        setState(() {
                                          _favoriteCurrencies.remove(currency);
                                        });
                                      },
                                      child: Icon(
                                        Icons.close,
                                        size: 16,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Show available currencies
                    Text(
                      'Available Currencies:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        itemCount: _allCurrencies.length,
                        itemBuilder: (context, index) {
                          final currency = _allCurrencies[index];
                          final isFavorite = _favoriteCurrencies.contains(
                            currency,
                          );
                          final isInactive = currency.status != 'active';
                          final canSelect =
                              !isInactive &&
                              (_favoriteCurrencies.length < 3 || isFavorite);

                          return ListTile(
                            leading: Text(
                              currency.flag,
                              style: const TextStyle(fontSize: 20),
                            ),
                            title: Text(
                              currency.code,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color:
                                    isInactive
                                        ? theme.colorScheme.error
                                        : theme.colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currency.name,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color:
                                        isInactive
                                            ? theme.colorScheme.error
                                                .withOpacity(0.7)
                                            : theme.colorScheme.onSurface
                                                .withOpacity(0.7),
                                  ),
                                ),
                                if (isInactive)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.error
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Temporarily blocked by team',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.error,
                                            fontSize: 10,
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                            trailing:
                                isFavorite
                                    ? Icon(
                                      Icons.star,
                                      color: theme.colorScheme.primary,
                                      size: 20,
                                    )
                                    : canSelect
                                    ? IconButton(
                                      icon: const Icon(Icons.star_border),
                                      onPressed: () {
                                        settings.addFavoriteCurrency(
                                          currency.code,
                                        );
                                        setState(() {
                                          _favoriteCurrencies.add(currency);
                                        });
                                      },
                                    )
                                    : null,
                            onTap:
                                canSelect
                                    ? () {
                                      if (isFavorite) {
                                        settings.removeFavoriteCurrency(
                                          currency.code,
                                        );
                                        setState(() {
                                          _favoriteCurrencies.remove(currency);
                                        });
                                      } else {
                                        settings.addFavoriteCurrency(
                                          currency.code,
                                        );
                                        setState(() {
                                          _favoriteCurrencies.add(currency);
                                        });
                                      }
                                    }
                                    : null,
                          );
                        },
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CurrenSee Pro',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        FutureBuilder<String>(
          future: AppVersionService.getAppVersion(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Row(
                children: [
                  Text('Version '),
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1),
                  ),
                ],
              );
            }
            return Text('Version ${snapshot.data ?? 'Loading...'}');
          },
        ),
        const SizedBox(height: 12),
        const Text(
          'This app provides real-time currency conversion using the latest exchange rates.',
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            _showRateAppDialog();
          },
          child: const Text(
            'Rate this app',
            style: TextStyle(color: Colors.blue),
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            _shareApp();
          },
          child: const Text(
            'Share with friends',
            style: TextStyle(color: Colors.blue),
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SupportHelpScreen(),
              ),
            );
          },
          child: const Text(
            'Send feedback',
            style: TextStyle(color: Colors.blue),
          ),
        ),
      ],
    );
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Backup Settings'),
          content: const Text(
            'Would you like to backup your settings to the cloud?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings backed up successfully'),
                  ),
                );
              },
              child: const Text('Backup'),
            ),
          ],
        );
      },
    );
  }

  void _showRateAppDialog() {
    int selectedRating = 0;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rate this app'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () {
                      setState(() {
                        selectedRating = index + 1;
                      });
                    },
                  );
                }),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null && selectedRating > 0) {
                  try {
                    // Get user's complete profile data from Firestore
                    final userDoc =
                        await FirebaseFirestore.instance
                            .collection('currentUser')
                            .doc(user.uid)
                            .get();

                    final userData = userDoc.data() ?? {};

                    // Save complete user data with rating
                    await FirebaseFirestore.instance
                        .collection('rate_this_app')
                        .add({
                          'userId': user.uid,
                          'userEmail': user.email ?? '',
                          'userDisplayName':
                              user.displayName ?? userData['displayName'] ?? '',
                          'userPhotoURL':
                              user.photoURL ?? userData['photoURL'] ?? '',
                          'userEmailVerified': user.emailVerified,
                          'userCreatedAt': userData['createdAt'],
                          'userLastLoginAt': userData['lastLoginAt'],
                          'rating': selectedRating,
                          'timestamp': FieldValue.serverTimestamp(),
                          'appVersion': await AppVersionService.getAppVersion(),
                          'platform':
                              kIsWeb
                                  ? 'Web'
                                  : (Platform.isAndroid ? 'Android' : 'iOS'),
                        });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Thank you for rating!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    print('Error saving rating: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error saving rating: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _shareApp() async {
    const appLink =
        'https://play.google.com/store/apps/details?id=com.example.currensee';
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      // Use share_plus for mobile
      try {
        await Share.share(
          'Check out this awesome currency converter app: $appLink',
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not share: $e')));
      }
    } else {
      // Web: copy to clipboard
      await Clipboard.setData(const ClipboardData(text: appLink));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('App link copied!')));
    }
  }

  // Watchlist Widget Management Section
  Widget _buildWatchlistWidgetSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.widgets, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Watchlist Widget Pairs',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildWatchlistPairsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildWatchlistPairsList() {
    return FutureBuilder<List<String>>(
      future: _getWatchlistPairs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final pairs = snapshot.data ?? [];

        return Column(
          children: [
            // Current pairs display
            if (pairs.isNotEmpty) ...[
              ...pairs.asMap().entries.map((entry) {
                final index = entry.key;
                final pair = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      pair,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Tap to edit'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showEditPairDialog(index, pair),
                    ),
                    onTap: () => _showEditPairDialog(index, pair),
                  ),
                );
              }),
              // Add new pair button
              if (pairs.length < 3) ...[
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green,
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Add New Pair',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    subtitle: const Text('Tap to add another currency pair'),
                    onTap: () => _showEditPairDialog(pairs.length, ''),
                  ),
                ),
              ],
            ] else ...[
              // No pairs configured message with add button
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: const Icon(Icons.info, color: Colors.white),
                  ),
                  title: const Text(
                    'No pairs configured',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Tap the plus icon to add your first currency pair',
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.add_circle,
                      color: Colors.green,
                      size: 28,
                    ),
                    onPressed: () => _showEditPairDialog(0, ''),
                  ),
                  onTap: () => _showEditPairDialog(0, ''),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<List<String>> _getWatchlistPairs() async {
    try {
      // Simple fixed pairs - no database complexity
      final pairs = ['USD/PKR', 'GBP/PKR', 'EUR/PKR'];

      // Save to local preferences for widget
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('watchlist_pairs', pairs);
      final jsonString = '["${pairs.join('","')}"]';
      await prefs.setString('flutter.watchlist_pairs', jsonString);

      print('Using fixed pairs: $pairs');
      return pairs;
    } catch (e) {
      print('Error getting watchlist pairs: $e');
      return ['USD/PKR', 'GBP/PKR', 'EUR/PKR']; // Fallback
    }
  }

  Future<void> _saveWatchlistPairs(List<String> pairs) async {
    final prefs = await SharedPreferences.getInstance();

    // Save to both native and Flutter preferences
    await prefs.setStringList('watchlist_pairs', pairs);

    // Also save as JSON string for Flutter preferences (native widget reads this)
    final jsonString = '["${pairs.join('","')}"]';
    await prefs.setString('flutter.watchlist_pairs', jsonString);

    // Mark that user has configured their own pairs
    await prefs.setBool('has_user_set_pairs', true);

    print('Saved pairs to both preferences: $pairs');

    // Save to Firebase database
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('user_widget_settings')
            .doc(user.uid)
            .set({
              'watchlist_pairs': pairs,
              'updated_at': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error saving to database: $e');
    }

    // Update widget
    try {
      // Clear previous rates for new pairs to ensure proper percentage calculation
      for (String pair in pairs) {
        await prefs.remove('${pair}_previous');
      }

      // Add a small delay to ensure preferences are saved
      await Future.delayed(Duration(milliseconds: 500));

      // Then trigger widget update
      const platform = MethodChannel('currensee_widget_channel');
      await platform.invokeMethod('updateWatchlistWidget');
      print('Watchlist widget update triggered for pairs: $pairs');
    } catch (e) {
      print('Error updating watchlist widget: $e');
    }
  }

  void _showEditPairDialog(int index, String currentPair) {
    String? fromCurrency;
    String? toCurrency;

    // Parse current pair
    final parts = currentPair.split('/');
    if (parts.length == 2) {
      fromCurrency = parts[0];
      toCurrency = parts[1];
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Currency Pair'),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  children: [
                    const Text(
                      'Select currencies for your pair:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    // From Currency Selection
                    const Text(
                      'From Currency:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: _getAvailableCurrencies(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final currencies = snapshot.data!;

                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: currencies.length,
                            itemBuilder: (context, index) {
                              final currency = currencies[index];
                              final isActive = currency['status'] == 'active';
                              final isSelected =
                                  fromCurrency == currency['code'];

                              return Container(
                                width: 100,
                                margin: const EdgeInsets.all(4),
                                child: Card(
                                  color:
                                      isSelected
                                          ? Colors.blue
                                          : (isActive
                                              ? Colors.blue.shade50
                                              : Colors.grey.shade100),
                                  child: InkWell(
                                    onTap:
                                        isActive
                                            ? () {
                                              setState(() {
                                                fromCurrency = currency['code'];
                                              });
                                            }
                                            : null,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          currency['flag'] ?? '🏳️',
                                          style: const TextStyle(fontSize: 24),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          currency['code'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                isSelected
                                                    ? Colors.white
                                                    : (isActive
                                                        ? Colors.black
                                                        : Colors.grey),
                                          ),
                                        ),
                                        Text(
                                          currency['name'],
                                          style: TextStyle(
                                            fontSize: 10,
                                            color:
                                                isSelected
                                                    ? Colors.white70
                                                    : (isActive
                                                        ? Colors.black54
                                                        : Colors.grey),
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // To Currency Selection
                    const Text(
                      'To Currency:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: _getAvailableCurrencies(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final currencies = snapshot.data!;

                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: currencies.length,
                            itemBuilder: (context, index) {
                              final currency = currencies[index];
                              final isActive = currency['status'] == 'active';
                              final isSelected = toCurrency == currency['code'];

                              return Container(
                                width: 100,
                                margin: const EdgeInsets.all(4),
                                child: Card(
                                  color:
                                      isSelected
                                          ? Colors.green
                                          : (isActive
                                              ? Colors.green.shade50
                                              : Colors.grey.shade100),
                                  child: InkWell(
                                    onTap:
                                        isActive
                                            ? () {
                                              setState(() {
                                                toCurrency = currency['code'];
                                              });
                                            }
                                            : null,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          currency['flag'] ?? '🏳️',
                                          style: const TextStyle(fontSize: 24),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          currency['code'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                isSelected
                                                    ? Colors.white
                                                    : (isActive
                                                        ? Colors.black
                                                        : Colors.grey),
                                          ),
                                        ),
                                        Text(
                                          currency['name'],
                                          style: TextStyle(
                                            fontSize: 10,
                                            color:
                                                isSelected
                                                    ? Colors.white70
                                                    : (isActive
                                                        ? Colors.black54
                                                        : Colors.grey),
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Selected pair display
                    if (fromCurrency != null && toCurrency != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              '$fromCurrency → $toCurrency',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed:
                      (fromCurrency != null && toCurrency != null)
                          ? () async {
                            final newPair = '$fromCurrency/$toCurrency';
                            final pairs = await _getWatchlistPairs();

                            if (pairs.length < 3 || index < pairs.length) {
                              if (index < pairs.length) {
                                pairs[index] = newPair;
                              } else {
                                pairs.add(newPair);
                              }

                              await _saveWatchlistPairs(pairs);
                              Navigator.pop(context);
                              setState(() {}); // Refresh UI

                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Pair updated successfully! Widget will refresh shortly.',
                                  ),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                          : null,
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddPairDialog() {
    _showPairDialog();
  }

  void _showPairDialog({int? editIndex, String? currentPair}) {
    String? fromCurrency;
    String? toCurrency;
    String fromSearchQuery = '';
    String toSearchQuery = '';

    if (currentPair != null) {
      final parts = currentPair.split('/');
      if (parts.length == 2) {
        fromCurrency = parts[0];
        toCurrency = parts[1];
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                editIndex != null ? 'Edit Currency Pair' : 'Add Currency Pair',
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Select currencies for your watchlist pair:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    // From Currency Section
                    const Text(
                      'From Currency:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search currency...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          fromSearchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: _getAvailableCurrencies(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final currencies = snapshot.data!;
                          final filteredCurrencies =
                              currencies.where((currency) {
                                final code =
                                    currency['code'].toString().toLowerCase();
                                final name =
                                    currency['name'].toString().toLowerCase();
                                final query = fromSearchQuery.toLowerCase();
                                return code.contains(query) ||
                                    name.contains(query);
                              }).toList();

                          return ListView.builder(
                            itemCount: filteredCurrencies.length,
                            itemBuilder: (context, index) {
                              final currency = filteredCurrencies[index];
                              final isActive = currency['status'] == 'active';
                              final isSelected =
                                  fromCurrency == currency['code'];

                              return ListTile(
                                leading: Text(
                                  currency['flag'] ?? '🏳️',
                                  style: const TextStyle(fontSize: 20),
                                ),
                                title: Text(
                                  '${currency['code']} - ${currency['name']}',
                                  style: TextStyle(
                                    color:
                                        isActive ? Colors.black : Colors.grey,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                                trailing:
                                    isSelected
                                        ? const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        )
                                        : !isActive
                                        ? const Icon(
                                          Icons.block,
                                          color: Colors.red,
                                          size: 16,
                                        )
                                        : null,
                                onTap:
                                    isActive
                                        ? () {
                                          setState(() {
                                            fromCurrency = currency['code'];
                                          });
                                        }
                                        : null,
                                tileColor:
                                    isSelected ? Colors.blue.shade50 : null,
                              );
                            },
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // To Currency Section
                    const Text(
                      'To Currency:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search currency...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          toSearchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: _getAvailableCurrencies(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final currencies = snapshot.data!;
                          final filteredCurrencies =
                              currencies.where((currency) {
                                final code =
                                    currency['code'].toString().toLowerCase();
                                final name =
                                    currency['name'].toString().toLowerCase();
                                final query = toSearchQuery.toLowerCase();
                                return code.contains(query) ||
                                    name.contains(query);
                              }).toList();

                          return ListView.builder(
                            itemCount: filteredCurrencies.length,
                            itemBuilder: (context, index) {
                              final currency = filteredCurrencies[index];
                              final isActive = currency['status'] == 'active';
                              final isSelected = toCurrency == currency['code'];

                              return ListTile(
                                leading: Text(
                                  currency['flag'] ?? '🏳️',
                                  style: const TextStyle(fontSize: 20),
                                ),
                                title: Text(
                                  '${currency['code']} - ${currency['name']}',
                                  style: TextStyle(
                                    color:
                                        isActive ? Colors.black : Colors.grey,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                                trailing:
                                    isSelected
                                        ? const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        )
                                        : !isActive
                                        ? const Icon(
                                          Icons.block,
                                          color: Colors.red,
                                          size: 16,
                                        )
                                        : null,
                                onTap:
                                    isActive
                                        ? () {
                                          setState(() {
                                            toCurrency = currency['code'];
                                          });
                                        }
                                        : null,
                                tileColor:
                                    isSelected ? Colors.blue.shade50 : null,
                              );
                            },
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),
                    if (fromCurrency == toCurrency && fromCurrency != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'From and To currencies cannot be the same!',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed:
                      (fromCurrency != null &&
                              toCurrency != null &&
                              fromCurrency != toCurrency)
                          ? () async {
                            final newPair = '$fromCurrency/$toCurrency';
                            final currentPairs = await _getWatchlistPairs();

                            if (editIndex != null) {
                              // Edit existing pair
                              if (currentPairs.length > editIndex) {
                                currentPairs[editIndex] = newPair;
                              }
                            } else {
                              // Add new pair
                              if (currentPairs.length >= 3) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Maximum 3 pairs allowed. Please remove one first.',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              currentPairs.add(newPair);
                            }

                            await _saveWatchlistPairs(currentPairs);
                            Navigator.pop(context);

                            // Refresh the UI
                            setState(() {});

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  editIndex != null
                                      ? 'Pair updated!'
                                      : 'Pair added!',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                          : null,
                  child: Text(editIndex != null ? 'Update' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getAvailableCurrencies() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('currencies').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'code': doc.id,
          'name': data['name'] ?? '',
          'flag': data['flag'] ?? '🏳️',
          'status': data['status'] ?? 'active',
        };
      }).toList();
    } catch (e) {
      print('Error fetching currencies: $e');
      return [];
    }
  }

  Future<void> _refreshWatchlistWidget() async {
    try {
      const platform = MethodChannel('currensee_widget_channel');
      await platform.invokeMethod('updateWatchlistWidget');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Watchlist widget refreshed!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error refreshing watchlist widget: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error refreshing widget: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _refreshConverterWidget() async {
    try {
      const platform = MethodChannel('currensee_widget_channel');
      await platform.invokeMethod('updateConverterWidget');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Converter widget refreshed!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error refreshing converter widget: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error refreshing widget: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removePair(int index) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Pair'),
          content: const Text(
            'Are you sure you want to remove this currency pair?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final currentPairs = await _getWatchlistPairs();
                if (currentPairs.length > index) {
                  currentPairs.removeAt(index);
                  await _saveWatchlistPairs(currentPairs);

                  // Refresh the UI
                  setState(() {});

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pair removed!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  // Converter Widget Management Section
  Widget _buildConverterWidgetSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.currency_exchange, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Currency Converter Widget',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildConverterPairDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildConverterPairDisplay() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getConverterPair(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final pair =
            snapshot.data ?? {'fromCurrency': 'USD', 'toCurrency': 'PKR'};

        return Column(
          children: [
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green,
                  child: const Icon(
                    Icons.currency_exchange,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  '${pair['fromCurrency']} → ${pair['toCurrency']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Current converter pair'),
              ),
            ),

            const SizedBox(height: 16),

            // Edit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showConverterPairDialog(),
                icon: const Icon(Icons.edit),
                label: const Text('Change Converter Pair'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getConverterPair() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'fromCurrency': prefs.getString('converter_from_currency') ?? 'USD',
      'toCurrency': prefs.getString('converter_to_currency') ?? 'PKR',
    };
  }

  Future<void> _saveConverterPair(
    String fromCurrency,
    String toCurrency,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('converter_from_currency', fromCurrency);
    await prefs.setString('converter_to_currency', toCurrency);

    // Update widget
    try {
      const platform = MethodChannel('currensee_widget_channel');
      await platform.invokeMethod('updateConverterWidget');
    } catch (e) {
      print('Error updating converter widget: $e');
    }
  }

  void _showConverterPairDialog() {
    String? fromCurrency;
    String? toCurrency;
    String fromSearchQuery = '';
    String toSearchQuery = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Configure Converter Widget'),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Select currencies for your converter widget:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    // From Currency Section
                    const Text(
                      'From Currency:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search currency...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          fromSearchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: _getAvailableCurrencies(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final currencies = snapshot.data!;
                          final filteredCurrencies =
                              currencies.where((currency) {
                                final code =
                                    currency['code'].toString().toLowerCase();
                                final name =
                                    currency['name'].toString().toLowerCase();
                                final query = fromSearchQuery.toLowerCase();
                                return code.contains(query) ||
                                    name.contains(query);
                              }).toList();

                          return ListView.builder(
                            itemCount: filteredCurrencies.length,
                            itemBuilder: (context, index) {
                              final currency = filteredCurrencies[index];
                              final isActive = currency['status'] == 'active';
                              final isSelected =
                                  fromCurrency == currency['code'];

                              return ListTile(
                                leading: Text(
                                  currency['flag'] ?? '🏳️',
                                  style: const TextStyle(fontSize: 20),
                                ),
                                title: Text(
                                  '${currency['code']} - ${currency['name']}',
                                  style: TextStyle(
                                    color:
                                        isActive ? Colors.black : Colors.grey,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                                trailing:
                                    isSelected
                                        ? const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        )
                                        : !isActive
                                        ? const Icon(
                                          Icons.block,
                                          color: Colors.red,
                                          size: 16,
                                        )
                                        : null,
                                onTap:
                                    isActive
                                        ? () {
                                          setState(() {
                                            fromCurrency = currency['code'];
                                          });
                                        }
                                        : null,
                                tileColor:
                                    isSelected ? Colors.blue.shade50 : null,
                              );
                            },
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // To Currency Section
                    const Text(
                      'To Currency:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search currency...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          toSearchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: _getAvailableCurrencies(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final currencies = snapshot.data!;
                          final filteredCurrencies =
                              currencies.where((currency) {
                                final code =
                                    currency['code'].toString().toLowerCase();
                                final name =
                                    currency['name'].toString().toLowerCase();
                                final query = toSearchQuery.toLowerCase();
                                return code.contains(query) ||
                                    name.contains(query);
                              }).toList();

                          return ListView.builder(
                            itemCount: filteredCurrencies.length,
                            itemBuilder: (context, index) {
                              final currency = filteredCurrencies[index];
                              final isActive = currency['status'] == 'active';
                              final isSelected = toCurrency == currency['code'];

                              return ListTile(
                                leading: Text(
                                  currency['flag'] ?? '🏳️',
                                  style: const TextStyle(fontSize: 20),
                                ),
                                title: Text(
                                  '${currency['code']} - ${currency['name']}',
                                  style: TextStyle(
                                    color:
                                        isActive ? Colors.black : Colors.grey,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                                trailing:
                                    isSelected
                                        ? const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        )
                                        : !isActive
                                        ? const Icon(
                                          Icons.block,
                                          color: Colors.red,
                                          size: 16,
                                        )
                                        : null,
                                onTap:
                                    isActive
                                        ? () {
                                          setState(() {
                                            toCurrency = currency['code'];
                                          });
                                        }
                                        : null,
                                tileColor:
                                    isSelected ? Colors.blue.shade50 : null,
                              );
                            },
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),
                    if (fromCurrency == toCurrency && fromCurrency != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'From and To currencies cannot be the same!',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed:
                      (fromCurrency != null &&
                              toCurrency != null &&
                              fromCurrency != toCurrency)
                          ? () async {
                            await _saveConverterPair(
                              fromCurrency!,
                              toCurrency!,
                            );
                            Navigator.pop(context);

                            // Refresh the UI
                            setState(() {});

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Converter widget updated!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                          : null,
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationHistorySection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Notification History',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'View all your notification history including alerts and app updates',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Collections: alert_history, version_history',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  onPressed: _testCollections,
                  icon: const Icon(Icons.bug_report, size: 14),
                  label: const Text('Test', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: const Size(0, 0),
                  ),
                ),
                TextButton.icon(
                  onPressed: _addTestData,
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Add Test', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: const Size(0, 0),
                  ),
                ),
                TextButton.icon(
                  onPressed: _refreshNotificationHistory,
                  icon: const Icon(Icons.refresh, size: 14),
                  label: const Text('Refresh', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: const Size(0, 0),
                  ),
                ),
                TextButton.icon(
                  onPressed: _testDirectQuery,
                  icon: const Icon(Icons.search, size: 14),
                  label: const Text(
                    'Direct Query',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: const Size(0, 0),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Alert History Section
        _buildAlertHistorySection(),
        const SizedBox(height: 16),

        // App Version History Section
        _buildAppVersionHistorySection(),
      ],
    );
  }

  Widget _buildAlertHistorySection() {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Alert Notifications',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                StreamBuilder<List<AlertHistory>>(
                  stream: AlertHistoryService.getUserAlertHistory(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      return TextButton.icon(
                        onPressed: _clearAlertHistory,
                        icon: const Icon(Icons.clear_all, size: 16),
                        label: const Text('Clear All'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<AlertHistory>>(
              stream: AlertHistoryService.getUserAlertHistory(),
              builder: (context, snapshot) {
                print(
                  'Alert History StreamBuilder - ConnectionState: ${snapshot.connectionState}',
                );
                print(
                  'Alert History StreamBuilder - HasData: ${snapshot.hasData}',
                );
                print(
                  'Alert History StreamBuilder - HasError: ${snapshot.hasError}',
                );
                if (snapshot.hasError) {
                  print(
                    'Alert History StreamBuilder - Error: ${snapshot.error}',
                  );
                }
                if (snapshot.hasData) {
                  print(
                    'Alert History StreamBuilder - Data length: ${snapshot.data?.length}',
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      children: [
                        SizedBox(height: 20),
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text(
                          'Loading alert history...',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Collection: alert_history',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'If loading takes too long, try Refresh button',
                          style: TextStyle(fontSize: 10, color: Colors.orange),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red[300],
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error loading alert history',
                          style: TextStyle(
                            color: Colors.red[300],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final alertHistory = snapshot.data ?? [];

                if (alertHistory.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.notifications_off,
                          color: Colors.grey,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No alert notifications yet',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Collection: alert_history (empty)',
                          style: TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: alertHistory.length,
                  separatorBuilder:
                      (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final alert = alertHistory[index];
                    return _buildAlertHistoryItem(alert);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertHistoryItem(AlertHistory alert) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, HH:mm');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.currency_exchange,
              color: Colors.orange,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.notificationTitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  alert.notificationBody,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${alert.baseCurrency} → ${alert.targetCurrency}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Target: ${alert.targetRate.toStringAsFixed(4)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Rate: ${alert.currentRate.toStringAsFixed(4)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                dateFormat.format(alert.triggeredAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 16),
                onPressed: () => _deleteAlertHistory(alert.id),
                style: IconButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.all(4),
                  minimumSize: const Size(24, 24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppVersionHistorySection() {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.system_update, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'App Update Notifications',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                StreamBuilder<List<VersionHistory>>(
                  stream: VersionHistoryService.getUserVersionHistory(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      return TextButton.icon(
                        onPressed: _clearAppVersionHistory,
                        icon: const Icon(Icons.clear_all, size: 16),
                        label: const Text('Clear All'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<VersionHistory>>(
              stream: VersionHistoryService.getUserVersionHistory(),
              builder: (context, snapshot) {
                print(
                  'Version History StreamBuilder - ConnectionState: ${snapshot.connectionState}',
                );
                print(
                  'Version History StreamBuilder - HasData: ${snapshot.hasData}',
                );
                print(
                  'Version History StreamBuilder - HasError: ${snapshot.hasError}',
                );
                if (snapshot.hasError) {
                  print(
                    'Version History StreamBuilder - Error: ${snapshot.error}',
                  );
                }
                if (snapshot.hasData) {
                  print(
                    'Version History StreamBuilder - Data length: ${snapshot.data?.length}',
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      children: [
                        SizedBox(height: 20),
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text(
                          'Loading app version history...',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Collection: version_history',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red[300],
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error loading app version history',
                          style: TextStyle(
                            color: Colors.red[300],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final versionHistory = snapshot.data ?? [];

                if (versionHistory.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.system_update_alt,
                          color: Colors.grey,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No app update notifications yet',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Collection: version_history (empty)',
                          style: TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: versionHistory.length,
                  separatorBuilder:
                      (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final version = versionHistory[index];
                    return _buildAppVersionHistoryItem(version);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppVersionHistoryItem(VersionHistory version) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, HH:mm');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.system_update, color: Colors.blue, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Version ${version.version}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getUpdateTypeColor(
                          version.updateType,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getUpdateTypeText(version.updateType),
                        style: TextStyle(
                          fontSize: 10,
                          color: _getUpdateTypeColor(version.updateType),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (version.releaseNotes != null &&
                    version.releaseNotes!.isNotEmpty)
                  Text(
                    version.releaseNotes!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Build ${version.buildNumber}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        version.platform.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.purple[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                dateFormat.format(version.timestamp),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 16),
                onPressed: () => _deleteAppVersionHistory(version.id),
                style: IconButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.all(4),
                  minimumSize: const Size(24, 24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getUpdateTypeColor(String updateType) {
    switch (updateType.toLowerCase()) {
      case 'available':
        return Colors.blue;
      case 'downloaded':
        return Colors.orange;
      case 'installed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getUpdateTypeText(String updateType) {
    switch (updateType.toLowerCase()) {
      case 'available':
        return 'Available';
      case 'downloaded':
        return 'Downloaded';
      case 'installed':
        return 'Installed';
      default:
        return updateType;
    }
  }

  Future<void> _clearAlertHistory() async {
    try {
      await AlertHistoryService.clearAllAlertHistory();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alert history cleared successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing alert history: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _clearAppVersionHistory() async {
    try {
      await VersionHistoryService.clearAllVersionHistory();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('App version history cleared successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing app version history: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAlertHistory(String alertId) async {
    try {
      await AlertHistoryService.deleteAlertHistory(alertId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alert notification deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting alert notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAppVersionHistory(String versionId) async {
    try {
      await VersionHistoryService.deleteVersionHistory(versionId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('App version notification deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting app version notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Test method to check if collections exist and indexes are working
  Future<void> _testCollections() async {
    print('=== Starting Collection Test ===');
    try {
      final user = FirebaseAuth.instance.currentUser;
      String userStatus =
          user != null ? 'Logged in: ${user.uid}' : 'Not logged in';

      print('=== Collection Test Results ===');
      print('User Status: $userStatus');

      // Test alert_history collection (without user filter first)
      try {
        final alertSnapshotAll =
            await FirebaseFirestore.instance
                .collection('alert_history')
                .limit(5)
                .get();

        print(
          'Alert history collection exists: ${alertSnapshotAll.docs.length} total documents',
        );

        if (user != null) {
          final alertSnapshotUser =
              await FirebaseFirestore.instance
                  .collection('alert_history')
                  .where('userId', isEqualTo: user.uid)
                  .limit(5)
                  .get();

          print(
            'Alert history for user: ${alertSnapshotUser.docs.length} documents',
          );
        }
      } catch (e) {
        print('Alert history collection error: $e');
      }

      // Test version_history collection (without user filter first)
      try {
        final versionSnapshotAll =
            await FirebaseFirestore.instance
                .collection('version_history')
                .limit(5)
                .get();

        print(
          'Version history collection exists: ${versionSnapshotAll.docs.length} total documents',
        );

        if (user != null) {
          final versionSnapshotUser =
              await FirebaseFirestore.instance
                  .collection('version_history')
                  .where('userId', isEqualTo: user.uid)
                  .limit(5)
                  .get();

          print(
            'Version history for user: ${versionSnapshotUser.docs.length} documents',
          );
        }
      } catch (e) {
        print('Version history collection error: $e');
      }

      // Check for missing indexes
      print('=== Checking for missing indexes ===');
      final indexResults = await FirestoreIndexService.checkMissingIndexes();
      final indexSummary = FirestoreIndexService.getIndexStatusSummary(
        indexResults,
      );
      print('Index Status: $indexSummary');

      // Show results
      String message = 'User: $userStatus\n';
      message +=
          'Alert History: ${await _getCollectionCount('alert_history')}\n';
      message +=
          'Version History: ${await _getCollectionCount('version_history')}\n';
      message += 'Index Status: $indexSummary';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 8),
        ),
      );

      // Show index creation dialog if indexes are missing
      if (indexResults.values.any((result) => result['status'] == 'missing')) {
        FirestoreIndexService.showIndexCreationDialog(context, indexResults);
      }
    } catch (e) {
      print('Error testing collections: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<String> _getCollectionCount(String collectionName) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection(collectionName)
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) {
        return 'Collection empty';
      } else {
        return '${snapshot.docs.length}+ documents';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  // Get alert history as Future for testing
  Future<List<AlertHistory>> _getAlertHistoryFuture() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user logged in for alert history future');
        return <AlertHistory>[];
      }

      print('Getting alert history future for user: ${user.uid}');

      final snapshot =
          await FirebaseFirestore.instance
              .collection('alert_history')
              .where('userId', isEqualTo: user.uid)
              .orderBy('triggeredAt', descending: true)
              .limit(100)
              .get();

      print('Alert History Future: ${snapshot.docs.length} documents');

      final alertHistory =
          snapshot.docs
              .map((doc) {
                try {
                  final data = doc.data();
                  print('Processing alert history document: ${doc.id}');
                  return AlertHistory.fromJson(data, doc.id);
                } catch (e) {
                  print('Error parsing alert history document ${doc.id}: $e');
                  return null;
                }
              })
              .where((alert) => alert != null)
              .cast<AlertHistory>()
              .toList();

      print(
        'Alert History Future: Successfully parsed ${alertHistory.length} records',
      );
      return alertHistory;
    } catch (e) {
      print('Error in alert history future: $e');
      return <AlertHistory>[];
    }
  }

  // Test direct query to check if data exists
  Future<void> _testDirectQuery() async {
    try {
      print('=== Testing Direct Query ===');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login first'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      print('User ID: ${user.uid}');

      // Test alert history directly
      final alertSnapshot =
          await FirebaseFirestore.instance
              .collection('alert_history')
              .where('userId', isEqualTo: user.uid)
              .limit(5)
              .get();

      print(
        'Alert History Direct Query: ${alertSnapshot.docs.length} documents',
      );

      // Test version history directly
      final versionSnapshot =
          await FirebaseFirestore.instance
              .collection('version_history')
              .where('userId', isEqualTo: user.uid)
              .limit(5)
              .get();

      print(
        'Version History Direct Query: ${versionSnapshot.docs.length} documents',
      );

      // Test without user filter to see if collections exist
      final allAlertSnapshot =
          await FirebaseFirestore.instance
              .collection('alert_history')
              .limit(5)
              .get();

      final allVersionSnapshot =
          await FirebaseFirestore.instance
              .collection('version_history')
              .limit(5)
              .get();

      print('All Alert History: ${allAlertSnapshot.docs.length} documents');
      print('All Version History: ${allVersionSnapshot.docs.length} documents');

      String message = 'Direct Query Results:\n';
      message += 'User Alert History: ${alertSnapshot.docs.length} docs\n';
      message += 'User Version History: ${versionSnapshot.docs.length} docs\n';
      message += 'Total Alert History: ${allAlertSnapshot.docs.length} docs\n';
      message +=
          'Total Version History: ${allVersionSnapshot.docs.length} docs';

      if (alertSnapshot.docs.isNotEmpty) {
        final firstAlert = alertSnapshot.docs.first.data();
        message += '\nFirst Alert: ${firstAlert['notificationTitle']}';
      }

      if (versionSnapshot.docs.isNotEmpty) {
        final firstVersion = versionSnapshot.docs.first.data();
        message += '\nFirst Version: ${firstVersion['version']}';
      }

      if (allAlertSnapshot.docs.isNotEmpty) {
        final firstAllAlert = allAlertSnapshot.docs.first.data();
        message += '\nFirst All Alert User: ${firstAllAlert['userId']}';
      }

      if (allVersionSnapshot.docs.isNotEmpty) {
        final firstAllVersion = allVersionSnapshot.docs.first.data();
        message += '\nFirst All Version User: ${firstAllVersion['userId']}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 10),
        ),
      );
    } catch (e) {
      print('Error in direct query: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Direct Query Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Refresh notification history
  Future<void> _refreshNotificationHistory() async {
    try {
      print('=== Refreshing Notification History ===');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login first'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Force refresh by rebuilding the widget
      setState(() {
        // This will trigger a rebuild and refresh the streams
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification history refreshed'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error refreshing notification history: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error refreshing: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Build reset and clear notifications section
  Widget _buildResetAndClearSection() {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cleaning_services, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Reset & Clear Data',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Clear all notifications, reset app settings, or perform a complete app reset',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _clearAllNotifications,
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Clear All Notifications'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _resetAppSettings,
                    icon: const Icon(Icons.settings_backup_restore, size: 16),
                    label: const Text('Reset Settings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showResetAppDialog,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Complete App Reset'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Reset app settings to defaults
  Future<void> _resetAppSettings() async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Reset App Settings'),
              content: const Text(
                'This will reset all app settings to default values:\n'
                '• Theme settings\n'
                '• Currency preferences\n'
                '• Notification settings\n'
                '• Calculator settings\n'
                '• Other app preferences\n\n'
                'Your data and account will remain intact. Continue?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text('Reset Settings'),
                ),
              ],
            ),
      );

      if (confirmed != true) return;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Resetting settings...'),
                ],
              ),
            ),
      );

      // Reset all settings to defaults
      final prefs = await SharedPreferences.getInstance();

      // Reset theme settings
      await prefs.remove('darkMode');
      await prefs.remove('themeMode');

      // Reset currency settings
      await prefs.remove('baseCurrency');
      await prefs.remove('decimalPlaces');
      await prefs.remove('favoriteCurrencies');

      // Reset notification settings
      await prefs.remove('notificationSound');
      await prefs.remove('hapticFeedback');
      await prefs.remove('autoUpdateRates');

      // Reset calculator settings
      await prefs.remove('showCalculator');

      // Reset other settings
      await prefs.remove('biometricAuth');
      await prefs.remove('vibrationEnabled');
      await prefs.remove('historicalData');
      await prefs.remove('offlineMode');
      await prefs.remove('selectedLanguage');
      await prefs.remove('selectedAppearance');

      // Update UI state
      setState(() {
        _darkMode = false;
        _decimalPlaces = 2;
        _baseCurrency = 'USD';
        _autoUpdateRates = true;
        _biometricAuth = false;
        _hapticFeedback = true;
        _showCalculator = true;
        _historicalData = false;
        _offlineMode = false;
        _selectedLanguage = 'English';
        _selectedAppearance = 'System';
        _notificationSound = '';
      });

      // Update provider
      final appSettings = Provider.of<AppSettings>(context, listen: false);
      appSettings.setDarkMode(false);
      appSettings.setDecimalPlaces(2);
      appSettings.setBaseCurrency('USD');
      appSettings.setAutoUpdateRates(true);
      appSettings.setBiometricAuth(false);
      appSettings.setHapticFeedback(true);
      appSettings.setShowCalculator(true);
      appSettings.setHistoricalData(false);
      appSettings.setOfflineMode(false);
      appSettings.setSelectedLanguage('English');
      appSettings.setSelectedAppearance('System');

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('App settings reset to defaults successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print('Error resetting app settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error resetting settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Add test data to collections
  Future<void> _addTestData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login first'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Add test alert history
      await FirebaseFirestore.instance.collection('alert_history').add({
        'userId': user.uid,
        'alertId': 'test_alert_${DateTime.now().millisecondsSinceEpoch}',
        'baseCurrency': 'USD',
        'targetCurrency': 'PKR',
        'targetRate': 280.0,
        'triggerType': 'above',
        'triggeredAt': FieldValue.serverTimestamp(),
        'currentRate': 285.50,
        'notificationTitle': 'Test Alert Triggered',
        'notificationBody': 'USD to PKR rate is now 285.50',
        'sound': 'default',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Add test version history
      await FirebaseFirestore.instance.collection('version_history').add({
        'userId': user.uid,
        'userName': user.displayName ?? 'Test User',
        'userEmail': user.email ?? 'test@example.com',
        'userPhotoUrl': user.photoURL,
        'version': AppVersionService.getAppVersionSync(),
        'buildNumber': '100',
        'platform': 'android',
        'updateType': 'available',
        'downloadUrl': 'https://example.com/app.apk',
        'releaseNotes': 'Test version with new features',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test data added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error adding test data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding test data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Clear all notifications from all collections
  Future<void> _clearAllNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login first'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Clear All Notifications'),
              content: const Text(
                'This will clear all your notification history including:\n'
                '• Alert notifications\n'
                '• App update notifications\n'
                '• Task notifications\n'
                '• All other notification history\n\n'
                'This action cannot be undone. Continue?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('Clear All'),
                ),
              ],
            ),
      );

      if (confirmed != true) return;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Clearing all notifications...'),
                ],
              ),
            ),
      );

      // Clear alert history
      await AlertHistoryService.clearAllAlertHistory();

      // Clear version history
      await VersionHistoryService.clearAllVersionHistory();

      // Clear task history
      await TaskService().clearAllTaskHistory();

      // Clear local notification history
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('notification_history');

      // Clear any other notification-related data
      await prefs.remove('lastAlertCheck');
      await prefs.remove('lastNotificationTime');

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications cleared successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print('Error clearing all notifications: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing notifications: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show complete app reset dialog
  Future<void> _showResetAppDialog() async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Complete App Reset'),
              content: const Text(
                '⚠️ WARNING: This will completely reset the app!\n\n'
                'This action will:\n'
                '• Clear ALL notifications and history\n'
                '• Reset ALL settings to defaults\n'
                '• Clear ALL local data\n'
                '• Remove ALL saved preferences\n'
                '• Log you out of your account\n\n'
                'This action cannot be undone. Are you absolutely sure?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Reset App'),
                ),
              ],
            ),
      );

      if (confirmed != true) return;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Performing complete app reset...'),
                ],
              ),
            ),
      );

      // Clear all notifications first
      await _clearAllNotifications();

      // Clear all local data
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Sign out user
      await FirebaseAuth.instance.signOut();

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('App reset complete! Please restart the app.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );

      // Navigate to login page
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/signin',
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print('Error performing complete app reset: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error resetting app: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
