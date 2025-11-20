// ignore_for_file: avoid_unnecessary_containers

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:graduation_swiftchat/pages/GroupChat/GroupTypeMessage.dart';
import 'package:graduation_swiftchat/pages/GroupInfo/GroupInfo.dart';
import 'package:graduation_swiftchat/pages/chat/widgets/chatbubble.dart';
import 'package:intl/intl.dart';
import 'package:graduation_swiftchat/config/images.dart';
import 'package:graduation_swiftchat/controllers/ProfileController.dart';
import 'package:graduation_swiftchat/controllers/group_controller.dart';
import 'package:graduation_swiftchat/models/group_model.dart';


class GroupChatPage extends StatelessWidget {
  final GroupModel groupModel;
  const GroupChatPage({super.key, required this.groupModel});

  @override
  Widget build(BuildContext context) {
    GroupController groupController = Get.put(GroupController());
    ProfileController profileController = Get.put(ProfileController());

    return Scaffold(
      appBar: AppBar(
        leading: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Get.back();
              },
            ),
            InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () {
                Get.to(() => GroupInfo(
                  groupModel: groupModel,
                ));
              },
              child: Container(
                width: 40,
                height: 40,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: (groupModel.profileUrl != null && groupModel.profileUrl!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: groupModel.profileUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => CircularProgressIndicator(),
                          errorWidget: (context, url, error) => Icon(Icons.group, size: 30),
                        )
                      : Icon(Icons.group, size: 30, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
        leadingWidth: 100,
        title: InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: () {
            Get.to(() => GroupInfo(
              groupModel: groupModel,
            ));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                groupModel.name ?? "Group Name",
                style: Theme.of(context).textTheme.bodyLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                "${groupModel.members?.length ?? 0} members",
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.phone,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.video_call,
            ),
          )
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
                    stream: groupController.getGroupMessages(groupModel.id!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text("Error: ${snapshot.error}"),
                        );
                      }
                      if (snapshot.data == null) {
                        return const Center(
                          child: Text("No Messages"),
                        );
                      } else {
                        return ListView.builder(
                          reverse: true,
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            DateTime timestamp = DateTime.parse(
                                snapshot.data![index].timestamp!);
                            String formattedTime =
                                DateFormat('hh:mm a').format(timestamp);
                            
                            bool isMyMessage = snapshot.data![index].senderId ==
                                profileController.currentUser.value!.id;
                            
                            return FutureBuilder<String>(
                              future: isMyMessage
                                  ? groupController.getGroupMessageStatus(
                                      groupModel.id!,
                                      snapshot.data![index].senderId!
                                    )
                                  : Future.value('read'),
                              builder: (context, statusSnapshot) {
                                String messageStatus = statusSnapshot.data ?? 'sent';
                                
                                return ChatBubble(
                                  message: snapshot.data![index].message!,
                                  imageUrl: snapshot.data![index].imageUrl ?? "",
                                  isComming: snapshot.data![index].senderId !=
                                      profileController.currentUser.value!.id,
                                  status: messageStatus,
                                  time: formattedTime,
                                );
                              },
                            );
                          },
                        );
                      }
                    },
                  ),
                  Obx(
                    () => (groupController.selectedImagePath.value != "")
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
                                        File(groupController
                                            .selectedImagePath.value),
                                      ),
                                      fit: BoxFit.contain,
                                    ),
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  height: 500,
                                ),
                                Positioned(
                                  right: 0,
                                  child: IconButton(
                                    onPressed: () {
                                      groupController.selectedImagePath.value =
                                          "";
                                    },
                                    icon: Icon(Icons.close),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(),
                  )
                ],
              ),
            ),
            GroupTypeMessage(
              groupModel: groupModel,
            ),
          ],
        ),
      ),
    );
  }
}