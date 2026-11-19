import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:moolah/screens/main_menu_profile/screens/change_password/change_password.dart';
import 'package:moolah/util/apptext.dart';
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
    return CommonGradientBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            commonAppBar(heading: "Edit Profile"),
            verticalSpace(8),
            // Avatar with the camera badge for changing the picture.
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 96,
                  width: 96,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.white, boxShadow: softShadow),
                  child: ClipOval(child: SvgPicture.asset(AppImages.person)),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: SvgPicture.asset(AppImages.editProfilePictureIcon),
                ),
              ],
            ),
            verticalSpace(20),
            Expanded(
              child: pageSheet(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                  children: [
                    _label("Full name"),
                    CustomTextField(hintText: "Enter Full Name", otherOne: true, prefixIcon: AppImages.nameField),
                    _label("Email"),
                    CustomTextField(
                        hintText: "Enter Email",
                        otherOne: true,
                        textInputType: TextInputType.emailAddress,
                        prefixIcon: AppImages.emailField),
                    _label("Mobile number"),
                    CustomTextField(
                        hintText: "Enter Mobile No",
                        otherOne: true,
                        textInputType: TextInputType.phone,
                        prefixIcon: AppImages.mobileField),
                    _label("Password"),
                    // Opens the change-password screen rather than editing here.
                    customGestureDetecter(
                      onTap: () => Get.toNamed(ChangePassword.screenName),
                      child: IgnorePointer(
                        child: CustomTextField(
                            hintText: "Change password", otherOne: true, prefixIcon: AppImages.passwordField),
                      ),
                    ),
                    verticalSpace(28),
                    CustomButton(text: "Save Profile", margin: EdgeInsets.zero),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
        child: regularText(text,
            fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.black.withValues(alpha: 0.75)),
      );
}
