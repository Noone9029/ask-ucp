class OsmPlace {
  final String id; // e.g. "node/123" or "way/456"
  final String name;
  final String type; // Parking, Cafés, Buildings, Library, Offices, etc.
  final double lat;
  final double lon;
  final Map<String, dynamic> tags;

  const OsmPlace({
    required this.id,
    required this.name,
    required this.type,
    required this.lat,
    required this.lon,
    required this.tags,
  });
}
