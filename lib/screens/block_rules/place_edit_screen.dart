import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:moolah/controllers/blockRulesController.dart';
import 'package:moolah/controllers/homeController.dart';
import 'package:moolah/helper/models/block_rule_model.dart';
import 'package:moolah/helper/models/kids_model.dart';
import 'package:moolah/helper/repo/placeSearchRepo.dart';
import 'package:moolah/screens/block_rules/app_picker_screen.dart';
import 'package:moolah/screens/block_rules/places_screen.dart';
import 'package:moolah/screens/block_rules/rule_widgets.dart';
import 'package:moolah/util/apptext.dart';
import 'package:moolah/util/colors.dart';
import 'package:moolah/util/customtoast.dart';
import 'package:moolah/util/common_widgets/common_widgets.dart';

/// Adds a place, or edits [place] when given: a pin on the map, the size of the area around it, and which
/// apps to block while the child is inside (or outside) it.
class PlaceEditScreen extends StatefulWidget {
  const PlaceEditScreen({required this.kidId, this.place, super.key});
  final String kidId;
  final BlockPlace? place;

  @override
  State<PlaceEditScreen> createState() => _PlaceEditScreenState();
}

class _PlaceEditScreenState extends State<PlaceEditScreen> {
  late final Kid kid = Get.find<HomeController>().getSelectedKid(widget.kidId);
  late final LatLng? _childAt = childPosition(kid);
  late final BlockPlace draft = widget.place?.copy() ??
      BlockPlace(
        id: BlockRulesController.newId("place"),
        lat: _childAt?.latitude ?? 0,
        lng: _childAt?.longitude ?? 0,
      );
  late final name = TextEditingController(text: draft.name);
  final address = TextEditingController();
  // A new place starts unpinned when the child's location isn't known.
  late bool pinned = widget.place != null || _childAt != null;
  GoogleMapController? _map;

  bool get _isNew => widget.place == null;
  LatLng get _pin => LatLng(draft.lat, draft.lng);

  @override
  void dispose() {
    name.dispose();
    address.dispose();
    _typingPause?.cancel();
    _map?.dispose();
    super.dispose();
  }

  void _movePin(LatLng to) => setState(() {
        draft.lat = to.latitude;
        draft.lng = to.longitude;
        pinned = true;
        _matches = [];
      });

  // Address search. While the parent types, OpenStreetMap suggestions (Photon) appear under the box. The
  // search button asks the phone's own geocoder instead (Google's on Android, Apple's on iOS), which also
  // works when the suggestions can't be fetched. Neither needs a key.
  final _geocoder = geo.Geocoding();
  bool _searching = false;
  // Places for the parent to pick from: suggestions while typing, or an address with several matches.
  List<PlaceSuggestion> _matches = [];
  bool _matchesFromSearch = false;
  Timer? _typingPause;
  int _suggestRequest = 0;

  LatLng? get _searchNear => _childAt ?? (pinned ? _pin : null);

  void _onAddressTyped(String text) {
    _typingPause?.cancel();
    final request = ++_suggestRequest;
    if (text.trim().length < PlaceSearchRepo.minChars) {
      if (_matches.isNotEmpty) setState(() => _matches = []);
      return;
    }
    _typingPause = Timer(const Duration(milliseconds: 400), () async {
      final near = _searchNear;
      final found = await PlaceSearchRepo.suggest(text, nearLat: near?.latitude, nearLng: near?.longitude);
      // Drop answers to text the parent has since changed, or after a place was picked.
      if (!mounted || request != _suggestRequest) return;
      setState(() {
        _matches = found;
        _matchesFromSearch = false;
      });
    });
  }

  Future<void> _findAddress() async {
    final query = address.text.trim();
    if (query.isEmpty || _searching) return;
    _typingPause?.cancel();
    _suggestRequest++;
    FocusScope.of(context).unfocus();
    setState(() {
      _searching = true;
      _matches = [];
    });
    List<PlaceSuggestion> found = [];
    try {
      final locations = await _geocoder.locationFromAddress(query);
      found = await Future.wait(locations.take(5).map((l) async => PlaceSuggestion(
          title: await _addressAt(LatLng(l.latitude, l.longitude)) ?? query,
          detail: "",
          lat: l.latitude,
          lng: l.longitude)));
    } catch (_) {
      // Android throws when nothing matches, as well as when the lookup fails.
    }
    if (!mounted) return;
    setState(() => _searching = false);
    if (found.isEmpty) {
      return errorToast("Couldn't find that address. Check it, or add the city or ZIP code.");
    }
    if (found.length == 1) return _goTo(found.single);
    setState(() {
      _matches = found;
      _matchesFromSearch = true;
    });
  }

  Future<String?> _addressAt(LatLng at) async {
    try {
      final marks = await _geocoder.placemarkFromCoordinates(at.latitude, at.longitude);
      if (marks.isEmpty) return null;
      final m = marks.first;
      final all = [m.name, m.street, m.locality, m.administrativeArea, m.postalCode]
          .map((part) => part?.trim() ?? "")
          .where((part) => part.isNotEmpty)
          .toList();
      // name is often just the house number, or the same as street: drop parts another part already says.
      final parts = <String>[];
      for (final (i, part) in all.indexed) {
        final saidElsewhere = all.indexed.any((o) => o.$1 != i && o.$2 != part && o.$2.contains(part));
        if (!saidElsewhere && !parts.contains(part)) parts.add(part);
      }
      return parts.isEmpty ? null : parts.join(", ");
    } catch (_) {
      return null;
    }
  }

  void _goTo(PlaceSuggestion match) {
    _typingPause?.cancel();
    _suggestRequest++;
    FocusScope.of(context).unfocus();
    _movePin(LatLng(match.lat, match.lng));
    address.text = match.label;
    _map?.animateCamera(CameraUpdate.newLatLngZoom(_pin, _zoomToFit()));
  }

  Widget _addressSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        fieldLabel("Address"),
        _textField(
          address,
          hint: "Type an address or a place's name",
          action: TextInputAction.search,
          onChanged: _onAddressTyped,
          onSubmitted: (_) => _findAddress(),
          suffix: _searching
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : IconButton(
                  tooltip: "Find address",
                  icon: Icon(Icons.search, color: AppColors.normalGreen),
                  onPressed: _findAddress,
                ),
        ),
        if (_matches.isNotEmpty) ...[
          verticalSpace(8),
          if (_matchesFromSearch) ...[
            regularText("More than one place matches. Which one?", fontSize: 13, color: AppColors.grey),
            verticalSpace(4),
          ],
          roundedContainer(
            borderRadius: 14,
            color: AppColors.white,
            border: Border.all(color: AppColors.darkLightGrey),
            child: Column(
              children: [
                for (final (i, m) in _matches.indexed) ...[
                  if (i > 0) Divider(height: 1, color: AppColors.darkLightGrey),
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.place_outlined, color: AppColors.normalGreen),
                    title: boldText(m.title, fontSize: 14),
                    subtitle: m.detail.isEmpty ? null : regularText(m.detail, fontSize: 13, color: AppColors.grey),
                    onTap: () => _goTo(m),
                  ),
                ],
              ],
            ),
          ),
          if (!_matchesFromSearch) ...[
            verticalSpace(4),
            regularText("Suggestions © OpenStreetMap contributors", fontSize: 11, color: AppColors.grey),
          ],
        ],
        verticalSpace(12),
      ],
    );
  }

  Widget _textField(TextEditingController controller,
      {required String hint,
      TextInputAction? action,
      ValueChanged<String>? onChanged,
      ValueChanged<String>? onSubmitted,
      Widget? suffix}) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: action,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: TextStyle(fontFamily: fontFamily, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.darkLightGrey)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.normalGreen, width: 2)),
      ),
    );
  }

  String? get _problem {
    if (!pinned) return "Search for an address, or tap the map to set where the place is.";
    if (name.text.trim().isEmpty) return "Give the place a name.";
    if (draft.useTimes && draft.days.isEmpty) return "Pick at least one day.";
    if (draft.useTimes && draft.from == draft.to) return "The start and end times are the same.";
    if (draft.packages.isEmpty) return "Choose at least one app.";
    return null;
  }

  Future<void> _chooseApps() async {
    final picked = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(builder: (_) => AppPickerScreen(kidId: widget.kidId, selected: draft.packages)),
    );
    if (picked != null) setState(() => draft.packages = picked);
  }

  // Sent to the child's phone first; the screen closes only once the MDM has it.
  bool _saving = false;

  Future<void> _run(Future<String?> Function(BlockRulesController rules) change) async {
    setState(() => _saving = true);
    final error = await change(Get.find<BlockRulesController>());
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) return errorToast(error);
    Navigator.pop(context);
  }

  void _save() {
    draft.name = name.text.trim();
    _run((rules) => rules.savePlace(widget.kidId, draft));
  }

  void _delete() {
    // What deleting changes depends on the saved place, not on edits not saved yet.
    final inside = widget.place?.inside ?? draft.inside;
    final child = childFirstName(kid);
    showDialog(
      context: context,
      builder: (dialog) => AlertDialog(
        title: boldText("Delete ${draft.name.isEmpty ? "this place" : draft.name}?", fontSize: 18),
        content: regularText(
            inside
                ? "Apps it blocks will stay on while $child is here."
                : "Apps it blocks will stay on while $child is away from here.",
            fontSize: 14),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog), child: regularText("Cancel", fontSize: 14)),
          TextButton(
            onPressed: () {
              Navigator.pop(dialog);
              _run((rules) => rules.deletePlace(widget.kidId, draft.id));
            },
            child: regularText("Delete", color: AppColors.red, fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _summary(String childName) {
    if (draft.packages.isEmpty) return "Choose the apps to block.";
    final placeName = name.text.trim().isEmpty ? "this place" : name.text.trim();
    final where = draft.inside
        ? "while $childName is within ${draft.radiusText} of $placeName"
        : "whenever $childName is more than ${draft.radiusText} from $placeName";
    final days = describeDays(draft.days);
    final when = draft.useTimes
        ? ", ${days == "Every day" ? "every day" : days == "Weekends" ? "at weekends" : "on $days"} "
            "from ${formatTime(draft.from)} to ${formatTime(draft.to)}"
        : ", at any time";
    return "${appListText(kid, draft.packages)} will be blocked $where$when.";
  }

  @override
  Widget build(BuildContext context) {
    final childName = childFirstName(kid);
    final problem = _problem;

    return ruleScreen(context, title: _isNew ? "New place" : "Edit place", children: [
      _addressSearch(),
      _mapCard(childName),
      verticalSpace(16),
      Row(
        children: [
          Expanded(child: boldText("Area size", fontSize: 14)),
          boldText(draft.radiusText, fontSize: 15, color: AppColors.normalGreen),
        ],
      ),
      Slider(
        value: draft.radiusM.toDouble(),
        min: BlockPlace.minRadius.toDouble(),
        max: BlockPlace.maxRadius.toDouble(),
        divisions: (BlockPlace.maxRadius - BlockPlace.minRadius) ~/ 50,
        label: draft.radiusText,
        activeColor: AppColors.normalGreen,
        inactiveColor: AppColors.veryVeryLightGreen,
        onChanged: (v) => setState(() => draft.radiusM = v.round()),
        onChangeEnd: (_) {
          if (pinned) _map?.animateCamera(CameraUpdate.newLatLngZoom(_pin, _zoomToFit()));
        },
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            regularText("100 m", fontSize: 12, color: AppColors.grey),
            regularText("1 km", fontSize: 12, color: AppColors.grey),
          ],
        ),
      ),
      verticalSpace(16),
      fieldLabel("Name"),
      _textField(name, hint: "e.g. School", onChanged: (_) => setState(() {})),
      verticalSpace(18),
      fieldLabel("Block apps while $childName is"),
      segmentedChoice(
        options: const ["Inside this place", "Outside it"],
        selected: draft.inside ? 0 : 1,
        onChanged: (i) => setState(() => draft.inside = i == 0),
      ),
      verticalSpace(18),
      fieldLabel("When"),
      segmentedChoice(
        options: const ["Any time", "Set times"],
        selected: draft.useTimes ? 1 : 0,
        onChanged: (i) => setState(() => draft.useTimes = i == 1),
      ),
      if (draft.useTimes) ...[
        verticalSpace(14),
        dayPicker(days: draft.days, onChanged: (d) => setState(() => draft.days = d)),
        verticalSpace(14),
        Row(
          children: [
            Expanded(
                child: timeField(context,
                    label: "From", minutes: draft.from, onChanged: (m) => setState(() => draft.from = m))),
            horizontalSpace(10),
            Expanded(
                child: timeField(context,
                    label: "Until", minutes: draft.to, onChanged: (m) => setState(() => draft.to = m))),
          ],
        ),
        if (childClockNote(kid) case final note?) ...[verticalSpace(12), infoNote(note)],
        verticalSpace(12),
        infoNote("Children's phones can't follow places with set times yet. The place is saved, but to block "
            "apps there now, choose Any time."),
      ],
      verticalSpace(18),
      fieldLabel("Apps to block"),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final pkg in draft.packages)
            InputChip(
              avatar: ruleAppIcon(appFor(kid, pkg), size: 24),
              label: regularText(appFor(kid, pkg).appName ?? pkg, fontSize: 14, fontWeight: FontWeight.w600),
              backgroundColor: AppColors.lightGrey,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              deleteIcon: Icon(Icons.close, size: 16, color: AppColors.grey),
              deleteButtonTooltipMessage: "Remove ${appFor(kid, pkg).appName ?? pkg}",
              onDeleted: () => setState(() => draft.packages = [...draft.packages]..remove(pkg)),
            ),
          ActionChip(
            avatar: Icon(Icons.add, size: 18, color: AppColors.normalGreen),
            label: boldText("Choose apps", fontSize: 14, color: AppColors.normalGreen),
            backgroundColor: AppColors.white,
            side: BorderSide(color: AppColors.normalGreen),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            onPressed: _chooseApps,
          ),
        ],
      ),
      verticalSpace(16),
      summaryNote(_summary(childName)),
      verticalSpace(16),
      if (problem != null) ...[
        regularText(problem, fontSize: 13, color: AppColors.grey),
        verticalSpace(8),
      ],
      primaryButton(_saving ? "Saving…" : "Save place", onTap: problem == null && !_saving ? _save : null),
      if (!_isNew) ...[
        verticalSpace(8),
        Center(
          child: TextButton(
            onPressed: _saving ? null : _delete,
            child: regularText("Delete place", color: AppColors.red, fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ]);
  }

  static const _mapHeight = 240.0;

  /// The zoom that shows the whole area with a margin around it in the map's height.
  double _zoomToFit() {
    final metresPerPixelAtZoom0 = 156543.03 * math.cos(_pin.latitude * math.pi / 180);
    final zoom = math.log(metresPerPixelAtZoom0 * _mapHeight / (2.6 * draft.radiusM)) / math.ln2;
    return zoom.clamp(3.0, 18.0);
  }

  Widget _mapCard(String childName) {
    final start = pinned ? _pin : const LatLng(0, 0);
    return roundedContainer(
      borderRadius: 20,
      border: Border.all(color: AppColors.buttonBorderGrey),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: _mapHeight,
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(target: start, zoom: pinned ? _zoomToFit() : 2),
                onMapCreated: (c) => _map = c,
                onTap: _movePin,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                myLocationButtonEnabled: false,
                // The map takes drags itself instead of scrolling the page.
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                },
                markers: {
                  if (pinned)
                    Marker(
                      markerId: const MarkerId("place"),
                      position: _pin,
                      draggable: true,
                      onDragEnd: _movePin,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                    ),
                  if (_childAt != null)
                    Marker(
                      markerId: const MarkerId("child"),
                      position: _childAt!,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                      infoWindow: InfoWindow(title: childName),
                    ),
                },
                circles: {
                  if (pinned)
                    Circle(
                      circleId: const CircleId("area"),
                      center: _pin,
                      radius: draft.radiusM.toDouble(),
                      strokeWidth: 2,
                      strokeColor: AppColors.normalGreen,
                      fillColor: AppColors.normalGreen.withValues(alpha: 0.16),
                    ),
                },
              ),
              Positioned(
                left: 12,
                top: 12,
                child: pill(
                  color: AppColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: regularText(pinned ? "Tap or drag the pin to adjust" : "Search above, or tap the map",
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
