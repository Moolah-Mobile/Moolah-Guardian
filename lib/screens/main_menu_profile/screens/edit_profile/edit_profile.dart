import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:moolah/screens/main_menu_profile/screens/change_password/change_password.dart';
import 'package:moolah/util/common_widgets/common_text_field.dart';

import '../../../../util/colors.dart';
import '../../../../util/common_widgets/CommonGradientBackground.dart';
import '../../../../util/common_widgets/common_appbar.dart';
import '../../../../util/common_widgets/common_button.dart';
import '../../../../util/common_widgets/common_widgets.dart';
import '../../../../util/images.dart';

class EditProfile extends StatefulWidget {
  static const screenName = "edit_profile";
  const EditProfile({Key? key}) : super(key: key);

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
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
                      Stack(
                        children: [
                          customProfileViewer(size: 90),
                          Positioned(
                              bottom: 0,
                              right: 0,
                              child: SvgPicture.asset(
                                  AppImages.editProfilePictureIcon))
                        ],
                      ),
                      verticalSpace(40),
                      CustomTextField(
                          hintText: "Enter Full Name",
                          otherOne: true,
                          prefixIcon: AppImages.nameField),
                      verticalSpace(15),
                      CustomTextField(
                          hintText: "Enter Email",
                          otherOne: true,
                          textInputType: TextInputType.emailAddress,
                          prefixIcon: AppImages.emailField),
                      verticalSpace(15),
                      CustomTextField(
                          hintText: "Enter Mobile No",
                          otherOne: true,
                          prefixIcon: AppImages.mobileField),
                      verticalSpace(15),
                      customGestureDetecter(
                        onTap: (){
                          Get.toNamed(ChangePassword.screenName);
                        },
                        child: IgnorePointer(
                          child: CustomTextField(
                              hintText: "Enter Password",
                              otherOne: true,
                              prefixIcon: AppImages.passwordField),
                        ),
                      ),
                      verticalSpace(25),
                      CustomButton(
                        text: "Save Profile",
                        margin: EdgeInsets.zero,
                      ),
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
}
