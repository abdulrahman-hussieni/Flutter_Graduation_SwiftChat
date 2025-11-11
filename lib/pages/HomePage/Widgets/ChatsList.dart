import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Config/Images.dart';
import '../../../controllers/ProfileController.dart';
import '../../../controllers/chat_controller.dart';
import '../../../controllers/contact_controller.dart';
import '../../../models/chat_room_model.dart';
import '../../chat/chatPage.dart';
import 'ChatTile.dart';

class ChatListWidget  extends StatelessWidget {
  const ChatListWidget ({super.key});

  @override
  Widget build(BuildContext context) {
    ContactController contactController = Get.put(ContactController());
    ProfileController profileController = Get.put(ProfileController());
    ChatController chatController = Get.put(ChatController());
    return StreamBuilder<List<ChatRoomModel>>(
      stream: contactController.getChatRoom(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        List<ChatRoomModel>? e = snapshot.data;

        return ListView.builder(
          itemCount: e!.length,
          itemBuilder: (context, index) {
            return InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () {
                chatController.markMessagesAsRead(e[index].id!);
                Get.to(
                  ChatPage(
                    userModel: (e[index].receiver!.id ==
                        profileController.currentUser.value?.id
                        ? e[index].sender
                        : e[index].receiver)!,
                  ),
                );
              },
              child: ChatTile(
                imageUrl: AssetsImage.boyPic,
                // imageUrl: (e[index].receiver!.id ==
                //     profileController.currentUser.value?.id
                //     ? e[index].sender!.profileImage
                //     : e[index].receiver!.profileImage) ??
                //     AssetsImage.connectSVG,
                name: (e[index].receiver!.id ==
                    profileController.currentUser.value?.id
                    ? e[index].sender!.name
                    : e[index].receiver!.name)!,
                lastChat: e[index].lastMessage ?? "Last Message",
                lastTime: e[index].lastMessageTimestamp ?? "Last Time",
              ),
            );
          },
        );
      },
    );
  }
}