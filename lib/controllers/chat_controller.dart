// ignore_for_file: override_on_non_overriding_member, avoid_print

import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:graduation_swiftchat/Config/Images.dart';
import 'package:graduation_swiftchat/models/call_model.dart';
import 'package:graduation_swiftchat/services/fcm_service.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_model.dart';
import '../models/chat_room_model.dart';
import '../models/user_model.dart';
import 'ProfileController.dart';
import 'contact_controller.dart';

class ChatController extends GetxController {
  final auth = FirebaseAuth.instance;
  final db = FirebaseFirestore.instance;
  RxBool isLoading = false.obs;
  var uuid = Uuid();
  RxString selectedImagePath = "".obs;
  @override
  ProfileController profileController = Get.put(ProfileController());
  ContactController contactController = Get.put(ContactController());
  String getRoomId(String targetUserId) {
    String currentUserId = auth.currentUser!.uid;
    if (currentUserId[0].codeUnitAt(0) > targetUserId[0].codeUnitAt(0)) {
      return currentUserId + targetUserId;
    } else {
      return targetUserId + currentUserId;
    }
  }

  UserModel getSender(UserModel currentUser, UserModel targetUser) {
    String currentUserId = currentUser.id!;
    String targetUserId = targetUser.id!;
    if (currentUserId[0].codeUnitAt(0) > targetUserId[0].codeUnitAt(0)) {
      return currentUser;
    } else {
      return targetUser;
    }
  }

  UserModel getReciver(UserModel currentUser, UserModel targetUser) {
    String currentUserId = currentUser.id!;
    String targetUserId = targetUser.id!;
    if (currentUserId[0].codeUnitAt(0) > targetUserId[0].codeUnitAt(0)) {
      return targetUser;
    } else {
      return currentUser;
    }
  }

  Future<void> sendMessage(
    String targetUserId,
    String message,
    UserModel targetUser,
  ) async {
    isLoading.value = true;
    String chatId = uuid.v6();
    String roomId = getRoomId(targetUserId);
    DateTime timestamp = DateTime.now();
    String nowTime = DateFormat('hh:mm a').format(timestamp);

    UserModel sender = getSender(
      profileController.currentUser.value!,
      targetUser,
    );
    UserModel receiver = getReciver(
      profileController.currentUser.value!,
      targetUser,
    );

    RxString imageUrl = "".obs;
    if (selectedImagePath.value.isNotEmpty) {
      imageUrl.value = await profileController.uploadFileToLocalStorage(
        selectedImagePath.value,
      );
    }
    var newChat = ChatModel(
      id: chatId,
      message: message,
      imageUrl: imageUrl.value,
      senderId: auth.currentUser!.uid,
      receiverId: targetUserId,
      senderName: profileController.currentUser.value?.name,
      timestamp: DateTime.now().toString(),
      readStatus: "sent", // ✅ تغيير من unread لـ sent
    );

    var roomDetails = ChatRoomModel(
      id: roomId,
      lastMessage: message,
      lastMessageTimestamp: nowTime,
      sender: sender,
      receiver: receiver,
      timestamp: DateTime.now().toString(),
      unReadMessNo: 0,
    );
    try {
      await db
          .collection("chats")
          .doc(roomId)
          .collection("messages")
          .doc(chatId)
          .set(newChat.toJson());
      selectedImagePath.value = "";
      await db.collection("chats").doc(roomId).set(roomDetails.toJson());
      await contactController.saveContact(targetUser);

      // 🔔 إرسال إشعار للمستقبل
      await FCMService.sendMessageNotification(
        receiverId: targetUserId,
        senderName: profileController.currentUser.value?.name ?? "مستخدم",
        messageText: message.isNotEmpty ? message : "📷 صورة",
        senderImage: profileController.currentUser.value?.profileImage ?? "",
      );
    } catch (e) {
      print(e);
    }
    isLoading.value = false;
  }

  Stream<List<ChatModel>> getMessages(String targetUserId) {
    String roomId = getRoomId(targetUserId);
    return db
        .collection("chats")
        .doc(roomId)
        .collection("messages")
        .orderBy("timestamp", descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatModel.fromJson(doc.data()))
              .toList(),
        );
  }

  Stream<UserModel> getStatus(String uid) {
    return db.collection('users').doc(uid).snapshots().map((event) {
      return UserModel.fromJson(event.data()!);
    });
  }

  Stream<List<CallModel>> getCalls() {
    return db
        .collection("users")
        .doc(auth.currentUser!.uid)
        .collection("calls")
        .orderBy("timestamp", descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CallModel.fromJson(doc.data()))
              .toList(),
        );
  }

  Stream<int> getUnreadMessageCount(String roomId) {
    return db
        .collection("chats")
        .doc(roomId)
        .collection("messages")
        .where("readStatus", isEqualTo: "unread")
        .where(
          "senderId",
          isNotEqualTo: profileController.currentUser.value?.id,
        )
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markMessagesAsRead(String roomId) async {
    QuerySnapshot<Map<String, dynamic>> messagesSnapshot = await db
        .collection("chats")
        .doc(roomId)
        .collection("messages")
        .where("readStatus", isEqualTo: "unread")
        .get();

    for (QueryDocumentSnapshot<Map<String, dynamic>> messageDoc
        in messagesSnapshot.docs) {
      String senderId = messageDoc.data()["senderId"];
      if (senderId != profileController.currentUser.value?.id) {
        await db
            .collection("chats")
            .doc(roomId)
            .collection("messages")
            .doc(messageDoc.id)
            .update({"readStatus": "read"});
      }
    }
  }

  // حساب status الرسالة للـ 1vs1 chat
  String getMessageStatusSync(String readStatus) {
    // لو قرأها -> علامتين أخضر ✓✓
    if (readStatus == 'read') {
      return 'read';
    }

    // لو وصلت بس مشافهاش -> علامتين رصاصي ✓✓
    if (readStatus == 'delivered') {
      return 'delivered';
    }

    // لو لسه بتتبعت -> علامة واحدة ✓
    return 'sent';
  }

  // تحديث status الرسالة لـ delivered لما يفتح الشات
  Future<void> markMessagesAsDelivered(String roomId) async {
    try {
      QuerySnapshot<Map<String, dynamic>> messagesSnapshot = await db
          .collection("chats")
          .doc(roomId)
          .collection("messages")
          .where("readStatus", isEqualTo: "sent")
          .where("receiverId", isEqualTo: auth.currentUser!.uid)
          .get();

      for (QueryDocumentSnapshot<Map<String, dynamic>> messageDoc
          in messagesSnapshot.docs) {
        await db
            .collection("chats")
            .doc(roomId)
            .collection("messages")
            .doc(messageDoc.id)
            .update({"readStatus": "delivered"});
      }
    } catch (e) {
      print("Error marking messages as delivered: $e");
    }
  }
}
