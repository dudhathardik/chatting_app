import 'dart:developer';
import 'dart:io';

import 'package:wp_chat/models/chat_room.dart';

import '../models/ui_helper.dart';
import '../models/users_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import 'home_screen.dart';

class GroupName extends StatefulWidget {
  final ChatRoomModel? chatroom;
  GroupName(this.chatroom);

  @override
  State<GroupName> createState() => _GroupNameState();
}

class _GroupNameState extends State<GroupName> {
  File? imageFile;
  TextEditingController fullNameController = TextEditingController();

  void selectImage(ImageSource source) async {
    XFile? pickedFile = await ImagePicker().pickImage(source: source);

    if (pickedFile != null) {
      File? pickFile = File(pickedFile.path);
      cropImage(pickFile);
    }
  }

  void cropImage(File file) async {
    CroppedFile? croppedImage = await ImageCropper().cropImage(
      sourcePath: file.path,
      compressQuality: 20,
      aspectRatioPresets: Platform.isAndroid
          ? [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9
            ]
          : [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio5x3,
              CropAspectRatioPreset.ratio5x4,
              CropAspectRatioPreset.ratio7x5,
              CropAspectRatioPreset.ratio16x9
            ],
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.white,
            toolbarWidgetColor: Colors.deepPurple,
            initAspectRatio: CropAspectRatioPreset.ratio3x2,
            lockAspectRatio: false),
        IOSUiSettings(
          title: 'Crop Image',
        ),
      ],
    );
    if (croppedImage != null) {
      setState(() {
        imageFile = File(croppedImage.path);
      });
    }
  }

  void showPhotoOptione() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Upload Profile Picture"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  onTap: () {
                    Navigator.pop(context);
                    selectImage(ImageSource.gallery);
                  },
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Select from Gallery'),
                ),
                ListTile(
                  onTap: () {
                    Navigator.pop(context);

                    selectImage(ImageSource.camera);
                  },
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Tack a photo'),
                ),
              ],
            ),
          );
        });
  }

  void checkValue() {
    String fullname = fullNameController.text.trim();

    if (fullname == "" || imageFile == null) {
      log("Please fill all the fields");
      print("Please fill all the fields");
      UIHelper.showAlertDialog(context, 'Incomplete data',
          "Please fill all the fileds and a upload a profile pictures");
    } else {
      uploadData();
    }
  }

  void uploadData() async {
    UIHelper.showLoadingDialog(context, "Uploading Image...");
    UploadTask uploadTask = FirebaseStorage.instance
        .ref("profilepitures")
        .child(widget.chatroom!.chatroomid.toString())
        .putFile(imageFile!);

    TaskSnapshot snapshot = await uploadTask;
    String imageUrl = await snapshot.ref.getDownloadURL();
    String fullname = fullNameController.text.trim();

    widget.chatroom!.groupName = fullname;
    widget.chatroom!.groupPic = imageUrl;

    await FirebaseFirestore.instance
        .collection("Chatrooms")
        .doc(widget.chatroom!.chatroomid)
        .set(widget.chatroom!.toMap())
        .then(
      (value) {
        log("DataUploaded !");
        Navigator.popUntil(context, (route) => route.isFirst);
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (context) {
        //     return Homepage(
        //       // chatRoomModel: widget.chatroom,
        //       userModel: widget.chatroom,
        //       firebaseUser: widget.firebaseUser,
        //     );
        //   }),
        // );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.teal,
        title: const Text(
          'Complete Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
          child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: ListView(
          children: [
            CupertinoButton(
              child: CircleAvatar(
                backgroundColor: Colors.teal.shade100,
                backgroundImage:
                    imageFile != null ? FileImage(imageFile!) : null,
                radius: 60,
                child: imageFile == null
                    ? const Icon(
                        Icons.person,
                        color: Colors.teal,
                        size: 60,
                      )
                    : null,
              ),
              onPressed: () {
                showPhotoOptione();
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: fullNameController,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Colors.teal,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.teal, width: 1),
                ),
                fillColor: Colors.white,
                filled: true,
                hintText: 'Full Name',
              ),
            ),
            const SizedBox(height: 20),
            CupertinoButton(
              onPressed: () {
                checkValue();
              },
              color: Colors.teal,
              child: const Text(
                "Submit",
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      )),
    );
  }
}
