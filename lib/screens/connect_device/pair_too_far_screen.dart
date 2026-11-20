import 'package:flutter/material.dart';
import 'package:moolah/controllers/connectDeviceController.dart';
import 'package:moolah/screens/block_rules/rule_widgets.dart';
import 'package:moolah/util/apptext.dart';
import 'package:moolah/util/colors.dart';
import 'package:moolah/util/common_widgets/common_widgets.dart';

/// Shown when pairing was refused because this phone is more than 1 mile from the child's device.
/// Pops with true when the parent wants to try again.
class PairTooFarScreen extends StatelessWidget {
  const PairTooFarScreen({required this.distanceMeters, super.key});
  final double distanceMeters;

  /// "8.4 miles", "120 miles".
  static String milesText(double meters) {
    final miles = meters / ConnectDeviceController.pairRadiusMeters;
    final shown = miles >= 10 ? miles.round().toString() : miles.toStringAsFixed(1);
    return "$shown miles";
  }

  @override
  Widget build(BuildContext context) {
    return ruleScreen(context, title: "Connect a Device", children: [
      verticalSpace(12),
      Center(child: iconBadge(Icons.wrong_location_outlined, size: 84)),
      verticalSpace(18),
      Center(child: boldText("You're too far from the device", fontSize: 22)),
      verticalSpace(8),
      regularText(
          "You're about ${milesText(distanceMeters)} away. Move within 1 mile of your child's device and try again.",
          fontSize: 15,
          color: AppColors.grey,
          textAlign: TextAlign.center,
          height: 1.5),
      verticalSpace(20),
      infoNote("This keeps anyone who doesn't have your child's phone from pairing with it."),
      verticalSpace(28),
      primaryButton("Try again", onTap: () => Navigator.pop(context, true)),
      verticalSpace(10),
      SizedBox(
        height: 56,
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.darkLightGrey),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: boldText("Back to Home", fontSize: 17),
        ),
      ),
    ]);
  }
}
