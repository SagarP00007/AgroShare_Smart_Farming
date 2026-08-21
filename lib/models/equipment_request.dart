import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a request created by a farmer needing farm equipment.
class EquipmentRequest {
  const EquipmentRequest({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.equipmentType,
    required this.taskCrop,
    required this.requiredDate,
    required this.durationHours,
    required this.locationName,
    this.latitude = 0.0,
    this.longitude = 0.0,
    required this.maxBudgetPerHour,
    required this.description,
    this.status = 'open',
    required this.createdAt,
    this.responseCount = 0,
  });

  final String id;
  final String requesterId;
  final String requesterName;
  final String equipmentType;
  final String taskCrop;
  final DateTime requiredDate;
  final int durationHours;
  final String locationName;
  final double latitude;
  final double longitude;
  final double maxBudgetPerHour;
  final String description;
  final String status; // 'open', 'fulfilled', 'cancelled'
  final DateTime createdAt;
  final int responseCount;

  bool get isOpen => status == 'open';
  bool get isFulfilled => status == 'fulfilled';

  factory EquipmentRequest.fromMap(String id, Map<String, dynamic> data) {
    return EquipmentRequest(
      id: id,
      requesterId: data['requesterId'] ?? '',
      requesterName: data['requesterName'] ?? 'Farmer',
      equipmentType: data['equipmentType'] ?? '',
      taskCrop: data['taskCrop'] ?? '',
      requiredDate:
          (data['requiredDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      durationHours: (data['durationHours'] ?? 1).toInt(),
      locationName: data['locationName'] ?? 'Unknown',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      maxBudgetPerHour: (data['maxBudgetPerHour'] ?? 0.0).toDouble(),
      description: data['description'] ?? '',
      status: data['status'] ?? 'open',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      responseCount: (data['responseCount'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requesterId': requesterId,
      'requesterName': requesterName,
      'equipmentType': equipmentType,
      'taskCrop': taskCrop,
      'requiredDate': Timestamp.fromDate(requiredDate),
      'durationHours': durationHours,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'maxBudgetPerHour': maxBudgetPerHour,
      'description': description,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'responseCount': responseCount,
    };
  }
}
