import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:external_path/external_path.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

import '../main.dart';
import '../models/message_model.dart';
import '../models/ui_helper.dart';
import '/models/chat_room.dart';
import '../models/users_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';

class ChatRoomPage extends StatefulWidget {
  final UserModel targetUser;
  final ChatRoomModel chatRoom;
  final UserModel userModel;
  final User firebaseUser;

  const ChatRoomPage(
      {Key? key,
      required this.userModel,
      required this.firebaseUser,
      required this.targetUser,
      required this.chatRoom})
      : super(key: key);

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  String? imageUrl;
  File? imageFile;
  var isLoading = false;
  // MessageModel? currentMessage;
  TextEditingController messageController = TextEditingController();

  Future openFile({required String url, required String? fileName}) async {
    final file = File("${await createFolder()}/$fileName");
    // if () {
    print("-----------------file.path---------------");
    print(file.path);
    print("-----------------fiel.path---------------");
    OpenFile.open(file.path);
    // } else {
    // final file = await downLoadFile(url, fileName!);
    // OpenFile.open(file!.path);
    // }

    // if (file == null) return;
    log("Path: ${file.path}");
    // OpenFile.open(file.path);
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

  Future<String> createFolder() async {
    const folderName = "Wp_Chat";
    var expath = await ExternalPath.getExternalStoragePublicDirectory(
        ExternalPath.DIRECTORY_DOWNLOADS);
    final path = Directory("$expath/$folderName");
    print("-----------------path---------------");
    print(path);
    print("-----------------path---------------");
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

  void sendMessage({String? mediaFilePath}) async {
    String msg = messageController.text.trim();
    messageController.clear();

    MessageModel newMessage = MessageModel(
      messageId: uuid.v1(),
      sender: widget.userModel.uid,
      createdon: DateTime.now(),
      text: msg,
      seen: false,
      type: "text",
      mediaFilePath: mediaFilePath,
    );

    var targetUserId = widget.targetUser.uid.toString();
    print(targetUserId);
    FirebaseFirestore.instance
        .collection("Chatrooms")
        .doc(widget.chatRoom.chatroomid)
        .collection("messages")
        .doc(newMessage.messageId)
        .set(newMessage.toMap());

    widget.chatRoom.lastMessage = msg;
    FirebaseFirestore.instance
        .collection("Chatrooms")
        .doc(widget.chatRoom.chatroomid)
        .set(widget.chatRoom.toMap());

    DocumentSnapshot<Map<String, dynamic>> data = await FirebaseFirestore
        .instance
        .collection('user')
        .doc(targetUserId)
        .get();

    final targetObject = data.data();
    final notificationToken = targetObject!['fcm_token'];
    print("--------------------receiver token----------------------------");
    print(notificationToken);
    print("--------------------receiver token----------------------------");

    log(notificationToken);
    log("Message Sent!");

    Future<http.Response?> sendNotification(
        String username, String message) async {
      final data = {
        "to": notificationToken,
        "notification": {
          "body": message,
          "title": username,
          "android_channel_id": "pushnotificationapp",
          "sound": true
        }
      };

      final sendData = jsonEncode(data);

      try {
        http.Response response = await http.post(
          Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization':
                'key=AAAAaz3dTvQ:APA91bF6WFARg3mZywOP5VMfz2h3FeevgVlwnzd-y5kcMdPO84NcNYg2J5dy1Z_QXxmHRvoV-ypIQSJjoS9yA6Ki2ykQ1_BXD9-Tx2krS8zr0BWXfAOZNyBNCP1DsVTDpMbMrFSj1Ecv'
          },
          body: sendData,
        );

        if (response.statusCode == 200) {
          log('notification sent');
          print(response.body);
        } else {
          print('error occured');
        }
      } catch (error) {
        print(error);
      }
      return null;
    }

    String userTitleNotification = widget.userModel.fullname ?? "";
    // String notificationUrl = currentMessage!.mediaFilePath!
    //     .split("?")
    //     .first
    //     .split("%")
    //     .last
    //     .toUpperCase();
    // sendNotification(userTitleNotification, msg, notificationUrl);
    sendNotification(userTitleNotification, msg);

    setState(() {
      imageFile = null;
    });
  }

  Future getFile() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: false);

    setState(() {
      if (result != null) {
        imageFile = File(result.files.single.path!);
      } else {
        // User canceled the picker
      }
    });
  }

  Future uploadImage() async {
    setState(() {
      isLoading = true;
    });
    String filename = Uuid().v1();
    var ref = FirebaseStorage.instance
        .ref()
        .child('images')
        .child('$filename.${imageFile!.path.split(".").last}');
    TaskSnapshot uploadTask = await ref.putFile(imageFile!);
    imageUrl = await uploadTask.ref.getDownloadURL();
    log(imageUrl!);
    sendMessage(mediaFilePath: imageUrl);
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    var userFullName = widget.targetUser.fullname;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.teal.shade300,
              backgroundImage:
                  NetworkImage(widget.targetUser.profilepic.toString()),
            ),
            const SizedBox(width: 10),
            Text(userFullName.toString()),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection("Chatrooms")
                      .doc(widget.chatRoom.chatroomid)
                      .collection("messages")
                      .orderBy("createdon", descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.active) {
                      if (snapshot.hasData) {
                        QuerySnapshot dataSnapshot =
                            snapshot.data as QuerySnapshot;

                        return ListView.builder(
                          reverse: true,
                          itemCount: dataSnapshot.docs.length,
                          itemBuilder: (context, index) {
                            MessageModel currentMessage = MessageModel.forMap(
                                dataSnapshot.docs[index].data()
                                    as Map<String, dynamic>);
                            final time = DateFormat("hh:mm a")
                                .format(currentMessage.createdon!)
                                .toLowerCase();
                            return Row(
                              mainAxisAlignment: (currentMessage.sender ==
                                      widget.userModel.uid)
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              children: [
                                currentMessage.sender != widget.userModel.uid
                                    ? CircleAvatar(
                                        backgroundImage: NetworkImage(widget
                                            .targetUser.profilepic
                                            .toString()),
                                        radius: 14,
                                      )
                                    : const SizedBox(),
                                const SizedBox(width: 5),
                                Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  // padding: const EdgeInsets.symmetric(
                                  //   vertical: 8,
                                  //   horizontal: 12,
                                  // ),
                                  decoration: BoxDecoration(
                                    color: (currentMessage.sender ==
                                            widget.userModel.uid)
                                        ? Colors.teal.shade100
                                        : Colors.teal.shade200,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                              0.6,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          (currentMessage.sender ==
                                                  widget.userModel.uid)
                                              ? CrossAxisAlignment.end
                                              : CrossAxisAlignment.start,
                                      children: [
                                        if (currentMessage.mediaFilePath !=
                                                null &&
                                            currentMessage
                                                .mediaFilePath!.isNotEmpty &&
                                            (currentMessage.mediaFilePath!
                                                        .split("?")
                                                        .first
                                                        .split(".")
                                                        .last
                                                        .toUpperCase() ==
                                                    "MP3" ||
                                                currentMessage.mediaFilePath!
                                                        .split("?")
                                                        .first
                                                        .split(".")
                                                        .last
                                                        .toUpperCase() ==
                                                    "MP4"))
                                          InkWell(
                                            onTap: () {
                                              createFolder().then((value) {
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
                                                color: Colors.teal.shade300,
                                                borderRadius:
                                                    BorderRadius.circular(7),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
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
                                                        overflow: TextOverflow
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
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                ],
                                              ),
                                            ),
                                          ),
                                        if (currentMessage.mediaFilePath !=
                                                null &&
                                            currentMessage
                                                .mediaFilePath!.isNotEmpty &&
                                            currentMessage.mediaFilePath!
                                                    .split("?")
                                                    .first
                                                    .split(".")
                                                    .last
                                                    .toUpperCase() ==
                                                "PDF")
                                          InkWell(
                                            onTap: () {
                                              createFolder().then((value) {
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
                                                  color: Colors.teal.shade300,
                                                  borderRadius:
                                                      BorderRadius.circular(7)),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
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
                                                        overflow: TextOverflow
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
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                ],
                                              ),
                                            ),
                                          ),
                                        if (currentMessage.mediaFilePath !=
                                                null &&
                                            currentMessage
                                                .mediaFilePath!.isNotEmpty &&
                                            (currentMessage.mediaFilePath!
                                                        .split("?")
                                                        .first
                                                        .split(".")
                                                        .last
                                                        .toUpperCase() ==
                                                    "PPT" ||
                                                currentMessage.mediaFilePath!
                                                        .split("?")
                                                        .first
                                                        .split(".")
                                                        .last
                                                        .toUpperCase() ==
                                                    "PPTX"))
                                          InkWell(
                                            onTap: () {
                                              createFolder().then((value) {
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
                                                  color: Colors.teal.shade300,
                                                  borderRadius:
                                                      BorderRadius.circular(7)),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
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
                                                        overflow: TextOverflow
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
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                ],
                                              ),
                                            ),
                                          ),
                                        if (currentMessage.mediaFilePath !=
                                                null &&
                                            currentMessage
                                                .mediaFilePath!.isNotEmpty &&
                                            currentMessage.mediaFilePath!
                                                    .split("?")
                                                    .first
                                                    .split(".")
                                                    .last
                                                    .toUpperCase() ==
                                                "DOCX")
                                          InkWell(
                                            onTap: () {
                                              createFolder().then((value) {
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
                                                  color: Colors.teal.shade300,
                                                  borderRadius:
                                                      BorderRadius.circular(7)),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
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
                                                        overflow: TextOverflow
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
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                ],
                                              ),
                                            ),
                                          ),
                                        if (currentMessage.mediaFilePath !=
                                                null &&
                                            currentMessage
                                                .mediaFilePath!.isNotEmpty &&
                                            currentMessage.mediaFilePath!
                                                    .split("?")
                                                    .first
                                                    .split(".")
                                                    .last
                                                    .toUpperCase() ==
                                                "ZIP")
                                          InkWell(
                                            onTap: () {
                                              createFolder().then((value) {
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
                                                  color: Colors.teal.shade300,
                                                  borderRadius:
                                                      BorderRadius.circular(7)),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
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
                                                        overflow: TextOverflow
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
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                ],
                                              ),
                                            ),
                                          ),
                                        if (currentMessage.mediaFilePath !=
                                                null &&
                                            currentMessage
                                                .mediaFilePath!.isNotEmpty &&
                                            (currentMessage.mediaFilePath!
                                                        .split("?")
                                                        .first
                                                        .split(".")
                                                        .last
                                                        .toUpperCase() ==
                                                    "XLSX" ||
                                                currentMessage.mediaFilePath!
                                                        .split("?")
                                                        .first
                                                        .split(".")
                                                        .last
                                                        .toUpperCase() ==
                                                    "XLSM" ||
                                                currentMessage.mediaFilePath!
                                                        .split("?")
                                                        .first
                                                        .split(".")
                                                        .last
                                                        .toUpperCase() ==
                                                    "XLSB" ||
                                                currentMessage.mediaFilePath!
                                                        .split("?")
                                                        .first
                                                        .split(".")
                                                        .last
                                                        .toUpperCase() ==
                                                    "XLTX"))
                                          InkWell(
                                            onTap: () {
                                              createFolder().then((value) {
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
                                                  color: Colors.teal.shade300,
                                                  borderRadius:
                                                      BorderRadius.circular(7)),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
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
                                                        overflow: TextOverflow
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
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                ],
                                              ),
                                            ),
                                          ),
                                        if (currentMessage.mediaFilePath !=
                                                null &&
                                            currentMessage
                                                .mediaFilePath!.isNotEmpty &&
                                            (currentMessage.mediaFilePath!
                                                        .split("?")
                                                        .first
                                                        .split(".")
                                                        .last
                                                        .toUpperCase() ==
                                                    "JPEG" ||
                                                currentMessage.mediaFilePath!
                                                        .split("?")
                                                        .first
                                                        .split(".")
                                                        .last
                                                        .toUpperCase() ==
                                                    "JPG" ||
                                                currentMessage.mediaFilePath!
                                                        .split("?")
                                                        .first
                                                        .split(".")
                                                        .last
                                                        .toUpperCase() ==
                                                    "PNG"))
                                          InkWell(
                                            onTap: () {
                                              createFolder().then((value) {
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
                                                      BorderRadius.circular(7),
                                                  child: SizedBox(
                                                    width: 150,
                                                    height: 200,
                                                    child: Image.network(
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
                                                                .split("?")
                                                                .first
                                                                .split("%")
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
                                        if (currentMessage.mediaFilePath !=
                                                null &&
                                            currentMessage
                                                .mediaFilePath!.isNotEmpty &&
                                            currentMessage.mediaFilePath!
                                                    .split("?")
                                                    .first
                                                    .split(".")
                                                    .last
                                                    .toUpperCase() !=
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
                                            currentMessage.mediaFilePath!
                                                    .split("?")
                                                    .first
                                                    .split(".")
                                                    .last
                                                    .toUpperCase() !=
                                                "MP3" &&
                                            currentMessage.mediaFilePath!
                                                    .split("?")
                                                    .first
                                                    .split(".")
                                                    .last
                                                    .toUpperCase() !=
                                                "MP4" &&
                                            currentMessage.mediaFilePath!
                                                    .split("?")
                                                    .first
                                                    .split(".")
                                                    .last
                                                    .toUpperCase() !=
                                                "DOCX")
                                          InkWell(
                                            onTap: () {
                                              createFolder().then((value) {
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
                                                  color: Colors.teal.shade300,
                                                  borderRadius:
                                                      BorderRadius.circular(7)),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
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
                                                        overflow: TextOverflow
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
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                ],
                                              ),
                                            ),
                                          ),
                                        if (currentMessage.text != null &&
                                            currentMessage.text!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              currentMessage.text.toString(),
                                              style:
                                                  const TextStyle(fontSize: 16),
                                            ),
                                          ),
                                        Text(
                                          time.toString(),
                                          style: TextStyle(fontSize: 12),
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
                    isLoading
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
