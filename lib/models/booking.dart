import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a booking for a piece of farm equipment.
class Booking {
  Booking({
    required this.id,
    required this.userId,
    required this.equipmentId,
    required this.equipmentName,
    required this.date,
    required this.durationHours,
    required this.totalCost,
    this.status = BookingStatus.upcoming,
    this.rating,
    this.reviewText,
  });

  final String id;
  final String userId;
  final String equipmentId;
  final String equipmentName;
  final DateTime date;
  final int durationHours;
  final double totalCost;
  BookingStatus status;
  double? rating;
  String? reviewText;

  /// Create from Firestore document.
  factory Booking.fromMap(String id, Map<String, dynamic> data) {
    return Booking(
      id: id,
      userId: data['userId'] ?? '',
      equipmentId: data['equipmentId'] ?? '',
      equipmentName: data['equipmentName'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      durationHours: (data['durationHours'] ?? 0).toInt(),
      totalCost: (data['totalCost'] ?? 0).toDouble(),
      status: _statusFromString(data['status'] ?? 'upcoming'),
      rating: data['rating']?.toDouble(),
      reviewText: data['reviewText'],
    );
  }

  /// Convert to Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'equipmentId': equipmentId,
      'equipmentName': equipmentName,
      'date': Timestamp.fromDate(date),
      'durationHours': durationHours,
      'totalCost': totalCost,
      'status': status.name,
      'rating': rating,
      'reviewText': reviewText,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static BookingStatus _statusFromString(String s) {
    switch (s) {
      case 'active':
        return BookingStatus.active;
      case 'completed':
        return BookingStatus.completed;
      default:
        return BookingStatus.upcoming;
    }
  }
}

/// Possible states of a booking.
enum BookingStatus {
  upcoming,
  active,
  completed,
}
