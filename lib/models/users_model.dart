// import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class UserModel {
  String? uid;
  String? fullname;
  String? profilepic;
  String? fcm_token;
  String? number;
  bool isSelect = false;

  UserModel({
    this.number,
    this.uid,
    this.fullname,
    this.profilepic,
    this.fcm_token,
  });

  UserModel.fromMap(Map<String, dynamic> map) {
    uid = map["uid"];
    fullname = map["fullname"];
    profilepic = map["profilepic"];
    fcm_token = map["fcm_token"];
    number = map["number"];
  }

  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "fullname": fullname,
      "profilepic": profilepic,
      "fcm_token": fcm_token,
      "number": number,
    };
  }
}
