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
    required this.mbps

});

  String kidId;
  bool isIPad;
  String? image;
  String name;
  String battery;
  String mbps;
  String active;


  @override
  State<SyncDevice> createState() => _SyncDeviceState();
}

class _SyncDeviceState extends State<SyncDevice> {
  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    return customGestureDetecter(
      onTap: (){

        Get.toNamed(SyncDeviceDetailScreen.screenName, arguments: {"kidId": widget.kidId});
      },
      child: roundedContainer(
        width: width,
        color: AppColors.lightGrey,
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.only(top: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 55,
              width: 55,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(1000),
                child: widget.image == null ? ClipRRect(
                    borderRadius: BorderRadius.circular(1000),
                    child: SvgPicture.asset(AppImages.person)) : Image.network(widget.image!,  errorBuilder: (c, e, v) => SvgPicture.asset(AppImages.person)),
              ),
            ),
            horizontalSpace(10),
            Expanded(
              child: Column(
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
                      horizontalSpace(10),
                      SvgPicture.asset(widget.isIPad ? AppImages.iPad : AppImages.mobile),
                      const Spacer(),
                      horizontalSpace(8),
                      regularText("View", color: AppColors.normalGreen, underline: true)
                    ],
                  ),
                  verticalSpace(10),
                  // The three stats share the row and shorten with an ellipsis on narrow screens.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _stat(AppImages.emptyBattery, "${widget.battery}%", shrink: false),
                      horizontalSpace(6),
                      _stat(AppImages.global, "${widget.mbps} Mb per sec"),
                      horizontalSpace(6),
                      _stat(AppImages.clock, "Active ${widget.active}", italic: true),
                    ],
                  )
                ],
              ),
            ),

          ],
        )
      ),
    );
  }

  // A stat with shrink: false (the short battery figure) keeps its full width; the others share the rest.
  Widget _stat(String icon, String text, {bool italic = false, bool shrink = true}) {
    final label = regularText(text,
        color: AppColors.grey, fontSize: 10, italic: italic, maxLines: 1, textOverflow: TextOverflow.ellipsis);
    final stat = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(icon, width: 15, height: 15),
        horizontalSpace(5),
        shrink ? Flexible(child: label) : label,
      ],
    );
    return shrink ? Flexible(child: stat) : stat;
  }
}
