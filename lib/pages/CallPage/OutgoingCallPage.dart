import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:graduation_swiftchat/models/user_model.dart';
import 'package:graduation_swiftchat/pages/CallPage/AudioCallPage.dart';
import 'package:graduation_swiftchat/pages/CallPage/VideoCallPage.dart';
import 'package:graduation_swiftchat/services/fcm_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:graduation_swiftchat/config/images.dart';
import 'dart:async';

class OutgoingCallPage extends StatefulWidget {
  final UserModel receiver;
  final String callType;
  final String callId;

  const OutgoingCallPage({
    super.key,
    required this.receiver,
    required this.callType,
    required this.callId,
  });

  @override
  State<OutgoingCallPage> createState() => _OutgoingCallPageState();
}

class _OutgoingCallPageState extends State<OutgoingCallPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  StreamSubscription? _callStatusSubscription;
  String _callStatus = 'Calling...';

  @override
  void initState() {
    super.initState();

    // Animation للصورة
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // الاستماع لحالة المكالمة
    _listenToCallStatus();

    // إنهاء المكالمة تلقائياً بعد 45 ثانية إذا لم يتم الرد
    Future.delayed(Duration(seconds: 45), () {
      if (mounted && _callStatus == 'Calling...') {
        _endCall();
        Get.snackbar(
          'Call Ended',
          'No answer',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _callStatusSubscription?.cancel();
    super.dispose();
  }

  // الاستماع لحالة المكالمة من Firestore
  void _listenToCallStatus() {
    _callStatusSubscription = FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.callId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;

      String status = snapshot.data()?['status'] ?? 'ringing';

      setState(() {
        if (status == 'accepted') {
          _callStatus = 'Connecting...';
        } else if (status == 'rejected') {
          _callStatus = 'Call Declined';
        } else if (status == 'ended') {
          _callStatus = 'Call Ended';
        } else {
          _callStatus = 'Calling...';
        }
      });

      // إذا تم قبول المكالمة
      if (status == 'accepted') {
        Future.delayed(Duration(seconds: 1), () {
          if (mounted) {
            Get.back(); // إغلاق شاشة Outgoing Call
            if (widget.callType == 'audio') {
              Get.to(() => AudioCallPage(target: widget.receiver));
            } else {
              Get.to(() => VideoCallPage(target: widget.receiver));
            }
          }
        });
      }

      // إذا تم رفض المكالمة
      if (status == 'rejected' || status == 'ended') {
        Future.delayed(Duration(seconds: 1), () {
          if (mounted) {
            Get.back();
          }
        });
      }
    });
  }

  // إنهاء المكالمة
  void _endCall() async {
    await FCMService.endCall(widget.callId);
    if (mounted) {
      Get.back();
    }
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
                    widget.receiver.name ?? 'Unknown',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    _callStatus,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),

            // Receiver Image
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
                  child: widget.receiver.profileImage != null &&
                          widget.receiver.profileImage!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.receiver.profileImage!,
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

            // Call Type Icon with Animation
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

            // End Call Button
            Padding(
              padding: EdgeInsets.all(40),
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _endCall,
                      icon: Icon(
                        Icons.call_end,
                        color: Colors.white,
                        size: 35,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'End Call',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
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
