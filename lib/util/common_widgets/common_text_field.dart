import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ironsource_mediation/ironsource_mediation.dart';
import 'package:moolah/helper/sharedHelper.dart';
import 'package:moolah/util/apptext.dart';
import 'package:moolah/util/colors.dart';
import 'package:moolah/util/common_widgets/common_widgets.dart';
import 'package:moolah/util/images.dart';

class CustomTextField extends StatefulWidget {
  CustomTextField(
      {required this.hintText,
        this.required = false,
        this.textEditingController,
        this.validators,
        this.textInputType = TextInputType.text,
        this.passwordForConfirmPassword,
        this.onChange,
        this.otherOne = false,
        this.prefixIcon,
        this.maxLines = 1
      });
  final String hintText;
  final String? prefixIcon;
  final bool required;
  final bool otherOne;
  final TextInputType textInputType;
  final TextEditingController? textEditingController;
  final Validators? validators;
  final String? passwordForConfirmPassword;
  final int maxLines;
  final Function(String)? onChange;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool obscure = false;
  bool error = false;
  String errorText = "";
  bool hasInteracted = false;
  late TextEditingController textEditingController;
  FocusNode focusNode = FocusNode();

  @override
  void initState() {
    obscure = widget.textInputType == TextInputType.visiblePassword;
    textEditingController = widget.textEditingController ?? TextEditingController();
    
    if(Prefs.isLoggedIn.get()) {
      focusNode.addListener(() {
        if(focusNode.hasFocus) {
          IronSource.hideBanner();
        } else {
          IronSource.displayBanner();
        }
      });
    }
    super.initState();
  }

  @override
  void didUpdateWidget(covariant CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update local controller if the widget's controller changed
    if (widget.textEditingController != null && widget.textEditingController != oldWidget.textEditingController) {
      textEditingController = widget.textEditingController!;
    }
    
    // If this is a confirmation field and the source password string changed, re-validate immediately
    if (widget.validators == Validators.confirmPassword && 
        oldWidget.passwordForConfirmPassword != widget.passwordForConfirmPassword) {
      if (hasInteracted || textEditingController.text.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _handleValidation(textEditingController.text);
          }
        });
      }
    }
  }

  void _handleValidation(String text) {
    final result = validate(text);
    setState(() {
      errorText = result ?? "";
      error = result != null;
    });
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.otherOne ? otherOneWidget() : Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        verticalSpace(10),
        if(widget.hintText.isNotEmpty)
        Wrap(
          children: [
            subHeadingText(widget.hintText, fontWeight: FontWeight.w500, color: error ? Colors.red : Colors.grey, height: 1.2),
            if (widget.required) boldText("*", color: Colors.red, fontSize: 13)
          ],
        ),
        verticalSpace(10),
        TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          validator: (String? text) {
            final result = validate(text ?? "");
            setState(() {
              errorText = result ?? "";
              error = result != null;
              hasInteracted = true;
            });
            return result != null ? "" : null;
          },
          onChanged: (String? text){
            if (widget.onChange != null) widget.onChange!(text ?? "");
            if(hasInteracted) {
              _handleValidation(text ?? "");
            }
          },
          maxLines: widget.maxLines,
          decoration: InputDecoration(
              errorText: null,
              errorStyle: const TextStyle(height: 0),
              border: error ? errorBorder : border,
              enabledBorder: error ? errorBorder : border,
              focusedBorder: error ? errorBorder : border,
              disabledBorder: error ? errorBorder : border,
              errorBorder: error ? errorBorder : border,
              focusedErrorBorder: error ? errorBorder : border,
              fillColor: AppColors.lightGrey,
              filled: true,
              suffixIcon: widget.textInputType == TextInputType.visiblePassword
                  ? customGestureDetecter(
                onTap: () {
                  setState(() {
                    obscure = !obscure;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: SvgPicture.asset(AppImages.unHideIcon),
                ),
              )
                  : null),
          obscureText: obscure,
          keyboardType: widget.textInputType,
        ),
        if (error)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 5).copyWith(bottom: 0),
          child: regularText(errorText, color: AppColors.red, fontSize: 12),
        )
      ],
    );
  }

  Widget otherOneWidget(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: textEditingController,
          validator: (String? text) {
            final result = validate(text ?? "");
            setState(() {
              errorText = result ?? "";
              error = result != null;
              hasInteracted = true;
            });
            return result != null ? "" : null;
          },
          onChanged: (String? text){
            if (widget.onChange != null) widget.onChange!(text ?? "");
            if(hasInteracted) {
              _handleValidation(text ?? "");
            }
          },
          decoration: InputDecoration(
              errorText: null,
              hintText: widget.hintText,
              errorStyle: const TextStyle(height: 0),
              hintStyle: textStyle.copyWith(fontWeight: FontWeight.w500, color: AppColors.grey9494),
              border: error ? otherErrorBorder : otherBorder,
              enabledBorder: error ? otherErrorBorder : otherBorder,
              focusedBorder: error ? otherErrorBorder : otherBorder,
              disabledBorder: error ? otherErrorBorder : otherBorder,
              errorBorder: error ? otherErrorBorder : otherBorder,
              focusedErrorBorder: error ? otherErrorBorder : otherBorder,
              fillColor: AppColors.lightGrey,
              filled: true,
              prefixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  horizontalSpace(20),
                  SvgPicture.asset(widget.prefixIcon!),
                  horizontalSpace(15),
                ],
              ),
              suffixIcon: widget.textInputType == TextInputType.visiblePassword
                  ? customGestureDetecter(
                onTap: () {
                  setState(() {
                    obscure = !obscure;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: SvgPicture.asset(AppImages.unHideIcon),
                ),
              )
                  : null),
          obscureText: obscure,
          keyboardType: widget.textInputType,
        ),
        if (error)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 5).copyWith(bottom: 0),
          child: regularText(errorText, color: AppColors.red, fontSize: 12),
        )
      ],
    );
  }

  String? validate(String text){
    final valid = widget.validators;
    if(valid != null){
      final trimmedValue = text.trim();
      
      // Basic Empty Check
      if(trimmedValue.isEmpty && (valid == Validators.notEmpty || valid == Validators.email || valid == Validators.password || valid == Validators.confirmPassword || valid == Validators.passwordForSignup)){
        return "Please enter ${widget.hintText}";
      }
      
      if(valid == Validators.email){
        if(!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(trimmedValue)){
          return "Please enter a valid Email";
        }
      }
      
      if(valid == Validators.passwordForSignup){
        RegExp regexPassword = RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$');
        if(!regexPassword.hasMatch(trimmedValue)){
          return "Must be 8+ chars with A-Z, a-z, 0-9, and special char";
        }
      }
      
      if(valid == Validators.password){
        if(trimmedValue.length < 8){
          return "Password must be at least 8 characters";
        }
      }
      
      if(valid == Validators.confirmPassword){
        final compareTo = (widget.passwordForConfirmPassword ?? "").trim();
        if(trimmedValue != compareTo){
          return "Passwords do not match";
        }
      }
    }
    return null;
  }
}

OutlineInputBorder border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(width: 0, color: Colors.transparent));
OutlineInputBorder otherBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(15),
    borderSide: const BorderSide(width: 0, color: Colors.transparent));
OutlineInputBorder errorBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(width: 1, color: Colors.red));
OutlineInputBorder otherErrorBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(15),
    borderSide: const BorderSide(width: 1, color: Colors.red));

enum Validators {notEmpty, email, password, confirmPassword, passwordForSignup}
