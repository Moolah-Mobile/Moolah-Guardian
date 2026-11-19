import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:moolah/screens/main_menu_profile/screens/change_password/widget/password_reset.dart';

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
    var width = MediaQuery.of(context).size.width;
    return CommonGradientBackground(
      child: SafeArea(
        child: Column(
          children: [
            commonAppBar(heading: "Change Password"),
            Expanded(
              child: roundedContainer(
                borderRadiusWhole: BorderRadius.circular(28).copyWith(
                    bottomRight: Radius.zero, bottomLeft: Radius.zero),
                padding: const EdgeInsets.all(25).copyWith(bottom: 0, left: 15),
                margin: const EdgeInsets.all(10).copyWith(bottom: 0),
                width: width,
                child: SingleChildScrollView(
                  child: Form(
                    key: key,
                    child: Column(
                      children: [
                        verticalSpace(20),
                        CustomTextField(
                            textEditingController: oldPasswordController,
                            hintText: "Enter Current Password",
                            otherOne: true,
                            validators: Validators.password,
                            prefixIcon: AppImages.passwordField),
                        verticalSpace(15),
                        CustomTextField(
                            textEditingController: newPasswordController,
                            hintText: "Enter New Password",
                            otherOne: true,
                            onChange: (e)=>setState((){}),
                            validators: Validators.passwordForSignup,
                            prefixIcon: AppImages.passwordField),
                        verticalSpace(15),
                        CustomTextField(
                            textEditingController: confirmPasswordController,
                            hintText: "Confirm New Password",
                            otherOne: true,
                            onChange: (e)=>setState((){}),
                            passwordForConfirmPassword: newPasswordController.text,
                            validators: Validators.confirmPassword,
                            prefixIcon: AppImages.passwordField),

                        verticalSpace(35),
                        CustomButton(
                          text: "Save Password",
                          margin: EdgeInsets.zero,
                          onTap: (){
                            if(key.currentState!.validate()) {
                              Get.toNamed(PasswordReset.screenName);
                            }
                          },
                        ),
                        verticalSpace(30),
                      ],
                    ),
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
