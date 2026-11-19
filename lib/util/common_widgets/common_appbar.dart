import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moolah/screens/otp_verification/otp_verification.dart';
import 'package:moolah/util/apptext.dart';
import 'package:moolah/util/common_widgets/common_widgets.dart';

import '../../screens/subscription_screen/subscription_screen.dart';

Widget commonAppBar({bool withIcon = false, String heading = "", void Function()? onTap}){
  return Padding(
    padding: const EdgeInsets.fromLTRB(12, 22, 12, 6),
    child: Row(
      children: [
        commonBackButton(onTap: onTap),
        Expanded(
          child: Center(
            child: withIcon
                ? GestureDetector(
                    onTap: () {
                      Get.toNamed(OtpVerification.screenName);
                    },
                    child: appLogo(size: 100),
                  )
                : boldText(heading, fontSize: 18, maxLines: 1, textOverflow: TextOverflow.ellipsis),
          ),
        ),
        // Balances the back button so the title stays centred.
        const SizedBox(width: 48),
      ],
    ),
  );
}
