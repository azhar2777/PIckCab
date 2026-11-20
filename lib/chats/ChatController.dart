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

    print("getChats loggedInuserid ${loggedInuserid.value} "
        "loggedInuserName ${loggedInuserName.value} "
        "loggedInuserImage ${loggedInuserImage.value}");

    print("${bookingData}}");
  }

}
