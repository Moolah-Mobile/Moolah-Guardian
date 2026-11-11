class EndPoints {
  static String baseUrl = "https://api2.moolahmobile.com";
  static String mdmBaseUrl = "https://moolahmdm.com/rest";
  
  // NOTE: Replace with your actual MDM API Key for production
  static String mdmApiKey = "d927eaf4dbfffdd18836301d5698e4772d75505c9cc464761920c04df45b09af";

  // Auth endpoints (api2)
  static String login = "$baseUrl/guardian/login";
  static String signUp = "$baseUrl/guardian/register";
  static String refreshToken = "$baseUrl/refreshTokens";
  static String sendMobileOtp = "$baseUrl/guardian/send-otp";
  static String verifyMobileOtp = "$baseUrl/guardian/verify-otp";
  static String forgotPassword = "$baseUrl/guardian/forgot-password";
  static String resetPassword = "$baseUrl/guardian/reset-password";

  // MDM Monitoring endpoints (moolahmdm)
  static String getSyncedKidDevicesUrl = "$mdmBaseUrl/getConnectedKidDevices";
  static String getDeviceDetails = "$mdmBaseUrl/getSingleDeviceDetail";
  static String getAppUsageUrl = "$mdmBaseUrl/getDeviceDetails"; 
  static String blacklistAppUrl = "$mdmBaseUrl/setDeviceRestrictions";
  static String getBlacklistedAppsUrl = "$mdmBaseUrl/getDeviceRestrictions";
  static String getInstalledAppsUrl = "$mdmBaseUrl/getInstalledApps";
  static String deleteAppUrl = "$mdmBaseUrl/deleteApp";
  static String getNetworkHistoryUrl = "$mdmBaseUrl/getNetworkHistory";
  static String getDeviceLocation = "$mdmBaseUrl/getDeviceLocation";
  static String sendActionToDevice = "$mdmBaseUrl/sendActionToDevice";
  
  // Device Connection Flow (moolahmdm)
  static String provisionDevice = "$mdmBaseUrl/guardian/provision";
  static String linkDevice = "$mdmBaseUrl/guardian/link";

  // Other Feature Management (api2)
  static String getMSMSMonitoringStatus = "$baseUrl/getMSMSMonitoringStatus";
  static String enableMSMSMonitoring = "$baseUrl/enableMSMSMonitoring";
  static String getWalletStatus = "$baseUrl/getWalletEnabled";
  static String enableWalletUrl = "$baseUrl/enableWallet";
  static String getBlacklistUrlsUrl = "$baseUrl/getBlockedUrlsEncryption";
  static String blacklistUrl = "$baseUrl/blacklistUrl";
  static String addBlacklistUrl = "$baseUrl/addBlockedUrl";
  static String getDeviceThreads = "$baseUrl/getDeviceThreadsEncryption";
  static String getThreadsMessages = "$baseUrl/getThreadMessagesEncryption";
  static String parentAppSecurityCheck = "$baseUrl/parentAppSecurityCheck";
  static String linkKidByConnectCode = "$baseUrl/linkKidByConnectCode";
  static String getBannerAds = "$baseUrl/getBannerAds";
  static String submitReview = "$baseUrl/submitReview";
  static String feedback = "$baseUrl/feedback";

  // Subscriptions (api2)
  static String createSubscription = "$baseUrl/createPaymentIntent";
}
