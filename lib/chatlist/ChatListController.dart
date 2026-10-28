import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:pickcab_partner/utils/ChatUtil.dart';

class ChatListController extends GetxController {
  final RxList<Map<String, dynamic>> conversations =
      <Map<String, dynamic>>[].obs;

  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  StreamSubscription<DatabaseEvent>? _chatListSubscription;

  String? _currentUserId;

  @override
  void onInit() {
    super.onInit();
  }

  void getConversations(String userId) {
    print("getConversations");
    if (userId.isEmpty) {
      errorMessage.value = 'User ID is missing';
      isLoading.value = false;
      return;
    }

    // Avoid creating duplicate listeners for the same user.
    if (_currentUserId == userId && _chatListSubscription != null) {
      return;
    }

    _currentUserId = userId;
    _chatListSubscription?.cancel();

    isLoading.value = true;
    errorMessage.value = '';

    _chatListSubscription = FirebaseDatabase.instance
        .ref('${ChatUtil.NODE_CHAT_LIST}/$userId')
        .onValue
        .listen(
      (event) {
        final List<Map<String, dynamic>> result = [];

        for (final child in event.snapshot.children) {
          final value = child.value;

          if (value is Map) {
            final data = Map<String, dynamic>.from(value);

            data['bookingId'] ??= child.key;
            data['conversationId'] ??= child.key;

            result.add(data);
          }
        }

        // Most recently active conversation first.
        result.sort((a, b) {
          final timeA = int.tryParse(
                a['lastMessageTime']?.toString() ?? '0',
              ) ??
              0;

          final timeB = int.tryParse(
                b['lastMessageTime']?.toString() ?? '0',
              ) ??
              0;

          return timeB.compareTo(timeA);
        });

        conversations.assignAll(result);
        isLoading.value = false;
        errorMessage.value = '';
      },
      onError: (Object error) {
        errorMessage.value = 'Failed to load conversations';
        isLoading.value = false;
      },
    );
  }

  Future<void> refreshConversations() async {
    final userId = _currentUserId;

    if (userId != null) {
      _currentUserId = null;
      getConversations(userId);
    }
  }

  @override
  void onClose() {
    _chatListSubscription?.cancel();
    super.onClose();
  }
}
