import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:moolah/controllers/authController.dart';
import 'package:moolah/controllers/homeController.dart';
import 'package:moolah/screens/login/login.dart';
import 'package:moolah/screens/main_menu_profile/screens/change_password/change_password.dart';
import 'package:moolah/screens/main_menu_profile/screens/change_password/widget/password_reset.dart';
import 'package:moolah/screens/main_menu_profile/screens/contact_us/contact_us.dart';
import 'package:moolah/screens/main_menu_profile/screens/feedback/feedback.dart';
import 'package:moolah/screens/main_menu_profile/screens/privacy_policy/privacy_policy.dart';
import 'package:moolah/screens/main_menu_profile/screens/profile/profile.dart';
import 'package:moolah/screens/main_menu_profile/screens/tutorial_screen/tutorial_screen.dart';
import 'package:moolah/util/apptext.dart';
import 'package:moolah/util/colors.dart';
import 'package:moolah/util/common_widgets/CommonGradientBackground.dart';
import 'package:moolah/util/common_widgets/common_appbar.dart';
import 'package:moolah/util/common_widgets/common_button.dart';
import 'package:moolah/util/images.dart';

import '../../controllers/subscription_controller.dart';
import '../../helper/sharedHelper.dart';
import '../subscription_screen/subscription_screen.dart';
import '../../util/common_widgets/common_widgets.dart';
import '../onboard/onboard.dart';

class MainMenuProfile extends StatefulWidget {
  static const screenName = "main_menu_profile";
  const MainMenuProfile({Key? key}) : super(key: key);

  @override
  State<MainMenuProfile> createState() => _MainMenuProfileState();
}

class _MainMenuProfileState extends State<MainMenuProfile> {
  @override
  Widget build(BuildContext context) {
    final listEnd = listEndPadding(context, 40);
    return CommonGradientBackground(
        child: SafeArea(
      bottom: false,
      child: GetBuilder<AuthController>(
        builder: (context) {
          final fullName = "${Prefs.firstName.get()} ${Prefs.lastName.get()}".trim();
          final email = Prefs.email.get();
          return Column(
            children: [
              commonAppBar(heading: "Menu"),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, listEnd),
                  children: [
                    // Who is signed in, and their plan (tap to manage it).
                    gradientCard(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                height: 64,
                                width: 64,
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle, color: AppColors.white.withValues(alpha: 0.35)),
                                child: ClipOval(
                                    child: ColoredBox(color: AppColors.white, child: SvgPicture.asset(AppImages.person))),
                              ),
                              horizontalSpace(14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    boldText(fullName.isEmpty ? "Your Name" : fullName,
                                        fontSize: 20, color: AppColors.white,
                                        maxLines: 1, textOverflow: TextOverflow.ellipsis),
                                    if (email.isNotEmpty) ...[
                                      verticalSpace(3),
                                      regularText(email,
                                          fontSize: 13, color: AppColors.white.withValues(alpha: 0.9),
                                          maxLines: 1, textOverflow: TextOverflow.ellipsis),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          verticalSpace(16),
                          GetBuilder<SubscriptionController>(
                            builder: (sub) => customGestureDetecter(
                              onTap: () => Get.toNamed(SubscriptionScreen.screenName),
                              child: glassTile(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: Row(
                                  children: [
                                    const Icon(Icons.workspace_premium_outlined, size: 20, color: Colors.white),
                                    horizontalSpace(10),
                                    Expanded(
                                      child: regularText("${sub.currentPlan.title} plan",
                                          fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.white),
                                    ),
                                    regularText(sub.currentPlan.isPaid ? "Manage" : "Upgrade",
                                        fontSize: 13, color: AppColors.white.withValues(alpha: 0.9)),
                                    const Icon(Icons.chevron_right_rounded, size: 22, color: Colors.white),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _sectionTitle("Account"),
                    _group([
                      option(icon: AppImages.profile, text: "Edit Profile", onTap: () => Get.toNamed(Profile.screenName)),
                      option(icon: AppImages.password, text: "Password", onTap: () => Get.toNamed(ChangePassword.screenName)),
                    ]),
                    _sectionTitle("Help & support"),
                    _group([
                      option(icon: AppImages.tutorial, text: "Tutorials", onTap: () => Get.toNamed(TutorialScreen.screenName)),
                      option(icon: AppImages.feedback, text: "Feedback", onTap: () => Get.toNamed(FeedbackScreen.screenName)),
                      option(icon: AppImages.contactUs, text: "Contact us", onTap: () => Get.toNamed(ContactUsScreen.screenName)),
                      option(icon: AppImages.privacyPolicy, text: "Privacy Policy", onTap: () => Get.toNamed(PrivacyScreen.screenName)),
                    ]),
                    verticalSpace(24),
                    CustomButton(onTap: (){
                      Get.find<AuthController>().logout();
                      Get.offAllNamed(OnBoard.screenName);
                    },text: "Logout", color: AppColors.white, textColor: AppColors.lightRed, border: Border.all(color: AppColors.lightRed.withValues(alpha: 0.3)), icon: AppImages.logout,notExpanded: true,margin: EdgeInsets.zero),
                  ],
                ),
              ),
            ],
          );
        }
      ),
    ));
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(6, 24, 6, 10),
        child: regularText(text.toUpperCase(),
            fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.black.withValues(alpha: 0.55)),
      );

  /// Options stacked in one card, separated by hairlines.
  Widget _group(List<Widget> options) {
    return roundedContainer(
      borderRadius: 20,
      shadow: softShadow,
      child: Column(
        children: [
          for (int i = 0; i < options.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, indent: 66, color: AppColors.greyF0F0),
            options[i],
          ],
        ],
      ),
    );
  }

  Widget option({required String icon, required String text, void Function()? onTap}) {
    return customGestureDetecter(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            roundedContainer(
              height: 38,
              width: 38,
              color: AppColors.veryVeryLightGreen,
              borderRadius: 12,
              padding: const EdgeInsets.all(9),
              child: SvgPicture.asset(icon, colorFilter: ColorFilter.mode(AppColors.normalGreen, BlendMode.srcIn)),
            ),
            horizontalSpace(14),
            Expanded(child: regularText(text, fontSize: 15, fontWeight: FontWeight.w500)),
            Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.grey),
          ],
        ),
      ),
    );
  }
}
