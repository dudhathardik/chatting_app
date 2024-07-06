import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class DownlodingDialog extends StatefulWidget {
  const DownlodingDialog({Key? key}) : super(key: key);

  @override
  State<DownlodingDialog> createState() => _DownlodingDialogState();
}

class _DownlodingDialogState extends State<DownlodingDialog> {
  Dio dio = Dio();
  double progress = 0.0;
  File? imageFile;

  @override
  void initState() {
    // TODO: implement initState
    stratDownloding();
    // print(object)
    super.initState();
  }

  void stratDownloding() async {
    String filename = Uuid().v1();
    var ref = FirebaseStorage.instance
        .ref()
        .child('images')
        .child('$filename.${imageFile!.path.split(".").last}');
    TaskSnapshot uploadTask = await ref.putFile(imageFile!);
    String imageUrl = await uploadTask.ref.getDownloadURL();
    log("this my download url");
    log(imageUrl);
    // String url
  }

  @override
  Widget build(BuildContext context) {
    return Center();
  }
}
