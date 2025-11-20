// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/chat_room_model.dart';
import '../models/user_model.dart';

class ContactController extends GetxController {
  final db = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  RxBool isLoading = false.obs;
  RxList<UserModel> userList = <UserModel>[].obs;
  // RxList<ChatRoomModel> chatRoomList = <ChatRoomModel>[].obs;
  void onInit() async {
    super.onInit();
    await getUserList();
  }

  Future<void> getUserList() async {
    isLoading.value = true;
    try {
      userList.clear();
      await db.collection("users").get().then(
            (value) => {
          userList.value = value.docs
              .map(
                (e) => UserModel.fromJson(e.data()),
          )
              .toList(),
        },
      );
    } catch (ex) {
      print(ex);
    }
    isLoading.value = false;
  }

  Stream<List<ChatRoomModel>> getChatRoom() {
    print("🔄 Listening to chat rooms...");

    return db
        .collection('chats')
        .orderBy("timestamp", descending: true)
        .snapshots()
        .map((snapshot) {
      print("📥 Fetched ${snapshot.docs.length} chat documents from Firestore");

      final chatList = snapshot.docs.map((doc) {
        final data = doc.data();
        print("💬 Chat doc: ${doc.id}, data: $data"); // show raw Firestore data
        return ChatRoomModel.fromJson(data);
      }).where((chatRoom) {
        final currentId = auth.currentUser!.uid;
        final isUserInChat =
            chatRoom.sender!.id == currentId ||
                chatRoom.receiver!.id == currentId;

        if (!isUserInChat) {
          print("⛔ Skipped chat ${chatRoom.id}, not part of current user");
        }
        return isUserInChat;
      }).toList();

      print("✅ Filtered chats count: ${chatList.length}");
      return chatList;
    });

    
  }


  // Stream<List<ChatRoomModel>> getChatRoom() async{
  //   List<ChatRoomModel> tempChatRoom = [];
  //   await db.collection('chats').get().then((value){
  //     tempChatRoom = value.docs.map((e) => ChatRoomModel.fromJson(e.data())).toList();
  //   });
  //   // return db
  //   //     .collection('chats')
  //   //     .orderBy("timestamp", descending: true)
  //   //     .snapshots()
  //   //     .map((snapshot) => snapshot.docs
  //   //     .map((doc) => ChatRoomModel.fromJson(doc.data()))
  //   //     .where((chatRoom) => chatRoom.id!.contains(auth.currentUser!.uid))
  //   //     .toList());
  //   return tempChatRoom;
  // }

 Future<void> saveContact(UserModel user) async {
    try {
      print("💾 Saving contact: ${user.name} to user ${auth.currentUser!.uid}");
      await db
          .collection("users")
          .doc(auth.currentUser!.uid)
          .collection("contacts")
          .doc(user.id)
          .set(user.toJson());
      print("✅ Contact saved successfully!");
    } catch (ex) {
      if (kDebugMode) {
        print("Error while saving Contact" + ex.toString());
      }
    }
  }

  Future<void> deleteContact(String userId) async {
    try {
      print("🗑️ Deleting contact: $userId");
      await db
          .collection("users")
          .doc(auth.currentUser!.uid)
          .collection("contacts")
          .doc(userId)
          .delete();
      print("✅ Contact deleted successfully!");
    } catch (ex) {
      if (kDebugMode) {
        print("Error while deleting Contact" + ex.toString());
      }
    }
  }

  Future<bool> isContact(String userId) async {
    try {
      final doc = await db
          .collection("users")
          .doc(auth.currentUser!.uid)
          .collection("contacts")
          .doc(userId)
          .get();
      return doc.exists;
    } catch (ex) {
      if (kDebugMode) {
        print("Error checking contact: " + ex.toString());
      }
      return false;
    }
  }

  Stream<List<UserModel>> getContacts() {
    print("📡 Getting contacts stream for user: ${auth.currentUser!.uid}");
    return db
        .collection("users")
        .doc(auth.currentUser!.uid)
        .collection("contacts")
        .snapshots()
        .map(
          (snapshot) {
            print("📥 Got ${snapshot.docs.length} contacts from Firestore");
            return snapshot.docs
                .map(
                  (doc) => UserModel.fromJson(doc.data()),
                )
                .toList();
          },
        );
  }
}