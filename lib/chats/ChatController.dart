import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pickcab_partner/model/ChatMessage.dart';
import 'package:pickcab_partner/utils/ChatUtil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../const/const.dart';
import '../utils/firebase_util.dart';
import 'package:firebase_database/firebase_database.dart';

class ChatScreenController extends GetxController {
  static ChatScreenController get to => Get.find();
  final Map<String, dynamic> bookingData;
  final String receiverId;
  final String receiverName;
  final String receiverImage;
  final String receiverMobile;
  final inputController = TextEditingController();
  var loggedInuserid = ''.obs;
  var loggedInuserName = ''.obs;
  var loggedInuserMobile = ''.obs;
  var loggedInuserImage = ''.obs;
  final Rxn<DatabaseReference> refMessage = Rxn<DatabaseReference>();
  // final Rxn<DatabaseReference> refReceiverBookingMessage = Rxn<DatabaseReference>();

  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;

  final RxBool isLoadingMessages = true.obs;
  final RxString messageError = ''.obs;

  StreamSubscription<DatabaseEvent>? _messagesSubscription;

  final RxBool isOtherUserOnline = false.obs;
  final RxInt otherUserLastSeen = 0.obs;
  // Receiver vars



  StreamSubscription<DatabaseEvent>? _presenceSubscription;

  ChatScreenController({
    required this.bookingData, required this.receiverId, required this.receiverName, required this.receiverImage, required this.receiverMobile}
      );

  @override
  void onInit() {
    getChats();
    super.onInit();
  }

  void listenToUserPresence(String userId) {
    _presenceSubscription?.cancel();

    final ref =
    FirebaseDatabase.instance.ref('${ChatUtil.NODE_USER_STATUS}/$userId');

    _presenceSubscription = ref.onValue.listen((event) {
      final value = event.snapshot.value;

      if (value is Map) {
        isOtherUserOnline.value = value['isOnline'] == true;

        otherUserLastSeen.value =
            int.tryParse(value['lastSeen']?.toString() ?? '0') ?? 0;
      } else {
        isOtherUserOnline.value = false;
        otherUserLastSeen.value = 0;
      }
    });
  }

  String formatLastSeen(int timestamp) {
    if (timestamp == 0) return 'Last seen a long time ago';

    // Assuming lastSeen is stored in milliseconds
    final lastSeen = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = DateTime.now().difference(lastSeen);

    if (difference.isNegative) return 'Last seen just now';

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else {
      return '${lastSeen.day.toString().padLeft(2, '0')}/'
          '${lastSeen.month.toString().padLeft(2, '0')}/'
          '${lastSeen.year}';
    }
  }

  void getConversation(){

  }

  void getChatMessages() {
    _messagesSubscription?.cancel();

    messages.clear();
    isLoadingMessages.value = true;
    messageError.value = '';

    final ref =
    FirebaseDatabase.instance.ref('${ChatUtil.NODE_MESSAGES}/${bookingData['id']}');

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
    loggedInuserImage.value = prefs.getString('user_image') ?? '';
    loggedInuserMobile.value = prefs.getString('mobile_number') ?? '';

    // debugPrint('Booking ID: $bookingId');
    // debugPrint('Receiver ID: $userUniqueId');
    // debugPrint('Current User ID: ${loggedInuserid.value}');

    if (loggedInuserid.value.isEmpty) {
      debugPrint('Logged-in user ID is missing');
      isLoadingMessages.value = false;
      messageError.value = 'User ID is missing';
      return;
    }

    getChatMessages();
  }

  Future<int> getUnreadCount(String bookingId) async{
    final DatabaseReference rootRef = FirebaseDatabase.instance.ref();
    final receiverChatRef = rootRef.child(
      '${ChatUtil.NODE_CHAT_LIST}/$receiverId/$bookingId',
    );
    final receiverSnapshot = await receiverChatRef.get();

    final receiverData = receiverSnapshot.value is Map
        ? Map<String, dynamic>.from(receiverSnapshot.value as Map)
        : <String, dynamic>{};


    return  int.tryParse(receiverData['unreadCount']?.toString() ?? '0') ?? 0;
  }

  Future<void> createChatMessage() async {
    final DatabaseReference rootRef = FirebaseDatabase.instance.ref();

    final String senderId = loggedInuserid.value.toString();
    // final String senderId = '9158';
    // receiverId = bookingData['user_id'].toString();
    final String bookingId = bookingData['id'].toString();

    final String message = inputController.text.trim();

    if (senderId == receiverId) {
      Get.snackbar(
        "Error",
        "Sender and Receiver cannot be same",
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (message.isEmpty) return;

    try {
      final int timestamp = DateTime.now().millisecondsSinceEpoch;

      // Generate message reference
      final messageRef = rootRef
          .child(ChatUtil.NODE_MESSAGES)
          .child(bookingId)
          .child(senderId)
          .push();

      final String messageId = messageRef.key!;

      final Map<String, dynamic> messageData = {
        'messageId': messageId,
        'bookingId': bookingId,
        'senderId': senderId,
        'receiverId': receiverId,
        'message': message,
        'timestamp': ServerValue.timestamp,
        'type': 'text',
        'isRead': false,
      };

      final Map<String, dynamic> updates = {};

      // 1. Message  entry.
      // Save message
      updates[
      '${ChatUtil.NODE_MESSAGES}/$bookingId/$senderId/$messageId'
      ] = messageData;

      // 2. Conversation  entry.
      // Update conversation details
      updates['${ChatUtil.NODE_CONVERSATION}/$bookingId/bookingData'] =
          bookingData;

      updates['${ChatUtil.NODE_CONVERSATION}/$bookingId/senderId'] =
          senderId;

      updates['${ChatUtil.NODE_CONVERSATION}/$bookingId/receiverId'] =
          receiverId;

      updates['${ChatUtil.NODE_CONVERSATION}/$bookingId/lastMessage'] =
          message;

      updates['${ChatUtil.NODE_CONVERSATION}/$bookingId/lastMessageTime'] =
          ServerValue.timestamp;

      updates['${ChatUtil.NODE_CONVERSATION}/$bookingId/senderName'] =
          loggedInuserName.value;

      // 3. User Conversation  entry.
      // User conversation indexes
      updates[
      '${ChatUtil.NODE_USER_CONVERSATIONS}/$senderId/$bookingId/${receiverId}'
      ] = true;

      updates[
      '${ChatUtil.NODE_USER_CONVERSATIONS}/${receiverId}/$bookingId/$senderId'
      ] = true;

      // Read the receiver's existing unread count for this booking.
      int oldUnreadCount = await getUnreadCount(bookingId);


      // 4. Sender's chat list entry.
      updates['${ChatUtil.NODE_CHAT_LIST}/$senderId/$bookingId'] = {
        'conversationId': bookingId,
        'bookingId': bookingId,
        'otherUserId': receiverId,
        'otherUserName': receiverName,
        'otherUserMobile': receiverMobile,
        'otherUserImage': receiverImage,
        'lastMessage': message,
        'messageType': 'text',
        'lastMessageTime': timestamp,
        'lastMessageSenderId': senderId,
        'unreadCount': 0,
      };

      // 5. Receiver's chat list entry.
      updates['${ChatUtil.NODE_CHAT_LIST}/${receiverId}/$bookingId'] = {
        'conversationId': bookingId,
        'bookingId': bookingId,
        'otherUserId': senderId,
        'otherUserName': loggedInuserName.value,
        'otherUserMobile': loggedInuserMobile.value,
        'otherUserImage': loggedInuserImage.value,
        'lastMessage': message,
        'messageType': 'text',
        'lastMessageTime': timestamp,
        'lastMessageSenderId': senderId,
        'unreadCount': oldUnreadCount + 1,
      };


      // Save everything atomically
      await rootRef.update(updates);

      inputController.clear();

    } catch (e) {
      print('Create chat message error: $e');

      Get.snackbar(
        "Error",
        "Unable to send message. Please try again.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }



  /*Future<void> createChat() async {
    var deviceToken = "";
    final text = inputController.text.trim();

    if (text.isEmpty) return;

    final String senderId = loggedInuserid.value;
    final String receiverId = bookingData['user_id'];
    final String currentBookingId = bookingData['id'];

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

    final receiverRef =
    FirebaseDatabase.instance.ref('${FirebaseUtil.NODE_USER}');


    try {

      // final receiverUserSnapshot = await receiverRef.child(receiverId).get();
      final receiverUserSnapshot = await receiverRef.child('9157').get();
      if (receiverUserSnapshot.exists && receiverUserSnapshot.value is Map) {
        final receiverUserData = Map<String, dynamic>.from(
          receiverUserSnapshot.value as Map,
        );

        print('Receiver ID: $receiverId');
        print('Receiver User Data: $receiverUserData');
        deviceToken = receiverUserData['device_token']?.toString() ?? '';
      } else {
        print('Receiver user not found: $receiverId');
      }

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

      // Add Booking Details
      updates['${ChatUtil.NODE_CONVERSATION}/$currentBookingId/bookingData'] =
          bookingData;


      // 6. User conversation indexes.
      updates[
      '${ChatUtil.NODE_USER_CONVERSATIONS}/$senderId/$currentBookingId'
      ] = true;

      updates[
      '${ChatUtil.NODE_USER_CONVERSATIONS}/$receiverId/$currentBookingId'
      ] = true;

      // 7. Save all data atomically.
      await rootRef.update(updates);

      *//**
       * Add participants details
       *//*
      updates[
      '${ChatUtil.NODE_CONVERSATION}/$currentBookingId/participants/$senderId'] = {
        'name': loggedInuserName.value,
        'mobile': loggedInuserMobile.value,
        'image': loggedInuserImage.value,
        'userId': senderId,
      };

      updates[
      '${ChatUtil.NODE_CONVERSATION}/$currentBookingId/participants/$receiverId'] = {
        'name': bookingData['user_name'],
        'mobile': bookingData['user_mobile'],
        'image': bookingData['user_image'],
        'userId': bookingData['user_id'],
      };

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
        'otherUserImage': bookingData['user_image'],
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
        'otherUserImage': loggedInuserImage.value,
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

      // sendBookingNotification(bookingId, deviceToken);



    } on FirebaseException catch (e) {
      debugPrint('Firebase error: ${e.code}');
      debugPrint('Firebase message: ${e.message}');
    } catch (e) {
      debugPrint('Error creating chat: $e');
    }
  }*/

  Future<void> sendBookingNotification(String bookingId, String fcmToken) async {

    try {
      final request = http.MultipartRequest(
        "POST",
        Uri.parse("$appurl/send_chat_notification"),
      );
      request.fields.addAll({
        "booking_id": bookingId,
        "fcm_token": fcmToken,
      });

      final response = await request.send();
      final resp = await response.stream.bytesToString();
      final json = jsonDecode(resp);
      print(json);

    } catch (e) {
      print("Error in sendBookingNotification");
      print(e);
      // CustomNotification.show(
      //   title: "Error",
      //   message: "Check internet",
      //   isSuccess: false,
      // );
    } finally {

    }
  }


  // Get Conversation
  Stream<List<Map<String, dynamic>>> getUserConversations() {
    final String userId = loggedInuserid.value.toString();
    print("getUserConversations $userId");

    final DatabaseReference userRef = FirebaseDatabase.instance
        .ref(ChatUtil.NODE_USER_CONVERSATIONS)
        .child(userId);

    return userRef.onValue.asyncMap((event) async {
      if (!event.snapshot.exists) {
        return <Map<String, dynamic>>[];
      }

      final userData = Map<dynamic, dynamic>.from(
        event.snapshot.value as Map,
      );

      final List<Map<String, dynamic>> result = [];

      // Get all booking IDs
      for (final bookingEntry in userData.entries) {
        final bookingId = bookingEntry.key.toString();

        final drivers = Map<dynamic, dynamic>.from(
          bookingEntry.value as Map,
        );

        // Get booking conversation
        final conversationSnapshot = await FirebaseDatabase.instance
            .ref(ChatUtil.NODE_CONVERSATION)
            .child(bookingId)
            .get();

        if (!conversationSnapshot.exists) continue;

        final conversation = Map<String, dynamic>.from(
          conversationSnapshot.value as Map,
        );

        // Add separate conversation for each driver
        for (final driverEntry in drivers.entries) {
          final driverId = driverEntry.key.toString();

          result.add({
            ...conversation,
            'bookingId': bookingId,
            'otherUserId': driverId,
          });
        }
      }

      result.sort((a, b) {
        final timeA = a['lastMessageTime'] ?? 0;
        final timeB = b['lastMessageTime'] ?? 0;

        return (timeB as num).compareTo(timeA as num);
      });
      print("getUserConversations ${result.length}");
      return result;
    });
  }
}