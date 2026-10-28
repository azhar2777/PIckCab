import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:pickcab_partner/chatlist/ChatListController.dart';
import 'package:pickcab_partner/chats/ChatScreen.dart';
import 'package:pickcab_partner/includes/header.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
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
      controller.getConversations(userId);
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
          itemCount: controller.conversations.length,
          itemBuilder: (context, index) {
            final chat = controller.conversations[index];

            final bookingId =
                chat['bookingId']?.toString() ?? '';
            final otherUserId =
                chat['otherUserId']?.toString() ?? '';
            final name =
                chat['name']?.toString() ?? 'User';
            final lastMessage =
                chat['lastMessage']?.toString() ?? '';
            final unreadCount = int.tryParse(
                  chat['unreadCount']?.toString() ?? '0',
                ) ??
                0;

            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE1BEE7),
                child: Icon(
                  Icons.person,
                  color: Color(0xFF6A1B9A),
                ),
              ),
              title: Text(name),
              subtitle: Text(
                lastMessage.isEmpty
                    ? 'Start a conversation'
                    : lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: unreadCount > 0
                  ? CircleAvatar(
                      radius: 12,
                      backgroundColor: const Color(0xFF6A1B9A),
                      child: Text(
                        unreadCount > 99
                            ? '99+'
                            : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    )
                  : null,
              onTap: () {
                Get.to(
                  () => ChatScreen(
                    bookingId: bookingId,
                    userUniqueId: otherUserId,
                    userName: name,
                  ),
                );
              },
            );
          },
        );
      }),
    );
  }
}