import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:moolah/controllers/homeController.dart';
import 'package:moolah/screens/chat/messaging_screen.dart';
import 'package:moolah/util/apptext.dart';
import 'package:moolah/util/colors.dart';
import 'package:moolah/util/common_widgets/common_appbar.dart';
import 'package:moolah/util/common_widgets/common_widgets.dart';
import 'package:moolah/util/images.dart';

import '../../helper/models/thread_model.dart';
import '../../util/common_widgets/CommonGradientBackground.dart';

class ChatListScreen extends StatelessWidget {

  ChatListScreen({required this.kidId});

  String kidId;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (homeController) {
        List<ThreadModel> threads = homeController.getSelectedKid(kidId).threads;
        return SingleChildScrollView(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  boldText("SMS Monitoring  Enabled"),
                  customGestureDetecter(
                    onTap: (){
                      homeController.enableMSMSMonitoring(kidId: kidId, value: !(homeController.getSelectedKid(kidId).msmsMonitoringStatus??false));
                      // homeController.connectedKids[homeController.getSelectedKidIndex(kidId)].msmsMonitoringStatus = false;
                      homeController.update();
                    },
                      child: customSwitchSMS(value: homeController.getSelectedKid(kidId).msmsMonitoringStatus ?? false, showM: false))
                ],
              ),
              for(int i =0;i<threads.length;i++)
              Column(
                children: [
                  _buildMessageItem(context, AppImages.child1,
                      threads[i].lastMessage?.messageData?.senderNumber??threads[i].lastMessage?.messageData?.senderNumber??"", threads[i].lastMessage?.messageData?.message??"", getSortedTime(threads[i].lastMessage?.messageData?.messageTimeStamp)??""),
                  const Divider(),
                ],
              ),
              verticalSpace(25)
              // _buildMessageItem(context, AppImages.child1,
              //     'John Campbell', "Mom i need 5 more mins", "9:56am"),
              // const Divider(),
              // _buildMessageItem(
              //     context,
              //     AppImages.child2,
              //     "Anna Campbell",
              //     "Mom can i use my device",
              //     "Yesterday")
            ],
          ),
        );
      }
    );
    // return CommonGradientBackground(
    //   child: Padding(
    //     padding: const EdgeInsets.only(top: 10.0, left: 10, right: 10),
    //     child: Column(
    //       children: [
    //         commonAppBar(heading: "Inbox"),
    //         Expanded(
    //           child: SizedBox(
    //             width: double.infinity,
    //             child: DecoratedBox(
    //               decoration: BoxDecoration(
    //                   borderRadius: const BorderRadius.only(
    //                       topLeft: Radius.circular(15),
    //                       topRight: Radius.circular(15)),
    //                   color: AppColors.white),
    //               child: Column(
    //                 crossAxisAlignment: CrossAxisAlignment.start,
    //                 children: [
    //                   Padding(
    //                     padding:
    //                         const EdgeInsets.only(left: 16, right: 16, top: 16),
    //                     child: boldText('Unread - 2', fontSize: 16),
    //                   ),
    //                   const SizedBox(height: 10),
    //                   _buildMessageItem(context, AppImages.child1,
    //                       'John Campbell', "Mom i need 5 more mins", "9:56am"),
    //                   const Divider(),
    //                   _buildMessageItem(
    //                       context,
    //                       AppImages.child2,
    //                       "Anna Campbell",
    //                       "Mom can i use my device",
    //                       "Yesterday")
    //                 ],
    //               ),
    //             ),
    //           ),
    //         )
    //       ],
    //     ),
    //   ),
    // );
  }

  Widget customSwitchSMS({bool showM = true, required bool value}) {
    double size = 35;
    bool switchButton = value;
    return customGestureDetecter(
      onTap: () {
        // setState(() {
        //   switchButton = !switchButton;
        // });
        // if (switchButton) {
        //   // _showAdDialog();
        // } else {}
        // if (!showM) {
        //   Get.back();
        // }
      },
      child: Stack(
        alignment: switchButton ? Alignment.centerRight : Alignment.centerLeft,
        children: [
          roundedContainer(
              borderRadius: 30,
              color:
              switchButton ? AppColors.lightGreen : AppColors.darkLightGrey,
              height: size * 0.65,
              width: size * 1.2),
          Stack(
            alignment: AlignmentDirectional.center,
            children: [
              roundedContainer(
                borderRadius: 30,
                color: Colors.white,
                margin: EdgeInsets.all(size * 0.083), //2.5
                height: size * 0.5,
                width: size * 0.5,
              ),
              if (showM)
                regularText("M!",
                    customFontFamily: fontFamilyPraise,
                    color: switchButton
                        ? AppColors.lightGreen
                        : AppColors.darkLightGrey,
                    fontSize: 11)
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(BuildContext context, String imageRes, String name,
      String message, String time) {
    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MessagingScreen(),
          ),
        );
      },
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(100),
          child: SvgPicture.asset(AppImages.person)),//Image.asset(imageRes),
      title: regularText(name, fontSize: 14, color: AppColors.black),
      subtitle: boldText(message, fontSize: 14, color: AppColors.black, maxLines: 1, textOverflow: TextOverflow.ellipsis),
      trailing: SizedBox(
        width: 68,
        child: Align(
          alignment: Alignment.topCenter,
          child:
              regularText(time, fontSize: 14, color: const Color(0xff6C7072)),
        ),
      ),
    );
  }
}
