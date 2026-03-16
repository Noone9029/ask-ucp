import 'package:flutter/material.dart';
import 'osm_place.dart';
import 'osrm_models.dart';

class PlaceDetailsSheet extends StatelessWidget {
  const PlaceDetailsSheet({
    super.key,
    required this.place,
    required this.route,
    required this.onNavigate,
    required this.onClearRoute,
    required this.routingLoading,
  });

  final OsmPlace place;
  final OsrmRoute? route;
  final VoidCallback onNavigate;
  final VoidCallback onClearRoute;
  final bool routingLoading;

  String _fmtDistance(double m) => m >= 1000 ? '${(m / 1000).toStringAsFixed(2)} km' : '${m.toStringAsFixed(0)} m';

  String _fmtDuration(double s) {
    final mins = (s / 60).round();
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final tags = place.tags;
    final amenity = tags['amenity']?.toString();
    final building = tags['building']?.toString();
    final office = tags['office']?.toString();
    final shop = tags['shop']?.toString();
    final tourism = tags['tourism']?.toString();
    final leisure = tags['leisure']?.toString();

    final tagChips = <String>[
      if (place.type.isNotEmpty) place.type,
      if (amenity != null) 'amenity: $amenity',
      if (building != null) 'building: $building',
      if (office != null) 'office: $office',
      if (shop != null) 'shop: $shop',
      if (tourism != null) 'tourism: $tourism',
      if (leisure != null) 'leisure: $leisure',
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: cs.primaryContainer,
                child: Icon(Icons.place_rounded, color: cs.onPrimaryContainer),
              ),
              title: Text(place.name, style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text('OSM • ${place.id}'),
            ),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tagChips.take(8).map((t) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: cs.surfaceVariant,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Text(t, style: Theme.of(context).textTheme.labelMedium),
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: routingLoading ? null : onNavigate,
                    icon: routingLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.directions_walk_rounded),
                    label: const Text('Navigate'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: route == null ? null : onClearRoute,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Clear Route'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            if (route != null) ...[
              Text(
                'Directions • ${_fmtDistance(route!.distanceMeters)} • ${_fmtDuration(route!.durationSeconds)}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),

              SizedBox(
                height: 260,
                child: ListView.separated(
                  itemCount: route!.steps.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final s = route!.steps[i];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: cs.primaryContainer,
                        child: Text('${i + 1}', style: TextStyle(color: cs.onPrimaryContainer, fontSize: 12, fontWeight: FontWeight.w800)),
                      ),
                      title: Text(s.instruction),
                      subtitle: Text('${_fmtDistance(s.distanceMeters)} • ${_fmtDuration(s.durationSeconds)}'),
                    );
                  },
                ),
              ),
            ] else
              Text(
                'Tip: Tap “Navigate” to draw a walking route and show directions.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}
