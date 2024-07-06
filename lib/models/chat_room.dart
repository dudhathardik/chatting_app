class ChatRoomModel {
  String? chatroomid;
  Map<String, dynamic>? participants;
  String? lastMessage;
  String? groupName = "";
  String? groupPic = "";
  String? type = "0";

    ChatRoomModel({
    this.chatroomid,
    this.participants,
    this.lastMessage,
    this.groupName,
    this.groupPic,
    this.type,
  });

  ChatRoomModel.fromMap(Map<String, dynamic> map) {
    chatroomid = map["chatroomid"];
    participants = map["participants"];
    lastMessage = map["lastMessage"];
    groupName = map["groupName"];
    groupPic = map["groupPic"];
    type = map["type"];
  }
  Map<String, dynamic> toMap() {
    return {
      "chatroomid": chatroomid,
      "participants": participants,
      "lastMessage": lastMessage,
      "groupName": groupName,
      "groupPic": groupPic,
      "type": type,
    };
  }
}
