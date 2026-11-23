import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:moolah/helper/endpoints.dart';
import 'package:moolah/helper/mock/mock_api.dart';
import 'package:moolah/helper/models/response_model.dart';
import 'package:moolah/helper/sharedHelper.dart';

class Network {
  static const String _logHeader = "═══════════════════════════════════════════";

  static Future<ResponseModel> get(String url) async {
    if (MockApi.enabled) return MockApi.handle("GET", url);
    final timestamp = DateTime.now().toString();
    print("\n$_logHeader");
    print("🔵 GET REQUEST - $timestamp");
    print("📍 URL: $url");
    final headers = getHeaders(url);
    print("📋 Headers: ${_loggableHeaders(headers)}");
    print("$_logHeader");

    try {
      final startTime = DateTime.now();
      var res = await http.get(Uri.parse(url), headers: headers);
      final duration = DateTime.now().difference(startTime);

      print("\n✅ GET RESPONSE (${duration.inMilliseconds}ms)");
      print("🔢 Status Code: ${res.statusCode}");
      log("📦 Response Body:\n${_formatJson(res.body)}");
      _printMdmBody(url, "📦 MDM Response Body:", res.body);
      print("$_logHeader\n");

      return responseHandler(res: res);
    } catch (e) {
      print("\n❌ GET ERROR: $e");
      print("$_logHeader\n");
      return responseHandler(empty: true);
    }
  }

  static Future<ResponseModel> post(String url,
      {Map<String, dynamic> body = const {}, bool encode = false}) async {
    MockApi.enableIfDemoLogin(url, body);
    if (MockApi.enabled) return MockApi.handle("POST", url, body);
    final timestamp = DateTime.now().toString();
    print("\n$_logHeader");
    print("🔴 POST REQUEST - $timestamp");
    print("📍 URL: $url");
    final headers = getHeaders(url);
    print("📋 Headers: ${_loggableHeaders(headers)}");
    log("📤 Request Body:\n${_formatJson(jsonEncode(body))}");
    _printMdmBody(url, "📤 MDM Request Body:", jsonEncode(body));
    print("$_logHeader");

    try {
      final startTime = DateTime.now();
      var res = await http.post(Uri.parse(url),
        body: jsonEncode(body),
        headers: headers
      );
      final duration = DateTime.now().difference(startTime);

      print("\n✅ POST RESPONSE (${duration.inMilliseconds}ms)");
      print("🔢 Status Code: ${res.statusCode}");
      log("📥 Response Body:\n${_formatJson(res.body)}");
      _printMdmBody(url, "📥 MDM Response Body:", res.body);
      print("$_logHeader\n");

      return responseHandler(res: res);
    } catch (e) {
      print("\n❌ POST ERROR: $e");
      print("$_logHeader\n");
      return responseHandler(empty: true);
    }
  }

  // `log()` only reaches DevTools. In debug builds, also print MDM request and response bodies to the
  // console (logcat) so a device action can be checked. MDM bodies carry no keys or tokens; those are in
  // the headers. api2 bodies can carry tokens and keys, so they are not printed here.
  static const int _maxPrintedBody = 3000;

  static void _printMdmBody(String url, String label, String body) {
    if (!kDebugMode || !url.contains(EndPoints.mdmBaseUrl)) return;
    final text = body.length > _maxPrintedBody
        ? "${body.substring(0, _maxPrintedBody)}… (${body.length - _maxPrintedBody} more characters)"
        : body;
    debugPrint("$label $text", wrapWidth: 900);
  }

  // The MDM key and the parent's login token must never reach the device log: `print` also writes to
  // logcat in release builds, where anyone with adb access to the phone could read them.
  static const _secretHeaders = {"x-api-key", "authorization"};

  static Map<String, String> _loggableHeaders(Map<String, String> headers) => {
        for (final e in headers.entries)
          e.key: _secretHeaders.contains(e.key.toLowerCase()) ? "<hidden>" : e.value,
      };

  static String _formatJson(String jsonString) {
    try {
      final jsonObject = jsonDecode(jsonString);
      return JsonEncoder.withIndent('  ').convert(jsonObject);
    } catch (e) {
      return jsonString;
    }
  }

  static Map<String, String> getHeaders(String url) {
    Map<String, String> header = {
      "X-API-VERSION":"0.0.0.1",
      "Content-type": "application/json; charset=utf-8"
    };

    // Add MDM API Key if the URL is for MDM
    if (url.contains(EndPoints.mdmBaseUrl)) {
      header.addAll({"x-api-key": EndPoints.mdmApiKey});
    }

    if (Prefs.accessToken.get().isNotEmpty) {
      header.addAll({"Authorization": "Bearer ${Prefs.accessToken.get()}"});
    }
    return header;
  }

  /// api2 puts its message at the top level; the MDM sends `{"success": false, "error": {"message": "..."}}`.
  static String? _errorMessage(dynamic body) {
    if (body is! Map) return null;
    final error = body["error"];
    final nested = error is Map ? error["message"] : null;
    return (body["message"] ?? nested)?.toString();
  }

  static Future<ResponseModel> responseHandler(
      {http.Response? res, bool empty = false}) async {
    if (empty || res == null) {
      return ResponseModel(isSuccessful: false, message: "Network Error", data: null);
    }

    // `log()` above only reaches DevTools; print subscription responses to the console in debug builds.
    // Login and OTP responses carry tokens, so only plan/order/subscription bodies are printed.
    final path = res.request?.url.path ?? "";
    if (kDebugMode && RegExp(r"^/guardian/(plans|subscription|orders)").hasMatch(path)) {
      debugPrint("🧾 ${res.request?.method} ${res.request?.url.path} → ${res.statusCode}: ${res.body}", wrapWidth: 900);
    }

    print("\n🔍 RESPONSE HANDLER");
    print("📊 Status Code: ${res.statusCode}");

    if ((res.statusCode == 200 || res.statusCode == 201)) {
      try {
        final responseData = jsonDecode(res.body);
        
        // Flexible success check for different backends
        bool isSuccessful = false;
        if (responseData["success"] is bool) {
          isSuccessful = responseData["success"];
        } else if (responseData["status"] is bool) {
          isSuccessful = responseData["status"];
        } else if (responseData["status"] is String) {
          isSuccessful = responseData["status"].toString().toLowerCase() == "success";
        } else {
          isSuccessful = true; 
        }

        final message = _errorMessage(responseData) ?? responseData["msg"] ?? "Success";

        print("✅ Parsed Success: $isSuccessful");
        return ResponseModel(
            isSuccessful: isSuccessful,
            data: responseData,
            message: message);
      } catch (e) {
        print("❌ JSON Parse Error: $e");
        return ResponseModel(isSuccessful: false, message: "Parse Error: $e", data: null);
      }
    }

    print("❌ Error Body: ${res.body}");
    try {
      final errorData = jsonDecode(res.body);
      final errorMessage = _errorMessage(errorData) ?? errorData["errorMsg"] ?? "Error ${res.statusCode}";
      return ResponseModel(isSuccessful: false, message: errorMessage, data: errorData);
    } catch (e) {
      return ResponseModel(isSuccessful: false, message: "Error ${res.statusCode}", data: null);
    }
  }
}
