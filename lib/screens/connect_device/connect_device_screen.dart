import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:moolah/controllers/connectDeviceController.dart';
import 'package:moolah/screens/connect_device/pair_too_far_screen.dart';
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

  Future<void> _connect(ConnectDeviceController controller) async {
    final success = await controller.linkKidByConnectCode(
      context: context,
      code: codeController.text.trim(),
      label: labelController.text.trim(),
    );
    if (success) {
      await _showSuccessDialog();
      return;
    }
    final tooFar = controller.tooFarMeters;
    if (tooFar == null || !mounted) return;
    final retry = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => PairTooFarScreen(distanceMeters: tooFar)));
    if (retry == true && mounted) _connect(controller);
  }

  /// Says pairing needs the parent near the child's device, and why.
  Widget _nearbyNote() {
    return roundedContainer(
      color: AppColors.veryVeryLightGreen,
      borderRadius: 16,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on_outlined, size: 22, color: AppColors.normalGreen),
          horizontalSpace(10),
          Expanded(
            child: regularText(
                "Be within 1 mile of the device. We check both phones' locations before pairing, so no one who "
                "doesn't have your child's phone can pair with it.",
                fontSize: 14,
                height: 1.45),
          ),
        ],
      ),
    );
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
                            gradientCard(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        boldText("Link a new device", fontSize: 20, color: AppColors.white),
                                        verticalSpace(6),
                                        regularText("Enter the connect code shown on your child's device.",
                                            fontSize: 13, color: AppColors.white.withValues(alpha: 0.9), height: 1.4),
                                      ],
                                    ),
                                  ),
                                  horizontalSpace(12),
                                  glassTile(child: const Icon(Icons.link_rounded, color: Colors.white, size: 28)),
                                ],
                              ),
                            ),
                            verticalSpace(14),
                            roundedContainer(
                              color: AppColors.lightGrey,
                              borderRadius: 18,
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  regularText("How to find the code", fontSize: 14, fontWeight: FontWeight.w700),
                                  verticalSpace(10),
                                  _step(1, "Open Moolah on your child's device."),
                                  _step(2, "Find the connect code it shows on screen."),
                                  _step(3, "Type the code below and give the device a name.", last: true),
                                ],
                              ),
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
                            verticalSpace(14),
                            _nearbyNote(),
                            verticalSpace(22),
                            CustomButton(
                              text: "Connect Device",
                              margin: EdgeInsets.zero,
                              onTap: () async {
                                if (!requireDeviceSlot()) return;
                                if (_formKey.currentState!.validate()) _connect(controller);
                              },
                            ),
                            if (controller.progressText != null) ...[
                              verticalSpace(12),
                              Center(
                                child: regularText(controller.progressText!,
                                    fontSize: 14, color: AppColors.grey, textAlign: TextAlign.center),
                              ),
                            ],
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

  /// A numbered line in the "How to find the code" card.
  Widget _step(int number, String text, {bool last = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 22,
            width: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.normalGreen, shape: BoxShape.circle),
            child: regularText("$number", fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.white),
          ),
          horizontalSpace(10),
          Expanded(child: regularText(text, fontSize: 13, height: 1.4)),
        ],
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
