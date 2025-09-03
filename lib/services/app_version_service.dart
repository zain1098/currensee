import 'package:package_info_plus/package_info_plus.dart';

class AppVersionService {
  static String _cachedVersion = '';
  static bool _isInitialized = false;

  /// Get the current app version dynamically
  static Future<String> getAppVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      _cachedVersion = packageInfo.version;
      _isInitialized = true;
      print('📱 Dynamic version loaded: $_cachedVersion');
      return _cachedVersion;
    } catch (e) {
      print('❌ Error loading package info: $e');
      // Force re-initialization on next call
      _isInitialized = false;
      _cachedVersion = 'Error loading version';
      return _cachedVersion;
    }
  }

  /// Get the current app version synchronously (returns cached version)
  static String getAppVersionSync() {
    return _cachedVersion.isNotEmpty ? _cachedVersion : '1.0.6';
  }

  /// Initialize the version service (call this in main.dart)
  static Future<void> initialize() async {
    await getAppVersion();
  }

  /// Clear cache and reinitialize
  static void clearCache() {
    _cachedVersion = '';
    _isInitialized = false;
  }
}
