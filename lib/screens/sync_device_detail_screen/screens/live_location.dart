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

  const LiveLocation({Key? key, this.lat, this.long, required this.deviceId}) : super(key: key);

  // Null when the device has not reported a position yet.
  final double? lat;
  final double? long;
  final String deviceId;



  @override
  State<LiveLocation> createState() => _LiveLocationState();
}

class _LiveLocationState extends State<LiveLocation> {

  final Completer<GoogleMapController> _controller =
  Completer<GoogleMapController>();
  double? lat;
  double? long;
  bool firstCheckDone = false;

  // 0,0 is what a missing fix looks like, so it is not a real position.
  static bool _isPosition(double? lat, double? long) =>
      lat != null && long != null && !(lat == 0 && long == 0);

  @override
  void initState() {
    print("LiveLocation::::${widget.lat}::::${widget.long}");
    if (_isPosition(widget.lat, widget.long)) {
      lat = widget.lat;
      long = widget.long;
    }
    getLocation();
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
            child: (lat != null && long != null)
                ? GoogleMap(
                    myLocationButtonEnabled: false,
                    myLocationEnabled: false,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(lat!, long!),
                      zoom: 14.4746,
                    ),
                    markers: {
                      Marker(markerId: const MarkerId("1"), position: LatLng(lat!, long!)),
                    },
                    onMapCreated: (GoogleMapController controller) {
                      if (!_controller.isCompleted) _controller.complete(controller);
                    },
                  )
                : _noPosition(),
          ),
        ),
      ],
    ));
  }
  Widget _noPosition() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!firstCheckDone) ...[
              const CircularProgressIndicator(),
              verticalSpace(16),
              const Text("Getting location…", textAlign: TextAlign.center),
            ] else ...[
              const Icon(Icons.location_off_outlined, size: 48, color: Colors.grey),
              verticalSpace(12),
              const Text("Location not available yet",
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              verticalSpace(8),
              const Text("The map will appear once the child's device reports its position.",
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            ],
          ],
        ),
      ),
    );
  }

  late Timer timer;
  void setLocationTimer() {
    timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      getLocation();
    });
  }

  void getLocation() async {
    ResponseModel responseModel = await HomeRepo.getSyncedKidDeviceLocation(widget.deviceId);
    if (!mounted) return;
    double? newLat;
    double? newLong;
    if (responseModel.isSuccessful) {
      final data = responseModel.data?["data"];
      log("responseModel.data::::$data");
      // The MDM returns lat/lng, and both are null until the device has reported a GPS fix.
      newLat = (data?["lat"] as num?)?.toDouble();
      newLong = (data?["lng"] as num?)?.toDouble();
    }
    final hadMap = lat != null && long != null;
    final hasPosition = _isPosition(newLat, newLong);
    setState(() {
      firstCheckDone = true;
      if (hasPosition) {
        lat = newLat;
        long = newLong;
      }
    });
    // A map that is already showing is moved; a new one opens at the position by itself.
    if (hasPosition && hadMap && _controller.isCompleted) {
      (await _controller.future).animateCamera(CameraUpdate.newLatLng(LatLng(newLat!, newLong!)));
    }
  }
}
