import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pickcab_partner/chats/ChatController.dart';
import 'package:pickcab_partner/includes/header.dart';

class ChatScreen extends StatefulWidget {
  final String bookingId;
  final String tripId;
  final String userUniqueId;

  const ChatScreen({
    super.key,
    required this.bookingId,
    required this.tripId,
    required this.userUniqueId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Use Get.find() if controller is initialized elsewhere,
  // or put it securely with a unique tag if necessary.
  late final ChatScreenController controller;

  @override
  void initState() {
    super.initState();
    // controller = Get.put(ChatScreenController(), tag: widget.tripId);
    controller = Get.put(
      ChatScreenController(
        bookingId: widget.bookingId,
        tripId: widget.tripId,
        userUniqueId: widget.userUniqueId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: const AppHeader(),
      backgroundColor: const Color(0xFFF8F9FA), // Soft background for contrast
      body: SafeArea(
        child: Column(
          children: [
            // Chat Message List
            Expanded(
              child: ListView.builder(
                reverse: true, // Standard for modern chat apps (newest at bottom)
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: 10,
                itemBuilder: (context, index) {
                  // Simulating alternating sent/received messages for UI demonstration
                  bool isMe = index % 2 == 0;
                  return _buildMessageBubble(
                    message: "Hi Message ${index + 1}",
                    time: "10:45 AM",
                    isMe: isMe,
                  );
                },
              ),
            ),

            // Modern Chat Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.inputController,
                      maxLines: 4,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: const Color(0xFFF1F3F5),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: Color(0xFF8E24AA),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send Button with Splash effect & Material design
                  Material(
                    color: const Color(0xFF6A1B9A),
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        controller.createChat();
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Icon(
                          Icons.send_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Reusable Modern Chat Bubble Widget
  Widget _buildMessageBubble({
    required String message,
    required String time,
    required bool isMe,
  }) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF8E24AA) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.grey.shade500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}