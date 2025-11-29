// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/chat_room_model.dart';
import '../models/user_model.dart';
import '../models/friend_request_model.dart';

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
      await db
          .collection("users")
          .get()
          .then(
            (value) => {
              userList.value = value.docs
                  .map((e) => UserModel.fromJson(e.data()))
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

    return db.collection('chats').snapshots().map((snapshot) {
      print("📥 Fetched ${snapshot.docs.length} chat documents from Firestore");

      final chatList = snapshot.docs
          .map((doc) {
            final data = doc.data();
            print("💬 Chat doc: ${doc.id}, data: $data");
            return ChatRoomModel.fromJson(data);
          })
          .where((chatRoom) {
            final currentId = auth.currentUser!.uid;
            final isUserInChat =
                chatRoom.sender!.id == currentId ||
                chatRoom.receiver!.id == currentId;

            if (!isUserInChat) {
              print("⛔ Skipped chat ${chatRoom.id}, not part of current user");
            }
            return isUserInChat;
          })
          .toList();

      // ترتيب الشاتات حسب timestamp بشكل صحيح
      chatList.sort((a, b) {
        try {
          DateTime timeA = DateTime.parse(a.timestamp ?? '1970-01-01');
          DateTime timeB = DateTime.parse(b.timestamp ?? '1970-01-01');
          return timeB.compareTo(timeA); // الأحدث أولاً
        } catch (e) {
          print("⚠️ Error parsing timestamp: $e");
          return 0;
        }
      });

      print("✅ Filtered and sorted chats count: ${chatList.length}");
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
        .map((snapshot) {
          print("📥 Got ${snapshot.docs.length} contacts from Firestore");
          return snapshot.docs
              .map((doc) => UserModel.fromJson(doc.data()))
              .toList();
        });
  }

  // Friend Requests additions
  /// Send a friend request to [targetUser]. Creates a pending request under target user's friend_requests.
  Future<void> sendFriendRequest(UserModel targetUser) async {
    try {
      final currentId = auth.currentUser!.uid;
      if (currentId == targetUser.id) return; // can't send to self
      final reqDoc = db
          .collection('users')
          .doc(targetUser.id)
          .collection('friend_requests')
          .doc(currentId);
      final existing = await reqDoc.get();
      if (existing.exists) {
        // Don't overwrite accepted; allow re-send only if rejected
        final status = existing.data()?['status'];
        if (status == 'pending') return;
        if (status == 'accepted') return;
      }
      final myUserDoc = await db.collection('users').doc(currentId).get();
      final myUser = UserModel.fromJson(myUserDoc.data()!);
      final request = FriendRequestModel(
        requesterId: currentId,
        receiverId: targetUser.id!,
        status: 'pending',
        timestamp: DateTime.now().toIso8601String(),
        requesterName: myUser.name,
        requesterImage: myUser.profileImage,
      );
      await reqDoc.set(request.toJson());
    } catch (e) {
      print('Error sending friend request: $e');
    }
  }

  /// Cancel an outgoing friend request (delete if pending)
  Future<void> cancelFriendRequest(String targetUserId) async {
    try {
      final currentId = auth.currentUser!.uid;
      final reqDoc = db
          .collection('users')
          .doc(targetUserId)
          .collection('friend_requests')
          .doc(currentId);
      final snap = await reqDoc.get();
      if (snap.exists && snap.data()?['status'] == 'pending') {
        await reqDoc.delete();
      }
    } catch (e) {
      print('Error cancelling friend request: $e');
    }
  }

  /// Accept an incoming friend request; updates status and adds each other as contacts
  Future<void> acceptFriendRequest(UserModel requesterModel) async {
    try {
      final currentId = auth.currentUser!.uid;
      final requesterId = requesterModel.id!;
      final reqDoc = db
          .collection('users')
          .doc(currentId)
          .collection('friend_requests')
          .doc(requesterId);
      final snap = await reqDoc.get();
      if (!snap.exists) return;
      if (snap.data()?['status'] != 'pending') return;
      await reqDoc.update({'status': 'accepted'});
      // Add contacts both sides
      await saveContact(requesterModel);
      // Add current user to requester's contacts
      final myUserDoc = await db.collection('users').doc(currentId).get();
      final myUser = UserModel.fromJson(myUserDoc.data()!);
      await db
          .collection('users')
          .doc(requesterId)
          .collection('contacts')
          .doc(currentId)
          .set(myUser.toJson());
    } catch (e) {
      print('Error accepting friend request: $e');
    }
  }

  /// Reject an incoming friend request (update status -> rejected)
  Future<void> rejectFriendRequest(String requesterId) async {
    try {
      final currentId = auth.currentUser!.uid;
      final reqDoc = db
          .collection('users')
          .doc(currentId)
          .collection('friend_requests')
          .doc(requesterId);
      final snap = await reqDoc.get();
      if (!snap.exists) return;
      if (snap.data()?['status'] != 'pending') return;
      await reqDoc.update({'status': 'rejected'});
    } catch (e) {
      print('Error rejecting friend request: $e');
    }
  }

  /// Get outgoing request status to a target user (null if none)
  Future<String?> getOutgoingRequestStatus(String targetUserId) async {
    try {
      final currentId = auth.currentUser!.uid;
      final doc = await db
          .collection('users')
          .doc(targetUserId)
          .collection('friend_requests')
          .doc(currentId)
          .get();
      if (!doc.exists) return null;
      return doc.data()?['status'];
    } catch (_) {
      return null;
    }
  }

  /// Get incoming request status from requesterId (null if none)
  Future<String?> getIncomingRequestStatus(String requesterId) async {
    try {
      final currentId = auth.currentUser!.uid;
      final doc = await db
          .collection('users')
          .doc(currentId)
          .collection('friend_requests')
          .doc(requesterId)
          .get();
      if (!doc.exists) return null;
      return doc.data()?['status'];
    } catch (_) {
      return null;
    }
  }

  /// Stream of pending incoming friend requests
  Stream<List<FriendRequestModel>> getIncomingFriendRequests() {
    final currentId = auth.currentUser!.uid;
    return db
        .collection('users')
        .doc(currentId)
        .collection('friend_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => FriendRequestModel.fromJson(d.data()))
            .toList());
  }
}
