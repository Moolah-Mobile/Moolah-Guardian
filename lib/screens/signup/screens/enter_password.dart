import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:moolah/screens/login/login.dart';
import 'package:moolah/util/colors.dart';
import 'package:moolah/util/common_widgets/common_button.dart';
import 'package:moolah/util/common_widgets/loader.dart';

import '../../../controllers/authController.dart';
import '../../../util/apptext.dart';
import '../../../util/common_widgets/CommonGradientBackground.dart';
import '../../../util/common_widgets/common_appbar.dart';
import '../../../util/common_widgets/common_text_field.dart';
import '../../../util/common_widgets/common_widgets.dart';
import '../../../util/mixpanel_events.dart';
import '../../home/home.dart';

class EnterPasswordSignUp extends StatefulWidget {
  static const screenName = "EnterPasswordSignUp";
  const EnterPasswordSignUp({Key? key}) : super(key: key);

  @override
  State<EnterPasswordSignUp> createState() => _EnterPasswordSignUpState();
}

class _EnterPasswordSignUpState extends State<EnterPasswordSignUp> {
  // TextEditingController firstNameController = TextEditingController();
  // TextEditingController lastNameController = TextEditingController();
  // TextEditingController usernameController = TextEditingController();
  // TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  // String phone = "";
  // String withoutCCPhone = "";
  // DateTime? dateOfBirth;
  // bool phoneError = false;
  // bool dateError = false;
  GlobalKey<FormState> key = GlobalKey<FormState>();
  // GlobalKey<FormState> key1 = GlobalKey<FormState>();

  @override
  void initState() {
    Get.find<MixPanelEventsController>().track(MixEvents.viewSignUp3);
    passwordController.text = Get.find<AuthController>().passwordGlob;
    confirmPasswordController.text = Get.find<AuthController>().passwordGlob;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    return CommonGradientBackground(
        child: GetBuilder<AuthController>(builder: (controller) {
          return Loader(
            c: controller,
            child: Column(
              children: [
                verticalSpace(40),
                commonAppBar(withIcon: true),
                Expanded(
                  child: roundedContainer(
                      borderRadiusWhole: BorderRadius.circular(13).copyWith(
                          bottomRight: Radius.zero, bottomLeft: Radius.zero),
                      padding:
                      const EdgeInsets.all(25).copyWith(bottom: 0, left: 15, right: 15),
                      margin: const EdgeInsets.all(10).copyWith(bottom: 0),
                      width: width,
                      child: SingleChildScrollView(
                        child: Form(
                          key: key,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              bigHeadingText("Signup"),
                              verticalSpace(5),
                              subHeadingText(
                                  "Start Securing your devices with Moolah Guardian"),
                              verticalSpace(20),
                              // Row(
                              //   children: [
                              //     Expanded(
                              //         child: CustomTextField(
                              //           hintText: "First Name",
                              //           validators: Validators.notEmpty,
                              //           textEditingController: firstNameController,
                              //         )),
                              //     SizedBox(
                              //       width: 10,
                              //     ),
                              //     Expanded(
                              //         child: CustomTextField(
                              //           hintText: "Last Name",
                              //           validators: Validators.notEmpty,
                              //           textEditingController: lastNameController,
                              //         )),
                              //   ],
                              // ),
                              // verticalSpace(15),
                              // subHeadingText("Phone Number",
                              //     fontWeight: FontWeight.w500,
                              //     color: phoneError?Colors.red:Colors.grey),
                              // verticalSpace(10),
                              // IntlPhoneField(
                              //   key: key1,
                              //   inputFormatters: <TextInputFormatter>[
                              //     FilteringTextInputFormatter.digitsOnly
                              //   ],
                              //   keyboardType: TextInputType.number,
                              //   decoration: InputDecoration(
                              //     counter: const SizedBox.shrink(),
                              //     border: phoneError?errorBorder:border,
                              //     enabledBorder: phoneError?errorBorder:border,
                              //     focusedBorder: phoneError?errorBorder:border,
                              //     disabledBorder: phoneError?errorBorder:border,
                              //     errorBorder: errorBorder,
                              //     focusedErrorBorder: phoneError?errorBorder:border,
                              //     fillColor: AppColors.lightGrey,
                              //     filled: true,
                              //     errorStyle: const TextStyle(height: 0),
                              //     errorText: null,
                              //   ),
                              //   onChanged: (number) {
                              //     phone = number.completeNumber;
                              //     withoutCCPhone = number.number;
                              //     print("phone: $phone");
                              //     print("withoutCCPhone: $withoutCCPhone");
                              //     try{
                              //       if(number.isValidNumber()){
                              //         phoneError = false;
                              //       }else{
                              //         phoneError = true;
                              //       }
                              //     }catch(e){
                              //       phoneError = true;
                              //     }
                              //     setState(() {
                              //
                              //     });
                              //   },
                              //   validator: (number) {
                              //     if (number != null) {
                              //       try {
                              //         if (!number.isValidNumber()) {
                              //           return "";
                              //         }
                              //       } catch (e) {}
                              //     }
                              //     return null;
                              //   },
                              // ),
                              // phoneError&&withoutCCPhone.isEmpty?Padding(
                              //   padding: const EdgeInsets.only(left: 12),
                              //   child: errorMsg("Please enter Phone Number"),
                              // ) :const SizedBox.shrink(),
                              // verticalSpace(15),
                              // subHeadingText("Date of Birth",
                              //     fontWeight: FontWeight.w500,
                              //     color: dateError?Colors.red:Colors.grey),
                              // verticalSpace(10),
                              // customGestureDetecter(
                              //   onTap: () async {
                              //     var tempDate = await showDatePicker(
                              //         context: context,
                              //         initialDate:
                              //         DateTime(DateTime.now().year - 20),
                              //         firstDate: DateTime(1940),
                              //         lastDate:
                              //         DateTime(DateTime.now().year - 20),
                              //         builder: (context, child) {
                              //           return Theme(
                              //             data: Theme.of(context).copyWith(
                              //               colorScheme: ColorScheme.light(
                              //                 primary: AppColors
                              //                     .normalGreen, // header background color
                              //                 onPrimary: AppColors
                              //                     .black, // header text color
                              //                 onSurface: AppColors
                              //                     .normalGreen, // body text color
                              //               ),
                              //               textButtonTheme: TextButtonThemeData(
                              //                 style: TextButton.styleFrom(
                              //                   foregroundColor: Colors
                              //                       .black, // button text color
                              //                 ),
                              //               ),
                              //             ),
                              //             child: child!,
                              //           );
                              //         });
                              //     if(tempDate!=null){
                              //       dateOfBirth = tempDate;
                              //       dateError = false;
                              //     }
                              //     setState(() {});
                              //   },
                              //   child: roundedContainer(
                              //       borderRadius: 10,
                              //       border: dateError?Border.all(color: AppColors.red):null,
                              //       padding: EdgeInsets.symmetric(
                              //           vertical: 20, horizontal: 10),
                              //       color: AppColors.lightGrey,
                              //       child: Row(
                              //         children: [
                              //           regularText(dateOfBirth == null
                              //               ? "__\\__\\___"
                              //               : getSortedDate(dateOfBirth)),
                              //         ],
                              //       )),
                              // ),
                              // dateError?Padding(
                              //   padding: const EdgeInsets.only(left: 10.0, top: 8),
                              //   child: errorMsg("Please enter Date of Birth"),
                              // ):const SizedBox.shrink(),
                              // verticalSpace(10),
                              // CustomTextField(
                              //   hintText: "Username",
                              //   textInputType: TextInputType.emailAddress,
                              //   validators: Validators.notEmpty,
                              //   textEditingController: usernameController,
                              // ),
                              // CustomTextField(
                              //   hintText: "Email",
                              //   required: true,
                              //   textInputType: TextInputType.emailAddress,
                              //   validators: Validators.email,
                              //   textEditingController: emailController,
                              // ),
                              // verticalSpace(25),
                              ///
                              CustomTextField(
                                hintText: "Password",
                                textInputType: TextInputType.visiblePassword,
                                validators: Validators.passwordForSignup,
                                textEditingController: passwordController,
                                onChange: (c){setState(() {});},
                              ),
                              CustomTextField(
                                hintText: "Confirm Password",
                                textInputType: TextInputType.visiblePassword,
                                validators: Validators.confirmPassword,
                                textEditingController: confirmPasswordController,
                                passwordForConfirmPassword:
                                passwordController.text,
                              ),
                              verticalSpace(30),
                              CustomButton(
                                  text: "Finish",
                                  margin: EdgeInsets.zero,
                                  onTap: () {
                                    if (key.currentState!.validate()){
                                      Get.find<MixPanelEventsController>().track(MixEvents.signUpComplete);
                                      controller.passwordGlob = passwordController.text.trim();
                                      controller.signup();
                                    }
                                  }),
                              verticalSpace(25),
                              // Row(
                              //   mainAxisAlignment: MainAxisAlignment.center,
                              //   children: [
                              //     subHeadingText("Already have an account?"),
                              //     customGestureDetecter(
                              //         onTap: () {
                              //           Get.toNamed(Login.screenName,
                              //               arguments: {"fromEnterPasswordSignUp": true});
                              //         },
                              //         child: subHeadingText(" Login here",
                              //             fontWeight: FontWeight.bold,
                              //             color: AppColors.black)),
                              //   ],
                              // ),
                              // verticalSpace(20),
                              // googleButton(),
                              // verticalSpace(50),
                            ],
                          ),
                        ),
                      )),
                )
              ],
            ),
          );
        }));
  }

  Widget errorMsg(String s) {
    return regularText(s, color: AppColors.red,fontSize: 11);
  }


}
