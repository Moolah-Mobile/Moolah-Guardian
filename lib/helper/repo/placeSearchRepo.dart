import 'dart:convert';

import 'package:http/http.dart' as http;

/// One address or named place (a school, a park) offered while the parent types in New place.
class PlaceSuggestion {
  const PlaceSuggestion({required this.title, required this.detail, required this.lat, required this.lng});

  /// The place's name, or its street address when it has no name.
  final String title;

  /// The rest of the address: street (when [title] is a name), city, state, ZIP code, country.
  final String detail;
  final double lat;
  final double lng;

  /// What goes in the Address box once the parent picks it.
  String get label => detail.isEmpty ? title : "$title, $detail";

  /// Reads a Photon search response (GeoJSON). Features with no point or no name/street are skipped.
  static List<PlaceSuggestion> fromPhoton(Map<String, dynamic> json) {
    final out = <PlaceSuggestion>[];
    for (final feature in (json["features"] as List? ?? const [])) {
      final coords = (feature["geometry"]?["coordinates"] as List?)?.cast<num>();
      final p = (feature["properties"] as Map?)?.cast<String, dynamic>() ?? const {};
      if (coords == null || coords.length < 2) continue;
      String text(String key) => (p[key] as String? ?? "").trim();

      final street = [text("housenumber"), text("street")].where((s) => s.isNotEmpty).join(" ");
      final name = text("name");
      final title = name.isNotEmpty ? name : street;
      if (title.isEmpty) continue;
      final parts = <String>[];
      for (final part in [
        if (name.isNotEmpty) street,
        text("city").isNotEmpty ? text("city") : text("locality"),
        [text("state"), text("postcode")].where((s) => s.isNotEmpty).join(" "),
        text("country"),
      ]) {
        if (part.isNotEmpty && part != title && !parts.contains(part)) parts.add(part);
      }
      final s = PlaceSuggestion(title: title, detail: parts.join(", "), lat: coords[1].toDouble(), lng: coords[0].toDouble());
      // Photon can list one place twice (e.g. a building and its address).
      if (!out.any((o) => o.label == s.label)) out.add(s);
    }
    return out;
  }
}

/// Address suggestions while typing, from OpenStreetMap data through Photon (https://github.com/komoot/photon).
/// No key needed. The public server is for fair use only: callers wait for a pause in typing and need at
/// least 3 characters. Point [photonUrl] at our own Photon server before heavy use.
class PlaceSearchRepo {
  static const photonUrl = "https://photon.komoot.io/api/";
  static const minChars = 3;

  static Future<List<PlaceSuggestion>> suggest(String query, {double? nearLat, double? nearLng}) async {
    final q = query.trim();
    if (q.length < minChars) return const [];
    final uri = Uri.parse(photonUrl).replace(queryParameters: {
      "q": q,
      "limit": "5",
      "lang": "en",
      // Rank places near the child first.
      if (nearLat != null && nearLng != null) ...{"lat": "$nearLat", "lon": "$nearLng"},
    });
    try {
      final res = await http
          .get(uri, headers: {"User-Agent": "MoolahGuardian (Android/iOS parent app)"})
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return const [];
      return PlaceSuggestion.fromPhoton(jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
    } catch (_) {
      // Offline, slow or throttled: no suggestions; the search button still works.
      return const [];
    }
  }
}
