import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:moolah/screens/sync_device_detail_screen/sync_device_detail_screen.dart';
import 'package:moolah/util/apptext.dart';
import 'package:moolah/util/colors.dart';
import 'package:moolah/util/common_widgets/common_widgets.dart';
import 'package:moolah/util/images.dart';

import '../../../controllers/authController.dart';

class SyncDevice extends StatefulWidget {
  SyncDevice({
    required this.kidId,
    required this.name,
    required this.image,
    required this.active,
    required this.battery,
    this.isIPad = false,
    this.batteryLocked = false,
    this.usageLocked = false,
    this.dataUsedGb,

});

  String kidId;
  bool isIPad;
  // A stat the parent's plan doesn't include shows a padlock instead of its value.
  bool batteryLocked;
  bool usageLocked;
  String? image;
  String name;
  String battery;
  // Data used over the last 7 days in GB, e.g. "1.47"; null until it has loaded.
  String? dataUsedGb;
  String active;


  @override
  State<SyncDevice> createState() => _SyncDeviceState();
}

class _SyncDeviceState extends State<SyncDevice> {
  @override
  Widget build(BuildContext context) {
    return customGestureDetecter(
      onTap: (){

        Get.toNamed(SyncDeviceDetailScreen.screenName, arguments: {"kidId": widget.kidId});
      },
      child: roundedContainer(
        borderRadius: 20,
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(top: 12),
        border: Border.all(color: AppColors.greyF0F0),
        shadow: softShadow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 52,
                  width: 52,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.veryVeryLightGreen),
                  child: ClipOval(
                    child: widget.image == null
                        ? SvgPicture.asset(AppImages.person)
                        : Image.network(widget.image!,
                            fit: BoxFit.cover, errorBuilder: (c, e, v) => SvgPicture.asset(AppImages.person)),
                  ),
                ),
                horizontalSpace(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textStyle.copyWith(
                                  fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.black),
                            ),
                          ),
                          horizontalSpace(6),
                          SvgPicture.asset(widget.isIPad ? AppImages.iPad : AppImages.mobile, height: 14),
                        ],
                      ),
                      verticalSpace(4),
                      Row(
                        children: [
                          SvgPicture.asset(AppImages.clock, width: 12, height: 12),
                          horizontalSpace(5),
                          Flexible(
                            child: regularText("Active ${widget.active}",
                                color: AppColors.grey, fontSize: 12, maxLines: 1, textOverflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(color: AppColors.lightGrey, shape: BoxShape.circle),
                  child: Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.black),
                ),
              ],
            ),
            verticalSpace(12),
            Row(
              children: [
                _stat(AppImages.emptyBattery, "${widget.battery}%", locked: widget.batteryLocked),
                horizontalSpace(8),
                Flexible(child: _stat(AppImages.global, "${widget.dataUsedGb ?? "–"} GB", locked: widget.usageLocked)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // A stat the parent's plan doesn't include shows a padlock instead of its value.
  Widget _stat(String icon, String text, {bool locked = false}) {
    return pill(
      color: AppColors.lightGrey,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(icon, width: 14, height: 14),
          horizontalSpace(6),
          if (locked)
            Icon(Icons.lock_outline, size: 13, color: AppColors.grey)
          else
            Flexible(
              child: regularText(text,
                  color: AppColors.black, fontSize: 12, fontWeight: FontWeight.w500,
                  maxLines: 1, textOverflow: TextOverflow.ellipsis),
            ),
        ],
      ),
    );
  }
}
