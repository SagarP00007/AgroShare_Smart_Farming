import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat.dart';
import '../models/equipment.dart';
import '../services/auth_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get or create a chat between user and equipment owner
  Future<String> getOrCreateChat(String equipmentId, String ownerId) async {
    final currentUserId = AuthService.instance.currentUser?.uid;
    if (currentUserId == null || currentUserId == ownerId) {
      throw Exception('Cannot create chat with yourself');
    }

    // Check if chat already exists
    final existingChatQuery = await _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .where('participants', arrayContains: ownerId)
        .where('equipmentId', isEqualTo: equipmentId)
        .limit(1)
        .get();

    if (existingChatQuery.docs.isNotEmpty) {
      return existingChatQuery.docs.first.id;
    }

    // Get equipment details
    final equipmentDoc = await _firestore
        .collection('equipment')
        .doc(equipmentId)
        .get();
    if (!equipmentDoc.exists) {
      throw Exception('Equipment not found');
    }
    final equipment = Equipment.fromMap(equipmentDoc.id, equipmentDoc.data()!);

    // Get owner details
    final ownerDoc = await _firestore.collection('users').doc(ownerId).get();
    if (!ownerDoc.exists) {
      throw Exception('Owner not found');
    }

    // Get current user details
    final currentUserDoc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .get();
    if (!currentUserDoc.exists) {
      throw Exception('User not found');
    }

    // Create new chat
    final chatDoc = await _firestore.collection('chats').add({
      'participants': [currentUserId, ownerId],
      'equipmentId': equipmentId,
      'equipmentName': equipment.name,
      'equipmentImage': equipment.imageUrl,
      'lastMessage': 'Chat started',
      'lastMessageTime': Timestamp.now(),
      'lastReadTime': {
        currentUserId: Timestamp.now(),
        ownerId: Timestamp.now(),
      },
      'createdAt': Timestamp.now(),
      'isArchived': false,
    });

    // Create initial system message
    await _firestore
        .collection('chats')
        .doc(chatDoc.id)
        .collection('messages')
        .add({
          'chatId': chatDoc.id,
          'senderId': 'system',
          'senderName': 'System',
          'senderAvatar': '',
          'receiverId': currentUserId,
          'message': 'Chat started for ${equipment.name}',
          'type': 'system',
          'timestamp': Timestamp.now(),
          'isRead': true,
        });

    return chatDoc.id;
  }

  // Send a message
  Future<void> sendMessage(
    String chatId,
    String message, {
    String? imageUrl,
  }) async {
    final currentUserId = AuthService.instance.currentUser?.uid;
    if (currentUserId == null) return;

    // Get current user details
    final currentUserDoc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .get();
    if (!currentUserDoc.exists) return;
    final currentUserData = currentUserDoc.data()!;

    // Get chat details to find receiver
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    if (!chatDoc.exists) return;
    final chat = Chat.fromMap(chatDoc.id, chatDoc.data()!);
    final receiverId = chat.getOtherUserId(currentUserId);

    // Create message
    final messageData = {
      'chatId': chatId,
      'senderId': currentUserId,
      'senderName': currentUserData['displayName'] ?? 'User',
      'senderAvatar': currentUserData['photoURL'] ?? '',
      'receiverId': receiverId,
      'message': message,
      'type': imageUrl != null ? 'image' : 'text',
      'timestamp': Timestamp.now(),
      'isRead': false,
    };

    if (imageUrl != null) {
      messageData['imageUrl'] = imageUrl;
    }

    // Add message
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(messageData);

    // Update chat with last message
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': message,
      'lastMessageTime': Timestamp.now(),
      'lastMessageSenderId': currentUserId,
    });

    // Create notification for receiver
    await _createMessageNotification(
      receiverId,
      chatId,
      message,
      currentUserData['displayName'] ?? 'User',
    );
  }

  // Get messages stream for a chat
  Stream<QuerySnapshot> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get user's chats stream
  Stream<QuerySnapshot> getUserChatsStream() {
    final currentUserId = AuthService.instance.currentUser?.uid;
    if (currentUserId == null) return const Stream.empty();

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .where('isArchived', isEqualTo: false)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId) async {
    final currentUserId = AuthService.instance.currentUser?.uid;
    if (currentUserId == null) return;

    // Update last read time
    await _firestore.collection('chats').doc(chatId).update({
      'lastReadTime.$currentUserId': Timestamp.now(),
    });

    // Mark unread messages as read
    final unreadMessages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in unreadMessages.docs) {
      await doc.reference.update({'isRead': true});
    }
  }

  // Get unread message count
  Future<int> getUnreadMessageCount() async {
    final currentUserId = AuthService.instance.currentUser?.uid;
    if (currentUserId == null) return 0;

    final chats = await _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .where('isArchived', isEqualTo: false)
        .get();

    int unreadCount = 0;
    for (final chatDoc in chats.docs) {
      final chat = Chat.fromMap(chatDoc.id, chatDoc.data());
      if (chat.hasUnreadMessages(currentUserId)) {
        unreadCount++;
      }
    }

    return unreadCount;
  }

  // Archive chat
  Future<void> archiveChat(String chatId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'isArchived': true,
    });
  }

  // Create notification for new message
  Future<void> _createMessageNotification(
    String receiverId,
    String chatId,
    String message,
    String senderName,
  ) async {
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    if (!chatDoc.exists) return;
    final chat = Chat.fromMap(chatId, chatDoc.data()!);

    final notification = {
      'userId': receiverId,
      'title': 'New message from $senderName',
      'body': message,
      'type': 'newMessage',
      'timestamp': Timestamp.now(),
      'isRead': false,
      'data': {
        'chatId': chatId,
        'senderName': senderName,
        'equipmentName': chat.equipmentName,
      },
    };

    await _firestore.collection('notifications').add(notification);

    // TODO: Send push notification via Firebase Cloud Messaging
  }

  // Get chat details
  Future<Chat?> getChatDetails(String chatId) async {
    final doc = await _firestore.collection('chats').doc(chatId).get();
    if (!doc.exists) return null;
    return Chat.fromMap(doc.id, doc.data()!);
  }

  // Delete message (for sender only)
  Future<void> deleteMessage(String chatId, String messageId) async {
    final currentUserId = AuthService.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final messageDoc = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .get();

    if (messageDoc.exists && messageDoc.data()!['senderId'] == currentUserId) {
      await messageDoc.reference.delete();
    }
  }
}
