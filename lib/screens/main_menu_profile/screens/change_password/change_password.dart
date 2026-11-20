import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moolah/screens/main_menu_profile/screens/change_password/widget/password_reset.dart';
import 'package:moolah/util/apptext.dart';
import 'package:moolah/util/colors.dart';

import '../../../../util/common_widgets/CommonGradientBackground.dart';
import '../../../../util/common_widgets/common_appbar.dart';
import '../../../../util/common_widgets/common_button.dart';
import '../../../../util/common_widgets/common_text_field.dart';
import '../../../../util/common_widgets/common_widgets.dart';
import '../../../../util/images.dart';

class ChangePassword extends StatefulWidget {
  static const screenName = "change_password";
  const ChangePassword({Key? key}) : super(key: key);

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  GlobalKey<FormState> key = GlobalKey<FormState>();
  TextEditingController oldPasswordController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return CommonGradientBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            commonAppBar(heading: "Change Password"),
            verticalSpace(12),
            Expanded(
              child: pageSheet(
                child: Form(
                  key: key,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16, 28, 16, listEndPadding(context, 40)),
                    children: [
                      iconBadge(Icons.lock_outline_rounded, size: 56),
                      verticalSpace(16),
                      sheetIntro("Set a new password",
                          "Use at least 8 characters, with upper and lower case letters, a number and a symbol."),
                      verticalSpace(24),
                      CustomTextField(
                          textEditingController: oldPasswordController,
                          hintText: "Enter Current Password",
                          otherOne: true,
                          textInputType: TextInputType.visiblePassword,
                          validators: Validators.password,
                          prefixIcon: AppImages.passwordField),
                      verticalSpace(14),
                      CustomTextField(
                          textEditingController: newPasswordController,
                          hintText: "Enter New Password",
                          otherOne: true,
                          textInputType: TextInputType.visiblePassword,
                          onChange: (e) => setState(() {}),
                          validators: Validators.passwordForSignup,
                          prefixIcon: AppImages.passwordField),
                      verticalSpace(14),
                      CustomTextField(
                          textEditingController: confirmPasswordController,
                          hintText: "Confirm New Password",
                          otherOne: true,
                          textInputType: TextInputType.visiblePassword,
                          onChange: (e) => setState(() {}),
                          passwordForConfirmPassword: newPasswordController.text,
                          validators: Validators.confirmPassword,
                          prefixIcon: AppImages.passwordField),
                      verticalSpace(32),
                      CustomButton(
                        text: "Save Password",
                        margin: EdgeInsets.zero,
                        onTap: () {
                          if (key.currentState!.validate()) {
                            Get.toNamed(PasswordReset.screenName);
                          }
                        },
                      ),
                      verticalSpace(14),
                      Center(
                        child: regularText("You'll stay signed in on this phone.",
                            fontSize: 12, color: AppColors.grey),
                      ),
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
