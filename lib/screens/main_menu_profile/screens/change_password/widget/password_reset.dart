import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:moolah/screens/home/home.dart';
import 'package:moolah/util/apptext.dart';
import 'package:moolah/util/colors.dart';
import 'package:moolah/util/common_widgets/CommonGradientBackground.dart';
import 'package:moolah/util/common_widgets/common_appbar.dart';
import 'package:moolah/util/common_widgets/common_button.dart';
import 'package:moolah/util/common_widgets/common_widgets.dart';
import 'package:moolah/util/images.dart';

class PasswordReset extends StatefulWidget {
  static const screenName = "password_reset";
  const PasswordReset({Key? key}) : super(key: key);

  @override
  State<PasswordReset> createState() => _PasswordResetState();
}

class _PasswordResetState extends State<PasswordReset> {
  @override
  Widget build(BuildContext context) {
    return CommonGradientBackground(
      child: SafeArea(
        child: Column(
          children: [
            commonAppBar(withIcon: true),
            const Spacer(),
            roundedContainer(
              borderRadius: 28,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
              width: double.infinity,
              shadow: softShadow,
              child: Column(
                children: [
                  // The success illustration pops in once.
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.6, end: 1),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutBack,
                    builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
                    child: SvgPicture.asset(AppImages.passwordReset, height: 120),
                  ),
                  verticalSpace(24),
                  boldText("Password changed", fontSize: 24),
                  verticalSpace(8),
                  regularText("Your new password is ready to use next time you sign in.",
                      fontSize: 14, color: AppColors.grey, textAlign: TextAlign.center, height: 1.45),
                  CustomButton(
                    text: "Back to Home",
                    margin: const EdgeInsets.only(top: 28),
                    onTap: () => Get.offAllNamed(Home.screenName),
                  ),
                ],
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}
