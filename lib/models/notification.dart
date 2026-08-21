import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  newMessage,
  equipmentRequest,
  bookingConfirmed,
  bookingCancelled,
  paymentReceived,
  equipmentAvailable,
  system,
}

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;
  final String? imageUrl;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    required this.isRead,
    this.data,
    this.imageUrl,
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) {
    return AppNotification(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${map['type']}',
        orElse: () => NotificationType.system,
      ),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
      data: map['data'],
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      if (data != null) 'data': data,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  static AppNotification createMessageNotification({
    required String userId,
    required String senderName,
    required String message,
    required String chatId,
    required String equipmentName,
  }) {
    return AppNotification(
      id: '',
      userId: userId,
      title: 'New message from $senderName',
      body: message,
      type: NotificationType.newMessage,
      timestamp: DateTime.now(),
      isRead: false,
      data: {
        'chatId': chatId,
        'senderName': senderName,
        'equipmentName': equipmentName,
      },
    );
  }

  static AppNotification createEquipmentRequestNotification({
    required String ownerId,
    required String requesterName,
    required String equipmentName,
    required String requestId,
  }) {
    return AppNotification(
      id: '',
      userId: ownerId,
      title: 'New equipment request',
      body: '$requesterName is interested in your $equipmentName',
      type: NotificationType.equipmentRequest,
      timestamp: DateTime.now(),
      isRead: false,
      data: {
        'requestId': requestId,
        'requesterName': requesterName,
        'equipmentName': equipmentName,
      },
    );
  }

  static AppNotification createBookingConfirmedNotification({
    required String userId,
    required String equipmentName,
    required DateTime bookingDate,
  }) {
    return AppNotification(
      id: '',
      userId: userId,
      title: 'Booking Confirmed!',
      body:
          'Your booking for $equipmentName on ${bookingDate.day}/${bookingDate.month}/${bookingDate.year} has been confirmed',
      type: NotificationType.bookingConfirmed,
      timestamp: DateTime.now(),
      isRead: false,
      data: {
        'equipmentName': equipmentName,
        'bookingDate': Timestamp.fromDate(bookingDate),
      },
    );
  }
}
