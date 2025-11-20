// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:graduation_swiftchat/config/custom_message.dart';
import 'package:graduation_swiftchat/controllers/ProfileController.dart';
import 'package:graduation_swiftchat/models/chat_model.dart';
import 'package:graduation_swiftchat/models/group_model.dart';
import 'package:graduation_swiftchat/models/user_model.dart';
import 'package:graduation_swiftchat/pages/HomePage/HomePage.dart';
import 'package:uuid/uuid.dart';

class GroupController extends GetxController {
  final db = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  RxList<UserModel> groupMembers = <UserModel>[].obs;
  var uuid = Uuid();
  RxBool isLoading = false.obs;
  RxString selectedImagePath = "".obs;
  RxList<GroupModel> groupList = <GroupModel>[].obs;
  ProfileController profileController = Get.put(ProfileController());

  @override
  void onInit() {
    super.onInit();
    getGroups();
  }

  void selectMember(UserModel user) {
    if (groupMembers.contains(user)) {
      groupMembers.remove(user);
    } else {
      groupMembers.add(user);
    }
  }

  Future<void> createGroup(String groupName, String imagePath) async {
    isLoading.value = true;
    String groupId = uuid.v6();
    groupMembers.add(
      UserModel(
        id: auth.currentUser!.uid,
        name: profileController.currentUser.value!.name,
        profileImage: profileController.currentUser.value!.profileImage,
        email: profileController.currentUser.value!.email,
        role: "admin",
      ),
    );
    try {
      String imageUrl = await profileController.uploadFileToLocalStorage(imagePath);

      await db.collection("groups").doc(groupId).set(
        {
          "id": groupId,
          "name": groupName,
          "profileUrl": imageUrl,
          "members": groupMembers.map((e) => e.toJson()).toList(),
          "createdAt": DateTime.now().toString(),
          "createdBy": auth.currentUser!.uid,
          "timeStamp": DateTime.now().toString(),
          "lastMessage": "Group Created",
          "lastMessageTime": DateTime.now().toString(),
          "lastMessageBy": auth.currentUser!.uid,
        },
      );
      getGroups();
      successMessage("Group Created");
      Get.offAll(HomePage());
      isLoading.value = false;
    } catch (e) {
      print(e);
    }
  }

  Future<void> getGroups() async {
    isLoading.value = true;
    List<GroupModel> tempGroup = [];
    await db.collection('groups').get().then(
      (value) {
        tempGroup = value.docs
            .map(
              (e) => GroupModel.fromJson(e.data()),
            )
            .toList();
      },
    );
    groupList.clear();
    groupList.value = tempGroup
        .where(
          (e) => e.members!.any(
            (element) => element.id == auth.currentUser!.uid,
          ),
        )
        .toList();
    isLoading.value = false;
  }

Stream<List<GroupModel>> getGroupss() {
  isLoading.value = true;
  return db.collection('groups').snapshots().map((snapshot) {
    List<GroupModel> tempGroup = snapshot.docs
        .map((doc) => GroupModel.fromJson(doc.data()))
        .toList();
    groupList.clear();
    groupList.value = tempGroup
        .where((group) => group.members!.any((member) => member.id == auth.currentUser!.uid))
        .toList();
    isLoading.value = false;
    return groupList;
  });
}

  Future<void> sendGroupMessage(
      String message, String groupId, String imagePath) async {
    isLoading.value = true;
    var chatId = uuid.v6();
    String imageUrl = "";
    
    print("📤 Sending group message...");
    print("   Group ID: $groupId");
    print("   Message: $message");
    print("   Sender: ${auth.currentUser!.uid}");
    
    // رفع الصورة فقط لو موجودة
    if (imagePath != "") {
      print("   Uploading image...");
      imageUrl = await profileController.uploadFileToLocalStorage(imagePath);
      print("   Image uploaded: $imageUrl");
    }
    
    var newChat = ChatModel(
      id: chatId,
      message: message,
      imageUrl: imageUrl,
      senderId: auth.currentUser!.uid,
      senderName: profileController.currentUser.value!.name,
      timestamp: DateTime.now().toString(),
    );
    
    await db
        .collection("groups")
        .doc(groupId)
        .collection("messages")
        .doc(chatId)
        .set(
          newChat.toJson(),
        );
    
    print("✅ Message saved to Firestore");
    
    // تحديث آخر رسالة ووقتها في الجروب
    String displayMessage = message.isEmpty ? "📷 Photo" : message;
    await db.collection("groups").doc(groupId).update({
      "lastMessage": displayMessage,
      "lastMessageTime": DateTime.now().toString(),
      "lastMessageBy": auth.currentUser!.uid,
    });
    
    print("✅ Group last message updated");
    
    selectedImagePath.value = "";
    isLoading.value = false;
  }

  Stream<List<ChatModel>> getGroupMessages(String groupId) {
    print("📡 Listening to group messages for group: $groupId");
    return db
        .collection("groups")
        .doc(groupId)
        .collection("messages")
        .orderBy("timestamp", descending: true)
        .snapshots()
        .map(
          (snapshot) {
            print("📥 Received ${snapshot.docs.length} messages from group $groupId");
            return snapshot.docs
                .map(
                  (doc) => ChatModel.fromJson(doc.data()),
                )
                .toList();
          },
        );
  }

  Future<void> addMemberToGroup(String groupId, UserModel user) async {
    isLoading.value = true;
    await db.collection("groups").doc(groupId).update(
      {
        "members": FieldValue.arrayUnion([user.toJson()]),
      },
    );
    getGroups();
    isLoading.value = false;
  }

  // حساب status رسالة الجروب بناءً على حالة الأعضاء
  Future<String> getGroupMessageStatus(String groupId, String senderId) async {
    try {
      // جيب بيانات الجروب
      DocumentSnapshot groupDoc = await db.collection("groups").doc(groupId).get();
      if (!groupDoc.exists) return 'sent';
      
      Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;
      List<dynamic> members = groupData['members'] ?? [];
      
      // لو المرسل أنا، شوف حالة باقي الأعضاء
      if (senderId == auth.currentUser!.uid) {
        bool anyOffline = false;
        
        for (var member in members) {
          String memberId = member['id'];
          // تجاهل نفسي
          if (memberId == senderId) continue;
          
          // شوف حالة العضو
          DocumentSnapshot userDoc = await db.collection("users").doc(memberId).get();
          if (userDoc.exists) {
            Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
            String userStatus = userData['status'] ?? 'Offline';
            
            if (userStatus != 'Online') {
              anyOffline = true;
            }
          }
        }
        
        // لو أي حد offline -> علامة واحدة
        if (anyOffline) {
          return 'sent';
        }
        
        // TODO: لازم نضيف tracking لمين قرأ الرسالة
        // دلوقتي هنفترض إن لو الكل online ومافيش حد قرأ -> delivered
        return 'delivered';
      }
    } catch (e) {
      print("Error getting group message status: $e");
    }
    return 'sent';
  }
}