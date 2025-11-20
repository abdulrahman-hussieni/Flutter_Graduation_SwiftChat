import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:graduation_swiftchat/config/PagePath.dart';
import 'package:graduation_swiftchat/config/thems.dart';
import 'package:graduation_swiftchat/controllers/ProfileController.dart';
import 'package:graduation_swiftchat/services/shared_preferences_service.dart';
import 'package:graduation_swiftchat/services/fcm_service.dart';
// import 'package:graduation_swiftchat/controllers/AppController.dart'; // Removed: No update dialog needed
import 'package:graduation_swiftchat/pages/SplashPage/splash_page.dart';
import 'package:graduation_swiftchat/pages/Welcome/welcome_page.dart';
import 'package:graduation_swiftchat/pages/HomePage/HomePage.dart';
import 'firebase_options.dart';

// Background message handler (must be top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('📨 Background Message: ${message.data}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // تهيئة FCM
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FCMService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final ProfileController _profileController = Get.put(ProfileController());
  Widget _initialPage = WelcomePage(); // الصفحة الافتراضية
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLoginStatus();
  }

  // التحقق من وجود session محفوظ
  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await SharedPreferencesService.isLoggedIn();

    if (isLoggedIn) {
      print("✅ User has active session - redirecting to HomePage");
      setState(() {
        _initialPage = HomePage();
        _isChecking = false;
      });
    } else {
      print("ℹ️ No active session - showing WelcomePage");
      setState(() {
        _initialPage = WelcomePage();
        _isChecking = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    // التحقق من وجود user مسجل دخول
    final isLoggedIn = await SharedPreferencesService.isLoggedIn();
    if (!isLoggedIn) return;

    switch (state) {
      case AppLifecycleState.resumed:
        // التطبيق رجع للمقدمة → Online
        print("🟢 App resumed - Setting user Online");
        _profileController.updateUserStatus(isOnline: true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // التطبيق في الخلفية أو اتقفل → Offline + حفظ آخر ظهور
        print("🔴 App paused/closed - Setting user Offline + saving last seen");
        _profileController.updateUserStatus(isOnline: false);
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      getPages: pagePath,
      title: 'Sampark',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: _isChecking
          ? Scaffold(body: Center(child: CircularProgressIndicator()))
          : _initialPage,
    );
  }
}
