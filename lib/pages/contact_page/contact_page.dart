import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:graduation_swiftchat/pages/Groups/NewGroup/new_group.dart';
import 'package:graduation_swiftchat/pages/contact_page/add_contact_page.dart';
import 'package:graduation_swiftchat/pages/contact_page/widgets/contact_search.dart';
import 'package:graduation_swiftchat/pages/contact_page/widgets/new_contact_tile.dart';


import 'package:graduation_swiftchat/config/images.dart';
import '../../controllers/ProfileController.dart';
import '../../controllers/contact_controller.dart';
import '../HomePage/Widgets/ChatTile.dart';
import '../chat/chatPage.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    RxBool isSearchEnable = false.obs;
    ContactController contactController = Get.put(ContactController());
    return Scaffold(
      appBar: AppBar(
        title: Text("Select contact"),
        actions: [
          Obx(
                () => IconButton(
              onPressed: () {
                isSearchEnable.value = !isSearchEnable.value;
              },
              icon:
              isSearchEnable.value ? Icon(Icons.close) : Icon(Icons.search),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: ListView(
          children: [
            Obx(
                  () => isSearchEnable.value ? ContactSearch() : SizedBox(),
            ),
            SizedBox(height: 10),
            NewContactTile(
              btnName: "New contact",
              icon: Icons.person_add,
              ontap: () {
                Get.to(() => AddContactPage());
              },
            ),
            SizedBox(height: 10),
            NewContactTile(
              btnName: "New Group",
              icon: Icons.group_add,
              ontap: () {
                Get.to(() => NewGroup());
              },
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text("My Contacts"),
              ],
            ),
            SizedBox(height: 10),
            SizedBox(
              height: 400,
              child: StreamBuilder(
                stream: contactController.getContacts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
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
                            "Add your first contact using the button above",
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final contact = snapshot.data![index];
                      return InkWell(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () {
                          Get.to(() => ChatPage(userModel: contact));
                        },
                        child: ChatTile(
                          imageUrl: contact.profileImage ?? "",
                          name: contact.name ?? "User",
                          lastChat: contact.about ?? "Hey there",
                          lastTime: "",
                        ),
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}