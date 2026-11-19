import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:moolah/screens/main_menu_profile/screens/edit_profile/edit_profile.dart';
import 'package:moolah/util/apptext.dart';
import 'package:moolah/util/colors.dart';
import 'package:moolah/util/common_widgets/common_button.dart';

import '../../../../helper/sharedHelper.dart';
import '../../../../util/common_widgets/CommonGradientBackground.dart';
import '../../../../util/common_widgets/common_appbar.dart';
import '../../../../util/common_widgets/common_widgets.dart';
import '../../../../util/images.dart';

class Profile extends StatefulWidget {
  static const screenName = "profile";
  const Profile({Key? key}) : super(key: key);

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return CommonGradientBackground(
      child: SafeArea(
        child: Column(
          children: [
            commonAppBar(heading: "Profile"),
            Expanded(
              child: roundedContainer(
                borderRadiusWhole: BorderRadius.circular(28).copyWith(
                    bottomRight: Radius.zero, bottomLeft: Radius.zero),
                padding: const EdgeInsets.all(25).copyWith(bottom: 0, left: 15, right: 15),
                margin: const EdgeInsets.all(10).copyWith(bottom: 0),
                width: width,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      verticalSpace(10),
                      customProfileViewer(),
                      verticalSpace(10),
                      valueContainers(icon: AppImages.nameField, heading: "Full Name", value: "${Prefs.firstName.get()} ${Prefs.lastName.get()}".trim().isEmpty ? "" : "${Prefs.firstName.get()} ${Prefs.lastName.get()}"),
                      valueContainers(icon: AppImages.emailField, heading: "Email", value: Prefs.email.get().isNotEmpty?Prefs.email.get():""),
                      valueContainers(icon: AppImages.mobileField, heading: "Mobile No.", value: Prefs.phone.get().isNotEmpty?Prefs.phone.get():""),
                      // valueContainers(icon: AppImages.passwordField, heading: "Password", value: "**********"),
                      verticalSpace(20),
                      CustomButton(margin: EdgeInsets.zero,text: "Edit Profile", onTap: (){
                        Get.toNamed(EditProfile.screenName);
                      },),
                      CustomButton(text: "Delete Account", textColor: AppColors.red, color: Colors.transparent),
                      verticalSpace(30),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  valueContainers({required String icon, required String heading, required String value}) {
    return roundedContainer(
        color: AppColors.greyFAFA,
        // color: AppColors.red,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
        margin: const EdgeInsets.only(top: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SvgPicture.asset(icon),
            horizontalSpace(25),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                verticalSpace(3),
                subHeadingText(heading, fontWeight: FontWeight.w500),
                verticalSpace(5),
                subHeadingText(value, fontWeight: FontWeight.w500, color: Colors.black),
              ],
            )
          ],
        )
    );
  }
}
