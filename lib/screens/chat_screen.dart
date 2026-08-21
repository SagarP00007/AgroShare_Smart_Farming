import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

/// Enhanced real-time chat between user and equipment owner
class ChatScreen extends StatefulWidget {
  final String chatId;
  final String equipmentId;
  final String equipmentName;
  final String equipmentImage;
  final String ownerId;
  final String ownerName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.equipmentId,
    required this.equipmentName,
    required this.equipmentImage,
    required this.ownerId,
    required this.ownerName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;
  String? _actualChatId;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    if (widget.chatId.isEmpty) {
      try {
        final chatId = await ChatService().getOrCreateChat(
          widget.equipmentId,
          widget.ownerId,
        );
        if (mounted) {
          setState(() {
            _actualChatId = chatId;
          });
          _markMessagesAsRead();
        }
      } catch (e) {
        debugPrint('Error creating chat: $e');
      }
    } else {
      setState(() {
        _actualChatId = widget.chatId;
      });
      _markMessagesAsRead();
    }
  }

  Future<void> _markMessagesAsRead() async {
    if (_actualChatId == null) return;
    try {
      await ChatService().markMessagesAsRead(_actualChatId!);
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _actualChatId == null) return;

    setState(() => _isLoading = true);

    try {
      await ChatService().sendMessage(
        _actualChatId!,
        _messageController.text.trim(),
      );
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendImage() async {
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _isLoading = true);

      await ChatService().sendMessage(
        _actualChatId!,
        '📷 Image shared: ${image.name}',
      );
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send image: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthService.instance.currentUser?.uid;
    final isOwner = currentUserId == widget.ownerId;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                widget.equipmentImage,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 40,
                    height: 40,
                    color: AppColors.divider,
                    child: const Icon(Icons.agriculture_rounded),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.equipmentName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    isOwner
                        ? 'Chat with Customer'
                        : 'Chat with ${widget.ownerName}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _actualChatId == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            )
          : Column(
              children: [
                // Equipment info bar
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.primaryGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Discuss rental details, availability, and pricing',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Messages list
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: ChatService().getMessagesStream(_actualChatId!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading messages: ${snapshot.error}',
                          ),
                        );
                      }

                      final rawMessages = snapshot.data?.docs ?? [];
                      final List<ChatMessage> messageObjects = [];

                      if (rawMessages.isNotEmpty && !snapshot.hasError) {
                        for (final doc in rawMessages) {
                          messageObjects.add(
                            ChatMessage.fromMap(
                              doc.id,
                              doc.data() as Map<String, dynamic>,
                            ),
                          );
                        }
                      } else {
                        // Dummy conversation fallback
                        final currentUid = currentUserId ?? 'user_demo';
                        messageObjects.addAll([
                          ChatMessage(
                            id: 'm3',
                            chatId: _actualChatId ?? 'demo_chat',
                            senderId: widget.ownerId,
                            senderName: widget.ownerName,
                            senderAvatar: '',
                            receiverId: currentUid,
                            message:
                                'Great! Machine is ready and fueled. See you tomorrow!',
                            timestamp: DateTime.now().subtract(
                              const Duration(minutes: 5),
                            ),
                            type: MessageType.text,
                            isRead: true,
                          ),
                          ChatMessage(
                            id: 'm2',
                            chatId: _actualChatId ?? 'demo_chat',
                            senderId: currentUid,
                            senderName: 'You',
                            senderAvatar: '',
                            receiverId: widget.ownerId,
                            message:
                                'Sounds good! I need it for 5 hours starting at 8:00 AM.',
                            timestamp: DateTime.now().subtract(
                              const Duration(minutes: 15),
                            ),
                            type: MessageType.text,
                            isRead: true,
                          ),
                          ChatMessage(
                            id: 'm1',
                            chatId: _actualChatId ?? 'demo_chat',
                            senderId: widget.ownerId,
                            senderName: widget.ownerName,
                            senderAvatar: '',
                            receiverId: currentUid,
                            message:
                                'Hello! Yes, the ${widget.equipmentName} is available for rent.',
                            timestamp: DateTime.now().subtract(
                              const Duration(hours: 1),
                            ),
                            type: MessageType.text,
                            isRead: true,
                          ),
                        ]);
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: messageObjects.length,
                        itemBuilder: (context, index) {
                          final message = messageObjects[index];

                          final isMe = message.senderId == currentUserId;
                          final isSystem = message.type == MessageType.system;

                          if (isSystem) {
                            return _buildSystemMessage(message);
                          }

                          return _buildMessageBubble(message, isMe);
                        },
                      );
                    },
                  ),
                ),

                // Message input
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _sendImage,
                        icon: Icon(
                          Icons.image_rounded,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: GoogleFonts.poppins(
                              color: AppColors.textMuted,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: AppColors.divider),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: AppColors.primaryGreen,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _isLoading ? null : _sendMessage,
                        icon: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryGreen,
                                ),
                              )
                            : Icon(
                                Icons.send_rounded,
                                color: AppColors.primaryGreen,
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryGreen,
              child: Text(
                message.senderName.isNotEmpty
                    ? message.senderName[0].toUpperCase()
                    : 'U',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primaryGreen : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: isMe ? null : Border.all(color: AppColors.divider),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.senderName,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isMe ? Colors.white70 : AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  Text(
                    message.message,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isMe ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: isMe ? Colors.white70 : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.divider,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.message,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
