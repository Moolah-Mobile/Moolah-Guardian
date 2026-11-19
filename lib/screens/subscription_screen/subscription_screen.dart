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
  /// Picked by the parent, or the plan a locked feature needs (passed as the route argument).
  Plan? selected;
  final couponController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final wanted = Get.arguments;
    if (wanted is Plan && wanted.isPaid) selected = wanted;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = Get.find<SubscriptionController>();
      c.loadSubscription();
      c.loadPlans();
    });
  }

  @override
  void dispose() {
    couponController.dispose();
    super.dispose();
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
          child: Container(
           decoration: BoxDecoration(
             gradient: LinearGradient(
               begin: Alignment.topCenter,
               end: Alignment.bottomCenter,
               colors: [AppColors.onBoard1, AppColors.normalGreen],
             ),
           ),
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
                            pill(
                              color: Colors.white.withValues(alpha: 0.2),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: regularText("Current plan: ${c.currentPlan.title}",
                                  color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            verticalSpace(4),
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
                        child: Container(
                          height: 72,
                          width: 72,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8))],
                          ),
                          child: SvgPicture.asset(AppImages.crown),
                        ),
                      ),
                      verticalSpace(16),
                      Center(child: bigHeadingText("Choose your plan", color: Colors.white, fontSize: 28)),
                      verticalSpace(6),
                      Center(
                        child: regularText("Upgrade any time. Plans renew monthly.",
                            color: Colors.white.withValues(alpha: 0.85), fontSize: 14),
                      ),
                      verticalSpace(20),
                      if (c.isPastDue) ...[
                        pastDueBanner(),
                        verticalSpace(12),
                      ],
                      for (final plan in Plan.values)
                        planCard(c, plan, current: plan == c.currentPlan, selected: plan == choice),
                      if (_needsPayment(c, choice)) couponField(),
                      verticalSpace(8),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0).copyWith(top: 8),
                  child: CustomButton(
                    text: _buttonText(c, choice),
                    margin: EdgeInsets.zero,
                    color: _canAct(c, choice) ? null : Colors.grey.shade600,
                    onTap: _canAct(c, choice) ? () => _onSubscribe(c, choice) : null,
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
    return c.cancelAtPeriodEnd ? "Ends on ${_date(date)}" : "Renews on ${_date(date)}";
  }

  /// A paid plan other than the one the parent already has.
  bool _needsPayment(SubscriptionController c, Plan choice) => choice.isPaid && choice != c.currentPlan;

  /// Free with a paid plan, or the paid plan already held: there's nothing to do.
  bool _canAct(SubscriptionController c, Plan choice) => choice == Plan.free ? !c.currentPlan.isPaid : _needsPayment(c, choice);

  String _buttonText(SubscriptionController c, Plan choice) {
    if (choice == Plan.free) {
      return c.currentPlan.isPaid ? "Included in your plan" : "Continue with Free";
    }
    // Plans renew every month on their own, so there's nothing to buy again.
    if (choice == c.currentPlan) return "Your current plan";
    return c.currentPlan.isPaid ? "Switch to ${choice.title}" : "Subscribe to ${choice.title}";
  }

  Future<void> _onSubscribe(SubscriptionController c, Plan choice) async {
    if (choice == Plan.free) {
      if (!c.currentPlan.isPaid) _leave();
      return;
    }
    if (!_needsPayment(c, choice)) return;
    if (c.currentPlan.isPaid && !await _confirmSwitch(c, choice)) return;
    final ok = await c.subscribe(choice, couponCode: couponController.text);
    if (ok && mounted) {
      couponController.clear();
      setState(() => selected = null);
    }
  }

  Future<bool> _confirmSwitch(SubscriptionController c, Plan choice) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: boldText("Switch to ${choice.title}?", fontSize: 18),
        content: regularText(
            "${choice.title} costs ${c.priceLabel(choice)} and replaces your ${c.currentPlan.title} plan from today.",
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

  Widget pastDueBanner() {
    return roundedContainer(
      color: Colors.orange.shade50,
      borderRadius: 10,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.orange.shade800, size: 20),
          horizontalSpace(10),
          Expanded(
            child: regularText(
                "Your last payment didn't go through. Stripe will try your card again, and your plan stays active meanwhile.",
                fontSize: 13, color: Colors.orange.shade900, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget couponField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 4),
      child: TextField(
        key: const ValueKey("coupon_code"),
        controller: couponController,
        textCapitalization: TextCapitalization.characters,
        textInputAction: TextInputAction.done,
        style: TextStyle(color: AppColors.black, fontFamily: fontFamily, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: "Coupon code (optional)",
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(Icons.local_offer_outlined, color: AppColors.normalGreen, size: 20),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.lightGreen, width: 2),
          ),
        ),
      ),
    );
  }

  Widget linkText(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: regularText(text,
            fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    );
  }

  Widget planCard(SubscriptionController c, Plan plan, {required bool current, required bool selected}) {
    return GestureDetector(
      onTap: () => setState(() => this.selected = plan),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: selected ? AppColors.lightGreen : Colors.white.withValues(alpha: 0.25), width: selected ? 2.5 : 1),
          boxShadow: selected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 24, offset: const Offset(0, 10))]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 18, 16),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 24,
                    width: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? AppColors.normalGreen : Colors.transparent,
                      border: Border.all(color: selected ? AppColors.normalGreen : Colors.white, width: 2),
                    ),
                    child: selected ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
                  ),
                  horizontalSpace(12),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                            child: bigHeadingText(plan.title,
                                color: selected ? AppColors.black : Colors.white, fontSize: 19)),
                        if (current) ...[
                          horizontalSpace(8),
                          pill(
                            color: selected ? AppColors.veryVeryLightGreen : Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            child: regularText("Current", fontSize: 11, color: AppColors.normalGreen,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      bigHeadingText(plan.isPaid ? "\$${c.priceOf(plan).toStringAsFixed(2)}" : "\$0",
                          color: selected ? AppColors.normalGreen : Colors.white, fontSize: 22),
                      regularText("/mo",
                          color: selected ? AppColors.grey : Colors.white.withValues(alpha: 0.8), fontSize: 13),
                    ],
                  ),
                ],
              ),
            ),
            if (selected)
              Container(
                margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.veryVeryLightGreen,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final h in plan.highlights)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 20,
                              width: 20,
                              decoration: BoxDecoration(
                                color: h.contains("coming soon") ? AppColors.greyF0F0 : AppColors.normalGreen,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(h.contains("coming soon") ? Icons.schedule : Icons.check_rounded,
                                  size: 13, color: h.contains("coming soon") ? AppColors.grey : Colors.white),
                            ),
                            horizontalSpace(10),
                            Expanded(child: regularText(h, fontWeight: FontWeight.w500, fontSize: 14, height: 1.3)),
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
