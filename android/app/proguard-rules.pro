# flutter_stripe references Stripe's optional push-provisioning classes, which are not bundled.
# Without this, R8 stops the release build with "Missing class com.stripe.android.pushProvisioning...".
-dontwarn com.stripe.android.pushProvisioning.**
