import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:pickcab_partner/chats/ChatController.dart';
import 'package:pickcab_partner/const/const.dart';
import 'package:pickcab_partner/includes/header.dart';

import '../utils/ChatUtil.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  final String receiverId;
  final String receiverMobile;
  final String receiverName;
  final String receiverImage;

  const ChatScreen({
    super.key,
    required this.bookingData, required this.receiverId, required this.receiverMobile, required this.receiverName, required this.receiverImage,
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
        bookingData: widget.bookingData, receiverId: widget.receiverId, receiverName: widget.receiverName, receiverImage: widget.receiverImage, receiverMobile: widget.receiverMobile,
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
            Obx(() => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(width: 1, color: Colors.black.withOpacity(0.1)),
                    ),
                    // boxShadow: [
                    //   BoxShadow(
                    //     color: Colors.black.withOpacity(0.1),
                    //     blurRadius: 12,
                    //     offset: const Offset(0, 5),
                    //   ),
                    // ],
                  ),

                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4,),
                  child: Row(
                    children: [
                      // SizedBox(
                      //   height: 50,
                      //   width: 50,
                      //   child: Container(
                      //     padding: const EdgeInsets.all(3), // Border thickness
                      //     decoration: BoxDecoration(
                      //       shape: BoxShape.circle,
                      //       border: Border.all(
                      //         color: const Color(0xFF6A1B9A),
                      //         width: 2,
                      //       ),
                      //     ),
                      //     child: CircleAvatar(
                      //       radius: 70,
                      //       backgroundImage: NetworkImage(widget.userImage
                      //               .contains('http')
                      //           ? widget.userImage
                      //           : widget.userImage.isNotEmpty
                      //               ? '$imageurl/${widget.userImage}'
                      //               : ''),
                      //       onBackgroundImageError: (_, __) {},
                      //     ),
                      //   ),
                      // ),
                      Container(
                        width: 54,
                        height: 54,
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF6A1B9A),
                        ),
                        child: ClipOval(
                          child: (widget.bookingData['user_mage'] == null ||
                              widget.bookingData['user_mage'].toString().trim().isEmpty)
                              ? _userPlaceholder()
                              : Image.network(
                            '$imageurl/${widget.bookingData['user_mage']}',
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _userPlaceholder();
                            },
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.bookingData['user_name']??'Chat user',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            controller.isOtherUserOnline.value
                                ? 'online'
                                : 'last seen ',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
            Expanded(
              child: Obx(() {
                if (controller.isLoadingMessages.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF6A1B9A),
                    ),
                  );
                }

                if (controller.messageError.value.isNotEmpty) {
                  return Center(
                    child: Text(controller.messageError.value),
                  );
                }

                if (controller.messages.isEmpty) {
                  return const Center(
                    child: Text('Start your conversation'),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: controller.messages.length,
                  itemBuilder: (context, index) {
                    final message = controller.messages[index];

                    final senderId = message['senderId']?.toString() ?? '';

                    final isMe = senderId == controller.loggedInuserid.value;

                    final messageBody =
                        message['messageBody']?.toString() ?? '';

                    final timestamp = message['timestamp']?.toString() ?? '';

                    return _buildMessageBubble(
                      message: messageBody,
                      time: timestamp.isNotEmpty
                          ? ChatUtil.getMessageDate(
                              timestamp,
                              timeOnly: true,
                            )
                          : '',
                      isMe: isMe,
                    );
                  },
                );
              }),
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
                        controller.createChatMessage();
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

  Widget _userPlaceholder() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Image.asset(
          "assets/images/ic_user_avatar.png",
          fit: BoxFit.contain,
          width: 30,
          height: 30,
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
