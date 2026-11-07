import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moolah/screens/forgot_password/widget/check_your_email.dart';
import 'package:moolah/screens/login/login.dart';

import '../../controllers/authController.dart';
import '../../util/apptext.dart';
import '../../util/colors.dart';
import '../../util/common_widgets/CommonGradientBackground.dart';
import '../../util/common_widgets/common_appbar.dart';
import '../../util/common_widgets/common_button.dart';
import '../../util/common_widgets/common_text_field.dart';
import '../../util/common_widgets/common_widgets.dart';
import '../../util/common_widgets/loader.dart';

class ForgotPassword extends StatefulWidget {
  static const screenName = "forgot_password";
  const ForgotPassword({Key? key}) : super(key: key);

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  TextEditingController emailController = TextEditingController();

  GlobalKey<FormState> key = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return CommonGradientBackground(
        child: GetBuilder<AuthController>(builder: (authController) {
          return Loader(
            c: authController,
            child: Form(
              key: key,
              child: Column(
                children: [
                  verticalSpace(40),
                  commonAppBar(withIcon: true),
                  Expanded(
                    child: roundedContainer(
                        borderRadiusWhole: BorderRadius.circular(13).copyWith(
                            bottomRight: Radius.zero, bottomLeft: Radius.zero),
                        padding:
                        const EdgeInsets.all(25).copyWith(bottom: 0, left: 15),
                        margin: const EdgeInsets.all(10).copyWith(bottom: 0),
                        width: width,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              bigHeadingText("Forgot Password"),
                              verticalSpace(5),
                              subHeadingText(
                                  "No Worries we will send you reset instructions"),
                              verticalSpace(20),
                              CustomTextField(
                                  hintText: "Email",
                                  textInputType: TextInputType.emailAddress,
                                  textEditingController: emailController,
                                  validators: Validators.email),

                              verticalSpace(30),
                              CustomButton(
                                text: "Reset",
                                margin: EdgeInsets.zero,
                                onTap: () {
                                  if (key.currentState!.validate()) {
                                    authController.forgotPassword(emailController.text.trim());
                                  }
                                },
                              ),
                              verticalSpace(20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  subHeadingText("Already have an account?"),
                                  customGestureDetecter(
                                      onTap: () {
                                        Get.toNamed(Login.screenName);
                                      },
                                      child: subHeadingText(" Login here",
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.black)),
                                ],
                              ),
                              verticalSpace(50),
                            ],
                          ),
                        )),
                  )
                ],
              ),
            ),
          );
        }));
  }
}
