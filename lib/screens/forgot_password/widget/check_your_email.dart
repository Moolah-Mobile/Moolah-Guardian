import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:moolah/screens/forgot_password/verify_reset_otp_screen.dart';

import '../../../util/apptext.dart';
import '../../../util/colors.dart';
import '../../../util/common_widgets/CommonGradientBackground.dart';
import '../../../util/common_widgets/common_appbar.dart';
import '../../../util/common_widgets/common_button.dart';
import '../../../util/common_widgets/common_widgets.dart';
import '../../../util/images.dart';

class CheckYourEmail extends StatefulWidget {
  static const screenName = "check_your_email";
  const CheckYourEmail({Key? key}) : super(key: key);

  @override
  State<CheckYourEmail> createState() => _CheckYourEmailState();
}

class _CheckYourEmailState extends State<CheckYourEmail> {
  String email = "";

  @override
  void initState() {
    email = Get.arguments ?? "";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return CommonGradientBackground(
      child: SafeArea(
        child: Column(
          children: [
            commonAppBar(withIcon: true),
            verticalSpace(50),
            roundedContainer(
                borderRadius: 20,
                margin: const EdgeInsets.all(15),
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 10),
                width: width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SvgPicture.asset(AppImages.emailCheck),
                    verticalSpace(30),
                    bigHeadingText("Check your Email"),
                    verticalSpace(10),
                    subHeadingText("We sent a password reset OTP to"),
                    subHeadingText(email, color: Colors.black),

                    verticalSpace(20),
                    CustomButton(text: "Enter OTP", onTap: (){
                      Get.toNamed(VerifyResetOTPScreen.screenName, arguments: email);
                    },),
                    verticalSpace(40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        subHeadingText("Didn’t Receive an Email?"),
                        customGestureDetecter(
                            onTap: () {
                              // Resend logic
                            },
                            child: subHeadingText(" Send Again",
                                fontWeight: FontWeight.bold,
                                color: AppColors.black)),
                      ],
                    ),
                  ],
                )
            )
          ],
        ),
      ),
    );
  }
}
