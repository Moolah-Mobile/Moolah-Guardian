import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:moolah/util/images.dart';

import '../apptext.dart';
import '../colors.dart';


/// Stripe publishable key. It must come from the same Stripe account and mode as the backend's secret key,
/// or the payment sheet fails with "No such payment_intent". This is a LIVE key: payments are real charges.
String getStripeSecretKey() {
  return "pk_live_51KO9fgLIMfEj3HFuUuyP1STEfAwtXXjsf1W7iEozlDXaptpKLjTHqq33ajf8gtFvpzGv9v7IXKo9OaGpz3S3Ty9v000JQGtj22";
}



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
      height: 30,
      width: 30,
      padding: const EdgeInsets.all(7.0),
      margin: const EdgeInsets.all(7.0),
      child: SvgPicture.asset(AppImages.backButtonIcon)
    ),
  );
}

Widget roundedContainer({double borderRadius = 7, Color? color, Widget? child, double? height, double? width, EdgeInsets? padding, EdgeInsets? margin, BorderRadius? borderRadiusWhole, BoxBorder? border}){
  return Container(
    height: height,
    width: width,
    padding: padding,
    margin: margin,
    decoration: BoxDecoration(
      border: border,
      borderRadius: borderRadiusWhole ?? BorderRadius.circular(borderRadius),
      color: color ?? AppColors.white
    ),
    child: child,
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
      regularText(s, color: AppColors.grey, fontSize: 10, italic: isItalic)
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
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      condition
          ? Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: regularText(s,
            color: AppColors.white,
            fontWeight: FontWeight.w500,
            fontSize: 10),
      )
          : Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: regularText(s,
            color: unselectedTextColor ?? AppColors.normalGreen,
            fontWeight: FontWeight.w500,
            fontSize: 10),
      ),
    ],
  );
}