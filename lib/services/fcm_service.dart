import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:graduation_swiftchat/models/user_model.dart';
import 'package:graduation_swiftchat/pages/CallPage/IncomingCallPage.dart';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // تهيئة FCM
  static Future<void> initialize() async {
    // طلب الأذونات
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('🔔 FCM Permission: ${settings.authorizationStatus}');

    // تهيئة Local Notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        if (response.payload != null) {
          _handleNotificationTap(response.payload!);
        }
      },
    );

    // الحصول على FCM Token
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      print('📱 FCM Token: $token');
      await _saveFCMToken(token);
    }

    // الاستماع لتحديثات Token
    _firebaseMessaging.onTokenRefresh.listen(_saveFCMToken);

    // معالجة الرسائل عندما التطبيق مفتوح
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // معالجة الرسائل عندما التطبيق في الخلفية وتم الضغط عليها
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);

    // معالجة الرسائل عندما التطبيق مقفول تماماً
    RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessageTap(initialMessage);
    }
  }

  // حفظ FCM Token في Firestore
  static Future<void> _saveFCMToken(String token) async {
    try {
      if (_auth.currentUser != null) {
        await _db.collection('users').doc(_auth.currentUser!.uid).update({
          'fcmToken': token,
          'lastTokenUpdate': DateTime.now().toString(),
        });
        print('✅ FCM Token saved to Firestore');
      }
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  // معالجة الرسائل عندما التطبيق مفتوح
  static void _handleForegroundMessage(RemoteMessage message) {
    print('📨 Foreground Message: ${message.data}');

    if (message.data['type'] == 'call') {
      // إظهار شاشة المكالمة الواردة
      _showIncomingCallScreen(message.data);
    } else {
      // إظهار notification عادية
      _showLocalNotification(message);
    }
  }

  // معالجة الضغط على notification من الخلفية
  static void _handleBackgroundMessageTap(RemoteMessage message) {
    print('📨 Background Message Tap: ${message.data}');

    if (message.data['type'] == 'call') {
      _showIncomingCallScreen(message.data);
    }
  }

  // معالجة الضغط على Local Notification
  static void _handleNotificationTap(String payload) {
    print('📨 Notification Tap: $payload');
    // Handle payload
  }

  // إظهار شاشة المكالمة الواردة
  static void _showIncomingCallScreen(Map<String, dynamic> data) {
    UserModel caller = UserModel(
      id: data['callerId'],
      name: data['callerName'],
      email: data['callerEmail'],
      profileImage: data['callerImage'],
    );

    String callType = data['callType'] ?? 'audio';
    String callId = data['callId'] ?? '';

    Get.to(
      () =>
          IncomingCallPage(caller: caller, callType: callType, callId: callId),
    );
  }

  // إظهار Local Notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'swiftchat_channel',
          'SwiftChat Notifications',
          channelDescription: 'SwiftChat app notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'SwiftChat',
      message.notification?.body ?? '',
      details,
      payload: message.data.toString(),
    );
  }

  // 💬 إرسال إشعار رسالة للطرف الآخر
  static Future<void> sendMessageNotification({
    required String receiverId,
    required String senderName,
    required String messageText,
    String? senderImage,
  }) async {
    try {
      // الحصول على FCM Token للمستقبل
      DocumentSnapshot userDoc = await _db
          .collection('users')
          .doc(receiverId)
          .get();
      if (!userDoc.exists) {
        print('❌ User not found');
        return;
      }

      String? fcmToken = (userDoc.data() as Map<String, dynamic>)['fcmToken'];
      if (fcmToken == null) {
        print('❌ FCM Token not found for user');
        return;
      }

      // إرسال notification عبر Firestore (يمكن استخدام Firebase Functions لاحقاً)
      await _db.collection('notifications').add({
        'to': fcmToken,
        'notification': {'title': senderName, 'body': messageText},
        'data': {
          'type': 'message',
          'senderId': _auth.currentUser?.uid,
          'senderName': senderName,
          'senderImage': senderImage ?? '',
        },
        'priority': 'high',
        'timestamp': DateTime.now().toString(),
      });

      print('✅ Message notification sent to $receiverId');
    } catch (e) {
      print('❌ Error sending message notification: $e');
    }
  }

  // 📞 إرسال call notification للطرف الآخر
  static Future<void> sendCallNotification({
    required String receiverId,
    required UserModel caller,
    required String callType,
    required String callId,
  }) async {
    try {
      // الحصول على FCM Token للمستقبل
      DocumentSnapshot userDoc = await _db
          .collection('users')
          .doc(receiverId)
          .get();
      if (!userDoc.exists) {
        print('❌ User not found');
        return;
      }

      String? fcmToken = (userDoc.data() as Map<String, dynamic>)['fcmToken'];
      if (fcmToken == null) {
        print('❌ FCM Token not found for user');
        return;
      }

      // إنشاء call document في Firestore
      await _db.collection('calls').doc(callId).set({
        'callId': callId,
        'callerId': caller.id,
        'callerName': caller.name,
        'callerEmail': caller.email,
        'callerImage': caller.profileImage,
        'receiverId': receiverId,
        'callType': callType,
        'status': 'ringing',
        'timestamp': DateTime.now().toString(),
      });

      print('✅ Call notification sent to $receiverId');
    } catch (e) {
      print('❌ Error sending call notification: $e');
    }
  }

  // إنهاء المكالمة
  static Future<void> endCall(String callId) async {
    try {
      await _db.collection('calls').doc(callId).update({
        'status': 'ended',
        'endTime': DateTime.now().toString(),
      });
      print('✅ Call ended: $callId');
    } catch (e) {
      print('❌ Error ending call: $e');
    }
  }

  // قبول المكالمة
  static Future<void> acceptCall(String callId) async {
    try {
      await _db.collection('calls').doc(callId).update({
        'status': 'accepted',
        'acceptTime': DateTime.now().toString(),
      });
      print('✅ Call accepted: $callId');
    } catch (e) {
      print('❌ Error accepting call: $e');
    }
  }

  // رفض المكالمة
  static Future<void> rejectCall(String callId) async {
    try {
      await _db.collection('calls').doc(callId).update({
        'status': 'rejected',
        'rejectTime': DateTime.now().toString(),
      });
      print('✅ Call rejected: $callId');
    } catch (e) {
      print('❌ Error rejecting call: $e');
    }
  }
}

// Background message handler (يجب أن يكون top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📨 Background Message: ${message.data}');
}
