import 'dart:io';

class ChatMessage {
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
  ChatMessage({this.messageId, this.messageBody, this.senderName, this.file, this.senderId, this.bookingId, this.receiverId, this.readStatus, this.type, this.timestamp});

  ChatMessage.fromJson(Map<String, dynamic> json) {
    messageId = json['messageId'];
    senderName = json['senderName'];
    senderId = json['senderId'];
    messageBody = json['messageBody'];
    readStatus = json['readStatus'];
    type = json['type'];
    timestamp = json['timestamp'];
    
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
    return data;
  }
}