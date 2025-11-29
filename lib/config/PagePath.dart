// ignore_for_file: file_names, depend_on_referenced_packages

import 'package:get/get.dart';
import 'package:graduation_swiftchat/pages/Auth/AuthPage.dart';
import 'package:graduation_swiftchat/pages/HomePage/HomePage.dart';
import 'package:graduation_swiftchat/pages/ProfilePage/ProfilePage.dart';
import 'package:graduation_swiftchat/pages/chat/chatPage.dart';
import 'package:graduation_swiftchat/pages/contact_page/contact_page.dart';
import 'package:graduation_swiftchat/pages/FriendRequests/friend_requests_page.dart';
var pagePath=[
  GetPage(
    name: "/authPage",
    page: () => AuthPage(),
    transition: Transition.rightToLeft,
  ),
  GetPage(
    name: "/homePage",
    page: () => HomePage(),
    transition: Transition.rightToLeft,
  ),
  // GetPage(
  //   name: "/chatpage",
  //   page: () => ChatPage(),
  //   transition: Transition.rightToLeft,
  // ),
  GetPage(
    name: "/Profilepage",
    page: () => ProfilePage(),
    transition: Transition.rightToLeft,
  ),
  GetPage(
    name: "/contactPage",
    page: () => ContactPage(),
    transition: Transition.rightToLeft,
  ),
  GetPage(
    name: "/friendRequests",
    page: () => FriendRequestsPage(),
    transition: Transition.rightToLeft,
  ),
];