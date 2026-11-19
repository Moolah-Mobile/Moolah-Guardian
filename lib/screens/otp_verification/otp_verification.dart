import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moolah/controllers/authController.dart';
import 'package:moolah/util/common_widgets/CommonGradientBackground.dart';
import 'package:moolah/util/common_widgets/common_appbar.dart';
import 'package:moolah/util/common_widgets/common_button.dart';
import 'package:moolah/util/common_widgets/loader.dart';
import 'package:moolah/util/customtoast.dart';
import 'package:pinput/pinput.dart';

import '../../util/apptext.dart';
import '../../util/colors.dart';
import '../../util/common_widgets/common_widgets.dart';
import '../onboard/onboard.dart';

class OtpVerification extends StatefulWidget {
  static const screenName = "OtpVerification";

  const OtpVerification({super.key});

  @override
  State<OtpVerification> createState() => _OtpVerificationState();
}

class _OtpVerificationState extends State<OtpVerification> {

  String pin = "";

  @override
  Widget build(BuildContext context) {
    return CommonGradientBackground(
      child: GetBuilder<AuthController>(
        builder: (authController) {
          return Loader(
            c: authController,
            child: Column(
              children: [
                verticalSpace(40),
                commonAppBar(withIcon: true, onTap: () {
                  Get.find<AuthController>().logout();
                  Get.offAllNamed(OnBoard.screenName);
                }),
                Expanded(
                  child: roundedContainer(
                    width: Get.width,
                    borderRadiusWhole: BorderRadius.circular(28)
                        .copyWith(bottomRight: Radius.zero, bottomLeft: Radius.zero),
                    padding:
                    const EdgeInsets.all(20).copyWith(bottom: 0, left: 15, right: 15),
                    margin: const EdgeInsets.all(10).copyWith(bottom: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        bigHeadingText("Verify OTP"),
                        verticalSpace(40),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25.0),
                          child: Pinput(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            keyboardType: TextInputType.phone,
                            defaultPinTheme: _pinPutTheme(),
                            disabledPinTheme: _pinPutTheme(),
                            submittedPinTheme: PinTheme(
                              height: 60,
                              width: 60,
                              textStyle: textStyle.copyWith(
                                  fontSize: 28,
                                  // color: AppColors.blackColor,
                                  fontWeight: FontWeight.w500),
                              decoration: BoxDecoration(
                                color: AppColors.lightGrey,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  // color: AppColors.borderColor,
                                  width: 1,
                                ),
                              ),
                            ),
                            focusedPinTheme: _pinPutTheme(),
                            onChanged: (val) {
                              pin = val;
                            },
                            length: 4,
                            // controller: c.otpController,
                          ),
                        ),
                        verticalSpace(25),
                        CustomButton(text: "Verify", onTap: () {
                          if(pin.length != 4){
                            errorToast("Please enter 4 digit pin");
                            return;
                          }
                          authController.verifyOtp(pin);

                        },)
                      ],
                    )
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  _pinPutTheme() {
    return PinTheme(
      height: 60,
      width: 60,
      textStyle: textStyle.copyWith(fontSize: 18),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(12),
        // border: Border.all(
        //   color: AppColors.borderColor,
        //   width: 1,
        // ),
      ),
    );
  }
}
