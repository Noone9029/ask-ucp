import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';

import '../../core/location/location_service.dart';
import 'osm_place.dart';
import 'overpass_service.dart';
import 'osrm_models.dart';
import 'osrm_service.dart';
import 'place_details_sheet.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const double _kHeaderHeight = 132;

  final MapController _mapController = MapController();
  final TextEditingController _search = TextEditingController();

  LatLng? _userLatLng;
  bool _locLoading = false;

  final Map<String, bool> _layers = {
    'Departments': true,
    'Labs': true,
    'Cafés': true,
    'Parking': true,
  };

  List<OsmPlace> _places = [];
  bool _loadingPlaces = true;
  String? _placesError;

  OsmPlace? _selectedPlace;
  OsrmRoute? _currentRoute;
  bool _routingLoading = false;
  String? _routingError;

  // ===================== UCP ONLY (Bounds) =====================
  // From your screenshots (tight campus-only rectangle)
  static const double _south = 31.4445;
  static const double _west = 74.2655;
  static const double _north = 31.4488;
  static const double _east = 74.2718;

  LatLngBounds get _ucpBounds => LatLngBounds(
        const LatLng(_south, _west), // SW
        const LatLng(_north, _east), // NE
      );

  List<LatLng> get _ucpRect => const [
        LatLng(_south, _west),
        LatLng(_south, _east),
        LatLng(_north, _east),
        LatLng(_north, _west),
      ];

  bool _isInsideUcp(LatLng p) {
    return p.latitude >= _south &&
        p.latitude <= _north &&
        p.longitude >= _west &&
        p.longitude <= _east;
  }

  @override
  void initState() {
    super.initState();
    _loadPlaces();

    // Lock initial view to campus bounds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: _ucpBounds,
          padding: const EdgeInsets.fromLTRB(30, 160, 30, 260),
        ),
      );
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _mapController.dispose(); // ✅ important to avoid red-screen assertions
    super.dispose();
  }

  Future<void> _loadPlaces() async {
    setState(() {
      _loadingPlaces = true;
      _placesError = null;
    });

    try {
      final data = await OverpassService.fetchUcpPlaces();
      if (!mounted) return;
      setState(() => _places = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _placesError = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _loadingPlaces = false);
    }
  }

  Future<void> _recenter() async {
    if (_locLoading) return;
    setState(() => _locLoading = true);

    try {
      final pos = await LocationService.currentPosition();
      if (!mounted) return;

      final ll = LatLng(pos.latitude, pos.longitude);
      setState(() => _userLatLng = ll);

      // Campus-only UX:
      // If user is inside campus -> center on them.
      // If outside -> keep campus bounds (do not show city).
      if (_isInsideUcp(ll)) {
        _mapController.move(ll, 18);
      } else {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: _ucpBounds,
            padding: const EdgeInsets.fromLTRB(30, 160, 30, 260),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are outside UCP. Map is locked to campus.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (!mounted) return;
      setState(() => _locLoading = false);
    }
  }

  void _openLayers() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Layers menu (coming next)')),
    );
  }

  void _flyToPlace(OsmPlace p) {
    // Only fly within campus bounds (safe)
    _mapController.move(LatLng(p.lat, p.lon), 19);
  }

  void _clearRoute() {
    setState(() {
      _currentRoute = null;
      _routingError = null;
    });
  }

  String _fmtDistance(double m) =>
      m >= 1000 ? '${(m / 1000).toStringAsFixed(2)} km' : '${m.toStringAsFixed(0)} m';

  String _fmtDuration(double s) {
    final mins = (s / 60).round();
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return '${h}h ${m}m';
  }

  bool _routeStaysInsideCampus(List<LatLng> pts) {
    for (final p in pts) {
      if (!_isInsideUcp(p)) return false;
    }
    return true;
  }

  Future<void> _navigateToPlace(OsmPlace place) async {
    if (_routingLoading) return;

    if (_userLatLng == null) {
      await _recenter();
      if (!mounted) return;
      if (_userLatLng == null) return;
    }

    // 🚫 Campus-only navigation
    if (!_isInsideUcp(_userLatLng!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Navigation works only inside UCP campus.')),
      );
      return;
    }

    setState(() {
      _routingLoading = true;
      _routingError = null;
      _selectedPlace = place;
      _currentRoute = null;
    });

    try {
      final route = await OsrmService.walkingRouteWithSteps(
        start: _userLatLng!,
        end: LatLng(place.lat, place.lon),
      );

      if (!mounted) return;

      // Optional safety: reject routes leaving campus
      if (!_routeStaysInsideCampus(route.points)) {
        setState(() => _routingError = 'Route goes outside campus.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Route goes outside campus. Try a different destination.')),
        );
        return;
      }

      setState(() => _currentRoute = route);

      final bounds = LatLngBounds.fromPoints(route.points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(40, 160, 40, 260),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Route: ${_fmtDistance(route.distanceMeters)} • ${_fmtDuration(route.durationSeconds)}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _routingError = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Routing failed: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _routingLoading = false);
    }
  }

  void _openPlaceSheet(OsmPlace place) {
    setState(() => _selectedPlace = place);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => PlaceDetailsSheet(
        place: place,
        route: (_selectedPlace?.id == place.id) ? _currentRoute : null,
        routingLoading: _routingLoading,
        onNavigate: () => _navigateToPlace(place),
        onClearRoute: _clearRoute,
      ),
    );
  }

  bool _chipMatch(OsmPlace p, Set<String> enabledChips) {
    if (p.type == 'Parking') return enabledChips.contains('Parking');
    if (p.type == 'Cafés') return enabledChips.contains('Cafés');

    if (p.type == 'Buildings' || p.type == 'Library' || p.type == 'Offices') {
      return enabledChips.contains('Departments') || enabledChips.contains('Labs');
    }

    return enabledChips.contains('Departments') || enabledChips.contains('Labs');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final topInset = MediaQuery.of(context).padding.top + _kHeaderHeight;

    final q = _search.text.trim().toLowerCase();
    final enabledChips = _layers.entries.where((e) => e.value).map((e) => e.key).toSet();

    final filtered = _places.where((p) {
      final matchesSearch = q.isEmpty || p.name.toLowerCase().contains(q);
      final matchesLayer = _chipMatch(p, enabledChips);
      return matchesSearch && matchesLayer;
    }).toList();

    return Scaffold(
      backgroundColor: cs.background,
      body: Stack(
        children: [
          _OsmMap(
            topInset: topInset,
            controller: _mapController,
            userLatLng: _userLatLng,
            places: filtered,
            route: _currentRoute,
            ucpBounds: _ucpBounds,
            ucpRect: _ucpRect,
            onMarkerTap: (p) {
              _flyToPlace(p);
              _openPlaceSheet(p);
            },
          ),

          // Header + Search
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: _GradientHeader(
              title: 'Campus Map',
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search building, lab, café…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: cs.surface.withOpacity(.85),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Chips
          Positioned(
            left: 0,
            right: 0,
            top: MediaQuery.of(context).padding.top + _kHeaderHeight - 12,
            child: Center(
              child: Material(
                elevation: 6,
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.surface.withOpacity(.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _layers.entries.map((e) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilterChip(
                            selected: e.value,
                            label: Text(e.key),
                            onSelected: (v) => setState(() => _layers[e.key] = v),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // FABs
          Positioned(
            right: 16,
            bottom: 180,
            child: Column(
              children: [
                _MapFab(
                  icon: _locLoading ? Icons.hourglass_top_rounded : Icons.my_location_rounded,
                  onTap: _locLoading ? () {} : () => _recenter(),
                ),
                const SizedBox(height: 10),
                _MapFab(icon: Icons.layers_rounded, onTap: _openLayers),
              ],
            ),
          ),

          // UCP watermark
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'UCP Campus Map',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),

          // Route bar
          if (_currentRoute != null || _routingError != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 140,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(14),
                color: cs.surface,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _routingError != null
                              ? 'Route error: $_routingError'
                              : 'Route • ${_fmtDistance(_currentRoute!.distanceMeters)} • ${_fmtDuration(_currentRoute!.durationSeconds)}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _clearRoute,
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Clear'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Places list
          DraggableScrollableSheet(
            initialChildSize: 0.24,
            minChildSize: 0.16,
            maxChildSize: 0.88,
            snap: true,
            builder: (context, controller) {
              return SafeArea(
                top: false,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 22,
                        spreadRadius: -6,
                        offset: const Offset(0, -6),
                        color: Colors.black.withOpacity(.25),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 8),
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: cs.outlineVariant,
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Row(
                          children: [
                            Text(
                              'Places',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const Spacer(),
                            if (_loadingPlaces)
                              Text('Loading...', style: Theme.of(context).textTheme.labelLarge)
                            else if (_placesError != null)
                              TextButton.icon(
                                onPressed: _loadPlaces,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              )
                            else
                              Text(
                                '${filtered.length}',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.primary),
                              ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: _loadingPlaces
                            ? const Center(child: CircularProgressIndicator())
                            : (_placesError != null)
                                ? Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(_placesError!, textAlign: TextAlign.center),
                                        const SizedBox(height: 12),
                                        FilledButton.icon(
                                          onPressed: _loadPlaces,
                                          icon: const Icon(Icons.refresh),
                                          label: const Text('Retry'),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    controller: controller,
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (_, i) {
                                      final p = filtered[i];
                                      return ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                        leading: CircleAvatar(
                                          radius: 20,
                                          backgroundColor: cs.primaryContainer,
                                          child: Icon(Icons.location_pin, color: cs.onPrimaryContainer),
                                        ),
                                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                        subtitle: Text(p.type),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.directions_walk_rounded),
                                          onPressed: () => _openPlaceSheet(p),
                                        ),
                                        onTap: () {
                                          _flyToPlace(p);
                                          _openPlaceSheet(p);
                                        },
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/* ======================== SUPPORT WIDGETS ======================== */

class _GradientHeader extends StatelessWidget {
  const _GradientHeader({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ],
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _MapFab extends StatelessWidget {
  const _MapFab({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.primary,
      elevation: 6,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 52, height: 52, child: Icon(icon, color: Colors.white)),
      ),
    );
  }
}

class _OsmMap extends StatelessWidget {
  const _OsmMap({
    required this.topInset,
    required this.controller,
    required this.userLatLng,
    required this.places,
    required this.route,
    required this.ucpBounds,
    required this.ucpRect,
    required this.onMarkerTap,
  });

  final double topInset;
  final MapController controller;
  final LatLng? userLatLng;
  final List<OsmPlace> places;
  final OsrmRoute? route;
  final LatLngBounds ucpBounds;
  final List<LatLng> ucpRect;
  final void Function(OsmPlace place) onMarkerTap;

  @override
  Widget build(BuildContext context) {
    const center = LatLng(31.446795, 74.268191);

    final markers = places.take(350).map((p) {
      return Marker(
        point: LatLng(p.lat, p.lon),
        width: 44,
        height: 44,
        child: GestureDetector(
          onTap: () => onMarkerTap(p),
          child: Icon(
            Icons.location_pin,
            size: 34,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      );
    }).toList();

    return Container(
      margin: EdgeInsets.only(top: topInset),
      child: FlutterMap(
        mapController: controller,
        options: MapOptions(
          initialCenter: center,
          initialZoom: 17,
          minZoom: 16,
          maxZoom: 20,

          // 🔒 Lock camera inside campus
          cameraConstraint: CameraConstraint.contain(
            bounds: ucpBounds,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.ask_ucp_flutter',
          ),

          // 🌑 Dark outside campus (mask with hole)
          PolygonLayer(
            polygons: [
              Polygon(
                points: const [
                  LatLng(-85, -180),
                  LatLng(-85, 180),
                  LatLng(85, 180),
                  LatLng(85, -180),
                ],
                holePointsList: [ucpRect],
                color: Colors.black.withOpacity(0.65),
                borderStrokeWidth: 0,
              ),
            ],
          ),

          // Outline campus boundary
          PolygonLayer(
            polygons: [
              Polygon(
                points: ucpRect,
                isFilled: false,
                borderStrokeWidth: 3,
                borderColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),

          if (route != null && route!.points.length > 1)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: route!.points,
                  strokeWidth: 5,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),

          MarkerClusterLayerWidget(
            options: MarkerClusterLayerOptions(
              markers: markers,
              maxClusterRadius: 45,
              size: const Size(44, 44),
              builder: (context, clusterMarkers) {
                return Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Text(
                    '${clusterMarkers.length}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                  ),
                );
              },
            ),
          ),

          if (userLatLng != null && _isPointInsideRect(userLatLng!, ucpBounds))
            MarkerLayer(
              markers: [
                Marker(
                  point: userLatLng!,
                  width: 22,
                  height: 22,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.primary,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 10,
                          color: Colors.black.withOpacity(.25),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // Local helper (so we don’t show user marker outside campus)
  bool _isPointInsideRect(LatLng p, LatLngBounds b) {
    return p.latitude >= b.southWest.latitude &&
        p.latitude <= b.northEast.latitude &&
        p.longitude >= b.southWest.longitude &&
        p.longitude <= b.northEast.longitude;
  }
}
