// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:graduation_swiftchat/config/images.dart';
import 'package:graduation_swiftchat/pages/Groups/NewGroup/selected_members_list.dart';
import 'package:graduation_swiftchat/pages/HomePage/Widgets/ChatTile.dart';
import 'package:graduation_swiftchat/controllers/contact_controller.dart';
import 'package:graduation_swiftchat/controllers/group_controller.dart';
import 'package:graduation_swiftchat/pages/Groups/NewGroup/group_title.dart';


class NewGroup extends StatelessWidget {
  const NewGroup({super.key});

  @override
  Widget build(BuildContext context) {
    ContactController contactController = Get.put(ContactController());
    GroupController groupController = Get.put(GroupController());
    return Scaffold(
      appBar: AppBar(
        title: Text('New Group'),
      ),
      floatingActionButton: Obx(
        () => FloatingActionButton(
          backgroundColor: groupController.groupMembers.isEmpty
              ? Colors.grey
              : Theme.of(context).colorScheme.primary,
          onPressed: () {
            if (groupController.groupMembers.isEmpty) {
              Get.snackbar("Error", "Please select atleast one member");
            } else {
              Get.to(() => GroupTitle());
            }
          },
          child: Icon(
            Icons.arrow_forward,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            SelectedMembers(),
            SizedBox(height: 10),
            Row(
              children: [
                Text(
                  "My Contacts",
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            SizedBox(height: 10),
            Expanded(
              child: StreamBuilder(
                stream: contactController.getContacts(),
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
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.contacts, size: 80, color: Colors.grey),
                          SizedBox(height: 10),
                          Text(
                            "No contacts yet",
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "Add contacts first to create a group",
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  } else {
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        return InkWell(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () {
                            groupController.selectMember(snapshot.data![index]);
                          },
                          child: ChatTile(
                            imageUrl: snapshot.data![index].profileImage ?? "",
                            name: snapshot.data![index].name!,
                            lastChat: snapshot.data![index].about ?? "",
                            lastTime: "",
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}