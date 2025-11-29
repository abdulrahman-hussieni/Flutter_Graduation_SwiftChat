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
            FutureBuilder<Map<String, dynamic>>(
              future: (() async {
                final contactCtrl = Get.find<ContactController>();
                final currentId = Get.find<AuthController>().auth.currentUser!.uid;
                final targetId = userModel.id!;
                final isContact = await contactCtrl.isContact(targetId);
                final outgoingStatus = await contactCtrl.getOutgoingRequestStatus(targetId); // request I sent
                final incomingStatus = await contactCtrl.getIncomingRequestStatus(targetId); // request they sent to me
                return {
                  'isContact': isContact,
                  'outgoingStatus': outgoingStatus, // null | pending | accepted | rejected
                  'incomingStatus': incomingStatus, // null | pending | accepted | rejected
                  'currentId': currentId,
                  'targetId': targetId,
                };
              })(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                final data = snapshot.data!;
                final bool isContact = data['isContact'] as bool;
                final String? outgoingStatus = data['outgoingStatus'] as String?; // I -> target
                final String? incomingStatus = data['incomingStatus'] as String?; // target -> me

                // Priority handling:
                // 1. If already contacts -> show Remove Friend
                if (isContact) {
                  return ElevatedButton.icon(
                    onPressed: () async {
                      await Get.find<ContactController>().deleteContact(userModel.id!);
                      Get.snackbar('Success', 'Friend removed', backgroundColor: Colors.orange, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 2));
                      (context as Element).markNeedsBuild();
                    },
                    icon: const Icon(Icons.person_remove),
                    label: const Text('Remove Friend'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                  );
                }

                // 2. If incoming pending request from target -> show Accept / Reject row
                if (incomingStatus == 'pending') {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          await Get.find<ContactController>().acceptFriendRequest(userModel);
                          Get.snackbar('Success', 'Friend request accepted', backgroundColor: Colors.green, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 2));
                          (context as Element).markNeedsBuild();
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Accept'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await Get.find<ContactController>().rejectFriendRequest(userModel.id!);
                          Get.snackbar('Notice', 'Friend request rejected', backgroundColor: Colors.grey, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 2));
                          (context as Element).markNeedsBuild();
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        ),
                      ),
                    ],
                  );
                }

                // 3. Outgoing states (request I sent)
                if (outgoingStatus == 'pending') {
                  return ElevatedButton.icon(
                    onPressed: () async {
                      await Get.find<ContactController>().cancelFriendRequest(userModel.id!);
                      Get.snackbar('Success', 'Friend request cancelled', backgroundColor: Colors.orange, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 2));
                      (context as Element).markNeedsBuild();
                    },
                    icon: const Icon(Icons.hourglass_empty),
                    label: const Text('Request Sent (Cancel)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                  );
                }

                if (outgoingStatus == 'rejected') {
                  return ElevatedButton.icon(
                    onPressed: () async {
                      await Get.find<ContactController>().sendFriendRequest(userModel);
                      Get.snackbar('Success', 'Friend request re-sent', backgroundColor: Colors.blue, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 2));
                      (context as Element).markNeedsBuild();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Request Rejected (Resend)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                  );
                }

                if (outgoingStatus == 'accepted') {
                  // If accepted but contact not yet added (rare race) allow manual add
                  return ElevatedButton.icon(
                    onPressed: () async {
                      await Get.find<ContactController>().saveContact(userModel);
                      Get.snackbar('Success', 'Friend added', backgroundColor: Colors.green, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 2));
                      (context as Element).markNeedsBuild();
                    },
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Add to Contacts'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                  );
                }

                // 4. Default -> show Add Friend (send request)
                return ElevatedButton.icon(
                  onPressed: () async {
                    await Get.find<ContactController>().sendFriendRequest(userModel);
                    Get.snackbar('Success', 'Friend request sent', backgroundColor: Colors.blue, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 2));
                    (context as Element).markNeedsBuild();
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Friend'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
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
