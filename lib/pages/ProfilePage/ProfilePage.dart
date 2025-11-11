// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_rx/get_rx.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:graduation_swiftchat/controllers/AuthController.dart';
import 'package:graduation_swiftchat/controllers/ProfileController.dart';
import 'package:graduation_swiftchat/controllers/image_picker_controller.dart';
import 'package:graduation_swiftchat/widgets/PrimaryButton.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    RxBool isEdit = false.obs;
    ProfileController profileController = Get.put(ProfileController());
    TextEditingController nameController = TextEditingController(
      text: profileController.currentUser.value!.name,
    );
    TextEditingController emailController = TextEditingController(
      text: profileController.currentUser.value!.email,
    );
    TextEditingController phoneController = TextEditingController(
      text: profileController.currentUser.value!.phoneNumber,
    );
    TextEditingController aboutController = TextEditingController(
      text: profileController.currentUser.value!.about,
    );
    ImagePickerController imagePickerController = Get.put(
      ImagePickerController(),
    );
    RxString imagePath = ''.obs;

    AuthController authController = Get.put(AuthController());
    return Scaffold(
      appBar: AppBar(title: Text('Profile Page'),
        actions: [
          IconButton(
            onPressed: () {
              authController.logOut();
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: ListView(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              //height: 300,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Obx(
                              () => isEdit.value
                                  ? InkWell(
                                      splashColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      onTap: () async {
                                        imagePath.value =
                                            await imagePickerController
                                                .pickImage(ImageSource.gallery);
                                        print("Image Picked" + imagePath.value);
                                      },
                                      child: Container(
                                        height: 200,
                                        width: 200,
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.background,
                                          borderRadius: BorderRadius.circular(
                                            100,
                                          ),
                                        ),
                                        child: imagePath.value == ""
                                            ? Icon(Icons.add)
                                            : ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(100),
                                                child: Image.file(
                                                  File(imagePath.value),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                      ),
                                    )
                                  : Container(
                                      height: 200,
                                      width: 200,
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.background,
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                      ),
                                      child:
                                          profileController.currentUser.value!.profileImage == null || profileController.currentUser.value!.profileImage == ""
                                          ? Icon(Icons.image)
                                          : ClipRRect(
                                            borderRadius:
                                            BorderRadius.circular(100),
                                            child: Image.file(
                                              File(profileController.currentUser.value!.profileImage!),
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
                                            ),
                                          ),
                                    ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Obx(
                          () => TextField(
                            controller: nameController,
                            enabled: isEdit.value,
                            decoration: InputDecoration(
                              filled: isEdit.value,
                              border: OutlineInputBorder(),
                              labelText: 'Name',
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                        ),
                        Obx(
                          () => TextField(
                            controller: aboutController,
                            enabled: isEdit.value,
                            decoration: InputDecoration(
                              filled: isEdit.value,
                              border: OutlineInputBorder(),
                              labelText: 'About',
                              prefixIcon: Icon(Icons.info),
                            ),
                          ),
                        ),
                        Obx(
                          () => TextField(
                            controller: emailController,
                            enabled: false,
                            decoration: InputDecoration(
                              filled: isEdit.value,
                              border: OutlineInputBorder(),
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.alternate_email_rounded),
                            ),
                          ),
                        ),
                        Obx(
                          () => TextField(
                            controller: phoneController,
                            enabled: isEdit.value,
                            decoration: InputDecoration(
                              filled: isEdit.value,
                              border: OutlineInputBorder(),
                              labelText: 'Phone',
                              prefixIcon: Icon(Icons.phone),
                            ),
                          ),
                        ),

                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Obx(
                              () => isEdit.value
                                  ? PrimaryButton(
                                      butName: 'Save',
                                      butIcon: Icons.save,
                                      onTap: () async {
                                        await profileController.updateProfile(
                                          imagePath.value,
                                          nameController.text,
                                          aboutController.text,
                                          phoneController.text,
                                        );

                                        isEdit.value = false;
                                      },
                                    )
                                  : PrimaryButton(
                                      butName: 'Edit',
                                      butIcon: Icons.edit,
                                      onTap: () {
                                        isEdit.value = true;
                                      },
                                    ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
