import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pickcab_partner/model/ChatMessage.dart';
import 'package:pickcab_partner/utils/ChatUtil.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreenController extends GetxController {
  static ChatScreenController get to => Get.find();
  final inputController = TextEditingController();
  final String bookingId;
  // final String tripId;
  final String userUniqueId;
  final String bookingUserName;
  var loggedInuserid = ''.obs;
  var loggedInuserName = ''.obs;
  final Rxn<DatabaseReference> refMessage = Rxn<DatabaseReference>();
  // final Rxn<DatabaseReference> refReceiverBookingMessage = Rxn<DatabaseReference>();

  final RxList<Map<String, dynamic>> messages =
      <Map<String, dynamic>>[].obs;

  final RxBool isLoadingMessages = true.obs;
  final RxString messageError = ''.obs;

  StreamSubscription<DatabaseEvent>? _messagesSubscription;

  ChatScreenController({
    required this.bookingId,
    // required this.tripId,
    required this.userUniqueId,
    required this.bookingUserName,
  });

  @override
  void onInit() {
    getChats();
    super.onInit();
  }

  void getChatMessages() {
    _messagesSubscription?.cancel();

    messages.clear();
    isLoadingMessages.value = true;
    messageError.value = '';

    final ref = FirebaseDatabase.instance
        .ref('${ChatUtil.NODE_MESSAGES}/$bookingId');

    _messagesSubscription = ref.onValue.listen(
          (event) {
        final List<Map<String, dynamic>> result = [];

        for (final child in event.snapshot.children) {
          if (child.value is Map) {
            final data = Map<String, dynamic>.from(
              child.value as Map,
            );

            data['messageId'] ??= child.key;
            result.add(data);
          }
        }

        // Newest first because your ListView uses reverse: true.
        result.sort((a, b) {
          final timeA = int.tryParse(
            a['timestamp']?.toString() ?? '0',
          ) ??
              0;

          final timeB = int.tryParse(
            b['timestamp']?.toString() ?? '0',
          ) ??
              0;

          return timeB.compareTo(timeA);
        });

        messages.assignAll(result);
        isLoadingMessages.value = false;
      },
      onError: (Object error) {
        messageError.value = 'Unable to load messages';
        isLoadingMessages.value = false;
        debugPrint('Message listener error: $error');
      },
    );
  }

  Future<void> getChats() async {
    final prefs = await SharedPreferences.getInstance();

    loggedInuserid.value = prefs.getString('user_id') ?? '';
    loggedInuserName.value = prefs.getString('user_name') ?? '';

    debugPrint('Booking ID: $bookingId');
    debugPrint('Receiver ID: $userUniqueId');
    debugPrint('Current User ID: ${loggedInuserid.value}');

    if (loggedInuserid.value.isEmpty) {
      debugPrint('Logged-in user ID is missing');
      isLoadingMessages.value = false;
      messageError.value = 'User ID is missing';
      return;
    }

    getChatMessages();
  }



  Future<void> createChat() async {
    final text = inputController.text.trim();

    if (text.isEmpty) return;

    final String senderId = loggedInuserid.value;
    final String receiverId = userUniqueId;
    final String currentBookingId = bookingId.toString();

    final DatabaseReference rootRef = FirebaseDatabase.instance.ref();

    // Generate a unique message ID.
    final messageRef =
        rootRef.child('${ChatUtil.NODE_MESSAGES}/$currentBookingId');

    final String? messageKey = messageRef.push().key;

    if (messageKey == null) {
      debugPrint('Unable to generate message ID');
      return;
    }

    final int timestamp = DateTime.now().millisecondsSinceEpoch;

    final newMessage = ChatMessage(
      bookingId: currentBookingId,
      messageBody: text,
      messageId: messageKey,
      timestamp: timestamp.toString(),
      readStatus: '0',
      receiverId: receiverId,
      senderId: senderId,
      senderName: loggedInuserName.value,
      type: 'text',
    );

    // Read the receiver's existing unread count for this booking.
    final receiverChatRef = rootRef.child(
      '${ChatUtil.NODE_CHAT_LIST}/$receiverId/$currentBookingId',
    );

    try {
      final receiverSnapshot = await receiverChatRef.get();

      final receiverData = receiverSnapshot.value is Map
          ? Map<String, dynamic>.from(receiverSnapshot.value as Map)
          : <String, dynamic>{};

      final int oldUnreadCount =
          int.tryParse(receiverData['unreadCount']?.toString() ?? '0') ?? 0;

      final Map<String, dynamic> updates = {};

      // 1. Messages: Messages/{bookingId}/{messageId}
      print('newMessage.toJson()');
      print(newMessage.toJson());
      updates['${ChatUtil.NODE_MESSAGES}/$currentBookingId/$messageKey'] =
          newMessage.toJson();

      // 2. Conversation: Conversation/{bookingId}
      updates['${ChatUtil.NODE_CONVERSATION}/$currentBookingId/bookingId'] =
          currentBookingId;

      updates['${ChatUtil.NODE_CONVERSATION}/$currentBookingId/conversationId'] =
          currentBookingId;

      updates['${ChatUtil.NODE_CONVERSATION}/$currentBookingId/participants/$senderId'] =
          true;

      updates['${ChatUtil.NODE_CONVERSATION}/$currentBookingId/participants/$receiverId'] =
          true;

      updates['${ChatUtil.NODE_CONVERSATION}/$currentBookingId/lastMessage'] =
          text;

      updates['${ChatUtil.NODE_CONVERSATION}/$currentBookingId/lastMessageTime'] =
          timestamp;

      updates['${ChatUtil.NODE_CONVERSATION}/$currentBookingId/lastMessageSenderId'] =
          senderId;

      updates['${ChatUtil.NODE_CONVERSATION}/$currentBookingId/status'] =
          'active';

      // 3. Sender's chat list entry.
      updates['${ChatUtil.NODE_CHAT_LIST}/$senderId/$currentBookingId'] = {
        'conversationId': currentBookingId,
        'bookingId': currentBookingId,
        'otherUserId': receiverId,
        'lastMessage': text,
        'messageType': 'text',
        'lastMessageTime': timestamp,
        'lastMessageSenderId': senderId,
        'unreadCount': 0,
      };

      // 4. Receiver's chat list entry.
      updates['${ChatUtil.NODE_CHAT_LIST}/$receiverId/$currentBookingId'] = {
        'conversationId': currentBookingId,
        'bookingId': currentBookingId,
        'otherUserId': senderId,
        'lastMessage': text,
        'messageType': 'text',
        'lastMessageTime': timestamp,
        'lastMessageSenderId': senderId,
        'unreadCount': oldUnreadCount + 1,
      };

      // Apply all changes atomically.
      await rootRef.update(updates);

      debugPrint('Message and chat details saved: $messageKey');

      // Clear the input only after a successful write.
      inputController.clear();
    } on FirebaseException catch (e) {
      debugPrint('Firebase error: ${e.code}');
      debugPrint('Firebase message: ${e.message}');
    } catch (e) {
      debugPrint('Error creating chat: $e');
    }
  }
}
