import 'package:flutter/material.dart';
import 'package:moolah/util/colors.dart';
import 'package:moolah/util/common_widgets/CommonGradientBackground.dart';
import 'package:moolah/util/common_widgets/common_appbar.dart';
import 'package:moolah/util/common_widgets/common_widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PrivacyScreen extends StatefulWidget {
  static const screenName = "privacyScreen";
  const PrivacyScreen({Key? key}) : super(key: key);

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  late WebViewController controller;
  // 0 to 100 while the page loads; the bar under the app bar hides at 100.
  int progress = 0;

  @override
  void initState() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int value) {
            if (mounted) setState(() => progress = value);
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {
            if (mounted) setState(() => progress = 100);
          },
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      // Assumption: privacy policy will be hosted at moolahguardian.com under /privacy-policy.
      ..loadRequest(Uri.parse('https://moolahguardian.com/privacy-policy'));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CommonGradientBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            commonAppBar(heading: "Privacy Policy"),
            verticalSpace(12),
            Expanded(
              child: pageSheet(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: WebViewWidget(controller: controller),
                      ),
                      if (progress < 100)
                        LinearProgressIndicator(
                          value: progress == 0 ? null : progress / 100,
                          minHeight: 3,
                          backgroundColor: AppColors.veryVeryLightGreen,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
