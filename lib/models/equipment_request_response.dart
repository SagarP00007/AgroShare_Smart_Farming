import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an offer/response submitted by an equipment owner to a farmer's request.
class EquipmentRequestResponse {
  const EquipmentRequestResponse({
    required this.id,
    required this.requestId,
    required this.ownerId,
    required this.ownerName,
    required this.equipmentId,
    required this.equipmentName,
    required this.equipmentImage,
    required this.offeredPricePerHour,
    required this.message,
    this.status = 'pending',
    required this.createdAt,
  });

  final String id;
  final String requestId;
  final String ownerId;
  final String ownerName;
  final String equipmentId;
  final String equipmentName;
  final String equipmentImage;
  final double offeredPricePerHour;
  final String message;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime createdAt;

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';

  factory EquipmentRequestResponse.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    return EquipmentRequestResponse(
      id: id,
      requestId: data['requestId'] ?? '',
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? 'Equipment Owner',
      equipmentId: data['equipmentId'] ?? '',
      equipmentName: data['equipmentName'] ?? '',
      equipmentImage: data['equipmentImage'] ?? '',
      offeredPricePerHour: (data['offeredPricePerHour'] ?? 0.0).toDouble(),
      message: data['message'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'equipmentId': equipmentId,
      'equipmentName': equipmentName,
      'equipmentImage': equipmentImage,
      'offeredPricePerHour': offeredPricePerHour,
      'message': message,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
