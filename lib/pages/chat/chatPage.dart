// ignore_for_file: unused_local_variable, avoid_unnecessary_containers

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:graduation_swiftchat/controllers/CallController.dart';
import 'package:graduation_swiftchat/pages/CallPage/AudioCallPage.dart';
import 'package:graduation_swiftchat/pages/CallPage/VideoCallPage.dart';
import 'package:graduation_swiftchat/pages/HomePage/HomePage.dart';
import 'package:graduation_swiftchat/pages/UserProfile/ProfilePage.dart';
import 'package:graduation_swiftchat/pages/chat/widgets/chatbubble.dart';
import 'package:graduation_swiftchat/pages/chat/widgets/type_message.dart';
import 'package:intl/intl.dart';
import 'package:graduation_swiftchat/config/images.dart';
import 'package:graduation_swiftchat/controllers/ProfileController.dart';
import 'package:graduation_swiftchat/controllers/chat_controller.dart';
import 'package:graduation_swiftchat/controllers/image_picker_controller.dart';
import 'package:graduation_swiftchat/models/user_model.dart';
import 'package:graduation_swiftchat/widgets/imager_picker_button_sheet.dart';

class ChatPage extends StatefulWidget {
  final UserModel userModel;
  const ChatPage({super.key, required this.userModel});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late ChatController chatController;
  late ProfileController profileController;
  late CallController callController;
  final TextEditingController messageController = TextEditingController();
  String? _roomId;

  @override
  void initState() {
    super.initState();
    chatController = Get.put(ChatController());
    profileController = Get.put(ProfileController());
    callController = Get.put(CallController());
    _roomId = chatController.getRoomId(widget.userModel.id!);
    // Mark messages as delivered immediately when opening chat (receiver side)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_roomId != null) {
        await chatController.markMessagesAsDelivered(_roomId!);
        // Delay read marking to allow UI to show delivered state briefly
        Future.delayed(const Duration(seconds: 2), () {
          chatController.markMessagesAsRead(_roomId!);
        });
      }
    });
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userModel = widget.userModel;
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 100,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {
                Get.to(HomePage());
              },
              icon: Icon(Icons.arrow_back),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
            SizedBox(width: 4),
            InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () {
                Get.to(UserProfilePage(userModel: userModel));
              },
              child: Container(
                width: 40,
                height: 40,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child:
                      (userModel.profileImage != null &&
                          userModel.profileImage!.startsWith('http'))
                      ? CachedNetworkImage(
                          imageUrl: userModel.profileImage!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              CircularProgressIndicator(),
                          errorWidget: (context, url, error) =>
                              Icon(Icons.person),
                        )
                      : Image.asset(
                          // Use gender-aware default image when no network image is available
                          (userModel.gender != null && userModel.gender!.toLowerCase() == 'female')
                              ? AssetsImage.girlPic
                              : AssetsImage.boyPic,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.person),
                        ),
                ),
              ),
            ),
          ],
        ),
        title: InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: () {
            Get.to(UserProfilePage(userModel: userModel));
          },
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userModel.name ?? "User",
                      style: Theme.of(context).textTheme.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    StreamBuilder<Map<String, dynamic>>(
                      stream: profileController.getUserStatus(userModel.id!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Text("........");
                        } else if (snapshot.hasData) {
                          String status = snapshot.data!['status'] ?? 'Offline';
                          String lastActive =
                              snapshot.data!['lastActive'] ?? '';

                          return Text(
                            status == 'Online'
                                ? 'Online'
                                : profileController.formatLastSeen(lastActive),
                            style: TextStyle(
                              fontSize: 12,
                              color: status == "Online"
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          );
                        } else {
                          return const Text(
                            "Offline",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Get.to(AudioCallPage(target: userModel));
              callController.callAction(
                userModel,
                profileController.currentUser.value!,
                "audio",
              );
            },
            icon: Icon(Icons.phone),
          ),
          IconButton(
            onPressed: () {
              Get.to(VideoCallPage(target: userModel));
              callController.callAction(
                userModel,
                profileController.currentUser.value!,
                "video",
              );
            },
            icon: Icon(Icons.video_call),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.only(bottom: 10, top: 10, left: 10, right: 10),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  StreamBuilder(
                    stream: chatController.getMessages(userModel.id!),
                    builder: (context, snapshot) {
                      // Continuously update status for messages while chat is open
                      if (_roomId != null) {
                        chatController.markMessagesAsDelivered(_roomId!);
                        chatController.markMessagesAsRead(_roomId!);
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text("Error: ${snapshot.error}"));
                      }
                      if (snapshot.data == null) {
                        return const Center(child: Text("No Messages"));
                      } else {
                        return ListView.builder(
                          reverse: true,
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            DateTime timestamp = DateTime.parse(
                              snapshot.data![index].timestamp!,
                            );
                            String formattedTime = DateFormat(
                              'hh:mm a',
                            ).format(timestamp);

                            bool isMyMessage =
                                snapshot.data![index].senderId ==
                                profileController.currentUser.value!.id;

                            String readStatus = snapshot.data![index].readStatus ?? 'sent';
                            String messageStatus = isMyMessage
                                ? chatController.getMessageStatusSync(readStatus)
                                : readStatus; // incoming can be used for logic later

                            return ChatBubble(
                              message: snapshot.data![index].message!,
                              imageUrl: snapshot.data![index].imageUrl ?? "",
                              isComming:
                                  snapshot.data![index].receiverId ==
                                  profileController.currentUser.value!.id,
                              status: messageStatus,
                              time: formattedTime,
                            );
                          },
                        );
                      }
                    },
                  ),
                  Obx(
                    () => (chatController.selectedImagePath.value != "")
                        ? Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Stack(
                              children: [
                                Container(
                                  margin: EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: FileImage(
                                        File(
                                          chatController
                                              .selectedImagePath
                                              .value,
                                        ),
                                      ),
                                      fit: BoxFit.contain,
                                    ),
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  height: 500,
                                ),
                                Positioned(
                                  right: 0,
                                  child: IconButton(
                                    onPressed: () {
                                      chatController.selectedImagePath.value =
                                          "";
                                    },
                                    icon: Icon(Icons.close),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(),
                  ),
                ],
              ),
            ),
            TypeMessage(userModel: userModel),
          ],
        ),
      ),
    );
  }
}
