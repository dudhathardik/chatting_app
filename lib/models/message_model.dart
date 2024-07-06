import 'dart:io';

class MessageModel {
  String? messageId;
  String? sender;
  String? text;
  bool? seen;
  DateTime? createdon;
  String? type;
  String? mediaFilePath;
  DateTime? time;

  MessageModel({
    this.sender,
    this.text,
    this.seen,
    this.createdon,
    this.messageId,
    this.type,
    this.mediaFilePath,
    this.time,
  });

  MessageModel.forMap(Map<String, dynamic> map) {
    messageId = map["messageId"];
    sender = map["sender"];
    text = map["text"];
    seen = map["map"];
    createdon = map["createdon"].toDate();
    type = map["type"];
    mediaFilePath = map["mediaFilePath"];
    time = map["time"];
  }

  Map<String, dynamic> toMap() {
    return {
      "messageId": messageId,
      "sender": sender,
      "text": text,
      "seen": seen,
      "createdon": createdon,
      "type": type,
      "mediaFilePath": mediaFilePath,
      "time": time,
    };
  }
}
