import 'package:cloud_firestore/cloud_firestore.dart';

class Routine {
  final String id;
  final String patientUid;
  final String title;
  final String description;
  final DateTime time;
  final List<String> days; // e.g., ['Mon', 'Tue', 'Wed']
  final bool isActive;
  final String? notificationId; // For managing notifications
  final String? category; // e.g., 'Medication', 'Meal', 'Exercise', etc.
  final Map<String, dynamic>? additionalData;

  Routine({
    required this.id,
    required this.patientUid,
    required this.title,
    required this.description,
    required this.time,
    required this.days,
    this.isActive = true,
    this.notificationId,
    this.category,
    this.additionalData,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    // Convert time to a consistent format (Timestamp for Firestore)
    final timeToSave = Timestamp.fromDate(time);
    
    return {
      'id': id,
      'patientUid': patientUid,
      'title': title,
      'description': description,
      'time': timeToSave,
      'days': days,
      'isActive': isActive,
      'notificationId': notificationId,
      'category': category,
      'additionalData': additionalData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Convert to JSON for Firestore (kept for backward compatibility)
  Map<String, dynamic> toJson() => toMap();

  // Create from Firestore document
  factory Routine.fromJson(Map<String, dynamic> json) {
    DateTime time;
    
    // Handle different time formats
    if (json['time'] is Map<String, dynamic>) {
      // Old format: time is a map with hour and minute
      final timeData = json['time'] as Map<String, dynamic>;
      time = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        timeData['hour'] as int,
        timeData['minute'] as int,
      );
    } else if (json['time'] is DateTime) {
      // If time is already a DateTime
      time = json['time'] as DateTime;
    } else if (json['time'] is Timestamp) {
      // If time is a Firestore Timestamp
      time = (json['time'] as Timestamp).toDate();
    } else {
      // Fallback to current time
      time = DateTime.now();
    }

    return Routine(
      id: json['id'] as String,
      patientUid: json['patientUid'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      time: time,
      days: List<String>.from((json['days'] as List<dynamic>).map((e) => e.toString())),
      isActive: json['isActive'] as bool? ?? true,
      notificationId: json['notificationId'] as String?,
      category: json['category'] as String?,
      additionalData: json['additionalData'] is Map ? 
          Map<String, dynamic>.from(json['additionalData'] as Map) : null,
    );
  }

  // Create a copy with updated fields
  Routine copyWith({
    String? id,
    String? patientUid,
    String? title,
    String? description,
    DateTime? time,
    List<String>? days,
    bool? isActive,
    String? notificationId,
    String? category,
    Map<String, dynamic>? additionalData,
  }) {
    return Routine(
      id: id ?? this.id,
      patientUid: patientUid ?? this.patientUid,
      title: title ?? this.title,
      description: description ?? this.description,
      time: time ?? this.time,
      days: days ?? this.days,
      isActive: isActive ?? this.isActive,
      notificationId: notificationId ?? this.notificationId,
      category: category ?? this.category,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}
