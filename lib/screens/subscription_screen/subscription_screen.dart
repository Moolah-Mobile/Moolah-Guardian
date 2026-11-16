import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:moolah/controllers/subscription_controller.dart';
import 'package:moolah/helper/models/plan.dart';
import 'package:moolah/util/apptext.dart';
import 'package:moolah/util/colors.dart';
import 'package:moolah/util/common_widgets/common_button.dart';
import 'package:moolah/util/common_widgets/loader.dart';
import 'package:moolah/util/images.dart';

import '../../controllers/authController.dart';
import '../../util/common_widgets/common_widgets.dart';
import '../home/home.dart';
import '../onboard/onboard.dart';

class SubscriptionScreen extends StatefulWidget {
  static const screenName = "subscription_screen";

  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  Plan? selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => Get.find<SubscriptionController>().loadSubscription());
  }

  void _leave() => Get.offAllNamed(Home.screenName);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.normalGreen,
      body: GetBuilder<SubscriptionController>(builder: (c) {
        final choice = selected ?? _defaultChoice(c.currentPlan);
        return Loader(
          c: c,
          child: SafeArea(
            child: Column(
              children: [
                verticalSpace(10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    commonBackButton(onTap: _leave),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            regularText("Current plan: ${c.currentPlan.title}",
                                color: Colors.white, fontWeight: FontWeight.w500),
                            if (_renewalText(c) != null)
                              regularText(_renewalText(c)!,
                                  color: Colors.white, fontWeight: FontWeight.w300, fontSize: 12),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      verticalSpace(6),
                      Center(
                        child: roundedContainer(
                            borderRadius: 100,
                            child: Padding(
                              padding: const EdgeInsets.all(13.0),
                              child: SvgPicture.asset(AppImages.crown),
                            )),
                      ),
                      verticalSpace(12),
                      Center(child: bigHeadingText("Choose your plan", color: Colors.white)),
                      verticalSpace(14),
                      for (final plan in Plan.values)
                        planCard(plan, current: plan == c.currentPlan, selected: plan == choice),
                      verticalSpace(8),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0).copyWith(top: 8),
                  child: CustomButton(
                    text: _buttonText(c, choice),
                    margin: EdgeInsets.zero,
                    onTap: () => _onSubscribe(c, choice),
                  ),
                ),
                verticalSpace(10),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 20,
                  runSpacing: 6,
                  children: [
                    if (!c.currentPlan.isPaid) linkText("Continue with Free", _leave),
                    linkText("Logout", () {
                      Get.find<AuthController>().logout();
                      Get.offAllNamed(OnBoard.screenName);
                    }),
                  ],
                ),
                verticalSpace(16),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// Free users see the cheapest upgrade picked; paid users see their own plan.
  Plan _defaultChoice(Plan current) => current == Plan.free ? Plan.basic : current;

  String _date(DateTime d) => "${d.day}/${d.month}/${d.year}";

  String? _renewalText(SubscriptionController c) {
    final date = c.expiresAt;
    if (!c.currentPlan.isPaid || date == null) return null;
    return "Active until ${_date(date)}";
  }

  String _buttonText(SubscriptionController c, Plan choice) {
    if (choice == Plan.free) {
      return c.currentPlan.isPaid ? "Included in your plan" : "Continue with Free";
    }
    if (choice == c.currentPlan) return "Renew ${choice.title} (+1 month)";
    return c.currentPlan.isPaid ? "Switch to ${choice.title}" : "Subscribe to ${choice.title}";
  }

  Future<void> _onSubscribe(SubscriptionController c, Plan choice) async {
    if (choice == Plan.free) {
      // Free needs no payment; a paid plan simply returns to Free when it runs out.
      if (!c.currentPlan.isPaid) _leave();
      return;
    }
    if (c.currentPlan.isPaid && choice != c.currentPlan && !await _confirmSwitch(c, choice)) return;
    final ok = await c.subscribe(choice);
    if (ok && mounted) setState(() => selected = null);
  }

  /// A switch starts a fresh month on the new plan; time left on the old one isn't carried over.
  Future<bool> _confirmSwitch(SubscriptionController c, Plan choice) async {
    final end = c.expiresAt;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: boldText("Switch to ${choice.title}?", fontSize: 18),
        content: regularText(
            "You'll pay ${choice.priceLabel} and get ${choice.title} for one month from today."
            "${end == null ? "" : " Your ${c.currentPlan.title} plan (active until ${_date(end)}) ends now."}",
            fontSize: 14),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: regularText("Cancel", fontSize: 14)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: regularText("Switch", color: AppColors.normalGreen, fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
    return result == true;
  }

  Widget linkText(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: regularText(text,
          underline: true, fontSize: 12, color: Colors.white, decorationColor: Colors.white),
    );
  }

  Widget planCard(Plan plan, {required bool current, required bool selected}) {
    return GestureDetector(
      onTap: () => setState(() => this.selected = plan),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.lightGreen : AppColors.lightGreen.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? Colors.white : Colors.transparent, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: Colors.white, size: 20),
                  horizontalSpace(10),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(child: bigHeadingText(plan.title, color: Colors.white, fontSize: 18)),
                        if (current) ...[
                          horizontalSpace(8),
                          roundedContainer(
                            borderRadius: 20,
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            child: regularText("Current", fontSize: 10, color: AppColors.normalGreen,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ],
                    ),
                  ),
                  bigHeadingText(plan.isPaid ? "\$${plan.monthlyPrice.toStringAsFixed(2)}" : "\$0",
                      color: Colors.white, fontSize: 18),
                  regularText("/mo", color: Colors.white, fontSize: 12),
                ],
              ),
            ),
            if (selected)
              roundedContainer(
                margin: const EdgeInsets.symmetric(horizontal: 7).copyWith(bottom: 7),
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final h in plan.highlights)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(h.contains("coming soon") ? Icons.schedule : Icons.check,
                                size: 16, color: AppColors.normalGreen),
                            horizontalSpace(8),
                            Expanded(child: regularText(h, fontWeight: FontWeight.w500, fontSize: 13)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
