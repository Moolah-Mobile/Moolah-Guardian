import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moolah/util/colors.dart';
import 'package:moolah/util/common_widgets/CommonGradientBackground.dart';
import 'package:moolah/util/common_widgets/common_appbar.dart';

import '../../../../controllers/feedbackController.dart';
import '../../../../util/apptext.dart';
import '../../../../util/common_widgets/common_button.dart';
import '../../../../util/common_widgets/common_text_field.dart';
import '../../../../util/common_widgets/common_widgets.dart';

class ContactUsScreen extends StatefulWidget {
  static const screenName = "contactUsScreen";
  const ContactUsScreen({Key? key}) : super(key: key);

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  TextEditingController textEditingController = TextEditingController();
  GlobalKey<FormState> form = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return CommonGradientBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            commonAppBar(heading: "Contact Us"),
            verticalSpace(12),
            Expanded(
              child: pageSheet(
                child: Form(
                  key: form,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 28, 16, 40),
                    children: [
                      iconBadge(Icons.support_agent_rounded, size: 56),
                      verticalSpace(16),
                      sheetIntro("We'd love to hear from you",
                          "Questions, problems or ideas: send us a message and our team will get back to you."),
                      verticalSpace(10),
                      CustomTextField(
                          hintText: "Message",
                          placeholder: "How can we help?",
                          maxLines: 6,
                          textEditingController: textEditingController,
                          validators: Validators.notEmpty),
                      CustomButton(
                        text: "Send Message",
                        margin: const EdgeInsets.only(top: 28),
                        onTap: () {
                          if (form.currentState?.validate() ?? false) {
                            Get.find<FeedbackContactController>().postFeedback(textEditingController.text.trim());
                          }
                        },
                      ),
                      verticalSpace(18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.schedule_rounded, size: 16, color: AppColors.grey),
                          horizontalSpace(6),
                          regularText("We usually reply within a day.", fontSize: 12, color: AppColors.grey),
                        ],
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
