import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:pickcab_partner/utils/ChatUtil.dart';

class ChatListController extends GetxController {
  final RxList<Map<String, dynamic>> conversations =
      <Map<String, dynamic>>[].obs;

  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  StreamSubscription<DatabaseEvent>? _conversationList;
  StreamSubscription<DatabaseEvent>? _chatListSubscription;
  final Map<String, StreamSubscription<DatabaseEvent>>
      _bookingConversationSubscriptions = {};
  final Map<String, Set<String>> _otherUsersByBooking = {};
  final Map<String, Map<String, dynamic>> _conversationData = {};
  final Map<String, Map<String, dynamic>> _chatListData = {};
  String? _currentUserId;

  void getUserConversations(String userId) {
    if (userId.isEmpty) {
      errorMessage.value = 'User ID is missing';
      isLoading.value = false;
      return;
    }

    if (_currentUserId == userId && _conversationList != null) return;

    _currentUserId = userId;
    _cancelConversationSubscriptions();
    _chatListSubscription?.cancel();
    conversations.clear();
    _conversationData.clear();
    _chatListData.clear();
    isLoading.value = true;
    errorMessage.value = '';

    _conversationList = FirebaseDatabase.instance
        .ref('${ChatUtil.NODE_USER_CONVERSATIONS}/$userId')
        .onValue
        .listen(
      _handleUserConversationIndex,
      onError: (Object error) {
        errorMessage.value = 'Failed to load conversations';
        isLoading.value = false;
      },
    );

    _chatListSubscription = FirebaseDatabase.instance
        .ref('${ChatUtil.NODE_CHAT_LIST}/$userId')
        .onValue
        .listen(
      (event) {
        _chatListData
          ..clear()
          ..addAll(_readChildMaps(event.snapshot));
        _updateConversations();
      },
      onError: (Object error) {
        errorMessage.value = 'Failed to load conversations';
        isLoading.value = false;
      },
    );
  }

  void _handleUserConversationIndex(DatabaseEvent event) {
    final otherUsersByBooking = <String, Set<String>>{};

    for (final bookingSnapshot in event.snapshot.children) {
      final bookingId = bookingSnapshot.key;
      if (bookingId == null) continue;

      final otherUserIds = bookingSnapshot.children
          .map((participant) => participant.key)
          .whereType<String>()
          .toSet();
      if (otherUserIds.isNotEmpty) {
        otherUsersByBooking[bookingId] = otherUserIds;
      }
    }

    for (final bookingId in _bookingConversationSubscriptions.keys.toList()) {
      if (!otherUsersByBooking.containsKey(bookingId)) {
        _bookingConversationSubscriptions.remove(bookingId)?.cancel();
        _conversationData.remove(bookingId);
      }
    }
    _otherUsersByBooking
      ..clear()
      ..addAll(otherUsersByBooking);

    for (final bookingId in otherUsersByBooking.keys) {
      if (_bookingConversationSubscriptions.containsKey(bookingId)) continue;

      _bookingConversationSubscriptions[bookingId] = FirebaseDatabase.instance
          .ref('${ChatUtil.NODE_CONVERSATION}/$bookingId')
          .onValue
          .listen(
        (conversationEvent) {
          final value = conversationEvent.snapshot.value;
          _conversationData[bookingId] = value is Map
              ? Map<String, dynamic>.from(value)
              : <String, dynamic>{};
          _updateConversations();
        },
        onError: (Object error) {
          errorMessage.value = 'Failed to load conversations';
          isLoading.value = false;
        },
      );
    }

    _updateConversations();
  }

  Map<String, Map<String, dynamic>> _readChildMaps(DataSnapshot snapshot) {
    final result = <String, Map<String, dynamic>>{};
    for (final child in snapshot.children) {
      final value = child.value;
      if (child.key != null && value is Map) {
        result[child.key!] = Map<String, dynamic>.from(value);
      }
    }
    return result;
  }

  void _updateConversations() {
    final result = <Map<String, dynamic>>[];

    for (final entry in _otherUsersByBooking.entries) {
      final bookingId = entry.key;
      final conversation = _conversationData[bookingId];
      if (conversation == null || conversation.isEmpty) continue;

      final bookingDataValue = conversation['bookingData'];
      final bookingData = bookingDataValue is Map
          ? Map<String, dynamic>.from(bookingDataValue)
          : <String, dynamic>{};
      final chatListEntry = _chatListData[bookingId] ?? const {};

      for (final otherUserId in entry.value) {
        final name = chatListEntry['otherUserName']?.toString() ??
            bookingData['user_name']?.toString() ??
            'User';
        final image = chatListEntry['otherUserImage']?.toString() ??
            bookingData['user_image']?.toString() ??
            '';
        final mobile = chatListEntry['otherUserMobile']?.toString() ??
            bookingData['mobile']?.toString() ??
            '';

        result.add({
          ...chatListEntry,
          ...conversation,
          'bookingId': bookingId,
          'conversationId': bookingId,
          'otherUserId': otherUserId,
          'name': name,
          'userImage': image,
          'otherUserMobile': mobile,
          'bookingData': bookingData,
        });
      }
    }

    result.sort((a, b) {
      final timeA = int.tryParse(a['lastMessageTime']?.toString() ?? '') ?? 0;
      final timeB = int.tryParse(b['lastMessageTime']?.toString() ?? '') ?? 0;
      return timeB.compareTo(timeA);
    });

    conversations.assignAll(result);
    isLoading.value = false;
    errorMessage.value = '';
  }

  void _cancelConversationSubscriptions() {
    for (final subscription in _bookingConversationSubscriptions.values) {
      subscription.cancel();
    }
    _bookingConversationSubscriptions.clear();
    _otherUsersByBooking.clear();
  }

  @override
  void onClose() {
    _conversationList?.cancel();
    _chatListSubscription?.cancel();
    _cancelConversationSubscriptions();
    super.onClose();
  }
}
