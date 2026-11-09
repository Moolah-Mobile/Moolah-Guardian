import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/get_core.dart';
import 'package:moolah/controllers/authController.dart';
import 'package:moolah/screens/forgot_password/forgot_password.dart';
import 'package:moolah/screens/signup/signup.dart';
import 'package:moolah/util/common_widgets/loader.dart';

import '../../util/apptext.dart';
import '../../util/colors.dart';
import '../../util/common_widgets/CommonGradientBackground.dart';
import '../../util/common_widgets/common_appbar.dart';
import '../../util/common_widgets/common_button.dart';
import '../../util/common_widgets/common_text_field.dart';
import '../../util/common_widgets/common_widgets.dart';
import '../home/home.dart';

class Login extends StatefulWidget {
  static const screenName = "login";

  Login({this.fromSignup = false});

  bool fromSignup;

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  GlobalKey<FormState> key = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
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
                    padding: const EdgeInsets.all(25)
                        .copyWith(bottom: 0, left: 15),
                    margin: const EdgeInsets.all(10).copyWith(bottom: 0),
                    width: width,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          bigHeadingText("Login"),
                          verticalSpace(5),
                          subHeadingText("Welcome Back"),
                          verticalSpace(20),
                          CustomTextField(
                              hintText: "Email",
                              textInputType: TextInputType.emailAddress,
                              textEditingController: emailController, validators: Validators.email),
                          CustomTextField(
                              hintText: "Password",
                              textInputType: TextInputType.visiblePassword,
                              textEditingController: passwordController,validators: Validators.password),
                          customGestureDetecter(
                            onTap: (){
                              Get.toNamed(ForgotPassword.screenName);
                            },
                            child: Column(
                              children: [
                                verticalSpace(10),
                                Align(
                                    alignment: Alignment.centerRight,
                                    child: subHeadingText("Forgot Password?",
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.normalGreen)),
                                verticalSpace(30),
                              ],
                            ),
                          ),
                          CustomButton(
                            text: "Login",
                            margin: EdgeInsets.zero,
                            onTap: () {
                              if(key.currentState!.validate()){
                                authController.emailGlob = emailController.text;
                                authController.passwordGlob = passwordController.text;
                                authController.login();
                              }
                            },
                          ),
                          verticalSpace(20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              subHeadingText("Don’t have an account?"),
                              customGestureDetecter(
                                  onTap: () {
                                    if (widget.fromSignup) {
                                      Get.back();
                                    } else {
                                      Get.toNamed(SignUp.screenName);
                                    }
                                  },
                                  child: subHeadingText(" Signup here",
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
