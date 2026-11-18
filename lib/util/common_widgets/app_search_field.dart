import 'package:flutter/material.dart';
import 'package:moolah/helper/models/device_detail_model.dart';
import 'package:moolah/util/colors.dart';

/// True when [query] is empty or appears in the app's name or package name, ignoring case.
bool appMatchesQuery(App app, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return (app.appName ?? "").toLowerCase().contains(q) || (app.packageName ?? "").toLowerCase().contains(q);
}

/// Search box for the long app lists on a child's device.
class AppSearchField extends StatelessWidget {
  const AppSearchField({required this.controller, required this.onChanged, this.focusNode, Key? key})
      : super(key: key);

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const ValueKey("app_search"),
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      decoration: InputDecoration(
        hintText: "Search apps",
        isDense: true,
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: "Clear search",
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  controller.clear();
                  onChanged("");
                },
              ),
        filled: true,
        fillColor: AppColors.lightGrey,
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }
}
