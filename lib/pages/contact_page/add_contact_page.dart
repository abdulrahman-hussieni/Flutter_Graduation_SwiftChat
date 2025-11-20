import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:graduation_swiftchat/controllers/contact_controller.dart';
import 'package:graduation_swiftchat/models/user_model.dart';
import 'package:graduation_swiftchat/pages/chat/chatPage.dart';

class AddContactPage extends StatelessWidget {
  const AddContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    ContactController contactController = Get.put(ContactController());
    TextEditingController searchController = TextEditingController();
    RxBool isSearching = false.obs;
    RxList<UserModel> foundUsers = <UserModel>[].obs;

    return Scaffold(
      appBar: AppBar(
        title: Text("Add New Contact"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Search field
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Enter name to search",
                prefixIcon: Icon(Icons.person_search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                suffixIcon: IconButton(
                  onPressed: () async {
                    if (searchController.text.isEmpty) {
                      Get.snackbar(
                        "Error",
                        "Please enter a name",
                        snackPosition: SnackPosition.BOTTOM,
                      );
                      return;
                    }
                    
                    isSearching.value = true;
                    foundUsers.clear();
                    
                    // Search for users by name (case-insensitive)
                    final users = contactController.userList
                        .where((user) => 
                            user.name?.toLowerCase().contains(
                                searchController.text.toLowerCase()) ?? false)
                        .toList();
                    
                    if (users.isEmpty) {
                      Get.snackbar(
                        "Not Found",
                        "No users found with this name",
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    } else {
                      foundUsers.value = users;
                    }
                    
                    isSearching.value = false;
                  },
                  icon: Icon(Icons.search),
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Loading indicator
            Obx(() => isSearching.value
                ? CircularProgressIndicator()
                : SizedBox()),
            
            SizedBox(height: 20),
            
            // Found users list
            Expanded(
              child: Obx(() {
                if (foundUsers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search, size: 100, color: Colors.grey),
                        SizedBox(height: 10),
                        Text(
                          "Search for users by name",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  itemCount: foundUsers.length,
                  itemBuilder: (context, index) {
                    final user = foundUsers[index];
                    
                    return FutureBuilder<bool>(
                      future: contactController.isContact(user.id ?? ''),
                      builder: (context, snapshot) {
                        final isInContacts = snapshot.data ?? false;
                        
                        return Card(
                          elevation: 2,
                          margin: EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(10),
                            leading: CircleAvatar(
                              radius: 30,
                              child: Icon(Icons.person, size: 30),
                            ),
                            title: Text(
                              user.name ?? "Unknown",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(user.email ?? ""),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // زرار إضافة/حذف من الكونتاكتس
                                IconButton(
                                  onPressed: snapshot.connectionState == ConnectionState.waiting 
                                      ? null 
                                      : () async {
                                    if (isInContacts) {
                                      // لو موجود، احذفه
                                      await contactController.deleteContact(user.id ?? '');
                                      Get.snackbar(
                                        "Removed",
                                        "${user.name} removed from contacts",
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Colors.orange,
                                        colorText: Colors.white,
                                      );
                                    } else {
                                      // لو مش موجود، اضيفه
                                      await contactController.saveContact(user);
                                      Get.snackbar(
                                        "Success",
                                        "${user.name} added to contacts",
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Colors.green,
                                        colorText: Colors.white,
                                      );
                                    }
                                    // أعد بناء الواجهة
                                    foundUsers.refresh();
                                  },
                                  icon: Icon(
                                    isInContacts ? Icons.person_remove : Icons.person_add,
                                  ),
                                  color: isInContacts 
                                      ? Colors.red 
                                      : Theme.of(context).colorScheme.primary,
                                  tooltip: isInContacts ? "Remove from contacts" : "Add to contacts",
                                ),
                                // زرار المحادثة
                                IconButton(
                                  onPressed: () {
                                    Get.to(() => ChatPage(userModel: user));
                                  },
                                  icon: Icon(Icons.chat),
                                  color: Colors.blue,
                                  tooltip: "Start chat",
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
