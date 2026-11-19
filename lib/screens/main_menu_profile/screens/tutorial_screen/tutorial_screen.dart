import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:moolah/util/apptext.dart';
import 'package:moolah/util/colors.dart';
import 'package:moolah/util/common_widgets/CommonGradientBackground.dart';
import 'package:moolah/util/common_widgets/common_appbar.dart';
import 'package:moolah/util/common_widgets/common_widgets.dart';
import 'package:moolah/util/images.dart';
import 'package:video_player/video_player.dart';

class TutorialScreen extends StatefulWidget {
  static const screenName = "tutorialScreen";
  const TutorialScreen({Key? key}) : super(key: key);

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  late VideoPlayerController controller;
  ChewieController? cController;

  static const _steps = [
    (Icons.download_rounded, "Install on your child's phone", "Download Moolah Guardian on the device you want to protect."),
    (Icons.qr_code_scanner_rounded, "Connect the device", "Tap Connect a Device on Home and enter the code shown on their phone."),
    (Icons.tune_rounded, "Set the rules", "Open the device to block apps and sites, see usage and track location."),
  ];

  @override
  void initState() {
    controller = VideoPlayerController.asset("assets/tutorial_video/tutorial_video.mp4");
    controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        cController = ChewieController(
          videoPlayerController: controller,
          aspectRatio: controller.value.aspectRatio,
          autoPlay: true,
          allowFullScreen: true,
          materialProgressColors: ChewieProgressColors(
            playedColor: AppColors.lightGreen,
            handleColor: AppColors.white,
            bufferedColor: AppColors.white.withValues(alpha: 0.4),
            backgroundColor: AppColors.white.withValues(alpha: 0.2),
          ),
        );
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    cController?.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = cController != null;
    return CommonGradientBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            commonAppBar(heading: "Tutorial"),
            verticalSpace(12),
            Expanded(
              child: pageSheet(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        color: AppColors.black,
                        child: AspectRatio(
                          aspectRatio: ready ? controller.value.aspectRatio : 16 / 9,
                          child: ready
                              ? Chewie(controller: cController!)
                              : Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.asset(AppImages.videoThumbnail, fit: BoxFit.cover),
                                    Container(color: AppColors.black.withValues(alpha: 0.25)),
                                    const Center(child: CircularProgressIndicator(color: Colors.white)),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    verticalSpace(24),
                    boldText("Getting started", fontSize: 20),
                    verticalSpace(4),
                    regularText("Three steps to protect your child's phone.", fontSize: 14, color: AppColors.grey),
                    verticalSpace(16),
                    for (int i = 0; i < _steps.length; i++) _step(i + 1, _steps[i].$1, _steps[i].$2, _steps[i].$3),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(int number, IconData icon, String title, String body) {
    return roundedContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      borderRadius: 18,
      color: AppColors.greyFAFA,
      border: Border.all(color: AppColors.greyF0F0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          iconBadge(icon, size: 42),
          horizontalSpace(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                regularText("STEP $number",
                    fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.normalGreen),
                verticalSpace(2),
                boldText(title, fontSize: 15),
                verticalSpace(4),
                regularText(body, fontSize: 13, color: AppColors.grey, height: 1.4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
