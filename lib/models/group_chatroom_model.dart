// import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class GroupUserModel {
  List<String>? uid;
  List<String>? fullname;
  List<String>? profilepic;
  List<String>? fcm_token;
  List<String>? number;

  GroupUserModel({
    this.number,
    this.uid,
    this.fullname,
    this.profilepic,
    this.fcm_token,
  });

  GroupUserModel.fromMap(Map<String, dynamic> map) {
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
