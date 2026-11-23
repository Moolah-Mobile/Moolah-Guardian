import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:moolah/helper/env.dart';
import 'package:moolah/util/images.dart';

import '../apptext.dart';
import '../colors.dart';


/// Stripe publishable key. It must come from the same Stripe account and mode as the backend's secret key,
/// or the payment sheet fails with "No such payment_intent". This is a LIVE key: payments are real charges.
String getStripeSecretKey() => Env.stripePublishableKey;



/// Empty space after the last row of a scrolling list, so it doesn't sit against the bottom edge.
const double listEndSpace = 24;

/// [listEndSpace] plus the phone's navigation buttons or gesture bar. Screens draw behind those so the white
/// sheet reaches the bottom edge, so a list's last row (often a button) must end above them.
double listEndPadding(BuildContext context, [double space = listEndSpace]) =>
    space + MediaQuery.paddingOf(context).bottom;


/// APP LOGO
Widget appLogo({double? size}) {
  if(size != null){
    size = size + 20;
  }

 double? height = size;
 double? width = size;
  return SvgPicture.asset(
    AppImages.appLogo2Svg,
    height: height,
    width: width,
  );
}


Widget commonBackButton({void Function()? onTap}){
  return customGestureDetecter(
    onTap: onTap??(){
      Get.back();
    },
    child: roundedContainer(
      height: 40,
      width: 40,
      borderRadius: 12,
      padding: const EdgeInsets.all(12.0),
      margin: const EdgeInsets.all(4.0),
      shadow: softShadow,
      child: SvgPicture.asset(AppImages.backButtonIcon)
    ),
  );
}

/// The light, diffuse shadow cards and floating controls use across the app.
List<BoxShadow> get softShadow => [
      BoxShadow(color: AppColors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4)),
      BoxShadow(color: AppColors.black.withValues(alpha: 0.03), blurRadius: 2, offset: const Offset(0, 1)),
    ];

Widget roundedContainer({double borderRadius = 12, Color? color, Widget? child, double? height, double? width, EdgeInsets? padding, EdgeInsets? margin, BorderRadius? borderRadiusWhole, BoxBorder? border, List<BoxShadow>? shadow}){
  return Container(
    height: height,
    width: width,
    padding: padding,
    margin: margin,
    decoration: BoxDecoration(
      border: border,
      borderRadius: borderRadiusWhole ?? BorderRadius.circular(borderRadius),
      color: color ?? AppColors.white,
      boxShadow: shadow,
    ),
    child: child,
  );
}

/// A small rounded label, such as a device stat or a status.
Widget pill({required Widget child, Color? color, EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4)}) {
  return Container(
    padding: padding,
    decoration: BoxDecoration(color: color ?? AppColors.veryVeryLightGreen, borderRadius: BorderRadius.circular(100)),
    child: child,
  );
}

/// The white panel with rounded top corners that holds a screen's content below its app bar, as on Home.
Widget pageSheet({required Widget child, EdgeInsets? padding}) {
  return Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      boxShadow: softShadow,
    ),
    child: child,
  );
}

/// The green gradient card that leads a screen, as "Add a device" on Home. Text and icons on it are white.
Widget gradientCard({required Widget child, EdgeInsets padding = const EdgeInsets.all(20), EdgeInsets? margin}) {
  return Container(
    margin: margin,
    padding: padding,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.normalGreen, AppColors.onBoard1, AppColors.lightGreen],
      ),
      boxShadow: [
        BoxShadow(color: AppColors.normalGreen.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
      ],
    ),
    child: child,
  );
}

/// A translucent white tile for an icon or a figure on a [gradientCard].
Widget glassTile({required Widget child, EdgeInsets padding = const EdgeInsets.all(12), double borderRadius = 16}) {
  return Container(
    padding: padding,
    decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(borderRadius)),
    child: child,
  );
}

/// A Material icon on a soft green rounded square, used to head cards and list rows.
Widget iconBadge(IconData icon, {double size = 44, Color? color, Color? background}) {
  return Container(
    height: size,
    width: size,
    decoration: BoxDecoration(
        color: background ?? AppColors.veryVeryLightGreen, borderRadius: BorderRadius.circular(size * 0.32)),
    child: Icon(icon, size: size * 0.52, color: color ?? AppColors.normalGreen),
  );
}

/// A screen's heading and a line of explanation, shown at the top of a [pageSheet].
Widget sheetIntro(String title, String subtitle) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      boldText(title, fontSize: 22),
      verticalSpace(6),
      regularText(subtitle, fontSize: 14, color: AppColors.grey, height: 1.45),
    ],
  );
}

Widget customProfileViewer({double size = 80}) {
  return roundedContainer(
      borderRadius: 100,
      height: size,
      width: size,
      // color: Colors.lightGreen,
      child: Center(
          child: SizedBox(
            height: 65,
            width: 65,
            // child: ClipRRect(
            //   child: Image.asset(AppImages.profileImage),
            // ),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(1000),
                child: SvgPicture.asset(AppImages.person)),
          )
      )
  );
}

Widget verticalSpace(double height){
  return SizedBox(height: height,);
}

Widget horizontalSpace(double width){
  return SizedBox(width: width,);
}

Widget customGestureDetecter({required Widget child, void Function()? onTap}){
  return GestureDetector(
    onTap: onTap,
    child: AbsorbPointer(child: child),
  );
}

Widget iconText(String icon, String s, {bool isItalic = false}) {
  double size = 15;
  return Row(
    children: [
      SvgPicture.asset(icon, width: size, height: size,),
      horizontalSpace(5),
      regularText(s, color: AppColors.grey, fontSize: 12, italic: isItalic)
    ],
  );
}

String getSortedDate(DateTime? dateOfBirth, {String sign = "-"}) {
  return "${dateOfBirth!.day < 10 ? ("0${dateOfBirth!.day}") : dateOfBirth!.day}$sign${dateOfBirth!.month < 10 ? ("0${dateOfBirth!.month}") : dateOfBirth!.month}$sign${dateOfBirth!.year}";
}

String? getSortedTime(DateTime? messageTimeStamp) {
  if(messageTimeStamp!=null){
    DateTime messageTimeStampTemp = messageTimeStamp;
    Duration difference = DateTime.now().difference(messageTimeStampTemp);
    String finalDate = "";
    if(difference.inDays == 0){
      return "${messageTimeStampTemp.hour}:${messageTimeStampTemp.minute}"; 
    }else {
      return getSortedDate(messageTimeStampTemp, sign: "/");
    }
  }
  return "";
}

textForTab(String s, bool condition, {Color? unselectedTextColor}) {
  // Scales down rather than overflowing when a long label meets a narrow tab.
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10.0),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: regularText(s,
          color: condition ? AppColors.white : (unselectedTextColor ?? AppColors.normalGreen),
          fontWeight: condition ? FontWeight.w600 : FontWeight.w500,
          fontSize: 13,
          maxLines: 1),
    ),
  );
}
