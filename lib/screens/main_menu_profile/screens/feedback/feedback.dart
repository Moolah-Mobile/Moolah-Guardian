import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:moolah/controllers/feedbackController.dart';
import 'package:moolah/util/apptext.dart';
import 'package:moolah/util/colors.dart';
import 'package:moolah/util/common_widgets/CommonGradientBackground.dart';
import 'package:moolah/util/common_widgets/common_appbar.dart';
import 'package:moolah/util/common_widgets/common_button.dart';
import 'package:moolah/util/common_widgets/common_text_field.dart';

import '../../../../util/common_widgets/common_widgets.dart';
import '../../../../util/images.dart';

class FeedbackScreen extends StatefulWidget {
  static const screenName = "feedbackScreen";
  const FeedbackScreen({Key? key}) : super(key: key);

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  TextEditingController textEditingController = TextEditingController();
  GlobalKey<FormState> form = GlobalKey();
  int rating = 1;

  static const _ratingLabels = ["Poor", "Fair", "Good", "Great", "Excellent"];

  @override
  Widget build(BuildContext context) {
    return CommonGradientBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            commonAppBar(heading: "Feedback"),
            verticalSpace(12),
            Expanded(
              child: pageSheet(
                child: Form(
                  key: form,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16, 28, 16, listEndPadding(context, 40)),
                    children: [
                      iconBadge(Icons.favorite_border_rounded, size: 56),
                      verticalSpace(16),
                      sheetIntro("How are we doing?",
                          "Rate Moolah Guardian and tell us what would make it better for your family."),
                      verticalSpace(24),
                      roundedContainer(
                        borderRadius: 20,
                        color: AppColors.greyFAFA,
                        border: Border.all(color: AppColors.greyF0F0),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Column(
                          children: [
                            RatingBar(
                              initialRating: 1,
                              allowHalfRating: false,
                              itemCount: 5,
                              itemSize: 44,
                              direction: Axis.horizontal,
                              onRatingUpdate: (rate) => setState(() => rating = rate.toInt()),
                              itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                              ratingWidget: RatingWidget(
                                empty: SvgPicture.asset(AppImages.rating),
                                full: SvgPicture.asset(AppImages.ratingFilled),
                                half: SvgPicture.asset(AppImages.ratingFilled),
                              ),
                            ),
                            verticalSpace(10),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: KeyedSubtree(
                                key: ValueKey(rating),
                                child: regularText(_ratingLabels[(rating - 1).clamp(0, 4)],
                                    fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.normalGreen),
                              ),
                            ),
                          ],
                        ),
                      ),
                      verticalSpace(14),
                      CustomTextField(
                          hintText: "Your review",
                          placeholder: "What do you like? What's missing?",
                          maxLines: 5,
                          textEditingController: textEditingController,
                          validators: Validators.notEmpty),
                      CustomButton(
                        text: "Submit Feedback",
                        margin: const EdgeInsets.only(top: 28),
                        onTap: () {
                          if (form.currentState?.validate() ?? false) {
                            Get.find<FeedbackContactController>().postReview(textEditingController.text.trim(), rating);
                          }
                        },
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
