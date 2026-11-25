import 'package:material_ui/material_ui.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:pickcab_partner/chatlist/ChatListController.dart';
import 'package:pickcab_partner/chats/ChatScreen.dart';
import 'package:pickcab_partner/includes/header.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Conversationscreen extends StatefulWidget {
  const Conversationscreen({super.key});

  @override
  State<Conversationscreen> createState() => _ConversationscreenState();
}

class _ConversationscreenState extends State<Conversationscreen> {
  late final ChatListController controller;

  @override
  void initState() {
    super.initState();

    controller = Get.put(ChatListController());

    getChats();
  }

  Future<void> getChats() async {
    final prefs = await SharedPreferences.getInstance();

    final userId = prefs.getString('user_id') ?? '';

    if (userId.isNotEmpty) {
      controller.getUserConversations(userId);
    } else {
      controller.errorMessage.value = 'User ID is missing';
      controller.isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppHeader(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF6A1B9A),
            ),
          );
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Text(controller.errorMessage.value),
          );
        }

        if (controller.conversations.isEmpty) {
          return const Center(
            child: Text('No conversations yet'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: controller.conversations.length,
          itemBuilder: (context, index) {
            final chat = controller.conversations[index];
            return _buildConversationCard(
              chat,
              onTap: () => _openConversation(chat),
            );
          },
        );
      }),
    );
  }

  Widget _buildConversationCard(
    Map<String, dynamic> chat, {
    required VoidCallback onTap,
  }) {
    final bookingDataValue = chat['bookingData'];
    final bookingData = bookingDataValue is Map
        ? Map<String, dynamic>.from(bookingDataValue)
        : <String, dynamic>{};
    final bookingId = chat['bookingId']?.toString() ?? '';
    final from = bookingData['from']?.toString() ?? 'Location not set';
    final to = bookingData['to']?.toString() ?? 'Location not set';
    final date = bookingData['date']?.toString() ?? '';
    final time = bookingData['time']?.toString() ?? '';
    final schedule =
        [date, time].where((value) => value.isNotEmpty).join(' @ ');
    final lastMessage = chat['lastMessage']?.toString() ?? '';
    final status = bookingData['status']?.toString() ?? 'Open';
    final unreadCount =
        int.tryParse(chat['unreadCount']?.toString() ?? '0') ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E5EC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'ID: $bookingId',
                    style: const TextStyle(
                      color: Color(0xFF45434A),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    status,
                    style: const TextStyle(
                      color: Color(0xFF579563),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF8A8790),
                    size: 22,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      from,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF38363D),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(
                      Icons.arrow_forward,
                      color: Color(0xFF6A1B9A),
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      to,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: Color(0xFF38363D),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      schedule.isEmpty ? 'Conversation' : schedule,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF77737D),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1E6F7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.chat_bubble,
                            color: Color(0xFF6A1B9A),
                            size: 15,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${unreadCount > 99 ? '99+' : unreadCount} unread',
                            style: const TextStyle(
                              color: Color(0xFF6A1B9A),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                lastMessage.isEmpty ? 'Start a conversation' : lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: lastMessage.isEmpty
                      ? const Color(0xFF9A96A0)
                      : const Color(0xFF55515B),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openConversation(Map<String, dynamic> chat) {
    final bookingId = chat['bookingId']?.toString() ?? '';
    final otherUserId = chat['otherUserId']?.toString() ?? '';
    final name = chat['name']?.toString() ?? 'User';
    final bookingDataValue = chat['bookingData'];
    final bookingData = bookingDataValue is Map
        ? Map<String, dynamic>.from(bookingDataValue)
        : <String, dynamic>{};
    final image = chat['userImage']?.toString() ?? '';
    final mobile = chat['otherUserMobile']?.toString() ?? '';

    bookingData['id'] ??= bookingId;
    bookingData['user_id'] ??= otherUserId;
    bookingData['user_name'] ??= name;
    bookingData['user_image'] ??= image;
    bookingData['user_mage'] ??= image;
    bookingData['mobile'] ??= mobile;

    Get.to(
      () => ChatScreen(
        bookingData: bookingData,
        receiverId: otherUserId,
        receiverName: name,
        receiverImage: image,
        receiverMobile: mobile,
      ),
    );
  }
}
