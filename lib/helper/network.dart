import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:moolah/helper/endpoints.dart';
import 'package:moolah/helper/models/response_model.dart';
import 'package:moolah/helper/sharedHelper.dart';

class Network {
  static const String _logHeader = "═══════════════════════════════════════════";

  static Future<ResponseModel> get(String url) async {
    final timestamp = DateTime.now().toString();
    print("\n$_logHeader");
    print("🔵 GET REQUEST - $timestamp");
    print("📍 URL: $url");
    final headers = getHeaders(url);
    print("📋 Headers: $headers");
    print("$_logHeader");

    try {
      final startTime = DateTime.now();
      var res = await http.get(Uri.parse(url), headers: headers);
      final duration = DateTime.now().difference(startTime);

      print("\n✅ GET RESPONSE (${duration.inMilliseconds}ms)");
      print("🔢 Status Code: ${res.statusCode}");
      log("📦 Response Body:\n${_formatJson(res.body)}");
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
    final timestamp = DateTime.now().toString();
    print("\n$_logHeader");
    print("🔴 POST REQUEST - $timestamp");
    print("📍 URL: $url");
    final headers = getHeaders(url);
    print("📋 Headers: $headers");
    log("📤 Request Body:\n${_formatJson(jsonEncode(body))}");
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
      print("$_logHeader\n");

      return responseHandler(res: res);
    } catch (e) {
      print("\n❌ POST ERROR: $e");
      print("$_logHeader\n");
      return responseHandler(empty: true);
    }
  }

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

  static Future<ResponseModel> responseHandler(
      {http.Response? res, bool empty = false}) async {
    if (empty || res == null) {
      return ResponseModel(isSuccessful: false, message: "Network Error", data: null);
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

        final message = responseData["message"] ?? responseData["msg"] ?? "Success";

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

    try {
      final errorData = jsonDecode(res.body);
      final errorMessage = errorData["message"] ?? errorData["errorMsg"] ?? "Error ${res.statusCode}";
      return ResponseModel(isSuccessful: false, message: errorMessage, data: errorData);
    } catch (e) {
      return ResponseModel(isSuccessful: false, message: "Error ${res.statusCode}", data: null);
    }
  }
}
