// ignore_for_file: avoid_print, unnecessary_null_comparison, unnecessary_brace_in_string_interps

import 'dart:io';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:graduation_swiftchat/models/user_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'image_picker_controller.dart';

class ProfileController extends GetxController {
  final auth = FirebaseAuth.instance;
  final db = FirebaseFirestore.instance;
  RxBool isLoading = false.obs;

  Rx<UserModel?> currentUser = UserModel().obs;
  
  // مراقبة حالة النت
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  RxBool isConnectedToInternet = true.obs;

  @override
  void onInit() async {
    super.onInit();
    await getUserDetails();
    
    // بدء مراقبة حالة النت
    _startConnectivityListener();
    
    // تحديث حالة المستخدم لـ Online عند فتح التطبيق
    await updateUserStatus(isOnline: true);
  }
  
  @override
  void onClose() {
    _connectivitySubscription.cancel();
    super.onClose();
  }
  
  // مراقبة حالة النت بشكل مستمر
  void _startConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) async {
      // Check if any connection exists
      bool hasConnection = results.any((result) => 
        result != ConnectivityResult.none
      );
      
      isConnectedToInternet.value = hasConnection;
      
      if (auth.currentUser != null) {
        if (hasConnection) {
          print("✅ Internet connected - Setting Online");
          await updateUserStatus(isOnline: true);
        } else {
          print("❌ Internet disconnected - Setting Offline");
          await updateUserStatus(isOnline: false);
        }
      }
    });
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
  // تحديث حالة المستخدم (Online/Offline)
  Future<void> updateUserStatus({required bool isOnline}) async {
    try {
      await db.collection("users").doc(auth.currentUser!.uid).update({
        'status': isOnline ? 'Online' : 'Offline',
        'Status': isOnline ? 'Online' : 'Offline', // للتوافق مع النموذج القديم
        'lastActive': DateTime.now().toString(),
        'LastOnlineStatus': DateTime.now().toString(), // للتوافق مع النموذج القديم
      });
      print("📱 Status updated: ${isOnline ? 'Online' : 'Offline'}");
    } catch (e) {
      print("Error updating status: $e");
    }
  }

  // جلب حالة مستخدم معين
  Stream<Map<String, dynamic>> getUserStatus(String userId) {
    return db.collection("users").doc(userId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        // جرب lowercase أولاً، لو مش موجود استخدم PascalCase
        String status = data['status'] ?? data['Status'] ?? 'Offline';
        String lastActive = data['lastActive'] ?? data['LastOnlineStatus'] ?? DateTime.now().toString();
        
        return {
          'status': status,
          'lastActive': lastActive,
        };
      }
      return {
        'status': 'Offline',
        'lastActive': DateTime.now().toString(),
      };
    });
  }

  // تنسيق آخر ظهور بشكل مقروء
  String formatLastSeen(String lastActiveString) {
    try {
      DateTime lastActive = DateTime.parse(lastActiveString);
      DateTime now = DateTime.now();
      
      // استخراج الوقت بتنسيق 12 ساعة
      String formattedTime = _formatTime(lastActive);
      
      // حساب الفرق
      Duration difference = now.difference(lastActive);
      
      // لو أقل من ساعة
      if (difference.inMinutes < 1) {
        return "Just now";
      } else if (difference.inMinutes < 60) {
        return "${difference.inMinutes} minutes ago";
      }
      
      // لو نفس اليوم (أكثر من ساعة)
      if (_isSameDay(lastActive, now)) {
        return "Today at $formattedTime";
      }
      
      // لو امبارح
      DateTime yesterday = now.subtract(Duration(days: 1));
      if (_isSameDay(lastActive, yesterday)) {
        return "Yesterday at $formattedTime";
      }
      
      // لو يوم تاني (اعرض التاريخ)
      return _formatDate(lastActive) + " at $formattedTime";
      
    } catch (e) {
      return "Recently";
    }
  }

  // فحص لو نفس اليوم
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  // تنسيق الوقت (12 ساعة)
  String _formatTime(DateTime dateTime) {
    int hour = dateTime.hour;
    int minute = dateTime.minute;
    String period = hour >= 12 ? 'PM' : 'AM';
    
    // تحويل لـ 12 ساعة
    if (hour > 12) {
      hour -= 12;
    } else if (hour == 0) {
      hour = 12;
    }
    
    String minuteStr = minute.toString().padLeft(2, '0');
    return "$hour:$minuteStr $period";
  }

  // تنسيق التاريخ (مثل: 19 Oct)
  String _formatDate(DateTime dateTime) {
    List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return "${dateTime.day} ${months[dateTime.month - 1]}";
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
