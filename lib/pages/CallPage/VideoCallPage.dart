import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:graduation_swiftchat/config/zego_cloud_config.dart';
import 'package:graduation_swiftchat/controllers/ProfileController.dart';
import 'package:graduation_swiftchat/controllers/chat_controller.dart';
import 'package:graduation_swiftchat/models/user_model.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoCallPage extends StatefulWidget {
  final UserModel target;
  const VideoCallPage({super.key, required this.target});

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> with WidgetsBindingObserver {
  bool _permissionsGranted = false;
  bool _checkingPermissions = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // لما المستخدم يرجع من Settings، نعيد فحص الأذونات
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _checkingPermissions = true;
    });
    
    // فحص حالة الأذونات الحالية
    var micStatus = await Permission.microphone.status;
    var cameraStatus = await Permission.camera.status;
    
    // لو مش ممنوحة، نطلبها
    if (!micStatus.isGranted || !cameraStatus.isGranted) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.microphone,
        Permission.camera,
      ].request();
      
      micStatus = statuses[Permission.microphone]!;
      cameraStatus = statuses[Permission.camera]!;
    }
    
    setState(() {
      _permissionsGranted = micStatus.isGranted && cameraStatus.isGranted;
      _checkingPermissions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    ProfileController profileController = Get.put(ProfileController());
    ChatController chatController = Get.put(ChatController());
    
    // جاري فحص الأذونات
    if (_checkingPermissions) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 20),
              Text(
                "Checking Permissions...",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
    
    // الأذونات مرفوضة
    if (!_permissionsGranted) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.back(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam_off, size: 100, color: Colors.red),
              SizedBox(height: 20),
              Text(
                "Permissions Required",
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  "Please allow camera and microphone access for video calls",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _checkPermissions(),
                    icon: Icon(Icons.refresh),
                    label: Text("Retry"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                    ),
                  ),
                  SizedBox(width: 15),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await openAppSettings();
                    },
                    icon: Icon(Icons.settings),
                    label: Text("Settings"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    
    // فحص إذا كان Zego Cloud مكونفج
    if (ZegoCloudConfig.appId == 0 || ZegoCloudConfig.appSign == "YOUR_APP_SIGN_HERE") {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam_off, size: 100, color: Colors.red),
              SizedBox(height: 20),
              Text(
                "Zego Cloud Not Configured",
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  "Please configure Zego Cloud credentials in zego_cloud_config.dart",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
              SizedBox(height: 30),
              Text(
                "Video calling: ${widget.target.name}",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => Get.back(),
                icon: Icon(Icons.arrow_back),
                label: Text("Go Back"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    var callId = chatController.getRoomId(widget.target.id!);
    return ZegoUIKitPrebuiltCall(
      appID: ZegoCloudConfig.appId,
      appSign: ZegoCloudConfig.appSign,
      userID: profileController.currentUser.value!.id ?? "root",
      userName: profileController.currentUser.value!.name ?? "root",
      callID: callId,
      config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall(),
    );
  }
}


// 123