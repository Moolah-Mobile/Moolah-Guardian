import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ironsource_mediation/ironsource_mediation.dart';
import 'package:moolah/helper/models/ad_model.dart';
import 'package:moolah/helper/repo/adRepo.dart';

import 'baseController.dart';

// The IronSource banner is drawn over the bottom of every screen; scrolling lists end with
// this much empty space so their last rows can be scrolled above it.
const double adBannerSpace = 90;

class AdvertisementController extends BaseController with LevelPlayBannerListener{

  bool showLocalAd = false;

  List<AdModel> localAds = [];
  late AdModel currentAd;
  int currentAdIndex = 0;

  init() async {
    loadLocalAds();
    await IronSource.init(appKey: "9459d105");


    IronSource.setLevelPlayBannerListener(this);
  }

  loadLocalAds() async {
    var res = await AdRepo.getBannerAds();
    if(res.isSuccessful){
      print("loadLocalAds:::${res.data}");
      Map<String, dynamic> tempRes = res.data;
      for(int i=0;i<tempRes["campaigns"].length;i++){
        localAds.add(AdModel.fromJson(tempRes["campaigns"][i]));
      }
      update();
    }
    // Map<String, dynamic> tempRes = {"campaigns":[
    //   {"campaign_id":133,"advertiser_id":"37","email":"admin@admin.com","bid":0.002,"status":"active","type":"impression","offer_name":"JCI   Campaign","app_name":"undefined","link":"--","expiration":"2020-12-25T12:00:00.000Z","mulaah":3,"description":"dummy    disc","icon":"--","instructions":"We need leads on this ad","city":"undefined","state":"NWIDE","banner_img":"https://firebasestorage.googleapis.com/v0/b/moolahmobilesystem.appspot.com/o/Banners%2F16057016104.png?alt=media","interstitial_img":"undefined","installs":0,"daily_limit":0,"total_budget":50,"banner_views":3632065,"interstitial_views":0,"banner_clicks":0,"interstitial_clicks":0,"question_1":null,"question_2":null,"question_3":null,"question_4":null,"question_5":null,"question_6":null,"question_7":null,"question_8":null,"question_9":null,"question_10":null}
    // ],"adValue":"0.5"};

  }

  loadBanner() async {
    print("IronSource.loadBanner");
    await IronSource.loadBanner(size: IronSourceBannerSize.BANNER, position: IronSourceBannerPosition.Bottom).then((value) {
      print("VAlue:::");
    }).catchError((e){
      print("catchError:::$e");
    });
    print("IronSource.loadBanner1");
        // .catchError((e){
      // print("IronSource.loadBanner:::$e");
    // });
  }

  Widget optionalAdWidget(){
    return showLocalAd ? Container(
      // height: 10,
      // width: 10,
      color: Colors.black,
      child: currentAd?.bannerImg == null ? const SizedBox() : Image.network(currentAd.bannerImg??"", errorBuilder: (_, __, ___) => const SizedBox()),
    ) : const SizedBox();
  }

  // class LevelListner extends LevelPlayBannerListener{
  @override
  void onAdClicked(IronSourceAdInfo adInfo) {
  print("onAdClicked:::::$adInfo");

  }

  @override
  void onAdLeftApplication(IronSourceAdInfo adInfo) {
  print("onAdLeftApplication:::::$adInfo");

  }

  @override
  void onAdLoadFailed(IronSourceError error) {
  print("onAdLoadFailed:::::$error");
  showLocal();
  }

  @override
  void onAdLoaded(IronSourceAdInfo adInfo) {
  print("onAdLoaded:::::$adInfo");

  //IronSourceAdInfo{auctionId=a1a492f0-90e2-11ee-92b3-492eabb280f0_1974115214, adUnit=banner, adNetwork=ironsource, instanceName=Bidding, instanceId=4377832, country=IN, revenue=0.0000134475, precision=BID, ab=A, segmentName=, encryptedCPM=}
  }

  @override
  void onAdScreenDismissed(IronSourceAdInfo adInfo) {
  print("onAdScreenDismissed:::::$adInfo");
  }

  @override
  void onAdScreenPresented(IronSourceAdInfo adInfo) {
    print("onAdScreenPresented:::::$adInfo");
  }

  void showLocal() async {
    // print("currentAdIndex");
    // print(currentAdIndex);
    if(localAds.isNotEmpty) {
      currentAd = localAds[currentAdIndex];
      showLocalAd = true;
      update();
      await Future.delayed(const Duration(seconds: 15));
      if (currentAdIndex == (localAds.length - 1)) {
        currentAdIndex = 0;
      } else {
        ++currentAdIndex;
      }
      showLocal();
    }
  }

  // }


}

