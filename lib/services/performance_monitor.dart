import 'dart:async';
import 'dart:developer' as developer;

/// 📊 Performance Monitor for CurrenSee App
/// Tracks and monitors app performance metrics
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  // Performance tracking
  static final Map<String, Stopwatch> _activeTimers = {};
  static final List<Map<String, dynamic>> _performanceLog = [];
  static const int _maxLogEntries = 200;

  // Memory tracking
  static final List<Map<String, dynamic>> _memoryLog = [];
  static const int _maxMemoryLogEntries = 50;

  // Error tracking
  static final List<Map<String, dynamic>> _errorLog = [];
  static const int _maxErrorLogEntries = 100;

  // Configuration
  static bool _isEnabled = true;
  static bool _isVerbose = false;

  /// Start timing an operation
  static void startTimer(String operation) {
    if (!_isEnabled) return;

    _activeTimers[operation] = Stopwatch()..start();

    if (_isVerbose) {
      print('⏱️ Started timer: $operation');
    }
  }

  /// End timing an operation and log the result
  static void endTimer(
    String operation, {
    Map<String, dynamic>? additionalData,
  }) {
    if (!_isEnabled) return;

    final timer = _activeTimers[operation];
    if (timer == null) {
      print('⚠️ Timer not found: $operation');
      return;
    }

    timer.stop();
    final duration = timer.elapsedMilliseconds;
    _activeTimers.remove(operation);

    // Log performance data
    final logEntry = {
      'operation': operation,
      'duration': duration,
      'timestamp': DateTime.now().toIso8601String(),
      'type': 'performance',
      if (additionalData != null) ...additionalData,
    };

    _performanceLog.add(logEntry);

    // Keep only recent log entries
    if (_performanceLog.length > _maxLogEntries) {
      _performanceLog.removeRange(0, _performanceLog.length - _maxLogEntries);
    }

    if (_isVerbose) {
      print('⏱️ Timer ended: $operation (${duration}ms)');
    }
  }

  /// Track memory usage
  static void trackMemoryUsage(
    String context, {
    Map<String, dynamic>? additionalData,
  }) {
    if (!_isEnabled) return;

    try {
      // Get memory info (this is a simplified approach)
      final memoryInfo = {
        'context': context,
        'timestamp': DateTime.now().toIso8601String(),
        'type': 'memory',
        'estimatedUsage': _getEstimatedMemoryUsage(),
        if (additionalData != null) ...additionalData,
      };

      _memoryLog.add(memoryInfo);

      // Keep only recent memory log entries
      if (_memoryLog.length > _maxMemoryLogEntries) {
        _memoryLog.removeRange(0, _memoryLog.length - _maxMemoryLogEntries);
      }

      if (_isVerbose) {
        print('💾 Memory tracked: $context');
      }
    } catch (e) {
      print('⚠️ Error tracking memory: $e');
    }
  }

  /// Track error occurrence
  static void trackError(
    String operation,
    String error, {
    Map<String, dynamic>? additionalData,
  }) {
    if (!_isEnabled) return;

    final errorEntry = {
      'operation': operation,
      'error': error,
      'timestamp': DateTime.now().toIso8601String(),
      'type': 'error',
      if (additionalData != null) ...additionalData,
    };

    _errorLog.add(errorEntry);

    // Keep only recent error log entries
    if (_errorLog.length > _maxErrorLogEntries) {
      _errorLog.removeRange(0, _errorLog.length - _maxErrorLogEntries);
    }

    if (_isVerbose) {
      print('❌ Error tracked: $operation - $error');
    }
  }

  /// Track API performance
  static void trackApiCall(
    String endpoint,
    int statusCode,
    int duration, {
    String? error,
  }) {
    if (!_isEnabled) return;

    final apiEntry = {
      'endpoint': endpoint,
      'statusCode': statusCode,
      'duration': duration,
      'timestamp': DateTime.now().toIso8601String(),
      'type': 'api',
      if (error != null) 'error': error,
    };

    _performanceLog.add(apiEntry);

    if (_isVerbose) {
      print('🌐 API tracked: $endpoint (${statusCode}) - ${duration}ms');
    }
  }

  /// Track widget performance
  static void trackWidgetPerformance(
    String widgetName,
    int buildTime, {
    Map<String, dynamic>? additionalData,
  }) {
    if (!_isEnabled) return;

    final widgetEntry = {
      'widget': widgetName,
      'buildTime': buildTime,
      'timestamp': DateTime.now().toIso8601String(),
      'type': 'widget',
      if (additionalData != null) ...additionalData,
    };

    _performanceLog.add(widgetEntry);

    if (_isVerbose) {
      print('📱 Widget tracked: $widgetName - ${buildTime}ms');
    }
  }

  /// Get performance statistics
  static Map<String, dynamic> getPerformanceStats() {
    if (_performanceLog.isEmpty) {
      return {
        'totalOperations': 0,
        'averageDuration': 0,
        'slowestOperation': null,
        'fastestOperation': null,
        'errorCount': _errorLog.length,
        'memoryLogCount': _memoryLog.length,
      };
    }

    final durations =
        _performanceLog
            .where((entry) => entry['duration'] != null)
            .map((entry) => entry['duration'] as int)
            .toList();

    if (durations.isEmpty) {
      return {
        'totalOperations': _performanceLog.length,
        'averageDuration': 0,
        'slowestOperation': null,
        'fastestOperation': null,
        'errorCount': _errorLog.length,
        'memoryLogCount': _memoryLog.length,
      };
    }

    final averageDuration =
        durations.reduce((a, b) => a + b) / durations.length;
    final slowestOperation = _performanceLog
        .where((entry) => entry['duration'] != null)
        .reduce(
          (a, b) => (a['duration'] as int) > (b['duration'] as int) ? a : b,
        );
    final fastestOperation = _performanceLog
        .where((entry) => entry['duration'] != null)
        .reduce(
          (a, b) => (a['duration'] as int) < (b['duration'] as int) ? a : b,
        );

    return {
      'totalOperations': _performanceLog.length,
      'averageDuration': averageDuration.round(),
      'slowestOperation': slowestOperation,
      'fastestOperation': fastestOperation,
      'errorCount': _errorLog.length,
      'memoryLogCount': _memoryLog.length,
      'activeTimers': _activeTimers.length,
    };
  }

  /// Get performance log
  static List<Map<String, dynamic>> getPerformanceLog() {
    return List.from(_performanceLog);
  }

  /// Get memory log
  static List<Map<String, dynamic>> getMemoryLog() {
    return List.from(_memoryLog);
  }

  /// Get error log
  static List<Map<String, dynamic>> getErrorLog() {
    return List.from(_errorLog);
  }

  /// Clear all logs
  static void clearLogs() {
    _performanceLog.clear();
    _memoryLog.clear();
    _errorLog.clear();
    _activeTimers.clear();
  }

  /// Enable/disable performance monitoring
  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
    print('📊 Performance monitoring ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Enable/disable verbose logging
  static void setVerbose(bool verbose) {
    _isVerbose = verbose;
    print('📊 Verbose logging ${verbose ? 'enabled' : 'disabled'}');
  }

  /// Get estimated memory usage (simplified)
  static int _getEstimatedMemoryUsage() {
    // This is a simplified estimation
    // In a real app, you might use platform-specific APIs
    return _performanceLog.length * 1024 +
        _memoryLog.length * 512 +
        _errorLog.length * 256;
  }

  /// Get active timers
  static Map<String, Stopwatch> getActiveTimers() {
    return Map.from(_activeTimers);
  }

  /// Check if timer is active
  static bool isTimerActive(String operation) {
    return _activeTimers.containsKey(operation);
  }

  /// Get timer duration without stopping it
  static int? getTimerDuration(String operation) {
    final timer = _activeTimers[operation];
    return timer?.elapsedMilliseconds;
  }

  /// Generate performance report
  static Map<String, dynamic> generateReport() {
    final stats = getPerformanceStats();
    final recentPerformance = _performanceLog.take(10).toList();
    final recentErrors = _errorLog.take(5).toList();
    final recentMemory = _memoryLog.take(5).toList();

    return {
      'summary': stats,
      'recentPerformance': recentPerformance,
      'recentErrors': recentErrors,
      'recentMemory': recentMemory,
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Log performance report to console
  static void logReport() {
    final report = generateReport();
    print('📊 Performance Report:');
    print('Generated at: ${report['generatedAt']}');
    print('Summary: ${report['summary']}');

    if (report['recentErrors'].isNotEmpty) {
      print('Recent Errors:');
      for (final error in report['recentErrors']) {
        print('  - ${error['operation']}: ${error['error']}');
      }
    }
  }
}
