import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String receiverId;
  final String message;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.receiverId,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.isRead,
    this.imageUrl,
  });

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) {
    return ChatMessage(
      id: id,
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderAvatar: map['senderAvatar'] ?? '',
      receiverId: map['receiverId'] ?? '',
      message: map['message'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${map['type']}',
        orElse: () => MessageType.text,
      ),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'receiverId': receiverId,
      'message': message,
      'type': type.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? receiverId,
    String? message,
    MessageType? type,
    DateTime? timestamp,
    bool? isRead,
    String? imageUrl,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

enum MessageType {
  text,
  image,
  system,
}

class Chat {
  final String id;
  final List<String> participants;
  final String equipmentId;
  final String equipmentName;
  final String equipmentImage;
  final String lastMessage;
  final DateTime lastMessageTime;
  final Map<String, DateTime> lastReadTime;
  final String? lastMessageSenderId;
  final bool isArchived;

  Chat({
    required this.id,
    required this.participants,
    required this.equipmentId,
    required this.equipmentName,
    required this.equipmentImage,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.lastReadTime,
    this.lastMessageSenderId,
    this.isArchived = false,
  });

  factory Chat.fromMap(String id, Map<String, dynamic> map) {
    return Chat(
      id: id,
      participants: List<String>.from(map['participants'] ?? []),
      equipmentId: map['equipmentId'] ?? '',
      equipmentName: map['equipmentName'] ?? '',
      equipmentImage: map['equipmentImage'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: (map['lastMessageTime'] as Timestamp).toDate(),
      lastReadTime: Map<String, dynamic>.from(map['lastReadTime'] ?? {}).map(
        (key, value) => MapEntry(key, (value as Timestamp).toDate()),
      ),
      lastMessageSenderId: map['lastMessageSenderId'],
      isArchived: map['isArchived'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'equipmentId': equipmentId,
      'equipmentName': equipmentName,
      'equipmentImage': equipmentImage,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'lastReadTime': lastReadTime.map((key, value) => MapEntry(key, Timestamp.fromDate(value))),
      if (lastMessageSenderId != null) 'lastMessageSenderId': lastMessageSenderId,
      'isArchived': isArchived,
    };
  }

  String getOtherUserId(String currentUserId) {
    return participants.firstWhere((id) => id != currentUserId, orElse: () => '');
  }

  bool hasUnreadMessages(String userId) {
    final userLastRead = lastReadTime[userId];
    if (userLastRead == null) return true;
    return lastMessageTime.isAfter(userLastRead);
  }
}
