// ignore_for_file: sized_box_for_whitespace

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:graduation_swiftchat/controllers/ProfileController.dart';
import 'package:graduation_swiftchat/controllers/chat_controller.dart';
import 'package:intl/intl.dart';

import 'package:graduation_swiftchat/config/images.dart';

class CallHistory extends StatelessWidget {
  const CallHistory({super.key});

  @override
  Widget build(BuildContext context) {
    ChatController chatController = Get.put(ChatController());
    ProfileController profileController = Get.put(ProfileController());
    return StreamBuilder(
      stream: chatController.getCalls(),
      builder: (context, snapshot) {
        // حالة الانتظار
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        // حالة الخطأ
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        // حالة وجود بيانات
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              DateTime timestamp = DateTime.parse(
                snapshot.data![index].timestamp!,
              );
              String formattedTime = DateFormat('hh:mm a').format(timestamp);
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: CachedNetworkImage(
                    imageUrl:
                        snapshot.data![index].callerUid ==
                            profileController.currentUser.value!.id
                        ? snapshot.data![index].receiverPic ?? ""
                        : snapshot.data![index].callerPic ?? "",
                    fit: BoxFit.cover,
                    placeholder: (context, url) => CircularProgressIndicator(),
                    errorWidget: (context, url, error) =>
                        Icon(Icons.person, size: 40),
                  ),
                ),
                title: Text(
                  snapshot.data![index].callerUid ==
                          profileController.currentUser.value!.id
                      ? snapshot.data![index].receiverName!
                      : snapshot.data![index].callerName!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                subtitle: Text(
                  formattedTime,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                trailing: snapshot.data![index].type == "video"
                    ? IconButton(icon: Icon(Icons.video_call), onPressed: () {})
                    : IconButton(icon: Icon(Icons.call), onPressed: () {}),
              );
            },
          );
        }

        // حالة عدم وجود مكالمات (Empty State)
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.call_outlined, size: 80, color: Colors.grey),
              SizedBox(height: 20),
              Text(
                'No Call History',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 10),
              Text(
                'Your call history will appear here',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }
}
