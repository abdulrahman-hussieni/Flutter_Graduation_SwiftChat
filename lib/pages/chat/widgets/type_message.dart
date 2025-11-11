import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../../../Config/Images.dart';
import '../../../controllers/chat_controller.dart';
import '../../../controllers/image_picker_controller.dart';
import '../../../models/user_model.dart';
import '../../../widgets/imager_picker_button_sheet.dart';

class TypeMessage extends StatelessWidget {
  final UserModel userModel;
  const TypeMessage({super.key, required this.userModel});

  @override
  Widget build(BuildContext context) {
    ChatController chatController = Get.put(ChatController());
    TextEditingController messageController = TextEditingController();
    RxString message = "".obs;
    ImagePickerController imagePickerController =
    Get.put(ImagePickerController());

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
                print("typing...");
                if (value.isNotEmpty) {
                  print("typing...");
                } else {
                  print("not typing");
                }
              },
              onEditingComplete: () {
                print("onEditingComplete");
              },
              controller: messageController,
              decoration: const InputDecoration(
                  filled: false, hintText: "Type message ..."),
            ),
          ),
          SizedBox(width: 10),
          Obx(
                () => chatController.selectedImagePath.value == ""
                ? InkWell(
              onTap: () async {
                ImagePickerBottomSheet(
                    context,
                    chatController.selectedImagePath,
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
                chatController.selectedImagePath.value != ""
                ? InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () {
                if (messageController.text.isNotEmpty ||
                    chatController.selectedImagePath.value.isNotEmpty) {
                  chatController.sendMessage(
                      userModel.id!, messageController.text, userModel);
                  messageController.clear();
                  message.value = "";
                }
              },
              child: Container(
                width: 30,
                height: 30,
                child: chatController.isLoading.value
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