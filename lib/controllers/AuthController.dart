import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:graduation_swiftchat/models/user_model.dart';
import 'package:graduation_swiftchat/services/shared_preferences_service.dart';
import 'package:graduation_swiftchat/controllers/ProfileController.dart';

class AuthController extends GetxController {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final db = FirebaseFirestore.instance;
  RxBool isLoading = false.obs;

  Future<void> login(String email, String password) async {
    isLoading.value = true;
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);

      // تحديث الحالة لـ Online بعد تسجيل الدخول
      try {
        await db.collection("users").doc(auth.currentUser!.uid).update({
          'status': 'Online',
          'Status': 'Online',
          'lastActive': DateTime.now().toString(),
          'LastOnlineStatus': DateTime.now().toString(),
        });
      } catch (e) {
        print("Error updating status on login: $e");
      }

      // حفظ session في SharedPreferences
      final userDoc = await db
          .collection("users")
          .doc(auth.currentUser!.uid)
          .get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        await SharedPreferencesService.saveLoginSession(
          userId: auth.currentUser!.uid,
          email: userData['email'] ?? email,
          name: userData['name'] ?? 'User',
        );
      }

      Get.snackbar(
        'Success',
        'Logged in successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
      );
      Get.offAllNamed("/homePage");
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        Get.snackbar(
          'Error',
          'No user found for that email',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 3),
        );
      } else if (e.code == 'wrong-password') {
        Get.snackbar(
          'Error',
          'Wrong password provided',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 3),
        );
      } else if (e.code == 'invalid-credential') {
        Get.snackbar(
          'Error',
          'Invalid email or password. Please check your credentials',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 3),
        );
      } else if (e.code == 'invalid-email') {
        Get.snackbar(
          'Error',
          'The email address is badly formatted',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          'Error',
          'Firebase Auth Error: ${e.message}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 3),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Something went wrong, please try again: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
      );
    }
    isLoading.value = false;
  }

  Future<void> createUser(
    String email,
    String password,
    String name,
    String gender,
  ) async {
    isLoading.value = true;
    try {
      await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await initUserData(email, name, gender);

      // حفظ session في SharedPreferences
      await SharedPreferencesService.saveLoginSession(
        userId: auth.currentUser!.uid,
        email: email,
        name: name,
      );

      Get.snackbar(
        'Success',
        'Account created successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
      );
      Get.offAllNamed("/homePage");
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        Get.snackbar(
          'Error',
          'The password provided is too weak',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 3),
        );
      } else if (e.code == 'email-already-in-use') {
        // Check if user exists in Firestore
        try {
          final userDoc = await db
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

          if (userDoc.docs.isEmpty) {
            // Email exists in Auth but not in Firestore (deleted user)
            // This is an orphaned auth account - user deleted from Firestore
            Get.snackbar(
              'Error',
              'This email is already in use. If you have deleted your account, please remove it from the Firebase Console or contact support.',
              backgroundColor: Colors.red,
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
              duration: Duration(seconds: 5),
            );
          } else {
            Get.snackbar(
              'Error',
              'An account already exists with this email',
              backgroundColor: Colors.red,
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
              duration: Duration(seconds: 3),
            );
          }
        } catch (checkError) {
          Get.snackbar(
            'خطأ',
            'الإيميل مسجل بالفعل',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            duration: Duration(seconds: 3),
          );
        }
      } else if (e.code == 'invalid-email') {
        Get.snackbar(
          'Error',
          'The email address is badly formatted',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          'Error',
          'Firebase Auth Error: ${e.message}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 3),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Something went wrong, please try again: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
      );
    }
    isLoading.value = false;
  }

  Future<void> showLogoutConfirmation() async {
    return Get.dialog(
      AlertDialog(
        title: Text('logout'),
        content: Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('No')),
          TextButton(
            onPressed: () {
              Get.back();
              logoutUser();
            },
            child: Text('Yes'),
          ),
        ],
      ),
    );
  }

  Future<void> logoutUser() async {
    // حفظ آخر ظهور بالدقة عند تسجيل الخروج
    try {
      final now = DateTime.now();
      await db.collection("users").doc(auth.currentUser!.uid).update({
        'status': 'Offline',
        'Status': 'Offline',
        'lastActive': now.toString(),
        'LastOnlineStatus': now.toString(),
        'lastSeenTimestamp': now.millisecondsSinceEpoch, // بالمليسيكند
      });
      print("✏️ Last seen saved: $now");
    } catch (e) {
      print("Error updating status on logout: $e");
    }

    // حذف session من SharedPreferences
    await SharedPreferencesService.clearLoginSession();

    // 🔥 حذف جميع الـ Controllers القديمة
    Get.delete<ProfileController>(force: true);
    Get.delete<AuthController>(force: true);

    await auth.signOut();
    Get.offAllNamed("/authPage");
  }

  Future<void> logOut() async {
    try {
      // حفظ آخر ظهور بالدقة عند تسجيل الخروج
      try {
        final now = DateTime.now();
        await db.collection("users").doc(auth.currentUser!.uid).update({
          'status': 'Offline',
          'Status': 'Offline',
          'lastActive': now.toString(),
          'LastOnlineStatus': now.toString(),
          'lastSeenTimestamp': now.millisecondsSinceEpoch, // بالمليسيكند
        });
        print("✏️ Last seen saved: $now");
      } catch (e) {
        print("Error updating status on logout: $e");
      }

      // حذف session من SharedPreferences
      await SharedPreferencesService.clearLoginSession();

      await auth.signOut();
      Get.snackbar(
        'Success',
        'Logged out successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
      );
      Get.offAllNamed("/authPage"); // welcomePage
    } catch (e) {
      Get.snackbar(
        'Error',
        'Something went wrong, please try again',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
      );
    }
  }

  Future<void> initUserData(String email, String name, String gender) async {
    var newUser = UserModel(
      email: email,
      name: name,
      id: auth.currentUser!.uid,
      status: 'Online',
      lastOnlineStatus: DateTime.now().toString(),
      gender: gender,
    );

    try {
      await db
          .collection('users')
          .doc(auth.currentUser!.uid)
          .set(newUser.toJson());
      // تحديث الحالة لـ Online
      await db.collection('users').doc(auth.currentUser!.uid).update({
        'status': 'Online',
        'Status': 'Online',
        'lastActive': DateTime.now().toString(),
        'LastOnlineStatus': DateTime.now().toString(),
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to initialize user data',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
      );
    }
  }
}
