import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:graduation_swiftchat/models/user_model.dart';
import 'package:graduation_swiftchat/pages/CallPage/AudioCallPage.dart';
import 'package:graduation_swiftchat/pages/CallPage/VideoCallPage.dart';
import 'package:graduation_swiftchat/services/fcm_service.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:graduation_swiftchat/config/images.dart';

class IncomingCallPage extends StatefulWidget {
  final UserModel caller;
  final String callType;
  final String callId;

  const IncomingCallPage({
    super.key,
    required this.caller,
    required this.callType,
    required this.callId,
  });

  @override
  State<IncomingCallPage> createState() => _IncomingCallPageState();
}

class _IncomingCallPageState extends State<IncomingCallPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // تشغيل نغمة الرنين
    FlutterRingtonePlayer().playRingtone();

    // Animation للصورة
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    FlutterRingtonePlayer().stop();
    _animationController.dispose();
    super.dispose();
  }

  // قبول المكالمة
  void _acceptCall() async {
    FlutterRingtonePlayer().stop();
    await FCMService.acceptCall(widget.callId);
    
    Get.back(); // إغلاق شاشة Incoming Call
    
    if (widget.callType == 'audio') {
      Get.to(() => AudioCallPage(target: widget.caller));
    } else {
      Get.to(() => VideoCallPage(target: widget.caller));
    }
  }

  // رفض المكالمة
  void _rejectCall() async {
    FlutterRingtonePlayer().stop();
    await FCMService.rejectCall(widget.callId);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  SizedBox(height: 40),
                  Text(
                    'Incoming ${widget.callType == 'audio' ? 'Audio' : 'Video'} Call',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    widget.caller.name ?? 'Unknown',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Caller Image
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: widget.caller.profileImage != null &&
                          widget.caller.profileImage!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.caller.profileImage!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => CircularProgressIndicator(
                            color: Colors.white,
                          ),
                          errorWidget: (context, url, error) => Image.asset(
                            AssetsImage.boyPic,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          AssetsImage.boyPic,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ),

            // Call Type Icon
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                widget.callType == 'audio' ? Icons.phone : Icons.videocam,
                color: Colors.white,
                size: 40,
              ),
            ),

            // Action Buttons
            Padding(
              padding: EdgeInsets.all(40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Reject Button
                  Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _rejectCall,
                          icon: Icon(
                            Icons.call_end,
                            color: Colors.white,
                            size: 35,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Decline',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  // Accept Button
                  Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _acceptCall,
                          icon: Icon(
                            Icons.call,
                            color: Colors.white,
                            size: 35,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Accept',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
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
