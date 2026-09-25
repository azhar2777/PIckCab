import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import '../model/PPUser.dart';

class Message {
  String? messageId;
  String? senderName;
  String? senderId;
  String? receiverId;
  String? bookingId;
  String? messageBody;
  String? readStatus;
  File? file;
  String? type;
  String? timestamp;
  String? messageDate;
  String? messageTime;
  Message({this.messageId, this.messageBody, this.senderName, this.file, this.senderId, this.bookingId, this.receiverId, this.readStatus, this.type, this.timestamp, this.messageDate, this.messageTime});

  Message.fromJson(Map<String, dynamic> json) {
    messageId = json['messageId'];
    senderName = json['senderName'];
    senderId = json['senderId'];
    messageBody = json['messageBody'];
    readStatus = json['readStatus'];
    type = json['type'];
    timestamp = json['timestamp'];
    messageDate = json['messageDate'];
    messageTime = json['messageTime'];
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['messageId'] = messageId;
    data['senderName'] = senderName;
    data['senderId'] = senderId;
    data['messageBody'] = messageBody;
    data['readStatus'] = readStatus;
    data['type'] = type;
    data['timestamp'] = timestamp;
    data['messageTime'] = messageTime;
    return data;
  }
}

class FirebaseUtil{

  static String NODE_USER = "users";
  static String NODE_CHAT_LIST = "chatList";
  static String NODE_USER_MESSAGES = "userMessages";
  static String NODE_MESSAGES = "messages";
  // static String FCM_SERVER_KEY = "AAAAVSFo0kk:APA91bGk1C7dxJnuHWSq-Pt7yKLtf-xKgz-lD07bCLg-Q_CwVYNsPh3dgNvxWVtfMJqY2L6fFH5C4E1DqL-BKGIOBsKzWSIAtg9fLEmKrjaRIrfKCRlb-IWR7J4LWqQ6GigYj3nHtTfH";
  static getFirebaseUser()  {
    if(FirebaseAuth.instance.currentUser !=null) {
      return FirebaseAuth.instance.currentUser;
    }
    return null;
  }

  static getUserNodeRefById(String userId) {
    DatabaseReference ref = FirebaseDatabase.instance.ref('$NODE_USER/${userId}');
    return ref;
  }
  static getChatListNodeRef() {
    DatabaseReference ref = FirebaseDatabase.instance.ref('$NODE_CHAT_LIST');
    return ref;
  }
  static updateUserSpecificFieledInFirebase(String userId, String key, String value) async{
    DatabaseReference ref =
    FirebaseDatabase.instance.ref('users');
    await ref.child(userId).set({
      key:value
    });
  }
  static updateuser(String userId, Map<String, dynamic> mapState) async{
    DatabaseReference ref =
    FirebaseDatabase.instance.ref('$NODE_USER');
    await ref.child(userId).update(mapState.cast());
  }
  static updateUserState(String userId, int status) async{
    DateTime today = DateTime.now().toUtc();
    Map<String, dynamic> mapState = {
      'state':status ==1 ? 'Online':'Offline',
      'dateTime':DateFormat('yyyy-MM-dd hh:mm:ss').format(today),
    };
    DatabaseReference ref =
    FirebaseDatabase.instance.ref('$NODE_USER');
    await ref.child(userId).child("/userState").update(mapState.cast());
  }

  static DatabaseReference getBookingMessagesRef(
      String bookingId,
      String driverId,
      ) {
    return FirebaseDatabase.instance
        .ref('$NODE_USER_MESSAGES/$bookingId/$driverId');
  }

  // static getFirebaseDatabaseRefForUserMessageIds(String? senderUID, String? receiverUID) {
  //   DatabaseReference ref =
  //   FirebaseDatabase.instance.ref('$NODE_USER_MESSAGES');
  //   return ref.child('${senderUID!}/${receiverUID!}');
  // }
  static DatabaseReference getFirebaseDatabaseRefForUserMessage() {
    DatabaseReference ref =
    FirebaseDatabase.instance.ref('$NODE_MESSAGES');
    return ref;
  }

  static updateUserData(PPUser user) async{
    final ref = await getUserNodeRefById(user.userUnqId.toString());
    // print("updateUserData ${user}");


    try{
      ref.update(user.toJson());
    }
    catch(e){

      print("Error while update");
      print(e);
    }


  }



  static insertMessage(Message message, String? senderUID, String? receiverUID, String? receiverId, String senderName, String receiverName, String senderPic, String receiverPic, bool isOnline){
    print(message.toJson().toString());
    // final senderMessageKey = getFirebaseDatabaseRefForUserMessageIds(message.senderId, receiverId);
    // final receiverMessageKey = getFirebaseDatabaseRefForUserMessageIds(receiverId, message.senderId);
    final messaageKey = getFirebaseDatabaseRefForUserMessage().push().key;
    print(messaageKey);
    final Map<String, Map> mapMessage = {};
    //Insert into message Node
    var timestamp = DateTime.now().millisecondsSinceEpoch;
    message.timestamp = '$timestamp';
    mapMessage['/$NODE_MESSAGES/$messaageKey'] = message.toJson();
    FirebaseDatabase.instance.ref().update(mapMessage);
    //Insert into Sender Message Node
    final Map<String, dynamic> mapMessageSender = {};
    mapMessageSender.putIfAbsent(messaageKey!, () => 1);
    // receiverMessageKey.update(mapMessageSender);
    //Insert into receiver Message Node
    // senderMessageKey.update(mapMessageSender);


    // Chat list for Sender
    createChatListForUsers(message, receiverUID!, message.senderId!, receiverId!, receiverPic, receiverName, true);
    // Chat list for Receiver
    createChatListForUsers(message, senderUID!, receiverId, message.senderId!, senderPic, senderName, false);
    // if(!isOnline)
      sendNotification(receiverId, message);

  }

  static createChatListForUsers(Message message, String userId, String senderId, String receiverId, String userPic, String senderName, bool addunread) async {

    DatabaseReference ref =  FirebaseDatabase.instance.ref('$NODE_CHAT_LIST').child('${senderId}/${receiverId}');
    int? unreadMessageCount = 0;
    if(!addunread) {
      DatabaseEvent event = await ref.child("unReadMessageCount").once();
      if(event.snapshot.value !=null) {
        unreadMessageCount = int.parse(event.snapshot.value.toString()) + 1;
        debugPrint("unReasMessageCount ${senderId} / ${receiverId}");
        debugPrint("unReasMessageCount $unreadMessageCount");
      }
      else{
        unreadMessageCount = 1;
      }


    }

    var timestamp = DateTime.now().millisecondsSinceEpoch;


    final Map<String, dynamic> mapChatList = {
      "userId":userId,
      "message":message.messageBody,
      "messageType":message.type,
      "name":senderName,
      "profilePic":userPic,
      "timeStamp": "$timestamp",
      "unReadMessageCount":unreadMessageCount > 0 ? unreadMessageCount :0,
    };
    ref.update(mapChatList);
  }

  static void sendNotification(String receiverUID, Message message) async {
    DatabaseReference ref =  FirebaseDatabase.instance.ref('$NODE_USER').child('$receiverUID');
    DatabaseEvent event = await ref.child("fcmToken").once();
    // debugPrint("$receiverUID fcmToken ${event.snapshot.value}");
    if(event.snapshot.value !=null ){
      debugPrint("$receiverUID fcmToken ${event.snapshot.value}");
      DatabaseReference refReceiver =  FirebaseDatabase.instance.ref('$NODE_CHAT_LIST').child('${receiverUID}');

      // DatabaseEvent eventReceiver = await ref.once();
      print("refReceiver");
      var snapshot = await refReceiver.get();
      var badgeCount= 0;
      snapshot.children.forEach((childSnapshot) {
        var databaseMapper = childSnapshot.value as Map;
        print("databaseMapper");
        badgeCount = int.parse(databaseMapper['unReadMessageCount'].toString());
        print(databaseMapper['unReadMessageCount']);
      });

      // badgeCount = 12;
      // callOnFcmApiSendPushNotifications([event.snapshot.value.toString()], message.messageBody!, message.senderName!, badgeCount > 0 ? badgeCount:1);
    }
  }



  // ====================
  static String getDateTime(String timestamp){
    String messageTime = "";
    // debugPrint("${int.parse(timestamp)}");
    var date = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp)).toUtc().toLocal();
    var today = DateTime.now().toUtc().toLocal();

    if(daysBetween(date, today) == 0){
      if(DateFormat('dd, MMM, yyyy').format(today) == DateFormat('dd, MMM, yyyy').format(date)){
        messageTime = DateFormat.jm().format(date);
      }
      else{
        messageTime = "Yesterday ${DateFormat('hh:mm a').format(date)}";
      }
    }
    else if(daysBetween(date, today) == 1){
      messageTime = "Yesterday ${DateFormat('hh:mm a').format(date)}";
    }
    else if(daysBetween(date, today) >1 && daysBetween(date, today) < 7){
      messageTime = "${DateFormat('EEEE').format(date)}";
    }
    else{
      messageTime = new DateFormat("dd, MMM, yyyy").format(date);
    }
    // debugPrint("timestamp ${messageTime}");
    return messageTime;
  }
  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }
  static String getMessageDate(String timestamp, {bool timeOnly = false}){
    String messageDate = "";
    // debugPrint("${int.parse(timestamp)}");
    var date = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp)).toUtc().toLocal();
    var today = DateTime.now().toUtc().toLocal();

    if(timeOnly){
      return messageDate = new DateFormat("h:mm aaa").format(date);
    }

    if(daysBetween(date, today) == 0){
      if(DateFormat('dd, MMM, yyyy').format(today) == DateFormat('dd, MMM, yyyy').format(date)){
        messageDate = "Today";
      }
      else{
        messageDate = "Yesterday";
      }
    }
    else if(daysBetween(date, today) == 1){
      messageDate = "Yesterday";
    }
    else if(daysBetween(date, today) >1 && daysBetween(date, today) < 7){
      messageDate = "${DateFormat('EEEE').format(date)}";
    }
    else{
      messageDate = new DateFormat("dd, MMM, yyyy").format(date);
    }
    // debugPrint("messageDate ${messageDate}");
    return messageDate;
  }

  static int getTotalUnReadCount(){

    return 0;
  }

  static void updateProfilePic(String? userId, String? photo){
    debugPrint("updateProfilePic $userId , update photo $photo");
    DatabaseReference ref =  FirebaseDatabase.instance.ref('${FirebaseUtil.NODE_USER}').child('$userId');
    ref.update({'photo': photo});
  }



  static deleteAccount(String userId, bool status) async {

    DatabaseReference ref =  FirebaseDatabase.instance.ref('$NODE_USER').child('$userId');;
    final Map<String, dynamic> mapDelete= {
      "accountDeleted":status ? "1" : "0",
    };
    ref.update(mapDelete);
  }
  static activateDeactivateAccount(String userId, bool status) async {

    DatabaseReference ref =  FirebaseDatabase.instance.ref('$NODE_USER').child('$userId');;
    final Map<String, dynamic> mapActive = {
      "isActive":status ? "1" : "0",
    };
    ref.update(mapActive);
  }
}