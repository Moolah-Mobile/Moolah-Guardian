import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:moolah/controllers/authController.dart';
import 'package:moolah/util/apptext.dart';
import 'package:moolah/util/colors.dart';
import 'package:moolah/util/common_widgets/common_widgets.dart';

import '../images.dart';
import '../mixpanel_events.dart';

class CustomButton extends StatefulWidget {
  CustomButton(
      {this.color,
      this.textColor,
      required this.text,
      this.onTap,
      this.margin,
      this.icon,
        this.notExpanded = false,
        this.isImage = false,
        this.border,
        this.borderRadius = 10
      });

  Color? color;
  Color? textColor;
  void Function()? onTap;
  String text;
  EdgeInsets? margin;
  String? icon;
  BoxBorder? border;
  double borderRadius;
  bool notExpanded;
  bool isImage;

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap != null && _pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    Color bg = widget.color ?? AppColors.black;
    final light = bg.computeLuminance() > 0.5;

    return Padding(
      padding: widget.margin ?? const EdgeInsets.all(10).copyWith(bottom: 0, top: 14),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: AbsorbPointer(
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: AnimatedOpacity(
              opacity: widget.onTap == null ? 0.5 : 1,
              duration: const Duration(milliseconds: 150),
              child: roundedContainer(
                  border: widget.border ??
                      (light ? Border.all(color: AppColors.buttonBorderGrey, width: 1) : null),
                  color: bg,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                  borderRadius: widget.borderRadius < 14 ? 14 : widget.borderRadius,
                  shadow: light
                      ? null
                      : [BoxShadow(color: bg.withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 6))],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: widget.isImage
                              ? Image.asset(widget.icon!, width: 20)
                              : SvgPicture.asset(widget.icon!, width: 22, height: 22),
                        ),
                      widget.notExpanded ? rest() : Flexible(child: rest()),
                    ],
                  )),
            ),
          ),
        ),
      ),
    );
  }

  Widget rest() {
    return regularText(widget.text,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        textAlign: TextAlign.center,
        color: widget.textColor ?? AppColors.white);
  }
}

Widget googleButton(){
  return CustomButton(
    border: Border.all(color: AppColors.buttonBorderGrey),
      color: Colors.white,
      icon: AppImages.googlePng,
      isImage: true,
      notExpanded: true,
      textColor: AppColors.black,
      text: "Sign in with Google",
      onTap: () {


        Get.find<AuthController>().googleSignIn();
      });
}