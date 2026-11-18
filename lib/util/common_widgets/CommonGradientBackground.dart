import 'package:flutter/material.dart';

import '../colors.dart';

class CommonGradientBackground extends StatefulWidget {
  CommonGradientBackground({required this.child, this.otherOne = false, this.resizeForKeyboard = true});

  Widget child;
  bool otherOne;
  // False for screens whose only text fields are in dialogs, so the keyboard doesn't squeeze the page.
  bool resizeForKeyboard;

  @override
  State<CommonGradientBackground> createState() => _CommonGradientBackgroundState();
}

class _CommonGradientBackgroundState extends State<CommonGradientBackground> {
  List<Color> colors = [];

  @override
  void initState() {
    List<Color> original = [

      AppColors.white,
      // AppColors.veryLightGreen,
      AppColors.veryLightGreen,
      AppColors.veryLightGreen,
      // AppColors.lightGreen,
      // AppColors.lightGreen,
      AppColors.lightGreen,
      AppColors.normalGreen,
    ];
    if(widget.otherOne){
      colors.addAll([
        AppColors.onBoard1,
        AppColors.onBoard2,
        AppColors.onBoard3,
        AppColors.onBoard4,
        AppColors.onBoard3,
        AppColors.onBoard2,
        AppColors.onBoard1,
      ]);
    }else{
      colors.addAll(original);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    /// FOR THE GRADIENT BACKGROUND ON ALL THE SCREENS

      return Scaffold(
        resizeToAvoidBottomInset: widget.resizeForKeyboard,
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: colors,
                  )),
            ),
            widget.child
          ],
        ),
      );
  }
}
