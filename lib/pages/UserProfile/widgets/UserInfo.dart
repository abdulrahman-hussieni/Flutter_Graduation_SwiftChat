// ignore_for_file: unused_local_variable, sized_box_for_whitespace, deprecated_member_use

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:graduation_swiftchat/config/images.dart';
import 'package:graduation_swiftchat/controllers/ProfileController.dart';

class LoginUserInfo extends StatelessWidget {
  final String profileImage;
  final String userName;
  final String userEmail;
  final String? gender;
  final VoidCallback? onAudioCall;
  final VoidCallback? onVideoCall;
  final VoidCallback? onChat;
  const LoginUserInfo({
    super.key,
    required this.profileImage,
    required this.userName,
    required this.userEmail,
    this.gender,
    this.onAudioCall,
    this.onVideoCall,
    this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    ProfileController profileController = Get.put(ProfileController());
    return Container(
      padding: EdgeInsets.all(20),
      // height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child:
                            (profileImage.isNotEmpty &&
                                (profileImage.startsWith('http://') ||
                                    profileImage.startsWith('https://')))
                            ? CachedNetworkImage(
                                imageUrl: profileImage,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    CircularProgressIndicator(),
                                errorWidget: (context, url, error) => Icon(
                                  Icons.person,
                                  size: 80,
                                  color: Colors.grey[600],
                                ),
                              )
                            : Image.asset(
                                gender == 'Male'
                                    ? AssetsImage.boyPic
                                    : AssetsImage.girlPic,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      userName,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      userEmail,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    InkWell(
                      onTap: onAudioCall,
                      child: Container(
                        height: 50,
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Theme.of(context).colorScheme.background,
                        ),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              AssetsImage.profileAudioCall,
                              width: 25,
                            ),
                            SizedBox(width: 10),
                            Text(
                              "Call",
                              style: TextStyle(color: Color(0xff039C00)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: onVideoCall,
                      child: Container(
                        height: 50,
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Theme.of(context).colorScheme.background,
                        ),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              AssetsImage.profileVideoCall,
                              width: 25,
                              color: Color(0xffFF9900),
                            ),
                            SizedBox(width: 10),
                            Text(
                              "Video",
                              style: TextStyle(color: Color(0xffFF9900)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: onChat,
                      child: Container(
                        height: 50,
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Theme.of(context).colorScheme.background,
                        ),
                        child: Row(
                          children: [
                            SvgPicture.asset(AssetsImage.appIconSVG, width: 25),
                            SizedBox(width: 10),
                            Text(
                              "Chat",
                              style: TextStyle(color: Color(0xff0057FF)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
