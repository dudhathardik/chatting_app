import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:file_picker/file_picker.dart';

import '../main.dart';
import '../models/chat_room.dart';
import '../models/users_model.dart';
import 'chatroom_page.dart';

class SearchPage extends StatefulWidget {
  final UserModel userModel;
  final User firebaseUser;

  const SearchPage(
      {Key? key, required this.userModel, required this.firebaseUser})
      : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String? loginUserId;
  @override
  void initState() {
    currentUserId();
    super.initState();
  }

  void currentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    loginUserId = prefs.getString('userId').toString();
  }

  TextEditingController searchController = TextEditingController(text: "+91");

  Future<ChatRoomModel?> getChatroomModel(UserModel targetUser) async {
    ChatRoomModel? chatRoom;

    log(targetUser.uid.toString());
    log(widget.userModel.uid.toString());

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("Chatrooms")
        .where("participants.${widget.userModel.uid}", isEqualTo: true)
        .where("participants.${targetUser.uid}", isEqualTo: true)
        .where("type", isEqualTo: 0)
        .get();

    if (snapshot.docs.length > 0) {
      var docData = snapshot.docs[0].data();
      log(docData.toString());
      ChatRoomModel existingChatroom =
          ChatRoomModel.fromMap(docData as Map<String, dynamic>);

      chatRoom = existingChatroom;
    } else {
      ChatRoomModel newChatroom = ChatRoomModel(
        chatroomid: uuid.v1(),
        lastMessage: "",
        participants: {
          widget.userModel.uid.toString(): true,
          targetUser.uid.toString(): true,
        },
      );

      await FirebaseFirestore.instance
          .collection("Chatrooms")
          .doc(newChatroom.chatroomid)
          .set(newChatroom.toMap());

      chatRoom = newChatroom;

      log("New Chatroom Created!");
    }
    return chatRoom;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: const Text("Contacts"),
        backgroundColor: Colors.teal.shade400,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20),
          child: Column(
            children: [
              // TextFormField(
              //   controller: searchController,
              //   decoration: const InputDecoration(
              //     enabledBorder: OutlineInputBorder(
              //       borderSide: BorderSide(color: Colors.teal, width: 2),
              //     ),
              //     focusedBorder: OutlineInputBorder(
              //       borderSide: BorderSide(
              //         color: Colors.teal,
              //         width: 1,
              //       ),
              //     ),
              //     fillColor: Colors.white,
              //     filled: true,
              //     hintText: "Email Address",
              //     hintStyle: TextStyle(
              //       color: Colors.grey,
              //       fontWeight: FontWeight.w400,
              //       fontSize: 18,
              //     ),
              //   ),
              // ),
              // const SizedBox(height: 20),
              // CupertinoButton(
              //   onPressed: () {
              //     setState(() {});
              //   },
              //   color: Colors.teal,
              //   child: const Text("Search"),
              // ),
              // const SizedBox(height: 20),

              StreamBuilder(
                stream:
                    FirebaseFirestore.instance.collection("user").snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.active) {
                    if (snapshot.hasData) {
                      QuerySnapshot dataSnapshot =
                          snapshot.data as QuerySnapshot;

                      if (dataSnapshot.docs.length > 0) {
                        List<UserModel> usersList = [];

                        for (int i = 0; i < dataSnapshot.docs.length; i++) {
                          usersList.add(UserModel.fromMap(dataSnapshot.docs[i]
                              .data() as Map<String, dynamic>));
                        }

                        usersList.removeWhere(
                          (element) => element.uid == loginUserId,
                        );
                        return Expanded(
                          child: ListView.builder(
                            itemCount: usersList.length,
                            itemBuilder: (context, index) {
                              Map<String, dynamic> userMap =
                                  dataSnapshot.docs[index].data()
                                      as Map<String, dynamic>;
                              print(
                                  "--------------------------------------------------");
                              print(dataSnapshot.docs.length);
                              print(
                                  "--------------------------------------------------");

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
                                    ChatRoomModel? chatRoomModel =
                                        await getChatroomModel(
                                            usersList[index]);

                                    if (chatRoomModel != null) {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) {
                                          return ChatRoomPage(
                                            targetUser: usersList[index],
                                            userModel: widget.userModel,
                                            firebaseUser: widget.firebaseUser,
                                            chatRoom: chatRoomModel,
                                          );
                                        }),
                                      );
                                    }
                                  },
                                  leading: CircleAvatar(
                                    backgroundImage: NetworkImage(
                                        usersList[index].profilepic ?? ''),
                                    backgroundColor: Colors.grey.shade300,
                                  ),
                                  title: Text(
                                      usersList[index].fullname.toString()),
                                  subtitle:
                                      Text(usersList[index].number.toString()),
                                  trailing:
                                      const Icon(Icons.keyboard_arrow_right),
                                  focusColor: Colors.white,
                                  autofocus: true,
                                ),
                              );
                            },
                          ),
                        );
                      } else {
                        return const Text("No Results found!");
                      }
                    } else if (snapshot.hasError) {
                      return const Text("An error occured!");
                    } else {
                      return const Text("No Results found!");
                    }
                  } else {
                    return const CircularProgressIndicator();
                  }
                },
              ),

              // StreamBuilder(
              //   stream: FirebaseFirestore.instance
              //       .collection("user")
              //       // .where("number", isEqualTo: searchController.text)
              //       // .where("number", isNotEqualTo: widget.userModel.number)
              //       .snapshots(),
              //   builder: (context, snapshot) {
              //     if (snapshot.connectionState == ConnectionState.active) {
              //       if (snapshot.hasData) {
              //         QuerySnapshot dataSnapshot =
              //             snapshot.data as QuerySnapshot;
              //         if (dataSnapshot.docs.length > 0) {
              //           // Map<String, dynamic> userMap =
              //           //     dataSnapshot.docs[0].data() as Map<String, dynamic>;

              //           // UserModel searchUser = UserModel.fromMap(userMap);

              //           return ListView.builder(
              //               itemCount: dataSnapshot.docs.length,
              //               itemBuilder: (context, index) {
              //                 Map<String, dynamic> userMap =
              //                     dataSnapshot.docs[index].data()
              //                         as Map<String, dynamic>;

              //                 UserModel userDataList =
              //                     UserModel.fromMap(userMap);
              //                 return Container(
              //                   decoration: BoxDecoration(
              //                       boxShadow: const [
              //                         BoxShadow(
              //                           blurRadius: 6,
              //                           spreadRadius: 1,
              //                           color: Colors.black12,
              //                         )
              //                       ],
              //                       color: Colors.white,
              //                       borderRadius: BorderRadius.circular(8)),
              //                   child: ListTile(
              //                     onTap: () async {
              //                       ChatRoomModel? chatRoomModel =
              //                           await getChatroomModel(userDataList);
              //                       if (chatRoomModel != null) {
              //                         Navigator.pop(context);
              //                         Navigator.push(
              //                           context,
              //                           MaterialPageRoute(builder: (context) {
              //                             return ChatRoomPage(
              //                               targetUser: userDataList,
              //                               userModel: widget.userModel,
              //                               firebaseUser: widget.firebaseUser,
              //                               chatRoom: chatRoomModel,
              //                             );
              //                           }),
              //                         );
              //                       }
              //                     },
              //                     leading: CircleAvatar(
              //                       backgroundImage:
              //                           NetworkImage(userDataList.profilepic!),
              //                       backgroundColor: Colors.grey.shade300,
              //                     ),
              //                     title: Text(userDataList.fullname.toString()),
              //                     subtitle:
              //                         Text(userDataList.number.toString()),
              //                     trailing:
              //                         const Icon(Icons.keyboard_arrow_right),
              //                     focusColor: Colors.white,
              //                     autofocus: true,
              //                   ),
              //                 );
              //               });
              //         } else {
              //           return const Text("No Results found!");
              //         }
              //       } else if (snapshot.hasError) {
              //         return const Text("An error occured!");
              //       } else {
              //         return const Text("No Results found!");
              //       }
              //     } else {
              //       return const CircularProgressIndicator();
              //     }
              //   },
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
