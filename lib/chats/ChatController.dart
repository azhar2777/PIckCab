import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:pickcab_partner/model/ChatMessage.dart';
import 'package:pickcab_partner/utils/ChatUtil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../const/const.dart';
import '../utils/firebase_util.dart';

class ChatScreenController extends GetxController {
  static ChatScreenController get to => Get.find();
  final inputController = TextEditingController();
  final Map<String, dynamic> bookingData;
  // final String bookingId;
  //
  // final String userUniqueId;
  // final String bookingUserName;
  // final String bookingUserImage;
  var loggedInuserid = ''.obs;
  var loggedInuserName = ''.obs;
  var loggedInuserImage = ''.obs;
  final Rxn<DatabaseReference> refMessage = Rxn<DatabaseReference>();
  // final Rxn<DatabaseReference> refReceiverBookingMessage = Rxn<DatabaseReference>();

  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;

  final RxBool isLoadingMessages = true.obs;
  final RxString messageError = ''.obs;

  StreamSubscription<DatabaseEvent>? _messagesSubscription;

  final RxBool isOtherUserOnline = false.obs;
  final RxInt otherUserLastSeen = 0.obs;

  RxString otherUserId = ''.obs;
  RxString otherUserName = ''.obs;
  RxString otherUserImage = ''.obs;
  RxString otherUserMobile = ''.obs;

  StreamSubscription<DatabaseEvent>? _presenceSubscription;

  ChatScreenController({
    // required this.bookingId,
    // // required this.tripId,
    // required this.userUniqueId,
    // required this.bookingUserName,
    // required this.bookingUserImage,
  required this.bookingData
  });

  @override
  void onInit() {
    getChats();
    super.onInit();
  }

  Future<void> getChats() async {
    final prefs = await SharedPreferences.getInstance();

    loggedInuserid.value = prefs.getString('user_id') ?? '';
    loggedInuserName.value = prefs.getString('user_name') ?? '';
    loggedInuserImage.value = prefs.getString('user_image') ?? '';

    if(loggedInuserid.value != bookingData['user_id']){
      otherUserId.value = bookingData['user_id'];
      otherUserName.value = bookingData['user_name'];
      otherUserImage.value = bookingData['user_image'];
      otherUserMobile.value = bookingData['user_mobile'];
    }





    // print("getChats loggedInuserid ${loggedInuserid.value} "
    //     "loggedInuserName ${loggedInuserName.value} "
    //     "loggedInuserImage ${loggedInuserImage.value}");
    //
    // print("bookingData ${bookingData}}");

    if (loggedInuserid.value.isEmpty) {
      debugPrint('Logged-in user ID is missing');
      isLoadingMessages.value = false;
      messageError.value = 'User ID is missing';
      return;
    }

    getChatMessages();

  }

  void getChatMessages() {
    _messagesSubscription?.cancel();

    messages.clear();
    isLoadingMessages.value = true;
    messageError.value = '';

    final ref =
    FirebaseDatabase.instance.ref('${ChatUtil.NODE_MESSAGES}/${bookingData['id'].toString()}');

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


  Future<void> createChat() async {

    final text = inputController.text.trim();
    if (text.isEmpty) return;

    final String senderId = loggedInuserid.value;
    final String receiverId = otherUserId.value;
    final String creatorId = bookingData['user_id'].toString();
    final String currentBookingId = bookingData['id'].toString();

    // Unique conversation for each driver in a booking.
    final String driverId =
    senderId == creatorId ? receiverId : senderId;

    final String conversationId =
        '${currentBookingId}_$driverId';

    final rootRef = FirebaseDatabase.instance.ref();

    // IMPORTANT: Messages are stored by conversationId.
    final messageRef = rootRef.child(
      '${ChatUtil.NODE_MESSAGES}/$conversationId',
    );

    final String? messageKey = messageRef.push().key;

    if (messageKey == null) return;

    final int timestamp = DateTime.now().millisecondsSinceEpoch;

    String getImageUrl(String image) {
      if (image.isEmpty || image.startsWith('http')) {
        return image;
      }
      return '$appurl/$image';
    }

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

    final receiverChatRef = rootRef.child(
      '${ChatUtil.NODE_CHAT_LIST}/$receiverId/$conversationId',
    );

    final receiverRef = FirebaseDatabase.instance.ref(
      FirebaseUtil.NODE_USER,
    );

    try {
      // Get receiver's device token.
      String deviceToken = '';

      final receiverUserSnapshot =
      await receiverRef.child(receiverId).get();

      if (receiverUserSnapshot.exists &&
          receiverUserSnapshot.value is Map) {
        final receiverUserData = Map<String, dynamic>.from(
          receiverUserSnapshot.value as Map,
        );

        deviceToken =
            receiverUserData['device_token']?.toString() ?? '';
      }

      // Get existing unread count for THIS conversation.
      final receiverSnapshot = await receiverChatRef.get();

      final receiverData = receiverSnapshot.value is Map
          ? Map<String, dynamic>.from(
        receiverSnapshot.value as Map,
      )
          : <String, dynamic>{};

      final int oldUnreadCount =
          int.tryParse(
            receiverData['unreadCount']?.toString() ?? '0',
          ) ?? 0;

      final String senderImage =
      getImageUrl(loggedInuserImage.value);

      final String receiverImage =
      getImageUrl(bookingData['user_image']);

      final Map<String, dynamic> updates = {};

      // 1. Messages
      updates[
      '${ChatUtil.NODE_MESSAGES}/$conversationId/$messageKey'
      ] = newMessage.toJson();

      // 2. Conversation details
      final String conversationPath =
          '${ChatUtil.NODE_CONVERSATION}/$conversationId';

      updates['$conversationPath/bookingId'] =
          currentBookingId;

      updates['$conversationPath/conversationId'] =
          conversationId;

      updates['$conversationPath/bookingData'] =
          bookingData;

      updates['$conversationPath/participants/$senderId'] = {
        'name': loggedInuserName.value,
        'image': senderImage,
        'userId': senderId,
      };

      updates['$conversationPath/participants/$receiverId'] = {
        'name': otherUserName.value,
        'image': receiverImage,
        'userId': receiverId,
      };

      updates['$conversationPath/lastMessage'] = text;

      updates['$conversationPath/lastMessageTime'] =
          timestamp;

      updates['$conversationPath/lastMessageSenderId'] =
          senderId;

      updates['$conversationPath/status'] = 'active';

      // 3. Sender's ChatList
      updates[
      '${ChatUtil.NODE_CHAT_LIST}/$senderId/$conversationId'
      ] = {
        'conversationId': conversationId,
        'bookingId': currentBookingId,
        'otherUserId': receiverId,
        'otherUserImage': receiverImage,
        'lastMessage': text,
        'messageType': 'text',
        'lastMessageTime': timestamp,
        'lastMessageSenderId': senderId,
        'unreadCount': 0,
      };

      // 4. Receiver's ChatList
      updates[
      '${ChatUtil.NODE_CHAT_LIST}/$receiverId/$conversationId'
      ] = {
        'conversationId': conversationId,
        'bookingId': currentBookingId,
        'otherUserId': senderId,
        'otherUserImage': senderImage,
        'lastMessage': text,
        'messageType': 'text',
        'lastMessageTime': timestamp,
        'lastMessageSenderId': senderId,
        'unreadCount': oldUnreadCount + 1,
      };

      // Save everything atomically.
      await rootRef.update(updates);

      debugPrint('Conversation ID: $conversationId');
      debugPrint('Message saved: $messageKey');

      inputController.clear();

      // Send notification to receiver.
      // sendBookingNotification(currentBookingId, deviceToken);

    } on FirebaseException catch (e) {
      debugPrint('Firebase error: ${e.code}');
      debugPrint('Firebase message: ${e.message}');
    } catch (e) {
      debugPrint('Error creating chat: $e');
    }
  }


}



