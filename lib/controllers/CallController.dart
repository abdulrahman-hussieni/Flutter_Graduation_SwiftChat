// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:graduation_swiftchat/models/call_model.dart';
import 'package:graduation_swiftchat/models/user_model.dart';
import 'package:graduation_swiftchat/pages/CallPage/AudioCallPage.dart';
import 'package:graduation_swiftchat/pages/CallPage/VideoCallPage.dart';
import 'package:graduation_swiftchat/pages/CallPage/OutgoingCallPage.dart';
import 'package:graduation_swiftchat/services/fcm_service.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class CallController extends GetxController {
  final db = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;

  @override
  void onInit() {
    super.onInit();

    getCallsNotification().listen((List<CallModel> callList) {
      if (callList.isNotEmpty) {
        var callData = callList[0];
        if (callData.type == "audio") {
          audioCallNotification(callData);
        } else if (callData.type == "video") {
          videoCallNotification(callData);
        }
      }
    });
  }

  Future<void> audioCallNotification(CallModel callData) async {
    Get.snackbar(
      duration: Duration(days: 1),
      barBlur: 0,
      backgroundColor: Colors.grey[900]!,
      isDismissible: false,
      icon: Icon(Icons.call),
      onTap: (snack) {
        Get.back();
        Get.to(
          AudioCallPage(
            target: UserModel(
              id: callData.callerUid,
              name: callData.callerName,
              email: callData.callerEmail,
              profileImage: callData.callerPic,
            ),
          ),
        );
      },
      callData.callerName!,
      "Incoming Audio Call",
      mainButton: TextButton(
        onPressed: () {
          endCall(callData);
          Get.back();
        },
        child: Text("End Call"),
      ),
    );
  }

  Future<void> callAction(
    UserModel reciver,
    UserModel caller,
    String type,
  ) async {
    // Generate unique call ID
    String callId = Uuid().v4();
    DateTime timestamp = DateTime.now();
    String nowTime = DateFormat('hh:mm a').format(timestamp);

    var newCall = CallModel(
      id: callId,
      callerName: caller.name,
      callerPic: caller.profileImage,
      callerUid: caller.id,
      callerEmail: caller.email,
      receiverName: reciver.name,
      receiverPic: reciver.profileImage,
      receiverUid: reciver.id,
      receiverEmail: reciver.email,
      status: "ringing", // Changed from "dialing" to "ringing"
      type: type,
      time: nowTime,
      timestamp: DateTime.now().toString(),
    );

    try {
      // Create call document in calls collection for real-time status
      await db.collection("calls").doc(callId).set(newCall.toJson());

      // Save to call history for both users
      await db
          .collection("users")
          .doc(auth.currentUser!.uid)
          .collection("calls")
          .add(newCall.toJson());
      await db
          .collection("users")
          .doc(reciver.id)
          .collection("calls")
          .add(newCall.toJson());

      // Send FCM notification to receiver
      await FCMService.sendCallNotification(
        receiverId: reciver.id!,
        caller: caller,
        callType: type,
        callId: callId,
      );

      // Navigate to outgoing call page
      Get.to(
        () =>
            OutgoingCallPage(receiver: reciver, callType: type, callId: callId),
      );
    } catch (e) {
      print('❌ Error making call: $e');
      Get.snackbar(
        'خطأ',
        'فشل إجراء المكالمة. حاول مرة أخرى.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Stream<List<CallModel>> getCallsNotification() {
    return FirebaseFirestore.instance
        .collection("notification")
        .doc(auth.currentUser!.uid)
        .collection("call")
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CallModel.fromJson(doc.data()))
              .toList(),
        );
  }

  Future<void> endCall(CallModel call) async {
    try {
      await db
          .collection("notification")
          .doc(call.receiverUid)
          .collection("call")
          .doc(call.id)
          .delete();
    } catch (e) {
      print(e);
    }
  }

  void videoCallNotification(CallModel callData) {
    Get.snackbar(
      duration: Duration(days: 1),
      barBlur: 0,
      backgroundColor: Colors.grey[900]!,
      isDismissible: false,
      icon: Icon(Icons.video_call),
      onTap: (snack) {
        Get.back();
        Get.to(
          VideoCallPage(
            target: UserModel(
              id: callData.callerUid,
              name: callData.callerName,
              email: callData.callerEmail,
              profileImage: callData.callerPic,
            ),
          ),
        );
      },
      callData.callerName!,
      "Incoming Video Call",
      mainButton: TextButton(
        onPressed: () {
          endCall(callData);
          Get.back();
        },
        child: Text("End Call"),
      ),
    );
  }
}
