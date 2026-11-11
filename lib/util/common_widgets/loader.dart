import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moolah/controllers/baseController.dart';
import 'package:moolah/util/colors.dart';

class Loader extends StatelessWidget {
  const Loader({super.key, required this.child, required this.c});
  
  final Widget child;
  final BaseController c;

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    
    return Obx(() {
      final bool loading = c.isLoading;
      
      return PopScope(
        canPop: !loading,
        child: Stack(
          children: [
            SizedBox(
              height: height,
              width: width,
              child: child,
            ),
            if (loading)
              Align(
                alignment: Alignment.center,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  height: height,
                  width: width,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                      child: CircularProgressIndicator(
                        color: AppColors.normalGreen,
                        strokeWidth: 4,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
