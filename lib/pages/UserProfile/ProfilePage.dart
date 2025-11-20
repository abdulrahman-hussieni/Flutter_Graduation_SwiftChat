// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:graduation_swiftchat/config/images.dart';
import 'package:graduation_swiftchat/controllers/AuthController.dart';
import 'package:graduation_swiftchat/controllers/ProfileController.dart';
import 'package:graduation_swiftchat/controllers/contact_controller.dart';
import 'package:graduation_swiftchat/models/user_model.dart';
import 'package:graduation_swiftchat/pages/CallPage/AudioCallPage.dart';
import 'package:graduation_swiftchat/pages/CallPage/VideoCallPage.dart';
import 'package:graduation_swiftchat/pages/chat/chatPage.dart';
import 'package:graduation_swiftchat/pages/UserProfile/widgets/UserInfo.dart';

class UserProfilePage extends StatelessWidget {
  final UserModel userModel;
  const UserProfilePage({super.key, required this.userModel});

  @override
  Widget build(BuildContext context) {
    AuthController authController = Get.put(AuthController());
    ProfileController profileController = Get.put(ProfileController());
    ContactController contactController = Get.put(ContactController());
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        actions: [
          IconButton(
            onPressed: () {
              Get.toNamed("/updateProfilePage");
            },
            icon: Icon(Icons.edit),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            LoginUserInfo(
              profileImage: userModel.profileImage ?? "",
              userName: userModel.name ?? "User",
              userEmail: userModel.email ?? "",
              gender: userModel.gender,
              onAudioCall: () {
                Get.to(() => AudioCallPage(target: userModel));
              },
              onVideoCall: () {
                Get.to(() => VideoCallPage(target: userModel));
              },
              onChat: () {
                Get.to(() => ChatPage(userModel: userModel));
              },
            ),
            SizedBox(height: 20),
            // عرض حالة المستخدم وآخر ظهور
            StreamBuilder<Map<String, dynamic>>(
              stream: profileController.getUserStatus(userModel.id!),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  String status = snapshot.data!['status'] ?? 'Offline';
                  String lastActive = snapshot.data!['lastActive'] ?? '';

                  return Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          status == 'Online' ? Icons.circle : Icons.access_time,
                          color: status == 'Online'
                              ? Colors.green
                              : Colors.grey,
                          size: 16,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            status == 'Online'
                                ? 'Online'
                                : 'Last seen ${profileController.formatLastSeen(lastActive)}',
                            style: TextStyle(
                              color: status == 'Online'
                                  ? Colors.green
                                  : Colors.grey,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return SizedBox.shrink();
              },
            ),
            SizedBox(height: 20),
            // Friend Request Button
            FutureBuilder<bool>(
              future: Get.find<ContactController>().isContact(userModel.id!),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return CircularProgressIndicator();
                }

                bool isContact = snapshot.data!;

                return ElevatedButton.icon(
                  onPressed: () async {
                    if (isContact) {
                      await Get.find<ContactController>().deleteContact(
                        userModel.id!,
                      );
                      Get.snackbar(
                        'Success',
                        'Contact removed successfully',
                        backgroundColor: Colors.orange,
                        colorText: Colors.white,
                        snackPosition: SnackPosition.BOTTOM,
                        duration: Duration(seconds: 2),
                      );
                    } else {
                      await Get.find<ContactController>().saveContact(
                        userModel,
                      );
                      Get.snackbar(
                        'Success',
                        'Contact added successfully',
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                        snackPosition: SnackPosition.BOTTOM,
                        duration: Duration(seconds: 2),
                      );
                    }
                    // Rebuild the widget to reflect changes
                    (context as Element).markNeedsBuild();
                  },
                  icon: Icon(
                    isContact ? Icons.person_remove : Icons.person_add,
                  ),
                  label: Text(isContact ? 'Remove Contact' : 'Add Friend'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isContact ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
