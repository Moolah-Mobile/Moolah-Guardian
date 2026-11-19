import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:moolah/controllers/connectDeviceController.dart';
import 'package:moolah/screens/home/home.dart';
import 'package:moolah/util/apptext.dart';
import 'package:moolah/util/colors.dart';
import 'package:moolah/util/common_widgets/CommonGradientBackground.dart';
import 'package:moolah/util/common_widgets/common_appbar.dart';
import 'package:moolah/util/common_widgets/common_button.dart';
import 'package:moolah/util/common_widgets/common_text_field.dart';
import 'package:moolah/util/common_widgets/common_widgets.dart';
import 'package:moolah/util/common_widgets/loader.dart';
import 'package:moolah/util/common_widgets/plan_gate.dart';
import 'package:moolah/util/images.dart';

class ConnectDeviceScreen extends StatefulWidget {
  static const screenName = "connectDeviceScreen";

  const ConnectDeviceScreen({Key? key}) : super(key: key);

  @override
  State<ConnectDeviceScreen> createState() => _ConnectDeviceScreenState();
}

class _ConnectDeviceScreenState extends State<ConnectDeviceScreen> {
  final TextEditingController codeController = TextEditingController();
  final TextEditingController labelController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    labelController.text = "Kid's Device";
  }

  @override
  void dispose() {
    codeController.dispose();
    labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return CommonGradientBackground(
      child: GetBuilder<ConnectDeviceController>(
        builder: (controller) {
          return Loader(
            c: controller,
            child: Column(
              children: [
                verticalSpace(10),
                commonAppBar(withIcon: true),
                Expanded(
                  child: roundedContainer(
                    width: width,
                    borderRadiusWhole: BorderRadius.circular(28).copyWith(
                      bottomRight: Radius.zero,
                      bottomLeft: Radius.zero,
                    ),
                    padding: const EdgeInsets.all(25)
                        .copyWith(bottom: 0, left: 20, right: 20),
                    margin: const EdgeInsets.all(10).copyWith(bottom: 0),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 60,
                              width: 60,
                              decoration: BoxDecoration(
                                color: AppColors.veryVeryLightGreen,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(Icons.link_rounded, size: 30, color: AppColors.normalGreen),
                            ),
                            verticalSpace(18),
                            bigHeadingText(
                              "Link New Device",
                              fontSize: 26,
                              height: 1.2,
                            ),
                            verticalSpace(8),
                            subHeadingText(
                              "Enter the connect code shown on the kid's device to link it.",
                              height: 1.4,
                              color: AppColors.grey,
                            ),
                            verticalSpace(14),
                            CustomTextField(
                              hintText: "Device Label",
                              placeholder: "e.g. John's Tablet",
                              textEditingController: labelController,
                              validators: Validators.notEmpty,
                            ),
                            verticalSpace(6),
                            CustomTextField(
                              hintText: "Connect Code",
                              placeholder: "Code shown on the child's device",
                              textEditingController: codeController,
                              validators: Validators.notEmpty,
                            ),
                            verticalSpace(22),
                            CustomButton(
                              text: "Connect Device",
                              margin: EdgeInsets.zero,
                              onTap: () async {
                                if (!requireDeviceSlot()) return;
                                if (_formKey.currentState!.validate()) {
                                  final success = await controller.linkKidByConnectCode(
                                    context: context,
                                    code: codeController.text.trim(),
                                    label: labelController.text.trim(),
                                  );
                                  if (success) {
                                    await _showSuccessDialog();
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showSuccessDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Material(
          type: MaterialType.transparency,
          child: Center(
            child: roundedContainer(
              margin: const EdgeInsets.all(28),
              borderRadius: 28,
              padding:
                  const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(AppImages.linkCircle),
                  verticalSpace(20),
                  bigHeadingText("Device Synced", fontSize: 26),
                  verticalSpace(12),
                  subHeadingText(
                    "Congrats! You have successfully\nconnected to your Moolah Device!",
                    textAlign: TextAlign.center,
                  ),
                  verticalSpace(24),
                  CustomButton(
                    text: "Back to Home",
                    onTap: () {
                      Get.offAllNamed(Home.screenName);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
