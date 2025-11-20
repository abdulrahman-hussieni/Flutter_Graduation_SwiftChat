import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:graduation_swiftchat/config/images.dart';
import 'package:graduation_swiftchat/controllers/group_controller.dart';
import 'package:graduation_swiftchat/models/group_model.dart';
import 'package:graduation_swiftchat/pages/GroupChat/GroupChat.dart';
import 'package:graduation_swiftchat/pages/HomePage/Widgets/ChatTile.dart';

class GroupPage extends StatelessWidget {
  const GroupPage({super.key});

  String _formatTime(String timestamp) {
    try {
      DateTime messageTime = DateTime.parse(timestamp);
      DateTime now = DateTime.now();
      
      // لو نفس اليوم، اعرض الوقت
      if (messageTime.year == now.year &&
          messageTime.month == now.month &&
          messageTime.day == now.day) {
        return DateFormat('hh:mm a').format(messageTime);
      }
      
      // لو امبارح، اعرض "Yesterday"
      DateTime yesterday = now.subtract(Duration(days: 1));
      if (messageTime.year == yesterday.year &&
          messageTime.month == yesterday.month &&
          messageTime.day == yesterday.day) {
        return "Yesterday";
      }
      
      // لو أكتر من امبارح، اعرض التاريخ
      return DateFormat('dd/MM/yyyy').format(messageTime);
    } catch (e) {
      return "Just Now";
    }
  }

  @override
  Widget build(BuildContext context) {
    GroupController groupController = Get.put(GroupController());
    return StreamBuilder<List<GroupModel>>(
      stream: groupController.getGroupss(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        List<GroupModel>? groups = snapshot.data;
        return ListView.builder(
          itemCount: groups!.length,
          itemBuilder: (context, index) {
            return InkWell(
              onTap: () {
                Get.to(() => GroupChatPage(groupModel: groups[index]));
              },
              child: ChatTile(
                name: groups[index].name!,
                imageUrl: groups[index].profileUrl ?? "",
                lastChat: groups[index].lastMessage ?? "No messages yet",
                lastTime: groups[index].lastMessageTime != null
                    ? _formatTime(groups[index].lastMessageTime!)
                    : "Just Now",
              ),
            );
          },
        );
      },
    );
  }
}