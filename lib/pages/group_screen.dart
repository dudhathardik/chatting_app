import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wp_chat/pages/group_name.dart';

import '../main.dart';
import '../models/chat_room.dart';
import '../models/users_model.dart';

class GroupScreen extends StatefulWidget {
  final UserModel userModel;
  final User firebaseUser;

  const GroupScreen(
      {Key? key, required this.userModel, required this.firebaseUser})
      : super(key: key);

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  // List<UserModel> groupList = [];
  List<UserModel> usersList = [];
  bool isLoading = false;
  List<UserModel> selectedUsersList = [];
  // bool isSelect = false;
  // List<bool> list = [];

  String? loginUserId;
  bool isSelected = true;
  String? chatRoomId;
  late ChatRoomModel newChatroom;
  @override
  void initState() {
    currentUserId();
    super.initState();
  }

  void currentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    loginUserId = prefs.getString('userId').toString();
    getUserList();
  }

  Future<ChatRoomModel?> getGroupChatroomModel(
      List<UserModel> targetUser) async {
    ChatRoomModel? chatRoom;

    log(widget.userModel.uid.toString());

    newChatroom = ChatRoomModel(
      chatroomid: uuid.v1(),
      lastMessage: "",
      groupPic: "",
      groupName: "",
      type: "1",
      participants: {
        widget.userModel.uid.toString(): true,
      },
    );
    targetUser.forEach((element) {
      newChatroom.participants!.addAll({element.uid.toString(): true});
    });

    await FirebaseFirestore.instance
        .collection("Chatrooms")
        .doc(newChatroom.chatroomid)
        .set(newChatroom.toMap());

    chatRoom = newChatroom;

    log("New Chatroom Created!");
    log(newChatroom.chatroomid.toString());
    chatRoomId = newChatroom.chatroomid.toString();

    return chatRoom;
  }

  Future<void> getUserList() async {
    var qs = await FirebaseFirestore.instance.collection("user").get();

    if (qs.docs.isNotEmpty) {
      for (int i = 0; i < qs.docs.length; i++) {
        usersList
            .add(UserModel.fromMap(qs.docs[i].data() as Map<String, dynamic>));
      }
      usersList.removeWhere(
        (element) => element.uid == loginUserId,
      );
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: const Text("Contacts"),
        backgroundColor: Colors.teal.shade400,
        actions: [
          IconButton(
            onPressed: () async {
              ChatRoomModel? chatRoomModel =
                  await getGroupChatroomModel(selectedUsersList);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupName(chatRoomModel),
                ),
              );
            },
            icon: const Icon(
              Icons.done,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20),
          child: isLoading
              ? const CircularProgressIndicator()
              : ListView.builder(
                  itemCount: usersList.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 6,
                            spreadRadius: 1,
                            color: Colors.black12,
                          )
                        ],
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        onTap: () async {
                          setState(() {
                            if (selectedUsersList.any((element) =>
                                element.uid == usersList[index].uid)) {
                              selectedUsersList.add(
                                  UserModel.fromMap(usersList[index].toMap()));
                            } else {
                              selectedUsersList.removeWhere((element) =>
                                  element.uid == usersList[index].uid);
                            }

                            // usersList[index].isSelect = value!;
                          });
                        },
                        leading: CircleAvatar(
                          backgroundImage:
                              NetworkImage(usersList[index].profilepic ?? ''),
                          backgroundColor: Colors.grey.shade300,
                        ),
                        title: Text(usersList[index].fullname.toString()),
                        subtitle: Text(usersList[index].number.toString()),
                        trailing: Checkbox(
                          onChanged: (bool? value) {
                            setState(() {
                              if (value ?? false) {
                                selectedUsersList.add(UserModel.fromMap(
                                    usersList[index].toMap()));
                              } else {
                                selectedUsersList.removeWhere((element) =>
                                    element.uid == usersList[index].uid);
                              }

                              // usersList[index].isSelect = value!;
                            });
                          },
                          value: selectedUsersList.any(
                              (element) => element.uid == usersList[index].uid),
                        ),
                        focusColor: Colors.white,
                        autofocus: true,
                      ),
                    );
                  }),
        ),
      ),
    );
  }
}
