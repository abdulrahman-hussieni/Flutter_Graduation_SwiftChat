import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:graduation_swiftchat/config/images.dart';
import 'package:graduation_swiftchat/controllers/AuthController.dart';
import 'package:graduation_swiftchat/controllers/ProfileController.dart';
import 'package:graduation_swiftchat/controllers/image_picker_controller.dart';
import 'package:graduation_swiftchat/widgets/PrimaryButton.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ProfileController profileController;
  late final AuthController authController;
  late final ImagePickerController imagePickerController;

  final RxBool isEdit = false.obs;
  final RxString imagePath = "".obs;

  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController aboutController;

  @override
  void initState() {
    super.initState();

    // جلب الـ Controllers الموجودة أو إنشاؤها
    profileController = Get.put(ProfileController());
    authController = Get.put(AuthController());
    imagePickerController = Get.put(ImagePickerController());

    // تحميل بيانات المستخدم الحالي (مهم جداً!)
    _loadUserData();
  }

  // تحميل بيانات المستخدم
  Future<void> _loadUserData() async {
    // إعادة تحميل بيانات المستخدم من Firestore
    await profileController.getUserDetails();

    // تهيئة الـ TextControllers بالبيانات الجديدة
    final user = profileController.currentUser.value;
    nameController = TextEditingController(text: user?.name ?? "");
    emailController = TextEditingController(text: user?.email ?? "");
    phoneController = TextEditingController(text: user?.phoneNumber ?? "");
    aboutController = TextEditingController(text: user?.about ?? "");

    // إعادة بناء الـ UI
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    aboutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // عرض loading فقط لو البيانات مش موجودة خالص
      final user = profileController.currentUser.value;
      if (user == null || user.name == null) {
        return Scaffold(
          appBar: AppBar(title: Text("Profile")),
          body: Center(child: CircularProgressIndicator()),
        );
      }
      return Scaffold(
        appBar: AppBar(
          title: Text("Profile"),
          actions: [
            IconButton(
              onPressed: () {
                authController.showLogoutConfirmation();
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
                // height: 300,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
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
                                                  .pickImage(
                                                    ImageSource.gallery,
                                                  );
                                          print(
                                            "Image Picked" + imagePath.value,
                                          );
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
                                                      BorderRadius.circular(
                                                        100,
                                                      ),
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
                                            profileController
                                                        .currentUser
                                                        .value
                                                        ?.profileImage ==
                                                    null ||
                                                profileController
                                                        .currentUser
                                                        .value
                                                        ?.profileImage ==
                                                    ""
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(100),
                                                child: Image.asset(
                                                  profileController
                                                              .currentUser
                                                              .value
                                                              ?.gender ==
                                                          'Female'
                                                      ? AssetsImage.girlPic
                                                      : AssetsImage.boyPic,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(100),
                                                child: CachedNetworkImage(
                                                  imageUrl: profileController
                                                      .currentUser
                                                      .value!
                                                      .profileImage!,
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) =>
                                                      CircularProgressIndicator(),
                                                  errorWidget:
                                                      (context, url, error) =>
                                                          Icon(Icons.error),
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
                                labelText: "Name",
                                prefixIcon: Icon(Icons.person),
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          Obx(
                            () => TextField(
                              controller: aboutController,
                              enabled: isEdit.value,
                              decoration: InputDecoration(
                                filled: isEdit.value,
                                labelText: "About",
                                prefixIcon: Icon(Icons.info),
                              ),
                            ),
                          ),
                          TextField(
                            controller: emailController,
                            enabled: false,
                            decoration: InputDecoration(
                              filled: isEdit.value,
                              labelText: "Email",
                              prefixIcon: Icon(Icons.alternate_email),
                            ),
                          ),
                          Obx(
                            () => TextField(
                              controller: phoneController,
                              enabled: isEdit.value,
                              decoration: InputDecoration(
                                filled: isEdit.value,
                                labelText: "Number",
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
                                        butName: "Save",
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
                                        butName: "Edit",
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
    });
  }
}
