// ignore_for_file: avoid_print, unnecessary_null_comparison, unnecessary_brace_in_string_interps

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:graduation_swiftchat/models/user_model.dart';
import 'package:image_picker/image_picker.dart';

import 'image_picker_controller.dart';

class ProfileController extends GetxController {
  final auth = FirebaseAuth.instance;
  final db = FirebaseFirestore.instance;
  RxBool isLoading = false.obs;

  Rx<UserModel?> currentUser = UserModel().obs;

  @override
  void onInit() async {
    super.onInit();
    await getUserDetails();
  }

  Future<void> getUserDetails() async {
    await db.collection("users").doc(auth.currentUser!.uid).get().then((value) {
      currentUser.value = UserModel.fromJson(value.data()!);
    });
  }

  Future<void> updateProfile(
    String imageUrl,
    String name,
    String about,
    String number,
  ) async {
    isLoading.value = true;
    try {
      final imageLink = await uploadFileToLocalStorage(imageUrl);
      final updatedUser = UserModel(
        id: auth.currentUser!.uid,
        email: auth.currentUser!.email,
        name: name,
        about: about,
        profileImage:
            imageUrl == "" ? currentUser.value!.profileImage : imageLink,
        phoneNumber: number,
      );
      await db.collection("users").doc(auth.currentUser!.uid).set(
        updatedUser.toJson(),
      );
      await getUserDetails();
    } catch (ex) {
      print(ex);
    }
    isLoading.value = false;
  }

  Future<String> uploadFileToLocalStorage(String imageUrl) async {
    try {
      String imagePath = imageUrl;
      if (imageUrl.isEmpty) {
        // Pick image from local storage
        final imagePickerController = Get.put(ImagePickerController());
        imagePath = await imagePickerController.pickImage(ImageSource.gallery);
      }
      // If imagePath is not empty, return it as the local file path
      if (imagePath != null && imagePath.isNotEmpty) {
        return imagePath;
      }
      return "";
    } catch (e) {
      // If no image selected, return empty string
      return "";
    }
  }
  // Future<String> uploadFileToFirebase(String imagePath) async {
  //   final path = "files/${imagePath}";
  //   final file = File(imagePath);
  //   if (imagePath != "") {
  //     try {
  //       final ref = store.ref().child(path).putFile(file);
  //       final uploadTask = await ref.whenComplete(() {});
  //       final downloadImageUrl = await uploadTask.ref.getDownloadURL();
  //       print(downloadImageUrl);
  //       return downloadImageUrl;
  //     } catch (ex) {
  //       print(ex);
  //       return "";
  //     }
  //   }
  //   return "";
  // }
}
