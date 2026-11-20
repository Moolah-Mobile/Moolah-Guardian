import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:moolah/controllers/blockRulesController.dart';
import 'package:moolah/controllers/homeController.dart';
import 'package:moolah/helper/models/block_rule_model.dart';
import 'package:moolah/helper/models/kids_model.dart';
import 'package:moolah/screens/block_rules/place_edit_screen.dart';
import 'package:moolah/screens/block_rules/rule_widgets.dart';
import 'package:moolah/util/apptext.dart';
import 'package:moolah/util/colors.dart';
import 'package:moolah/util/common_widgets/common_widgets.dart';

/// The child's last known position, or null when the phone hasn't reported one.
LatLng? childPosition(Kid kid) {
  final location = kid.deviceDetail?.data?.location;
  final lat = location?.lat, lng = location?.lng;
  if (lat == null || lng == null || (lat == 0 && lng == 0)) return null;
  return LatLng(lat, lng);
}

/// Distance in metres between two points (haversine).
double distanceMeters(LatLng a, LatLng b) {
  const r = 6371000.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(b.latitude - a.latitude), dLng = rad(b.longitude - a.longitude);
  final h = math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(a.latitude)) * math.cos(rad(b.latitude)) * math.pow(math.sin(dLng / 2), 2);
  return 2 * r * math.asin(math.sqrt(h));
}

/// The device's places: areas where apps are turned off while the child is in (or away from) them.
class PlacesScreen extends StatelessWidget {
  const PlacesScreen({required this.kidId, super.key});
  final String kidId;

  void _open(BuildContext context, [BlockPlace? place]) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => PlaceEditScreen(kidId: kidId, place: place)));
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BlockRulesController>(builder: (rules) {
      final kid = Get.find<HomeController>().getSelectedKid(kidId);
      final name = childFirstName(kid);
      final places = rules.placesFor(kidId);
      final child = childPosition(kid);

      return ruleScreen(context, title: "Block by location", children: [
        regularText("Choose where apps should turn off: while $name is at a place, such as school, or away from one.",
            fontSize: 14, color: AppColors.grey, height: 1.45),
        verticalSpace(16),
        if (child != null || places.isNotEmpty) ...[
          _overviewMap(child, places, name, kid),
          verticalSpace(16),
        ],
        if (places.isEmpty)
          roundedContainer(
            color: AppColors.lightGrey,
            borderRadius: 20,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            child: Column(
              children: [
                iconBadge(Icons.location_on_outlined, size: 52),
                verticalSpace(12),
                boldText("No places yet", fontSize: 16),
                verticalSpace(4),
                regularText("Add school, a tuition centre or anywhere apps should be off.",
                    fontSize: 14, color: AppColors.grey, textAlign: TextAlign.center),
              ],
            ),
          ),
        for (final p in places) _placeCard(context, rules, kid, p, child, name),
        verticalSpace(4),
        primaryButton("Add a place", icon: Icons.add, onTap: () => _open(context)),
        verticalSpace(16),
        infoNote("Uses the location of $name's phone. Apps turn off when $name arrives and back on when $name leaves."),
        verticalSpace(12),
        notOnPhoneYetNote(name),
      ]);
    });
  }

  Widget _overviewMap(LatLng? child, List<BlockPlace> places, String name, Kid kid) {
    final center = child ?? LatLng(places.first.lat, places.first.lng);
    final updated = kid.lastActive;
    return roundedContainer(
      borderRadius: 20,
      border: Border.all(color: AppColors.buttonBorderGrey),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              height: 180,
              child: GoogleMap(
                liteModeEnabled: true,
                initialCameraPosition: CameraPosition(target: center, zoom: 14),
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                myLocationButtonEnabled: false,
                markers: {
                  if (child != null)
                    Marker(
                      markerId: const MarkerId("child"),
                      position: child,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                      infoWindow: InfoWindow(title: name),
                    ),
                },
                circles: {
                  for (final p in places)
                    Circle(
                      circleId: CircleId(p.id),
                      center: LatLng(p.lat, p.lng),
                      radius: p.radiusM.toDouble(),
                      strokeWidth: 2,
                      strokeColor: p.enabled ? AppColors.normalGreen : AppColors.grey,
                      fillColor: (p.enabled ? AppColors.normalGreen : AppColors.grey).withValues(alpha: 0.15),
                    ),
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                    width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF1A62C9), shape: BoxShape.circle)),
                horizontalSpace(10),
                Expanded(
                  child: regularText(
                      child == null
                          ? "$name's location isn't known yet"
                          : "$name's last location${updated == null ? "" : " · $updated"}",
                      fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeCard(BuildContext context, BlockRulesController rules, Kid kid, BlockPlace p, LatLng? child, String name) {
    final here = child != null && distanceMeters(child, LatLng(p.lat, p.lng)) <= p.radiusM;
    final apps = appListText(kid, p.packages);
    final rule =
        p.inside ? "Set to block $apps while $name is here" : "Set to block $apps while $name is away from here";
    final placeMatches = child != null && (p.inside ? here : !here);
    final inTimes = !p.useTimes || windowCovers(p.days, p.from, p.to, DateTime.now());
    final blockingNow = p.enabled && placeMatches && inTimes;
    final status = child == null
        ? "Location not known yet"
        : !p.enabled
            ? "Off"
            : "${here ? "$name is here" : "$name isn't here"} · "
                "${blockingNow ? "rule applies now" : placeMatches ? "outside the set times" : "rule doesn't apply"}";

    return ruleCard(
      onTap: () => _open(context, p),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              iconBadge(Icons.location_on_outlined, size: 40),
              horizontalSpace(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    boldText(p.name.isEmpty ? "Place" : p.name, fontSize: 17),
                    verticalSpace(2),
                    regularText("${p.radiusText} area · ${p.whenText}", fontSize: 13, color: AppColors.grey),
                  ],
                ),
              ),
              ruleSwitch(value: p.enabled, onChanged: (v) => rules.setPlaceEnabled(kidId, p.id, v)),
            ],
          ),
          verticalSpace(10),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: regularText("$rule.", fontSize: 14, height: 1.4),
          ),
          verticalSpace(8),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: blockingNow ? AppColors.normalGreen : AppColors.darkLightGrey, shape: BoxShape.circle),
              ),
              horizontalSpace(8),
              Expanded(child: regularText(status, fontSize: 13, color: AppColors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}
