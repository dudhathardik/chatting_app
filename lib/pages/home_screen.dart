import 'package:flutter/cupertino.dart';
import 'package:wp_chat/pages/group_screen.dart';

import '../models/chat_room.dart';
import '../models/users_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../notifiction/local_notofiction.dart';
import '../pages/chatroom_page.dart';
import '../pages/firebase_helper.dart';
import '../pages/search_page.dart';
import 'group_chatroom_page.dart';
import 'login_screen.dart';

enum FilterOption {
  NewGroup,
  Logout,
}

class Homepage extends StatefulWidget {
  final UserModel? userModel;
  final User? firebaseUser;
  // final ChatRoomModel? chatRoomModel;

  const Homepage({Key? key, this.userModel, this.firebaseUser})
      : super(key: key);

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  String deviceTokenToSendPushNotifiction = "";
  var _showOnlyFavorite = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    // method:-app close tyare:
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      print("----------------------------------------------------------------");

      print("FiarebaseMessaging.instance.getInitialMessage");
      if (message != null) {
        print("New  Notification");
      }
    });

    //method:-app open hoi tyare:-
    FirebaseMessaging.onMessage.listen((message) {
      print("FirebaseMessaging.onMessage.listen");
      if (message.notification != null) {
        print(
            "----------------------------------------------------------------");
        print(message.notification!.title);
        print(message.notification!.body);
        print("message.data11 ${message.data}");
        LocalNotifiction.createanddisplaynotification(message);
      }
    });

    // method 3:app background ma hoi tyare:-

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print("FirebaseMessaging.onMessageOpenedApp.listen");
      if (message.notification != null) {
        print(
            "----------------------------------------------------------------");

        print(message.notification!.title);
        print(message.notification!.body);
        print("message.data22 ${message.data['_id']}");
      }
    });
  }

  Future<void> getDeviceTokenToSendNotifiction() async {
    final FirebaseMessaging _fcm = FirebaseMessaging.instance;
    final token = await _fcm.getToken();
    deviceTokenToSendPushNotifiction = token.toString();
    final pref = await SharedPreferences.getInstance();
    await pref.setString("userToken", deviceTokenToSendPushNotifiction);
    print("Token Value $deviceTokenToSendPushNotifiction");
  }

  @override
  Widget build(BuildContext context) {
    getDeviceTokenToSendNotifiction();

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text(widget.userModel?.fullname ?? ""),
        centerTitle: true,
        actions: [
          PopupMenuButton(
            onSelected: (FilterOption selecteValue) {
              if (selecteValue == FilterOption.NewGroup) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupScreen(
                      userModel: widget.userModel!,
                      firebaseUser: widget.firebaseUser!,
                    ),
                  ),
                );
              } else {
                showDialog(
                    builder: (context) {
                      return CupertinoAlertDialog(
                        title: const Text("Do you want logout"),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              "Cancel",
                              style: TextStyle(color: Colors.teal),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();

                              // ignore: use_build_context_synchronously
                              Navigator.pop(context);
                              // ignore: use_build_context_synchronously
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) {
                                    return LoginScreen();
                                  },
                                ),
                              );
                            },
                            child: const Text(
                              "Logout",
                              style: TextStyle(color: Colors.teal),
                            ),
                          ),
                        ],
                      );
                    },
                    context: context);
              }
            },
            icon: const Icon(Icons.more_vert),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: FilterOption.NewGroup,
                child: Text('New Group'),
              ),
              const PopupMenuItem(
                value: FilterOption.Logout,
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.only(top: 5),
          child: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection("Chatrooms")
                .where("participants.${widget.userModel?.uid}", isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.active) {
                if (snapshot.hasData) {
                  QuerySnapshot chatRoomSnapshot =
                      snapshot.data as QuerySnapshot;

                  print(
                      "------------------widget.userModel.uid-----------------------");
                  print(chatRoomSnapshot.docs.length);
                  print(
                      "------------------widget.userModel.uid-----------------------");

                  return ListView.builder(
                      itemCount: chatRoomSnapshot.docs.length,
                      itemBuilder: (context, index) {
                        ChatRoomModel chatRoomModel = ChatRoomModel.fromMap(
                            chatRoomSnapshot.docs[index].data()
                                as Map<String, dynamic>);
                        // print(chatRoomModel);

                        if (chatRoomModel.type == "1") {
                          return Column(
                            children: [
                              ListTile(
                                trailing: IconButton(
                                    onPressed: () {
                                      showDialog(
                                          builder: (context) {
                                            return CupertinoAlertDialog(
                                              title: const Text(
                                                  "Do you want delete permanently"),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text(
                                                    "Cancel",
                                                    style: TextStyle(
                                                        color: Colors.teal),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    FirebaseFirestore.instance
                                                        .collection("Chatrooms")
                                                        .doc(chatRoomSnapshot
                                                            .docs[index].id)
                                                        .delete();
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text(
                                                    "Delete",
                                                    style: TextStyle(
                                                        color: Colors.teal),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                          context: context);
                                    },
                                    icon: Icon(Icons.delete)),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) {
                                      return GroupChatroomPage(chatRoomModel);
                                    }),
                                  );
                                },
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    chatRoomModel.groupPic.toString(),
                                  ),
                                ),
                                focusColor: Colors.white,
                                title: Text(
                                  chatRoomModel.groupName.toString(),
                                ),
                                subtitle: (chatRoomModel.lastMessage
                                            .toString() !=
                                        "")
                                    ? Text(chatRoomModel.lastMessage.toString())
                                    : Text(
                                        "Say hi to your new friend!",
                                        style: TextStyle(
                                            color: Colors.deepPurple.shade200),
                                      ),
                              ),
                              Divider(
                                thickness: 1,
                                color: Colors.deepPurple.withOpacity(0.2),
                                indent: 65,
                                endIndent: 10,
                              )
                            ],
                          );
                        } else {
                          Map<String, dynamic> participants =
                              chatRoomModel.participants!;

                          List<String> participantKeys =
                              participants.keys.toList();

                          participantKeys.remove(widget.userModel!.uid);

                          return FutureBuilder(
                              future: FirebaseHelper.getUserModelById(
                                  participantKeys[0]),
                              builder: (context, userData) {
                                if (userData.connectionState ==
                                    ConnectionState.done) {
                                  if (userData.data != null) {
                                    UserModel targetUser =
                                        userData.data as UserModel;
                                    print(
                                        "------------------------hello hello-------------------");
                                    // userData.data.forEach((e) {
                                    //   print(e.data());
                                    // });
                                    //7203874378
                                    print(targetUser.fullname);
                                    print(
                                        "------------------------hello helloooo-------------------");
                                    return Column(
                                      children: [
                                        ListTile(
                                          trailing: IconButton(
                                              onPressed: () {
                                                showDialog(
                                                    builder: (context) {
                                                      return CupertinoAlertDialog(
                                                        title: const Text(
                                                            "Do you want delete permanently"),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: const Text(
                                                              "Cancel",
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .teal),
                                                            ),
                                                          ),
                                                          TextButton(
                                                            onPressed: () {
                                                              FirebaseFirestore
                                                                  .instance
                                                                  .collection(
                                                                      "Chatrooms")
                                                                  .doc(chatRoomSnapshot
                                                                      .docs[
                                                                          index]
                                                                      .id)
                                                                  .delete();
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: const Text(
                                                              "Delete",
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .teal),
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                    context: context);
                                              },
                                              icon: Icon(Icons.delete)),
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) {
                                                return ChatRoomPage(
                                                  chatRoom: chatRoomModel,
                                                  firebaseUser:
                                                      widget.firebaseUser!,
                                                  userModel: widget.userModel!,
                                                  targetUser: targetUser,
                                                );
                                              }),
                                            );
                                          },
                                          dense: true,
                                          visualDensity: VisualDensity.compact,
                                          leading: CircleAvatar(
                                            backgroundImage: NetworkImage(
                                              targetUser.profilepic.toString(),
                                            ),
                                          ),
                                          focusColor: Colors.white,
                                          title: Text(
                                            targetUser.fullname.toString(),
                                          ),
                                          subtitle: (chatRoomModel.lastMessage
                                                      .toString() !=
                                                  "")
                                              ? Text(chatRoomModel.lastMessage
                                                  .toString())
                                              : Text(
                                                  "Say hi to your new friend!",
                                                  style: TextStyle(
                                                      color: Colors
                                                          .deepPurple.shade200),
                                                ),
                                        ),
                                        Divider(
                                          thickness: 1,
                                          color: Colors.deepPurple
                                              .withOpacity(0.2),
                                          indent: 65,
                                          endIndent: 10,
                                        )
                                      ],
                                    );
                                  } else {
                                    return const SizedBox();
                                  }
                                } else {
                                  return const SizedBox();
                                }
                              });
                        }
                      });
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(snapshot.error.toString()),
                  );
                } else {
                  return const Center(
                    child: Text("No chats"),
                  );
                }
              } else {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SearchPage(
                userModel: widget.userModel!,
                firebaseUser: widget.firebaseUser!,
              ),
            ),
          );
        },
        child: const Icon(Icons.search),
      ),
    );
  }
}
