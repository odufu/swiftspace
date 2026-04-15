import 'package:flutter/material.dart';
import 'dart:math' as math;

/// VPN-style glowing dot marker for a property on the map.
/// Default: small glowing circle. Selected: large pulsing rings + tooltip.
/// Best Offer: hot-pink neon rings.
class PropertyDotMarker extends StatefulWidget {
  final Color color;
  final bool isSelected;
  final bool isBestOffer;
  final bool isForSale;
  final String formattedPrice;

  final VoidCallback onTap;

  const PropertyDotMarker({
    super.key,
    required this.color,
    required this.formattedPrice,

    required this.onTap,
    this.isSelected = false,
    this.isBestOffer = false,
    this.isForSale = false,
  });

  @override
  State<PropertyDotMarker> createState() => _PropertyDotMarkerState();
}

class _PropertyDotMarkerState extends State<PropertyDotMarker>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _pulseCtrl2;
  late final AnimationController _selectCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulseCtrl2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _selectCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _updateAnimations();
  }

  void _updateAnimations() {
    final shouldPulse = widget.isSelected || widget.isBestOffer || widget.isForSale;
    if (shouldPulse) {
      _pulseCtrl.repeat();
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _pulseCtrl2.repeat();
      });
      _selectCtrl.forward();
    } else {
      _pulseCtrl.stop();
      _pulseCtrl.reset();
      _pulseCtrl2.stop();
      _pulseCtrl2.reset();
      _selectCtrl.reverse();
    }
  }

  @override
  void didUpdateWidget(PropertyDotMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected ||
        widget.isBestOffer != oldWidget.isBestOffer) {
      _updateAnimations();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _pulseCtrl2.dispose();
    _selectCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isBestOffer ? const Color(0xFFFF2A5F) : widget.color;

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 80,
        height: 80,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulse ring 1
            if (widget.isSelected || widget.isBestOffer || widget.isForSale)
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (ctx, _) {
                  return _PulseRing(
                    progress: _pulseCtrl.value,
                    color: color,
                    maxRadius: 48, // Made larger to be very obvious
                  );
                },
              ),
            // Outer pulse ring 2 (delayed, offset phase)
            if (widget.isSelected || widget.isBestOffer || widget.isForSale)
              AnimatedBuilder(
                animation: _pulseCtrl2,
                builder: (ctx, _) {
                  return _PulseRing(
                    progress: _pulseCtrl2.value,
                    color: color,
                    maxRadius: 48, // Made larger
                  );
                },
              ),

            // Core dot
            AnimatedBuilder(
              animation: _selectCtrl,
              builder: (ctx, _) {
                final scale = 1.0 + _selectCtrl.value * 0.5;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: widget.isSelected || widget.isBestOffer || widget.isForSale ? 14 : 10,
                    height: widget.isSelected || widget.isBestOffer || widget.isForSale ? 14 : 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.9),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.6),
                          blurRadius: widget.isSelected ? 12 : 6,
                          spreadRadius: widget.isSelected ? 2 : 0,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Best offer sparkle badge
            if (widget.isBestOffer)
              Positioned(
                top: 14,
                right: 10,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.amberAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(Icons.star, size: 10, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  final double progress;
  final Color color;
  final double maxRadius;

  const _PulseRing({
    required this.progress,
    required this.color,
    required this.maxRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = maxRadius * progress;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: opacity * 0.6),
          width: 1.5,
        ),
      ),
    );
  }
}

/// Cluster marker — shows count of grouped properties.
class ClusterMarker extends StatefulWidget {
  final int count;
  final Color color;
  final VoidCallback onTap;

  const ClusterMarker({
    super.key,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  State<ClusterMarker> createState() => _ClusterMarkerState();
}

class _ClusterMarkerState extends State<ClusterMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathCtrl;

  @override
  void initState() {
    super.initState();
    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.count < 10
        ? 36.0
        : widget.count < 50
            ? 42.0
            : 52.0;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _breathCtrl,
        builder: (ctx, _) {
          final glow = 0.3 + _breathCtrl.value * 0.3;
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: 0.15),
              border: Border.all(
                color: widget.color.withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: glow),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.count > 99 ? '99+' : '${widget.count}',
                style: TextStyle(
                  color: widget.color,
                  fontWeight: FontWeight.bold,
                  fontSize: size * 0.3,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Calculates simple clustering of properties by proximity.
/// Returns list of clusters: each with a representative LatLng and count.
class MapCluster {
  final double lat;
  final double lng;
  final List<int> indices; // property indices
  const MapCluster(this.lat, this.lng, this.indices);
}

List<MapCluster> clusterProperties(
  List<Map<String, dynamic>> points, // [{lat, lng, index}]
  double zoomLevel,
) {
  // Adjust radius by zoom level — further out = bigger cluster radius
  final double radiusDeg = zoomLevel < 11
      ? 0.5
      : zoomLevel < 13
          ? 0.15
          : zoomLevel < 15
              ? 0.05
              : 0.01;

  final visited = <int>{};
  final clusters = <MapCluster>[];

  for (int i = 0; i < points.length; i++) {
    if (visited.contains(i)) continue;
    visited.add(i);

    final lat = points[i]['lat'] as double;
    final lng = points[i]['lng'] as double;
    final nearby = [i];

    for (int j = i + 1; j < points.length; j++) {
      if (visited.contains(j)) continue;
      final dlat = (points[j]['lat'] as double) - lat;
      final dlng = (points[j]['lng'] as double) - lng;
      final dist = math.sqrt(dlat * dlat + dlng * dlng);
      if (dist < radiusDeg) {
        nearby.add(j);
        visited.add(j);
      }
    }

    // Centroid of cluster
    final avgLat =
        nearby.map((k) => points[k]['lat'] as double).reduce((a, b) => a + b) /
            nearby.length;
    final avgLng =
        nearby.map((k) => points[k]['lng'] as double).reduce((a, b) => a + b) /
            nearby.length;
    clusters.add(MapCluster(avgLat, avgLng, nearby.map((k) => points[k]['index'] as int).toList()));
  }

  return clusters;
}
