import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ironsource_mediation/ironsource_mediation.dart';
import 'package:moolah/helper/repo/homeRepo.dart';
import 'package:moolah/util/common_widgets/CommonGradientBackground.dart';

import '../../../helper/models/response_model.dart';
import '../../../util/common_widgets/common_appbar.dart';
import '../../../util/common_widgets/common_widgets.dart';

class LiveLocation extends StatefulWidget {
  static const screenName = "LiveLocation";

  const LiveLocation({Key? key, required this.lat, required this.long, required this.deviceId}) : super(key: key);

  final double lat;
  final double long;
  final String deviceId;



  @override
  State<LiveLocation> createState() => _LiveLocationState();
}

class _LiveLocationState extends State<LiveLocation> {

  final Completer<GoogleMapController> _controller =
  Completer<GoogleMapController>();
  double? lat;
  double? long;

  @override
  void initState() {
    print("LiveLocation::::${widget.lat}::::${widget.long}");
    setLocationTimer();
    IronSource.hideBanner();
    super.initState();
  }

  @override
  void dispose() {
    timer.cancel();
    IronSource.displayBanner();
    super.dispose();
  }
  

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return CommonGradientBackground(
        child: Column(
      children: [
        verticalSpace(10),
        commonAppBar(heading: "Live Location"),
        Expanded(
          child: roundedContainer(
            borderRadiusWhole: BorderRadius.circular(13)
                .copyWith(bottomRight: Radius.zero, bottomLeft: Radius.zero),
            // padding: const EdgeInsets.all(25)
            //     .copyWith(bottom: 0, left: 15, right: 15),
            margin: const EdgeInsets.all(10).copyWith(bottom: 0),
            width: width,
            child: GoogleMap(
              myLocationButtonEnabled: false,
              myLocationEnabled: false,
              // mapType: MapType.hybrid,
              initialCameraPosition: CameraPosition(
                target: LatLng(lat??widget.lat, long??widget.long),
                zoom: 14.4746,
              ),
              markers: {
                Marker(
                  markerId: MarkerId("1"),
                  position: LatLng(lat??widget.lat, long??widget.long)
                ),
              },
              onMapCreated: (GoogleMapController controller) {
                print("Hello Map");
                _controller.complete(controller);
              },
            )
          ),
        ),
      ],
    ));
  }
  late Timer timer;
  void setLocationTimer() {
    timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      getLocation();
    });
  }

  void getLocation() async {
    ResponseModel responseModel = await HomeRepo.getSyncedKidDeviceLocation(widget.deviceId);
    if(responseModel.isSuccessful){
      final data = responseModel.data["data"];
      log("responseModel.data::::$data");
      // The MDM returns lat/lng, and both are null until the device has reported a GPS fix.
      final newLat = (data?["lat"] as num?)?.toDouble();
      final newLong = (data?["lng"] as num?)?.toDouble();
      if (newLat == null || newLong == null || !mounted) return;
      setState(() {
        lat = newLat;
        long = newLong;
      });
      (await _controller.future).animateCamera(CameraUpdate.newLatLng(LatLng(newLat, newLong)));
    }
  }
}
