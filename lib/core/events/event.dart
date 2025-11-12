/// 📤 Event - Base event class for hybrid architecture
/// 
/// All events in the system use this structure.
/// Events are fired locally and sent to backend asynchronously.
library;

import 'package:flutter/foundation.dart';

/// Event class representing a single analytics/tracking event
/// 
/// Structure:
/// - name: Event type (e.g., "game_ended", "purchase_completed")
/// - data: Event-specific payload
/// - userId: User who triggered the event
/// - sessionId: Current session
/// - timestamp: When event occurred
@immutable
class Event {
  /// Event type/name (e.g., "game_ended")
  final String name;
  
  /// Event-specific data payload
  final Map<String, dynamic> data;
  
  /// User who triggered the event
  final String userId;
  
  /// Current session ID
  final String sessionId;
  
  /// When the event occurred
  final DateTime timestamp;
  
  /// Create a new event
  const Event({
    required this.name,
    required this.data,
    required this.userId,
    required this.sessionId,
    required this.timestamp,
  });
  
  /// Create event from JSON
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      name: json['name'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map),
      userId: json['userId'] as String,
      sessionId: json['sessionId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
  
  /// Convert event to JSON for transmission
  /// 
  /// Backend expects these base fields for ALL events:
  /// - event_type (string, required)
  /// - user_id (string, required)
  /// - timestamp (ISO string, required)
  /// - app_version (string, required)
  /// - platform ('ios' | 'android', required)
  /// 
  /// Plus event-specific payload fields merged into the root object
  Map<String, dynamic> toJson() {
    return {
      'event_type': name,
      'user_id': userId,
      'session_id': sessionId,
      'timestamp': timestamp.toIso8601String(),
      // Merge event-specific payload directly into root (not nested)
      ...data,
    };
  }
  
  /// Create a copy with updated fields
  Event copyWith({
    String? name,
    Map<String, dynamic>? data,
    String? userId,
    String? sessionId,
    DateTime? timestamp,
  }) {
    return Event(
      name: name ?? this.name,
      data: data ?? this.data,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      timestamp: timestamp ?? this.timestamp,
    );
  }
  
  @override
  String toString() {
    return 'Event(name: $name, userId: ${userId.substring(0, 10)}..., '
           'sessionId: ${sessionId.substring(0, 10)}..., timestamp: $timestamp)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Event &&
        other.name == name &&
        other.userId == userId &&
        other.sessionId == sessionId &&
        other.timestamp == timestamp;
  }
  
  @override
  int get hashCode {
    return Object.hash(name, userId, sessionId, timestamp);
  }
}

