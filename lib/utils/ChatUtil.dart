

import 'package:firebase_database/firebase_database.dart';
import 'package:pickcab_partner/model/ChatMessage.dart';

class ChatUtil {
  static String NODE_USER = "users";
  static String NODE_CHAT_LIST = "chatlist";
  static String NODE_CONVERSATION = "conversation";
  static String NODE_MESSAGES = "messages";
  

  static DatabaseReference getChatListNodeRef() {
    DatabaseReference ref = FirebaseDatabase.instance.ref('$NODE_CHAT_LIST');
    return ref;
  }

  static DatabaseReference getConversationRef() {
    DatabaseReference ref = FirebaseDatabase.instance.ref('$NODE_CONVERSATION');
    return ref;
  }

  static DatabaseReference getMessageNodeRef() {
    DatabaseReference ref = FirebaseDatabase.instance.ref('$NODE_MESSAGES');
    return ref;
  }


  static insertMessage(
    ChatMessage message, 
    String? senderUID, 
    String? receiverUID, 
    String? receiverId, 
    String senderName, 
    String receiverName, 
    String senderPic, 
    String receiverPic
  ){
    
    print(message.toJson().toString());
    
    final messaageKey = getConversationRef().push().key;
    print(messaageKey);
    
    final Map<String, Map> mapMessage = {};
    //Insert into message Node
    var timestamp = DateTime.now().millisecondsSinceEpoch;
    message.timestamp = '$timestamp';
    mapMessage['/$NODE_MESSAGES/$messaageKey'] = message.toJson();
    FirebaseDatabase.instance.ref().update(mapMessage);
    
    final Map<String, dynamic> mapMessageSender = {};
    mapMessageSender.putIfAbsent(messaageKey!, () => 1);
    

    // Chat list for Sender
    // createChatListForUsers(message, receiverUID!, message.senderId!, receiverId!, receiverPic, receiverName, true);
    // Chat list for Receiver
    // createChatListForUsers(message, senderUID!, receiverId, message.senderId!, senderPic, senderName, false);
    

  }

  static String getMessageDate(
      String timestamp, {
        bool timeOnly = false,
      }) {
    final int? milliseconds = int.tryParse(timestamp);

    if (milliseconds == null) return '';

    final DateTime date =
    DateTime.fromMillisecondsSinceEpoch(milliseconds);

    final String hour = (date.hour % 12 == 0 ? 12 : date.hour % 12)
        .toString();

    final String minute = date.minute.toString().padLeft(2, '0');

    final String period = date.hour >= 12 ? 'PM' : 'AM';

    final String time = '$hour:$minute $period';

    if (timeOnly) {
      return time;
    }

    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();

    return '$day/$month/$year $time';
  }

}
