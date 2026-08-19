import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents pre-rental or post-rental equipment condition verification details.
class ConditionRecord {
  ConditionRecord({
    required this.photos,
    required this.notes,
    required this.checklist,
    required this.timestamp,
    required this.verifiedBy,
    this.stage = 'pre', // 'pre' or 'post'
  });

  final List<String> photos;
  final String notes;
  final Map<String, bool> checklist;
  final DateTime timestamp;
  final String verifiedBy;
  final String stage;

  /// Default standard equipment checklist items.
  static Map<String, bool> defaultChecklist() {
    return {
      'Engine & Transmission Operational': true,
      'Tires / Tracks Condition Good': true,
      'Fuel / Battery Level Verified': true,
      'Exterior Body Intact (No Cracks/Leaks)': true,
      'Safety Controls & Brakes Functional': true,
    };
  }

  factory ConditionRecord.fromMap(Map<String, dynamic> data) {
    final rawChecklist = data['checklist'];
    Map<String, bool> parsedChecklist = {};
    if (rawChecklist is Map) {
      rawChecklist.forEach((key, value) {
        parsedChecklist[key.toString()] = value == true;
      });
    }

    final rawPhotos = data['photos'];
    List<String> parsedPhotos = [];
    if (rawPhotos is List) {
      parsedPhotos = rawPhotos.map((e) => e.toString()).toList();
    }

    return ConditionRecord(
      photos: parsedPhotos,
      notes: data['notes'] ?? '',
      checklist: parsedChecklist.isEmpty ? defaultChecklist() : parsedChecklist,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      verifiedBy: data['verifiedBy'] ?? '',
      stage: data['stage'] ?? 'pre',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'photos': photos,
      'notes': notes,
      'checklist': checklist,
      'timestamp': Timestamp.fromDate(timestamp),
      'verifiedBy': verifiedBy,
      'stage': stage,
    };
  }
}
