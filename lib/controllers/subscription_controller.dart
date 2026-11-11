import 'dart:convert';

import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:moolah/helper/sharedHelper.dart';
import 'package:moolah/util/common_widgets/common_widgets.dart';
import 'package:moolah/util/customtoast.dart';

import '../helper/endpoints.dart';
import '../helper/network.dart';
import 'baseController.dart';
import 'package:http/http.dart' as http;

class SubscriptionController extends BaseController {

  Future<void> checkIfUserAlreadyHasTheSubscription() async {

  }


  Future<void> purchaseSubscription({bool isMonthly = false}) async {
    isLoading = true;
    update();
    var res = await Network.post(EndPoints.createSubscription, body: {
      "amount": isMonthly ? 399 : 3000
    });
    
    apiToast(res);

    if(res.isSuccessful){
      try {
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: res.data["clientSecret"],
            merchantDisplayName: 'Moolah Guardian',
          ),
        );

        await Stripe.instance.presentPaymentSheet();
        successToast("Payment completed successfully");
      } catch (e) {
        print("Stripe Error: $e");
        // Don't show generic error if user cancelled
        if (e is StripeException) {
          errorToast("Payment failed: ${e.error.localizedMessage}");
        }
      }
    }
    isLoading = false;
    update();
  }

  createPaymentIntent(String amount, String currency, String apiKey) async {
    try {
      Map<String, dynamic> body = {
        'amount': amount,
        'currency': currency,
      };

      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: body,
      );
      return json.decode(response.body);
    } catch (err) {
      throw Exception(err.toString());
    }
  }

}