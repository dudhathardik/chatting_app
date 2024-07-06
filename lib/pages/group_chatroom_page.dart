import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:external_path/external_path.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:wp_chat/models/message_model.dart';

import '../main.dart';
import '../models/chat_room.dart';
import '../models/ui_helper.dart';
import '../models/users_model.dart';

class GroupChatroomPage extends StatefulWidget {
  ChatRoomModel chatRoommodel;
  GroupChatroomPage(this.chatRoommodel);

  @override
  State<GroupChatroomPage> createState() => _GroupChatroomPageState();
}

class _GroupChatroomPageState extends State<GroupChatroomPage> {
  List<String> groupUserMemberId = [];
  // List<UserModel> groupUserInfo = [];
  List<UserModel> memberList = [];
  // ChatRoomModel? chatRoomDataList;
  File? imageFile;
  var isLoading = true;
  var _isLoading = false;
  String? imageUrl;
  ChatRoomModel? chatRoomAllData;
  String? loginUserId;
  TextEditingController messageController = TextEditingController();

  @override
  void initState() {
    getAllData();
    super.initState();
  }

  Future<void> getAllData() async {
    // await getChatroomData();
    await currentUserId();
    await getGroupMember();
    await getUserData();
    setState(() {
      isLoading = false;
    });
  }
  // Future<List<String>> getAllToken() async {
  // QuerySnapshot querySnapshot =
  //     await FirebaseFirestore.instance.collection('users').get();

  // List<String> dataList = await querySnapshot.docs
  //     .map((doc) => doc.get('token').toString())
  //     .toList();

  // final prefs = await SharedPreferences.getInstance();
  // var currentUserToken = prefs.getString('userToken');

  // print('---------------------Total List-----------------');
  // print(dataList);
  // dataList.removeWhere((element) => element == currentUserToken);
  // print('...............Remove List ........................');
  // print(dataList);
  //   return dataList;
  // }

  Future<void> currentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    loginUserId = prefs.getString('userId').toString();
    print("_______________loginUserId_____________");
    print(loginUserId);
    print("______________loginUserId______________");
  }

  Future<void> getGroupMember() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('Chatrooms')
        .where("chatroomid", isEqualTo: widget.chatRoommodel.chatroomid)
        .get();
    print("---------------widget.chatRoomID---------------");

    print(widget.chatRoommodel.chatroomid);
    Map<String, dynamic>? singleChatRoomData =
        querySnapshot.docs[0].data() as Map<String, dynamic>?;
    List<String> dataList =
        (singleChatRoomData?["participants"] as Map<String, dynamic>?)
                ?.keys
                .toList() ??
            [];
    // List<String, dynamic>?
    print("---------------dataList---------------");
    print(dataList);
    groupUserMemberId.addAll(dataList);
    print("----------------groupUserMemberId---------------");
    print(groupUserMemberId);
  }

  getUserData() async {
    for (var sid in groupUserMemberId) {
      await dosome(sid);
    }
  }

  dosome(id) async {
    QuerySnapshot<Map<String, dynamic>> userJso = await FirebaseFirestore
        .instance
        .collection("user")
        .where("uid", isEqualTo: id)
        .get();

    UserModel userData = UserModel.fromMap(userJso.docs[0].data());
    memberList.add(userData);
  }

  // Future<void> getChatroomData() async {
  //   QuerySnapshot<Map<String, dynamic>> chatRoomData = await FirebaseFirestore
  //       .instance
  //       .collection("Chatrooms")
  //       .where("chatroomid", isEqualTo: widget.chatRoommodel.chatroomid)
  //       .get();

  //   chatRoomAllData = ChatRoomModel.fromMap(chatRoomData.docs[0].data());

  //   print(
  //       "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
  //   print(chatRoomAllData!.groupName);
  //   print(chatRoomAllData!.groupPic);
  //   setState(() {});
  // }

  // send messages
  void sendMessage({String? mediaFilePath}) async {
    String msg = messageController.text.trim();
    messageController.clear();

    MessageModel newMessage = MessageModel(
      messageId: uuid.v1(),
      sender: loginUserId,
      createdon: DateTime.now(),
      text: msg,
      seen: false,
      type: "text",
      mediaFilePath: mediaFilePath,
    );

    // var targetUserId = widget.targetUser.uid.toString();
    // print(targetUserId);
    FirebaseFirestore.instance
        .collection("Chatrooms")
        .doc(widget.chatRoommodel.chatroomid)
        .collection("messages")
        .doc(newMessage.messageId)
        .set(newMessage.toMap());

    widget.chatRoommodel.lastMessage = msg;
    FirebaseFirestore.instance
        .collection("Chatrooms")
        .doc(widget.chatRoommodel.chatroomid)
        .set(widget.chatRoommodel.toMap());

    // DocumentSnapshot<Map<String, dynamic>> data = await FirebaseFirestore
    //     .instance
    //     .collection('user')
    //     .doc(targetUserId)
    //     .get();

    setState(() {
      imageFile = null;
    });
  }

//file picker
  Future getFile() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: false);

    setState(
      () {
        if (result != null) {
          imageFile = File(result.files.single.path!);
        } else {
          // User canceled the picker
        }
      },
    );
  }

  Future uploadImage() async {
    setState(() {
      _isLoading = true;
    });
    String filename = Uuid().v1();
    var ref = FirebaseStorage.instance
        .ref()
        .child('images')
        .child('$filename.${imageFile!.path.split(".").last}');
    TaskSnapshot uploadTask = await ref.putFile(imageFile!);
    imageUrl = await uploadTask.ref.getDownloadURL();
    // log(imageUrl!);
    sendMessage(mediaFilePath: imageUrl);
    setState(() {
      _isLoading = false;
    });
  }

  Future<String> createFolder() async {
    const folderName = "Wp_Chat";
    var expath = await ExternalPath.getExternalStoragePublicDirectory(
        ExternalPath.DIRECTORY_DOWNLOADS);
    final path = Directory("$expath/$folderName");
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
    if ((await path.exists())) {
      return path.path;
    } else {
      path.create();
      return path.path;
    }
  }

  Future<File?> downLoadFile(String url, String name) async {
    UIHelper.showLoadingDialog(context, "File Downloading...");

    final file = File("${await createFolder()}/$name");
    try {
      final response = await Dio().get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          receiveTimeout: 0,
        ),
      );
      file.writeAsBytes(response.data);
      Navigator.pop(context, (route) => route.isFirst);

      return file;
    } catch (e) {
      return null;
    }
  }

  Future openFile({required String url, required String? fileName}) async {
    final file = File("${await createFolder()}/$fileName");

    OpenFile.open(file.path);

    log("Path: ${file.path}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: widget.chatRoommodel != null
            ? Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.teal.shade300,
                    backgroundImage:
                        NetworkImage(widget.chatRoommodel.groupPic ?? ""),
                  ),
                  const SizedBox(width: 10),
                  Text(widget.chatRoommodel.groupName ?? ""),
                ],
              )
            : const SizedBox(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                child: !isLoading
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        child: StreamBuilder(
                          stream: FirebaseFirestore.instance
                              .collection("Chatrooms")
                              .doc(widget.chatRoommodel.chatroomid)
                              .collection("messages")
                              .orderBy("createdon")
                              .snapshots(),
                          builder: (context, snapshot) {
                            // snapshot.data
                            // var obj = memberList.firstWhere((e) => e.uid = mes)
                            if (snapshot.connectionState ==
                                ConnectionState.active) {
                              if (snapshot.hasData) {
                                QuerySnapshot dataSnapshot =
                                    snapshot.data as QuerySnapshot;
                                return ListView.builder(
                                  itemCount: dataSnapshot.docs.length,
                                  itemBuilder: (context, index) {
                                    MessageModel currentMessage =
                                        MessageModel.forMap(
                                            dataSnapshot.docs[index].data()
                                                as Map<String, dynamic>);
                                    var obj = memberList.firstWhere(
                                        (e) => e.uid == currentMessage.sender,
                                        orElse: () {
                                      return UserModel(fullname: "test");
                                    });

                                    log(memberList.length.toString());

                                    final time = DateFormat("hh:mm a")
                                        .format(currentMessage.createdon!)
                                        .toLowerCase();
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisAlignment:
                                          (currentMessage.sender == loginUserId)
                                              ? MainAxisAlignment.end
                                              : MainAxisAlignment.start,
                                      children: [
                                        currentMessage.sender != loginUserId &&
                                                obj.profilepic != null &&
                                                obj.profilepic != ""
                                            ? Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 10),
                                                child: CircleAvatar(
                                                  backgroundImage: NetworkImage(
                                                      obj.profilepic.toString()
                                                      // memberList[index]
                                                      //     .profilepic
                                                      //     .toString(),
                                                      ),
                                                  radius: 14,
                                                ),
                                              )
                                            : const SizedBox(),
                                        const SizedBox(width: 5),
                                        Container(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 4),
                                          decoration: BoxDecoration(
                                            color: (currentMessage.sender ==
                                                    loginUserId)
                                                ? Colors.teal.shade100
                                                : Colors.teal.shade200,
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          child: Container(
                                            constraints: BoxConstraints(
                                              maxWidth: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.6,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  (currentMessage.sender ==
                                                          loginUserId)
                                                      ? CrossAxisAlignment.end
                                                      : CrossAxisAlignment
                                                          .start,
                                              children: [
                                                if (currentMessage
                                                            .mediaFilePath !=
                                                        null &&
                                                    currentMessage
                                                        .mediaFilePath!
                                                        .isNotEmpty &&
                                                    (currentMessage
                                                                .mediaFilePath!
                                                                .split("?")
                                                                .first
                                                                .split(".")
                                                                .last
                                                                .toUpperCase() ==
                                                            "MP3" ||
                                                        currentMessage
                                                                .mediaFilePath!
                                                                .split("?")
                                                                .first
                                                                .split(".")
                                                                .last
                                                                .toUpperCase() ==
                                                            "MP4"))
                                                  InkWell(
                                                    onTap: () {
                                                      createFolder()
                                                          .then((value) {
                                                        openFile(
                                                            url: currentMessage
                                                                .mediaFilePath!,
                                                            fileName: currentMessage
                                                                .mediaFilePath!
                                                                .split("?")
                                                                .first
                                                                .split("%")
                                                                .last
                                                                .toUpperCase());
                                                      });
                                                    },
                                                    child: Container(
                                                      width: 280,
                                                      height: 60,
                                                      decoration: BoxDecoration(
                                                        color: Colors
                                                            .teal.shade300,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(7),
                                                      ),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          Container(
                                                            height: 50,
                                                            width: 50,
                                                            child: Image.asset(
                                                                "assets/mp3.png"),
                                                          ),
                                                          Expanded(
                                                            child: Center(
                                                              child: Text(
                                                                currentMessage
                                                                    .mediaFilePath!
                                                                    .split("?")
                                                                    .first
                                                                    .split("%")
                                                                    .last
                                                                    .toUpperCase(),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                          ),
                                                          const Spacer(),
                                                          IconButton(
                                                            onPressed: () {
                                                              downLoadFile(
                                                                currentMessage
                                                                    .mediaFilePath!,
                                                                currentMessage
                                                                    .mediaFilePath!
                                                                    .split("?")
                                                                    .first
                                                                    .split("%")
                                                                    .last
                                                                    .toUpperCase(),
                                                              );
                                                            },
                                                            icon: const Icon(
                                                              Icons
                                                                  .download_for_offline_outlined,
                                                              size: 35,
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 10),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                if (currentMessage
                                                            .mediaFilePath !=
                                                        null &&
                                                    currentMessage
                                                        .mediaFilePath!
                                                        .isNotEmpty &&
                                                    currentMessage
                                                            .mediaFilePath!
                                                            .split("?")
                                                            .first
                                                            .split(".")
                                                            .last
                                                            .toUpperCase() ==
                                                        "PDF")
                                                  InkWell(
                                                    onTap: () {
                                                      createFolder()
                                                          .then((value) {
                                                        openFile(
                                                            url: currentMessage
                                                                .mediaFilePath!,
                                                            fileName: currentMessage
                                                                .mediaFilePath!
                                                                .split("?")
                                                                .first
                                                                .split("%")
                                                                .last
                                                                .toUpperCase());
                                                      });
                                                    },
                                                    child: Container(
                                                      width: 280,
                                                      height: 60,
                                                      decoration: BoxDecoration(
                                                          color: Colors
                                                              .teal.shade300,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(7)),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          Container(
                                                            height: 50,
                                                            width: 50,
                                                            child: Image.asset(
                                                                "assets/PDF.png"),
                                                          ),
                                                          Expanded(
                                                            child: Center(
                                                              child: Text(
                                                                currentMessage
                                                                    .mediaFilePath!
                                                                    .split("?")
                                                                    .first
                                                                    .split("%")
                                                                    .last
                                                                    .toUpperCase(),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                          ),
                                                          const Spacer(),
                                                          IconButton(
                                                            onPressed: () {
                                                              downLoadFile(
                                                                currentMessage
                                                                    .mediaFilePath!,
                                                                currentMessage
                                                                    .mediaFilePath!
                                                                    .split("?")
                                                                    .first
                                                                    .split("%")
                                                                    .last
                                                                    .toUpperCase(),
                                                              );
                                                            },
                                                            icon: const Icon(
                                                              Icons
                                                                  .download_for_offline_outlined,
                                                              size: 35,
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 10),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                if (currentMessage
                                                            .mediaFilePath !=
                                                        null &&
                                                    currentMessage
                                                        .mediaFilePath!
                                                        .isNotEmpty &&
                                                    (currentMessage
                                                                .mediaFilePath!
                                                                .split("?")
                                                                .first
                                                                .split(".")
                                                                .last
                                                                .toUpperCase() ==
                                                            "PPT" ||
                                                        currentMessage
                                                                .mediaFilePath!
                                                                .split("?")
                                                                .first
                                                                .split(".")
                                                                .last
                                                                .toUpperCase() ==
                                                            "PPTX"))
                                                  InkWell(
                                                    onTap: () {
                                                      createFolder()
                                                          .then((value) {
                                                        openFile(
                                                            url: currentMessage
                                                                .mediaFilePath!,
                                                            fileName: currentMessage
                                                                .mediaFilePath!
                                                                .split("?")
                                                                .first
                                                                .split("%")
                                                                .last
                                                                .toUpperCase());
                                                      });
                                                    },
                                                    child: Container(
                                                      width: 280,
                                                      height: 60,
                                                      decoration: BoxDecoration(
                                                          color: Colors
                                                              .teal.shade300,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(7)),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          Container(
                                                            height: 50,
                                                            width: 50,
                                                            child: Image.asset(
                                                                "assets/ppt.png"),
                                                          ),
                                                          Expanded(
                                                            child: Center(
                                                              child: Text(
                                                                currentMessage
                                                                    .mediaFilePath!
                                                                    .split("?")
                                                                    .first
                                                                    .split("%")
                                                                    .last
                                                                    .toUpperCase(),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                          ),
                                                          const Spacer(),
                                                          IconButton(
                                                            onPressed: () {
                                                              downLoadFile(
                                                                currentMessage
                                                                    .mediaFilePath!,
                                                                currentMessage
                                                                    .mediaFilePath!
                                                                    .split("?")
                                                                    .first
                                                                    .split("%")
                                                                    .last
                                                                    .toUpperCase(),
                                                              );
                                                            },
                                                            icon: const Icon(
                                                              Icons
                                                                  .download_for_offline_outlined,
                                                              size: 35,
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 10),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                if (currentMessage
                                                            .mediaFilePath !=
                                                        null &&
                                                    currentMessage
                                                        .mediaFilePath!
                                                        .isNotEmpty &&
                                                    currentMessage
                                                            .mediaFilePath!
                                                            .split("?")
                                                            .first
                                                            .split(".")
                                                            .last
                                                            .toUpperCase() ==
                                                        "DOCX")
                                                  InkWell(
                                                    onTap: () {
                                                      createFolder()
                                                          .then((value) {
                                                        openFile(
                                                            url: currentMessage
                                                                .mediaFilePath!,
                                                            fileName: currentMessage
                                                                .mediaFilePath!
                                                                .split("?")
                                                                .first
                                                                .split("%")
                                                                .last
                                                                .toUpperCase());
                                                      });
                                                    },
                                                    child: Container(
                                                      width: 280,
                                                      height: 60,
                                                      decoration: BoxDecoration(
                                                          color: Colors
                                                              .teal.shade300,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(7)),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          Container(
                                                            height: 50,
                                                            width: 50,
                                                            child: Image.asset(
                                                                "assets/doc.png"),
                                                          ),
                                                          Expanded(
                                                            child: Center(
                                                              child: Text(
                                                                currentMessage
                                                                    .mediaFilePath!
                                                                    .split("?")
                                                                    .first
                                                                    .split("%")
                                                                    .last
                                                                    .toUpperCase(),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                          ),
                                                          const Spacer(),
                                                          IconButton(
                                                            onPressed: () {
                                                              downLoadFile(
                                                                currentMessage
                                                                    .mediaFilePath!,
                                                                currentMessage
                                                                    .mediaFilePath!
                                                                    .split("?")
                                                                    .first
                                                                    .split("%")
                                                                    .last
                                                                    .toUpperCase(),
                                                              );
                                                            },
                                                            icon: const Icon(
                                                              Icons
                                                                  .download_for_offline_outlined,
                                                              size: 35,
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 10),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                if (currentMessage
                                                            .mediaFilePath !=
                                                        null &&
                                                    currentMessage
                                                        .mediaFilePath!
                                                        .isNotEmpty &&
                                                    currentMessage
                                                            .mediaFilePath!
                                                            .split("?")
                                                            .first
                                                            .split(".")
                                                            .last
                                                            .toUpperCase() ==
                                                        "ZIP")
                                                  InkWell(
                                                    onTap: () {
                                                      createFolder()
                                                          .then((value) {
                                                        openFile(
                                                            url: currentMessage
                                                                .mediaFilePath!,
                                                            fileName: currentMessage
                                                                .mediaFilePath!
                                                                .split("?")
                                                                .first
                                                                .split("%")
                                                                .last
                                                                .toUpperCase());
                                                      });
                                                    },
                                                    child: Container(
                                                      width: 280,
                                                      height: 60,
                                                      decoration: BoxDecoration(
                                                          color: Colors
                                                              .teal.shade300,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(7)),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          SizedBox(
                                                            height: 50,
                                                            width: 50,
                                                            child: Image.asset(
                                                                "assets/zip.png"),
                                                          ),
                                                          Expanded(
                                                            child: Center(
                                                              child: Text(
                                                                currentMessage
                                                                    .mediaFilePath!
                                                                    .split("?")
                                                                    .first
                                                                    .split("%")
                                                                    .last
                                                                    .toUpperCase(),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                          ),
                                                          const Spacer(),
                                                          IconButton(
                                                            onPressed: () {
                                                              downLoadFile(
                                                                currentMessage
                                                                    .mediaFilePath!,
                                                                currentMessage
                                                                    .mediaFilePath!
                                                                    .split("?")
                                                                    .first
                                                                    .split("%")
                                                                    .last
                                                                    .toUpperCase(),
                                                              );
                                                            },
                                                            icon: const Icon(
                                                              Icons
                                                                  .download_for_offline_outlined,
                                                              size: 35,
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 10),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                if (currentMessage
                                                            .mediaFilePath !=
                                                        null &&
                                                    currentMessage
                                                        .mediaFilePath!
                                                        .isNotEmpty &&
                                                    (currentMessage
                                                                .mediaFilePath!
                                                                .split("?")
                                                                .first
                                                                .split(".")
                                                                .last
                                                                .toUpperCase() ==
                                                            "XLSX" ||
                                                        currentMessage
                                                                .mediaFilePath!
                                                                .split("?")
                                                                .first
                                                                .split(".")
                                                                .last
                                                                .toUpperCase() ==
                                                            "XLSM" ||
                                                        currentMessage
                                                                .mediaFilePath!
                                                                .split("?")
                                                                .first
                                                                .split(".")
                                                                .last
                                                                .toUpperCase() ==
                                                            "XLSB" ||
                                                        currentMessage
                                                                .mediaFilePath!
                                                                .split("?")
                                                                .first
                                                                .split(".")
                                                                .last
                                                                .toUpperCase() ==
                                                            "XLTX"))
                                                  InkWell(
                                                    onTap: () {
                                                      createFolder()
                                                          .then((value) {
                                                        openFile(
                                                            url: currentMessage
                                                                .mediaFilePath!,
                                                            fileName: currentMessage
                                                                .mediaFilePath!
                                                                .split("?")
                                                                .first
                                                                .split("%")
                                                                .last
                                                                .toUpperCase());
                                                      });
                                                    },
                                                    child: Container(
                                                      width: 280,
                                                      height: 60,
                                                      decoration: BoxDecoration(
                                                          color: Colors
                                                              .teal.shade300,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(7)),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          SizedBox(
                                                            height: 60,
                                                            width: 60,
                                                            child: Image.asset(
                                                                "assets/excel.png"),
                                                          ),
                                                          Expanded(
                                                            child: Center(
                                                              child: Text(
                                                                currentMessage
                                                                    .mediaFilePath!
                                                                    .split("?")
                                                                    .first
                                                                    .split("%")
                                                                    .last
                                                                    .toUpperCase(),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                          ),
                                                          const Spacer(),
                                                          IconButton(
                                                            onPressed: () {
                                                              downLoadFile(
                                                                currentMessage
                                                                    .mediaFilePath!,
                                                                currentMessage
                                                                    .mediaFilePath!
                                                                    .split("?")
                                                                    .first
                                                                    .split("%")
                                                                    .last
                                                                    .toUpperCase(),
                                                              );
                                                            },
                                                            icon: const Icon(
                                                              Icons
                                                                  .download_for_offline_outlined,
                                                              size: 35,
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 10),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                if (currentMessage
                                                            .mediaFilePath !=
                                                        null &&
                                                    currentMessage
                                                        .mediaFilePath!
                                                        .isNotEmpty &&
                                                    (currentMessage
                                                                .mediaFilePath!
                                                                .split("?")
                                                                .first
                                                                .split(".")
                                                                .last
                                                                .toUpperCase() ==
                                                            "JPEG" ||
                                                        currentMessage
                                                                .mediaFilePath!
                                                                .split("?")
                                                                .first
                                                                .split(".")
                                                                .last
                                                                .toUpperCase() ==
                                                            "JPG" ||
                                                        currentMessage
                                                                .mediaFilePath!
                                                                .split("?")
                                                                .first
                                                                .split(".")
                                                                .last
                                                                .toUpperCase() ==
                                                            "PNG"))
                                                  InkWell(
                                                    onTap: () {
                                                      createFolder()
                                                          .then((value) {
                                                        openFile(
                                                            url: currentMessage
                                                                .mediaFilePath!,
                                                            fileName: currentMessage
                                                                .mediaFilePath!
                                                                .split("?")
                                                                .first
                                                                .split("%")
                                                                .last
                                                                .toUpperCase());
                                                      });
                                                    },
                                                    child: Stack(
                                                      children: [
                                                        ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(7),
                                                          child: SizedBox(
                                                            width: 150,
                                                            height: 200,
                                                            child:
                                                                Image.network(
                                                              currentMessage
                                                                  .mediaFilePath!,
                                                              fit: BoxFit.cover,
                                                            ),
                                                          ),
                                                        ),
                                                        Positioned(
                                                          bottom: 5,
                                                          right: 5,
                                                          child: IconButton(
                                                              onPressed: () {
                                                                downLoadFile(
                                                                    currentMessage
                                                                        .mediaFilePath!,
                                                                    currentMessage
                                                                        .mediaFilePath!
                                                                        .split(
                                                                            "?")
                                                                        .first
                                                                        .split(
                                                                            "%")
                                                                        .last
                                                                        .toUpperCase());
                                                              },
                                                              icon: const Icon(
                                                                Icons
                                                                    .download_for_offline_outlined,
                                                                size: 35,
                                                              )),
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                if (currentMessage.mediaFilePath != null &&
                                                    currentMessage
                                                        .mediaFilePath!
                                                        .isNotEmpty &&
                                                    currentMessage.mediaFilePath!.split("?").first.split(".").last.toUpperCase() !=
                                                        "JPEG" &&
                                                    currentMessage.mediaFilePath!
                                                            .split("?")
                                                            .first
                                                            .split(".")
                                                            .last
                                                            .toUpperCase() !=
                                                        "JPG" &&
                                                    currentMessage.mediaFilePath!
                                                            .split("?")
                                                            .first
                                                            .split(".")
                                                            .last
                                                            .toUpperCase() !=
                                                        "PNG" &&
                                                    currentMessage.mediaFilePath!
                                                            .split("?")
                                                            .first
                                                            .split(".")
                                                            .last
                                                            .toUpperCase() !=
                                                        "XLSX" &&
                                                    currentMessage.mediaFilePath!
                                                            .split("?")
                                                            .first
                                                            .split(".")
                                                            .last
                                                            .toUpperCase() !=
                                                        "XLSM" &&
                                                    currentMessage.mediaFilePath!
                                                            .split("?")
                                                            .first
                                                            .split(".")
                                                            .last
                                                            .toUpperCase() !=
                                                        "XLSB" &&
                                                    currentMessage.mediaFilePath!
                                                            .split("?")
                                                            .first
                                                            .split(".")
                                                            .last
                                                            .toUpperCase() !=
                                                        "XLTX" &&
                                                    currentMessage.mediaFilePath!
                                                            .split("?")
                                                            .first
                                                            .split(".")
                                                            .last
                                                            .toUpperCase() !=
                                                        "ZIP" &&
                                                    currentMessage.mediaFilePath!
                                                            .split("?")
                                                            .first
                                                            .split(".")
                                                            .last
                                                            .toUpperCase() !=
                                                        "PDF" &&
                                                    currentMessage.mediaFilePath!
                                                            .split("?")
                                                            .first
                                                            .split(".")
                                                            .last
                                                            .toUpperCase() !=
                                                        "PPT" &&
                                                    currentMessage.mediaFilePath!
                                                            .split("?")
                                                            .first
                                                            .split(".")
                                                            .last
                                                            .toUpperCase() !=
                                                        "PPTX" &&
                                                    currentMessage.mediaFilePath!.split("?").first.split(".").last.toUpperCase() != "MP3" &&
                                                    currentMessage.mediaFilePath!.split("?").first.split(".").last.toUpperCase() != "MP4" &&
                                                    currentMessage.mediaFilePath!.split("?").first.split(".").last.toUpperCase() != "DOCX")
                                                  InkWell(
                                                    onTap: () {
                                                      createFolder()
                                                          .then((value) {
                                                        openFile(
                                                            url: currentMessage
                                                                .mediaFilePath!,
                                                            fileName: currentMessage
                                                                .mediaFilePath!
                                                                .split("?")
                                                                .first
                                                                .split("%")
                                                                .last
                                                                .toUpperCase());
                                                      });
                                                    },
                                                    child: Container(
                                                      width: 280,
                                                      height: 60,
                                                      decoration: BoxDecoration(
                                                          color: Colors
                                                              .teal.shade300,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(7)),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          Container(
                                                            height: 50,
                                                            width: 50,
                                                            child: Image.asset(
                                                                "assets/file.png"),
                                                          ),
                                                          Expanded(
                                                            child: Center(
                                                              child: Text(
                                                                currentMessage
                                                                    .mediaFilePath!
                                                                    .split("?")
                                                                    .first
                                                                    .split("%")
                                                                    .last
                                                                    .toUpperCase(),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                          ),
                                                          const Spacer(),
                                                          IconButton(
                                                            onPressed: () {
                                                              downLoadFile(
                                                                currentMessage
                                                                    .mediaFilePath!,
                                                                currentMessage
                                                                    .mediaFilePath!
                                                                    .split("?")
                                                                    .first
                                                                    .split("%")
                                                                    .last
                                                                    .toUpperCase(),
                                                              );
                                                            },
                                                            icon: const Icon(
                                                              Icons
                                                                  .download_for_offline_outlined,
                                                              size: 35,
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 10),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                if (currentMessage.text !=
                                                        null &&
                                                    currentMessage
                                                        .text!.isNotEmpty)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Text(
                                                      currentMessage.text
                                                          .toString(),
                                                      style: const TextStyle(
                                                          fontSize: 16),
                                                    ),
                                                  ),
                                                Text(
                                                  time.toString(),
                                                  style:
                                                      TextStyle(fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              } else if (snapshot.hasError) {
                                return const Center(
                                  child: Text(
                                      "An error occured! Please check your internet connection."),
                                );
                              } else {
                                return const Center(
                                  child: Text("Say hi to your new friend"),
                                );
                              }
                            } else {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                          },
                        ),
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
            ),
            if (imageFile != null)
              Container(
                color: Colors.grey.shade200,
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 5,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(imageFile!.path.split("/").last),
                    ),
                    _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : IconButton(
                            onPressed: () {
                              setState(() {
                                imageFile = null;
                              });
                            },
                            icon: const Icon(Icons.close),
                            color: Colors.grey,
                          )
                  ],
                ),
              ),
            Container(
              color: Colors.grey.shade200,
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 5,
              ),
              child: Row(
                children: [
                  Flexible(
                    child: TextFormField(
                      controller: messageController,
                      maxLines: null,
                      decoration: InputDecoration(
                          suffixIcon: IconButton(
                              icon: const Icon(Icons.attach_file,
                                  color: Colors.teal),
                              onPressed: () => getFile()),
                          border: InputBorder.none,
                          hintText: "Enter message"),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (imageFile == null && messageController.text.isEmpty) {
                        //error msg
                      } else if (imageFile != null) {
                        uploadImage();
                      } else {
                        sendMessage();
                      }
                    },
                    icon: const Icon(Icons.send),
                    color: Colors.teal,
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
