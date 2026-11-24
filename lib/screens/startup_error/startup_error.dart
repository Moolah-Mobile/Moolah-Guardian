import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moolah/util/colors.dart';
import 'package:moolah/util/theme/app_theme.dart';

/// Shown instead of the app when it can't start: the build is missing its config, or something failed
/// before the first screen. Without it the phone stays on the launch screen with no explanation.
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.title, required this.message, required this.details});

  /// The app was built without some of its keys (config/prod.json). The screen names no keys; debug builds
  /// list them in the log.
  factory StartupErrorApp.missingConfig() => const StartupErrorApp(
        title: "This version can't start",
        message: "This copy of Moolah Guardian wasn't set up completely, so it can't connect to your "
            "account. Install the latest version from the Play Store or App Store.\n\n"
            "Your account and your child's settings are safe.",
        details: "Missing build config.",
      );

  /// Something threw before the first screen was drawn.
  factory StartupErrorApp.crashed(Object error) {
    final text = error.toString();
    return StartupErrorApp(
      title: "Something went wrong",
      message: "Moolah Guardian couldn't open. Close it and open it again. If this keeps happening, "
          "restart your phone or reinstall the app.\n\n"
          "Your account and your child's settings are safe.",
      details: "Startup error: ${text.length > 400 ? "${text.substring(0, 400)}…" : text}",
    );
  }

  final String title;
  final String message;

  /// For support: what exactly failed. Folded away until tapped.
  final String details;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: StartupErrorScreen(title: title, message: message, details: details),
    );
  }
}

class StartupErrorScreen extends StatefulWidget {
  const StartupErrorScreen({super.key, required this.title, required this.message, required this.details});
  final String title;
  final String message;
  final String details;

  @override
  State<StartupErrorScreen> createState() => _StartupErrorScreenState();
}

class _StartupErrorScreenState extends State<StartupErrorScreen> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // assets/images/common/logo.svg is a grey placeholder; the real logo is only an Android drawable.
                Text("MOOLAH GUARDIAN",
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 2.5, color: AppColors.normalGreen)),
                const SizedBox(height: 40),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: AppColors.normalGreen.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(Icons.error_outline_rounded, size: 34, color: AppColors.normalGreen),
                ),
                const SizedBox(height: 20),
                Text(widget.title,
                    textAlign: TextAlign.center,
                    style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.black)),
                const SizedBox(height: 12),
                Text(widget.message,
                    textAlign: TextAlign.center,
                    style: text.bodyLarge?.copyWith(height: 1.45, color: AppColors.black.withValues(alpha: 0.75))),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () => SystemNavigator.pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.normalGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text("Close app", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() => _showDetails = !_showDetails),
                  child: Text(_showDetails ? "Hide details" : "Details for support",
                      style: TextStyle(color: AppColors.grey9494)),
                ),
                if (_showDetails)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.grey9494.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SelectableText(widget.details,
                        style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.black.withValues(alpha: 0.7))),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
