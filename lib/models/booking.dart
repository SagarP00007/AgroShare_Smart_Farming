import 'package:cloud_firestore/cloud_firestore.dart';
import 'condition_record.dart';

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
    this.depositAmount = 200.0,
    this.paymentStatus = 'deposit_paid',
    this.paymentMethod = 'UPI',
    this.ownerId = '',
    this.ownerName = '',
    this.depositTxnId = '',
    this.finalTxnId = '',
    this.preCondition,
    this.postCondition,
    this.isPreVerified = false,
    this.isPostVerified = false,
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

  // Prototype payment tracking fields
  final double depositAmount;
  String paymentStatus; // 'deposit_paid', 'fully_paid', 'pending', 'paid'
  String paymentMethod; // 'UPI', 'Cash on Pickup', etc.
  String ownerId;
  String ownerName;
  String depositTxnId;
  String finalTxnId;

  // Rental Condition Verification fields
  ConditionRecord? preCondition;
  ConditionRecord? postCondition;
  bool isPreVerified;
  bool isPostVerified;

  bool get isPayAtPickup =>
      paymentMethod.toLowerCase().contains('cash') ||
      paymentStatus == 'pending' ||
      paymentStatus == 'pending_cash';

  bool get isCashPending =>
      isPayAtPickup &&
      (paymentStatus == 'pending' || paymentStatus == 'pending_cash');

  double get remainingAmount =>
      (totalCost - depositAmount).clamp(0.0, double.infinity);

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
      depositAmount: (data['depositAmount'] ?? 200.0).toDouble(),
      paymentStatus: data['paymentStatus'] ?? 'deposit_paid',
      paymentMethod: data['paymentMethod'] ?? 'UPI',
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      depositTxnId: data['depositTxnId'] ?? '',
      finalTxnId: data['finalTxnId'] ?? '',
      preCondition: data['preCondition'] != null && data['preCondition'] is Map
          ? ConditionRecord.fromMap(
              Map<String, dynamic>.from(data['preCondition']),
            )
          : null,
      postCondition:
          data['postCondition'] != null && data['postCondition'] is Map
          ? ConditionRecord.fromMap(
              Map<String, dynamic>.from(data['postCondition']),
            )
          : null,
      isPreVerified: data['isPreVerified'] ?? false,
      isPostVerified: data['isPostVerified'] ?? false,
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
      'depositAmount': depositAmount,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'depositTxnId': depositTxnId,
      'finalTxnId': finalTxnId,
      'isPreVerified': isPreVerified,
      'isPostVerified': isPostVerified,
      if (preCondition != null) 'preCondition': preCondition!.toMap(),
      if (postCondition != null) 'postCondition': postCondition!.toMap(),
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
enum BookingStatus { upcoming, active, completed }
