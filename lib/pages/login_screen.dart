import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/users_model.dart';
import 'package:flutter/material.dart';

import '../pages/complete_page.dart';

enum MobileVerificationState {
  SHOW_MOBILE_FORM_STATE,
  SHOW_OTP_FORM_STATE,
}

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  MobileVerificationState currentState =
      MobileVerificationState.SHOW_MOBILE_FORM_STATE;

  final phoneController = TextEditingController(text: "+91");
  final otpController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? verificationId;

  bool showLoading = false;
  bool showLoadingOtp = false;

  void signInWithPhoneAuthCredetial(
      PhoneAuthCredential phoneAuthCredential) async {
    UserCredential? authCredetial;
    String number = phoneController.text.trim();
    String number1 = number.substring(3, 13);

    setState(() {
      showLoadingOtp = true;
    });

    try {
      final authCredetial =
          await _auth.signInWithCredential(phoneAuthCredential);

      if (authCredetial != null) {
        String uid = authCredetial.user!.uid;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', uid);
        final FirebaseMessaging _fcm = FirebaseMessaging.instance;
        final token = await _fcm.getToken();

        UserModel newUser = UserModel(
          uid: uid,
          fullname: "",
          profilepic: "",
          number: number1,
          fcm_token: token,
        );
        await FirebaseFirestore.instance
            .collection("user")
            .doc(uid)
            .set(newUser.toMap())
            .then((value) {
          print("New User Created!");
          setState(() {
            showLoadingOtp = false;
          });
          Navigator.popUntil(context, (route) => route.isFirst);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CompletePage(
                userModel: newUser,
                firebaseUser: authCredetial.user!,
              ),
            ),
          );
        });
      }
    } on FirebaseAuthException catch (e) {
      // setState(() {
      //   showLoading = false;
      // });
      _scaffoldkey.currentState?.showSnackBar(
        SnackBar(
          content: Text(e.message ?? ""),
        ),
      );
    }
  }

  getMoibleFormState(BuildContext context) {
    return Column(
      // crossAxis CrossAxisAlignment.start,
      // crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(30.0),
          child: Image.asset(
            'assets/eagel.png',
            fit: BoxFit.contain,
          ),
        ),
        const Text(
          "Enter your mobile number",
          style: TextStyle(fontSize: 17, color: Colors.black),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: TextField(
            decoration: const InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.teal, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.teal,
                  width: 1,
                ),
              ),
              fillColor: Colors.white,
              filled: true,
              hintText: "Mobile Number",
              hintStyle: TextStyle(
                color: Color.fromARGB(255, 84, 84, 84),
                fontWeight: FontWeight.w400,
                fontSize: 18,
              ),
            ),
            controller: phoneController,
            keyboardType: const TextInputType.numberWithOptions(),
          ),
        ),
        const SizedBox(
          height: 16,
        ),
        InkWell(
          onTap: () async {
            setState(() {
              showLoading = true;
            });
            await _auth.verifyPhoneNumber(
              phoneNumber: phoneController.text,
              verificationCompleted: (PhoneAuthCredential) {
                // setState(() {
                //   showLoading = false;
                // });
              },
              verificationFailed: (VerificationFailed) {
                // setState(() {
                //   showLoading = false;
                // });
                _scaffoldkey.currentState?.showSnackBar(
                  SnackBar(
                    content: Text(VerificationFailed.message ?? ""),
                  ),
                );
              },
              codeSent: (verificatioId, resendingToken) {
                setState(() {
                  currentState = MobileVerificationState.SHOW_OTP_FORM_STATE;
                  verificationId = verificatioId;
                  showLoading = false;
                });
              },
              codeAutoRetrievalTimeout: (verificationId) {},
            );
            print(phoneController);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.teal,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: showLoading
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                  : const Text(
                      'Send',
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  getOtpFormState(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(30.0),
          child: Image.asset("assets/eagel.png"),
        ),
        const Text(
          "Please enter OTP",
          style: TextStyle(fontSize: 17, color: Colors.black),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: TextField(
            decoration: const InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.teal, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.teal,
                  width: 1,
                ),
              ),
              fillColor: Colors.white,
              filled: true,
              hintText: "X X X X X X",
              hintStyle: TextStyle(
                color: Color.fromARGB(255, 84, 84, 84),
                fontWeight: FontWeight.w400,
                fontSize: 18,
              ),
            ),
            controller: otpController,
            keyboardType: const TextInputType.numberWithOptions(),
          ),
        ),
        const SizedBox(
          height: 16,
        ),
        InkWell(
          onTap: () async {
            // setState(() {
            //   showLoadingOtp = true;
            // });
            PhoneAuthCredential phoneAuthCredential =
                PhoneAuthProvider.credential(
                    verificationId: verificationId!,
                    smsCode: otpController.text);

            signInWithPhoneAuthCredetial(phoneAuthCredential);
            // setState(() {
            //   showLoadingOtp = false;
            // });
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.teal,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: showLoadingOtp
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'verify',
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  final GlobalKey<ScaffoldState> _scaffoldkey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade300,
      key: _scaffoldkey,
      body: SingleChildScrollView(
        child: Container(
          child: currentState == MobileVerificationState.SHOW_MOBILE_FORM_STATE
              ? getMoibleFormState(context)
              : getOtpFormState(context),
        ),
      ),
    );
  }
}
