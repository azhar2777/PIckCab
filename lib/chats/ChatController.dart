import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pickcab_partner/utils/firebase_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreenController extends GetxController {
  static ChatScreenController get to => Get.find();
  final inputController = TextEditingController();
  final String bookingId;
  final String tripId;
  final String userUniqueId;
  var loggedInuserid = ''.obs;
  final Rxn<DatabaseReference> refSenderBookingMessage = Rxn<DatabaseReference>();
  final Rxn<DatabaseReference> refReceiverBookingMessage = Rxn<DatabaseReference>();

  ChatScreenController({
    required this.bookingId,
    required this.tripId,
    required this.userUniqueId,
  });

  @override
  void onInit() {
    getChats();
    super.onInit();
  }

  Future<void> getChats() async {
    final prefs = await SharedPreferences.getInstance();
    loggedInuserid.value =
        prefs.getString("user_id") != null ? prefs.getString("user_id")! : '';
    print("getChatsss");
    print('Booking ID: $bookingId');
    print('Trip ID: $tripId');
    print('User ID: $userUniqueId');
    print('Current User ID: ${loggedInuserid.value}');
  }

  void createChat() async {
    print("inputController ${inputController.text.toString().trim()}");
    refSenderBookingMessage.value = FirebaseUtil.getBookingMessagesRef(loggedInuserid.value, tripId, userUniqueId);
    

  }
}
