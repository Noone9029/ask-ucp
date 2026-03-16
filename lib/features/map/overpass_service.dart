import 'dart:convert';
import 'package:http/http.dart' as http;
import 'osm_place.dart';

class OverpassService {
  // If this endpoint is down, swap with:
  // https://overpass.kumi.systems/api/interpreter
  // https://overpass.nchc.org.tw/api/interpreter
  static const String _endpoint = 'https://overpass-api.de/api/interpreter';

  // UCP bounding box (approx) — tweak if you want bigger/smaller coverage.
  // south, west, north, east
  static const String _bbox = '31.4445,74.2655,31.4488,74.2718';

  static Future<List<OsmPlace>> fetchUcpPlaces() async {
    final query = '''
[out:json][timeout:25];
(
  // Buildings
  way["building"]($_bbox);
  relation["building"]($_bbox);

  // Amenities / POIs
  node["amenity"]($_bbox);
  way["amenity"]($_bbox);
  relation["amenity"]($_bbox);

  // Parking
  node["amenity"="parking"]($_bbox);
  way["amenity"="parking"]($_bbox);
  relation["amenity"="parking"]($_bbox);

  // Offices / shops
  node["office"]($_bbox);
  way["office"]($_bbox);
  relation["office"]($_bbox);

  node["shop"]($_bbox);
  way["shop"]($_bbox);
  relation["shop"]($_bbox);

  // Leisure / tourism (sports, parks, etc.)
  node["leisure"]($_bbox);
  way["leisure"]($_bbox);
  relation["leisure"]($_bbox);

  node["tourism"]($_bbox);
  way["tourism"]($_bbox);
  relation["tourism"]($_bbox);
);
out tags center;
''';

    final res = await http.post(
      Uri.parse(_endpoint),
      headers: {'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'},
      body: {'data': query},
    );

    if (res.statusCode != 200) {
      throw Exception('Overpass error: ${res.statusCode} ${res.reasonPhrase}');
    }

    final jsonMap = jsonDecode(res.body) as Map<String, dynamic>;
    final elements = (jsonMap['elements'] as List).cast<Map<String, dynamic>>();

    final places = <OsmPlace>[];

    for (final el in elements) {
      final tags = (el['tags'] as Map?)?.cast<String, dynamic>() ?? {};
      final name = _bestName(tags);
      if (name.isEmpty) continue;

      // node: lat/lon directly; way/relation: use "center"
      final lat = (el['lat'] ?? el['center']?['lat']) as num?;
      final lon = (el['lon'] ?? el['center']?['lon']) as num?;
      if (lat == null || lon == null) continue;

      places.add(
        OsmPlace(
          id: '${el['type']}/${el['id']}',
          name: name,
          type: _classify(tags),
          lat: lat.toDouble(),
          lon: lon.toDouble(),
          tags: tags,
        ),
      );
    }

    // Sort alphabetically
    places.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return places;
  }

  static String _bestName(Map<String, dynamic> tags) {
    return (tags['name:en'] ?? tags['name'] ?? '').toString().trim();
  }

  static String _classify(Map<String, dynamic> tags) {
    final amenity = tags['amenity']?.toString();
    final building = tags['building']?.toString();
    final office = tags['office']?.toString();
    final shop = tags['shop']?.toString();
    final leisure = tags['leisure']?.toString();

    if (amenity == 'parking') return 'Parking';
    if (amenity == 'cafe' || amenity == 'restaurant' || amenity == 'fast_food') return 'Cafés';
    if (amenity == 'library') return 'Library';
    if (office != null) return 'Offices';
    if (shop != null) return 'Shop';
    if (leisure != null) return 'Leisure';
    if (building != null) return 'Buildings';

    return 'Other';
  }
}
