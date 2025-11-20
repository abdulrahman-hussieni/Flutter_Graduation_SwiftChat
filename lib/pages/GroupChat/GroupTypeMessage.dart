// ignore_for_file: sized_box_for_whitespace

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:graduation_swiftchat/config/images.dart';
import 'package:graduation_swiftchat/controllers/group_controller.dart';
import 'package:graduation_swiftchat/controllers/image_picker_controller.dart';
import 'package:graduation_swiftchat/models/group_model.dart';
import 'package:graduation_swiftchat/widgets/imager_picker_button_sheet.dart';

class GroupTypeMessage extends StatelessWidget {
  final GroupModel groupModel;
  const GroupTypeMessage({super.key, required this.groupModel});

  @override
  Widget build(BuildContext context) {
    TextEditingController messageController = TextEditingController();
    RxString message = "".obs;
    ImagePickerController imagePickerController =
        Get.put(ImagePickerController());
    GroupController groupController = Get.put(GroupController());
    return Container(
      // margin: EdgeInsets.all(10),
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: Theme.of(context).colorScheme.primaryContainer),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            child: SvgPicture.asset(
              AssetsImage.chatEmoji,
              width: 25,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: (value) {
                message.value = value;
              },
              controller: messageController,
              decoration: const InputDecoration(
                  filled: false, hintText: "Type message ..."),
            ),
          ),
          SizedBox(width: 10),
          Obx(
            () => groupController.selectedImagePath.value == ""
                ? InkWell(
                    onTap: () {
                      ImagePickerBottomSheet(
                          context,
                          groupController.selectedImagePath,
                          imagePickerController);
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      child: SvgPicture.asset(
                        AssetsImage.chatGallarySvg,
                        width: 25,
                      ),
                    ),
                  )
                : SizedBox(),
          ),
          SizedBox(width: 10),
          Obx(
            () => message.value != "" ||
                    groupController.selectedImagePath.value != ""
                ? InkWell(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () {
                      if (groupController.selectedImagePath.value != "") {
                        groupController.sendGroupMessage(
                          messageController.text,
                          groupModel.id!,
                          groupController.selectedImagePath.value,
                        );
                        groupController.selectedImagePath.value = "";
                      } else {
                        groupController.sendGroupMessage(
                          messageController.text,
                          groupModel.id!,
                          "",
                        );
                      }
                      messageController.clear();
                      message.value = "";
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      child: groupController.isLoading.value
                          ? CircularProgressIndicator()
                          : SvgPicture.asset(
                              AssetsImage.chatSendSvg,
                              width: 25,
                            ),
                    ),
                  )
                : Container(
                    width: 30,
                    height: 30,
                    child: SvgPicture.asset(
                      AssetsImage.chatMicSvg,
                      width: 25,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}