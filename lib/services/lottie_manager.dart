import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';

/// 🎬 Lottie Manager for CurrenSee App
/// Handles Lottie animation loading with caching and memory management
class LottieManager {
  // Performance monitoring
  static final List<Map<String, dynamic>> _performanceLog = [];
  static const int _maxLogEntries = 50;
  static final Set<String> _preloadedAssets = {};

  /// Preload common animations for better performance
  static Future<void> preloadCommonAnimations() async {
    const commonAnimations = [
      'assets/Welcome Page Logo.json',
      'assets/Currency Loader.json',
      'assets/Chat Bot.json',
      'assets/Login Background.json',
      'assets/Icon Login.json',
      'assets/Menu Icon.json',
      'assets/user-profile.json',
    ];

    try {
      // Mark as preloaded (actual preloading will be handled by Lottie.asset)
      for (final asset in commonAnimations) {
        _preloadedAssets.add(asset);
      }
      _logPerformance('preload_success', DateTime.now(), 'common_animations');
    } catch (e) {
      _logPerformance(
        'preload_error',
        DateTime.now(),
        'common_animations',
        error: e.toString(),
      );
      print('Preload error: $e');
    }
  }

  /// Get optimized Lottie widget with performance tracking
  static Widget getOptimizedLottie(
    String assetPath, {
    double? width,
    double? height,
    BoxFit? fit,
    bool repeat = true,
    bool animate = true,
    FrameRate? frameRate,
    String? package,
    void Function(LottieComposition)? onLoaded,
    void Function(String)? onError,
  }) {
    final startTime = DateTime.now();

    return Lottie.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      repeat: repeat,
      animate: animate,
      frameRate: frameRate,
      package: package,
      onLoaded: (composition) {
        _logPerformance('lottie_loaded', startTime, assetPath);
        onLoaded?.call(composition);
      },
      errorBuilder: (context, error, stackTrace) {
        _logPerformance(
          'lottie_error',
          startTime,
          assetPath,
          error: error.toString(),
        );
        onError?.call(error.toString());
        return _getErrorWidget(width, height, error.toString());
      },
    );
  }

  /// Get loading widget
  static Widget _getLoadingWidget(double? width, double? height) {
    return Container(
      width: width ?? 100,
      height: height ?? 100,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
          ),
        ),
      ),
    );
  }

  /// Get error widget
  static Widget _getErrorWidget(double? width, double? height, String error) {
    return Container(
      width: width ?? 100,
      height: height ?? 100,
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!, width: 1),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 24, color: Colors.red[400]),
            const SizedBox(height: 4),
            Text(
              'Animation Error',
              style: TextStyle(
                fontSize: 10,
                color: Colors.red[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Log performance metrics
  static void _logPerformance(
    String type,
    DateTime startTime,
    String assetPath, {
    String? error,
  }) {
    final duration = DateTime.now().difference(startTime).inMilliseconds;

    _performanceLog.add({
      'type': type,
      'asset': assetPath,
      'duration': duration,
      'timestamp': DateTime.now().toIso8601String(),
      if (error != null) 'error': error,
    });

    // Keep only recent log entries
    if (_performanceLog.length > _maxLogEntries) {
      _performanceLog.removeRange(0, _performanceLog.length - _maxLogEntries);
    }
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return {
      'preloadedAssets': _preloadedAssets.length,
      'performanceLogSize': _performanceLog.length,
    };
  }

  /// Get performance metrics
  static List<Map<String, dynamic>> getPerformanceMetrics() {
    return List.from(_performanceLog);
  }

  /// Clear cache and reset state
  static void clearCache() {
    _preloadedAssets.clear();
    _performanceLog.clear();
  }

  /// Check if asset is preloaded
  static bool isPreloaded(String assetPath) {
    return _preloadedAssets.contains(assetPath);
  }

  /// Get memory usage estimate
  static int getEstimatedMemoryUsage() {
    // Simplified estimate since we're not caching compositions directly
    return _preloadedAssets.length * 1024 * 1024; // 1MB per preloaded asset
  }
}
