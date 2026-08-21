import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a payment transaction in AgroShare (Simulated prototype payment).
class Payment {
  Payment({
    required this.id,
    required this.transactionId,
    required this.userId,
    required this.equipmentId,
    required this.equipmentName,
    this.equipmentImage = '',
    required this.amount,
    required this.paymentType,
    required this.paymentMethod,
    this.upiId = '',
    required this.status,
    required this.date,
    this.bookingId = '',
  });

  final String id;
  final String transactionId;
  final String userId;
  final String equipmentId;
  final String equipmentName;
  final String equipmentImage;
  final double amount;
  final String
  paymentType; // 'rental_deposit', 'rental_remaining', 'equipment_purchase'
  final String
  paymentMethod; // 'Google Pay', 'PhonePe', 'Paytm', 'UPI ID', 'QR Code'
  final String upiId;
  final String status; // 'successful', 'failed', 'cancelled'
  final DateTime date;
  final String bookingId;

  String get formattedType {
    switch (paymentType) {
      case 'rental_deposit':
        return 'Rental Deposit';
      case 'rental_remaining':
        return 'Remaining Balance';
      case 'equipment_purchase':
        return 'Equipment Purchase';
      default:
        return 'Equipment Payment';
    }
  }

  factory Payment.fromMap(String id, Map<String, dynamic> data) {
    return Payment(
      id: id,
      transactionId: data['transactionId'] ?? '',
      userId: data['userId'] ?? '',
      equipmentId: data['equipmentId'] ?? '',
      equipmentName: data['equipmentName'] ?? '',
      equipmentImage: data['equipmentImage'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      paymentType: data['paymentType'] ?? 'rental_deposit',
      paymentMethod: data['paymentMethod'] ?? 'UPI',
      upiId: data['upiId'] ?? '',
      status: data['status'] ?? 'successful',
      date:
          (data['date'] as Timestamp?)?.toDate() ??
          (data['timestamp'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      bookingId: data['bookingId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'transactionId': transactionId,
      'userId': userId,
      'equipmentId': equipmentId,
      'equipmentName': equipmentName,
      'equipmentImage': equipmentImage,
      'amount': amount,
      'paymentType': paymentType,
      'paymentMethod': paymentMethod,
      'upiId': upiId,
      'status': status,
      'date': Timestamp.fromDate(date),
      'timestamp': FieldValue.serverTimestamp(),
      'bookingId': bookingId,
    };
  }
}
