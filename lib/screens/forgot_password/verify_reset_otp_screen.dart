import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moolah/controllers/authController.dart';
import 'package:moolah/util/common_widgets/CommonGradientBackground.dart';
import 'package:moolah/util/common_widgets/common_appbar.dart';
import 'package:moolah/util/common_widgets/common_button.dart';
import 'package:moolah/util/common_widgets/common_text_field.dart';
import 'package:moolah/util/common_widgets/loader.dart';
import 'package:moolah/util/customtoast.dart';
import 'package:pinput/pinput.dart';

import '../../util/apptext.dart';
import '../../util/colors.dart';
import '../../util/common_widgets/common_widgets.dart';

class VerifyResetOTPScreen extends StatefulWidget {
  static const screenName = "verify_reset_otp_screen";

  const VerifyResetOTPScreen({super.key});

  @override
  State<VerifyResetOTPScreen> createState() => _VerifyResetOTPScreenState();
}

class _VerifyResetOTPScreenState extends State<VerifyResetOTPScreen> {
  String pin = "";
  String email = "";
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void initState() {
    email = Get.arguments ?? "";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CommonGradientBackground(
      child: GetBuilder<AuthController>(
        builder: (authController) {
          return Loader(
            c: authController,
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  verticalSpace(40),
                  commonAppBar(withIcon: true),
                  Expanded(
                    child: roundedContainer(
                      width: Get.width,
                      borderRadiusWhole: BorderRadius.circular(13)
                          .copyWith(bottomRight: Radius.zero, bottomLeft: Radius.zero),
                      padding: const EdgeInsets.all(20).copyWith(bottom: 0, left: 15, right: 15),
                      margin: const EdgeInsets.all(10).copyWith(bottom: 0),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            bigHeadingText("Reset Password"),
                            verticalSpace(10),
                            subHeadingText("Enter the 6-digit OTP sent to your email and your new password."),
                            verticalSpace(30),
                            Center(
                              child: Pinput(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                keyboardType: TextInputType.number,
                                defaultPinTheme: _pinPutTheme(),
                                focusedPinTheme: _pinPutTheme().copyWith(
                                  decoration: _pinPutTheme().decoration!.copyWith(
                                    border: Border.all(color: AppColors.normalGreen),
                                  ),
                                ),
                                length: 6,
                                onChanged: (val) {
                                  pin = val;
                                },
                              ),
                            ),
                            verticalSpace(30),
                            CustomTextField(
                              hintText: "New Password",
                              textInputType: TextInputType.visiblePassword,
                              textEditingController: passwordController,
                              validators: Validators.password,
                              onChange: (v) => setState(() {}), // Trigger rebuild to update confirm password reference
                            ),
                            CustomTextField(
                              hintText: "Confirm New Password",
                              textInputType: TextInputType.visiblePassword,
                              textEditingController: confirmPasswordController,
                              passwordForConfirmPassword: passwordController.text,
                              validators: Validators.confirmPassword,
                            ),
                            verticalSpace(30),
                            CustomButton(
                              text: "Reset Password",
                              onTap: () {
                                if (pin.length != 6) {
                                  errorToast("Please enter 6-digit OTP");
                                  return;
                                }
                                if (formKey.currentState!.validate()) {
                                  authController.resetPassword(
                                    email,
                                    pin,
                                    passwordController.text.trim(),
                                  );
                                }
                              },
                            ),
                            verticalSpace(20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  PinTheme _pinPutTheme() {
    return PinTheme(
      height: 45,
      width: 45,
      textStyle: textStyle.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
