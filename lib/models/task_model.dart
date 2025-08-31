import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Task {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String? userPhotoUrl;
  final String taskName;
  final String fromCurrency;
  final String toCurrency;
  final double amount;
  final String frequency; // "daily", "weekly", "monthly"
  final TimeOfDay time;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastExecuted;
  final DateTime? nextExecution;

  Task({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userPhotoUrl,
    required this.taskName,
    required this.fromCurrency,
    required this.toCurrency,
    required this.amount,
    required this.frequency,
    required this.time,
    this.isActive = true,
    required this.createdAt,
    this.lastExecuted,
    this.nextExecution,
  });

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhotoUrl': userPhotoUrl,
      'taskName': taskName,
      'fromCurrency': fromCurrency,
      'toCurrency': toCurrency,
      'amount': amount,
      'frequency': frequency,
      'time': {'hour': time.hour, 'minute': time.minute},
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastExecuted':
          lastExecuted != null ? Timestamp.fromDate(lastExecuted!) : null,
      'nextExecution':
          nextExecution != null ? Timestamp.fromDate(nextExecution!) : null,
    };
  }

  // Create from Map (Firebase document)
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      userPhotoUrl: map['userPhotoUrl'],
      taskName: map['taskName'] ?? '',
      fromCurrency: map['fromCurrency'] ?? '',
      toCurrency: map['toCurrency'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      frequency: map['frequency'] ?? 'daily',
      time: _parseTimeOfDay(map['time']),
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastExecuted:
          map['lastExecuted'] != null
              ? (map['lastExecuted'] as Timestamp).toDate()
              : null,
      nextExecution:
          map['nextExecution'] != null
              ? (map['nextExecution'] as Timestamp).toDate()
              : null,
    );
  }

  // Create a copy with updated fields
  Task copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    String? userPhotoUrl,
    String? taskName,
    String? fromCurrency,
    String? toCurrency,
    double? amount,
    String? frequency,
    TimeOfDay? time,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastExecuted,
    DateTime? nextExecution,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      taskName: taskName ?? this.taskName,
      fromCurrency: fromCurrency ?? this.fromCurrency,
      toCurrency: toCurrency ?? this.toCurrency,
      amount: amount ?? this.amount,
      frequency: frequency ?? this.frequency,
      time: time ?? this.time,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastExecuted: lastExecuted ?? this.lastExecuted,
      nextExecution: nextExecution ?? this.nextExecution,
    );
  }

  // Get display name for the task
  String get displayName {
    return '$amount $fromCurrency → $toCurrency';
  }

  // Get frequency display text
  String get frequencyDisplay {
    switch (frequency) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      default:
        return 'Daily';
    }
  }

  // Get time display text
  String get timeDisplay {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'Task(id: $id, taskName: $taskName, fromCurrency: $fromCurrency, toCurrency: $toCurrency, amount: $amount, frequency: $frequency, isActive: $isActive)';
  }

  // Helper method to parse int from dynamic value
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  // Helper method to parse TimeOfDay from various formats
  static TimeOfDay _parseTimeOfDay(dynamic timeData) {
    try {
      // Handle null or empty time data
      if (timeData == null) {
        return const TimeOfDay(hour: 9, minute: 0); // Default time
      }

      // Handle if timeData is already a TimeOfDay (unlikely but safe)
      if (timeData is TimeOfDay) {
        return timeData;
      }

      // Handle if timeData is a Map
      if (timeData is Map) {
        final hour = _parseInt(timeData['hour']) ?? 9;
        final minute = _parseInt(timeData['minute']) ?? 0;
        return TimeOfDay(hour: hour, minute: minute);
      }

      // Handle if timeData is a String (e.g., "09:30")
      if (timeData is String) {
        final parts = timeData.split(':');
        if (parts.length == 2) {
          final hour = int.tryParse(parts[0]) ?? 9;
          final minute = int.tryParse(parts[1]) ?? 0;
          return TimeOfDay(hour: hour, minute: minute);
        }
      }

      // Default fallback
      return const TimeOfDay(hour: 9, minute: 0);
    } catch (e) {
      print('Error parsing TimeOfDay: $e, data: $timeData');
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }
}

class TaskHistory {
  final String notificationId;
  final String taskId;
  final String userId;
  final double rate;
  final double convertedAmount;
  final DateTime triggeredAt;
  final bool isRead;

  TaskHistory({
    required this.notificationId,
    required this.taskId,
    required this.userId,
    required this.rate,
    required this.convertedAmount,
    required this.triggeredAt,
    this.isRead = false,
  });

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'notificationId': notificationId,
      'taskId': taskId,
      'userId': userId,
      'rate': rate,
      'convertedAmount': convertedAmount,
      'triggeredAt': Timestamp.fromDate(triggeredAt),
      'isRead': isRead,
    };
  }

  // Create from Map (Firebase document)
  factory TaskHistory.fromMap(Map<String, dynamic> map) {
    return TaskHistory(
      notificationId: map['notificationId'] ?? '',
      taskId: map['taskId'] ?? '',
      userId: map['userId'] ?? '',
      rate: (map['rate'] ?? 0.0).toDouble(),
      convertedAmount: (map['convertedAmount'] ?? 0.0).toDouble(),
      triggeredAt:
          map['triggeredAt'] != null
              ? (map['triggeredAt'] as Timestamp).toDate()
              : DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }

  // Create a copy with updated fields
  TaskHistory copyWith({
    String? notificationId,
    String? taskId,
    String? userId,
    double? rate,
    double? convertedAmount,
    DateTime? triggeredAt,
    bool? isRead,
  }) {
    return TaskHistory(
      notificationId: notificationId ?? this.notificationId,
      taskId: taskId ?? this.taskId,
      userId: userId ?? this.userId,
      rate: rate ?? this.rate,
      convertedAmount: convertedAmount ?? this.convertedAmount,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  String toString() {
    return 'TaskHistory(notificationId: $notificationId, taskId: $taskId, rate: $rate, convertedAmount: $convertedAmount, isRead: $isRead)';
  }
}
