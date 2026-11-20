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
    final fullName = "${Prefs.firstName.get()} ${Prefs.lastName.get()}".trim();
    final email = Prefs.email.get();
    final phone = Prefs.phone.get();
    return CommonGradientBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            commonAppBar(heading: "Profile"),
            verticalSpace(8),
            // The avatar and name sit on the gradient, above the details sheet.
            Container(
              height: 96,
              width: 96,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.white, boxShadow: softShadow),
              child: ClipOval(child: SvgPicture.asset(AppImages.person)),
            ),
            verticalSpace(12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: boldText(fullName.isEmpty ? "Your Name" : fullName,
                  fontSize: 22, maxLines: 1, textOverflow: TextOverflow.ellipsis),
            ),
            verticalSpace(20),
            Expanded(
              child: pageSheet(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, listEndPadding(context, 40)),
                  children: [
                    regularText("PERSONAL DETAILS",
                        fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.black.withValues(alpha: 0.55)),
                    verticalSpace(10),
                    roundedContainer(
                      borderRadius: 20,
                      color: AppColors.greyFAFA,
                      border: Border.all(color: AppColors.greyF0F0),
                      child: Column(
                        children: [
                          _detail(AppImages.nameField, "Full name", fullName),
                          Divider(height: 1, thickness: 1, indent: 66, color: AppColors.greyF0F0),
                          _detail(AppImages.emailField, "Email", email),
                          Divider(height: 1, thickness: 1, indent: 66, color: AppColors.greyF0F0),
                          _detail(AppImages.mobileField, "Mobile number", phone),
                        ],
                      ),
                    ),
                    verticalSpace(24),
                    CustomButton(
                      margin: EdgeInsets.zero,
                      text: "Edit Profile",
                      onTap: () => Get.toNamed(EditProfile.screenName),
                    ),
                    CustomButton(
                      margin: const EdgeInsets.only(top: 12),
                      text: "Delete Account",
                      textColor: AppColors.lightRed,
                      color: AppColors.white,
                      border: Border.all(color: AppColors.lightRed.withValues(alpha: 0.3)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(String icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          roundedContainer(
            height: 38,
            width: 38,
            color: AppColors.veryVeryLightGreen,
            borderRadius: 12,
            padding: const EdgeInsets.all(10),
            child: SvgPicture.asset(icon, colorFilter: ColorFilter.mode(AppColors.normalGreen, BlendMode.srcIn)),
          ),
          horizontalSpace(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                regularText(label, fontSize: 12, color: AppColors.grey, fontWeight: FontWeight.w500),
                verticalSpace(3),
                regularText(value.isEmpty ? "Not added" : value,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: value.isEmpty ? AppColors.grey9494 : AppColors.black,
                    maxLines: 1,
                    textOverflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
