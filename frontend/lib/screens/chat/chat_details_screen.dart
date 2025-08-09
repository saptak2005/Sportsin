import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sportsin/components/custom_toast.dart';
import 'package:sportsin/models/models.dart';
import 'package:sportsin/services/db/db_provider.dart';
import '../../config/theme/app_colors.dart';
import 'package:intl/intl.dart';

class ChatDetailsScreen extends StatefulWidget {
  final String roomId;
  final User otherUser;

  const ChatDetailsScreen({
    super.key,
    required this.roomId,
    required this.otherUser,
  });

  @override
  State<ChatDetailsScreen> createState() => _ChatDetailsScreenState();
}

class _ChatDetailsScreenState extends State<ChatDetailsScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  StreamSubscription? _messageSubscription;
  String? _currentUserId;
  late String _currentRoomId;

  @override
  void initState() {
    super.initState();
    _currentUserId = DbProvider.instance.cashedUser?.id;
    _currentRoomId = widget.roomId;

    if (_currentUserId == null) {
      setState(() => _isLoading = false);
      CustomToast.showError(message: "Cannot load chat: User not found.");
      return;
    }
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      _messageSubscription =
          DbProvider.instance.messagesStream.listen((newMessage) {
        if (_currentRoomId.isEmpty) {
          _currentRoomId = newMessage.chatRoomId;
        }

        if (newMessage.chatRoomId == _currentRoomId) {
          if (mounted && !_messages.any((m) => m.id == newMessage.id)) {
            setState(() {
              _messages.add(newMessage);
            });
            _scrollToBottom();
          }
        }
      });

      if (_currentRoomId.isNotEmpty) {
        final historicalMessages =
            await DbProvider.instance.getMessagesForRoom(_currentRoomId);
        if (mounted) {
          setState(() {
            _messages.insertAll(0, historicalMessages);
          });
        }
        await DbProvider.instance.markRoomAsRead(_currentRoomId);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        CustomToast.showError(
          message: 'Failed to load chat messages: ${e.toString()}',
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageSubscription?.cancel();
    super.dispose();
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isNotEmpty && _currentUserId != null) {
      final optimisticMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        chatRoomId: _currentRoomId,
        senderId: _currentUserId!,
        read: false,
        message: content,
      );

      setState(() {
        _messages.add(optimisticMessage);
      });

      DbProvider.instance.sendMessage(
        recipientId: widget.otherUser.id,
        content: content,
      );

      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.otherUser.profilePicture != null
                  ? NetworkImage(widget.otherUser.profilePicture!)
                  : null,
              radius: 20,
              child: widget.otherUser.profilePicture == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.otherUser.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isSender = message.senderId == _currentUserId;

                      String formattedTime = '';
                      try {
                        final dateTime = DateTime.parse(message.createdAt);
                        formattedTime = DateFormat.jm().format(dateTime);
                      } catch (e) {
                        formattedTime = DateFormat.jm().format(DateTime.now());
                      }

                      return Align(
                        alignment: isSender
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Column(
                            crossAxisAlignment: isSender
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 5.0),
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  color: isSender
                                      ? AppColors.linkedInBlue
                                      : AppColors.linkedInPurple,
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                child: Text(
                                  message.message,
                                  style: const TextStyle(
                                      fontSize: 16.0, color: Colors.white),
                                ),
                              ),
                              if (formattedTime.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 2.0, left: 8.0, right: 8.0),
                                  child: Text(
                                    formattedTime,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12.0,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.send_rounded,
                      color: AppColors.linkedInBlue, size: 30),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
