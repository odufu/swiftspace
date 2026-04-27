import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:swiftspace/core/di/injection_container.dart';
import 'package:swiftspace/core/services/map_service.dart';
import 'package:swiftspace/features/property/domain/entities/property.dart';
import 'package:provider/provider.dart';
import 'package:swiftspace/core/theme/theme_provider.dart';

class GeoFenceMapperScreen extends StatefulWidget {
  final Property property;

  const GeoFenceMapperScreen({super.key, required this.property});

  @override
  State<GeoFenceMapperScreen> createState() => _GeoFenceMapperScreenState();
}

class _GeoFenceMapperScreenState extends State<GeoFenceMapperScreen> {
  late MapController _mapController;
  List<LatLng> _points = [];
  bool _isSatelliteMode = true; // Default to satellite for drawing boundaries

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    if (widget.property.geoFencePoints != null) {
      _points = List.from(widget.property.geoFencePoints!);
    }
  }

  void _handleTap(TapPosition tapPosition, LatLng latlng) {
    setState(() {
      _points.add(latlng);
    });
  }

  void _undoLastPoint() {
    if (_points.isNotEmpty) {
      setState(() {
        _points.removeLast();
      });
    }
  }

  void _clearAllPoints() {
    setState(() {
      _points.clear();
    });
  }

  void _saveGeoFence() {
    if (_points.length < 3 && _points.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A geo-fence must have at least 3 points or be empty.')),
      );
      return;
    }
    Navigator.pop(context, _points);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    List<Polygon> polygons = [];
    List<Polyline> polylines = [];
    List<Marker> markers = [];

    // Always render lines between points for clarity
    if (_points.isNotEmpty) {
      polylines.add(
        Polyline(
          points: _points.length > 2 ? [..._points, _points.first] : _points,
          color: theme.colorScheme.primary,
          strokeWidth: 4.0,
        ),
      );
      
      // Render filled polygon if we have at least 3 points
      if (_points.length > 2) {
        polygons.add(
          Polygon(
            points: _points,
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            borderColor: theme.colorScheme.primary,
            borderStrokeWidth: 0, // Handled by Polyline
          ),
        );
      }

      // Render dots at each vertex
      for (var i = 0; i < _points.length; i++) {
        markers.add(
          Marker(
            point: _points[i],
            width: 16,
            height: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.primary, width: 4),
              ),
            ),
          ),
        );
      }
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Map Property Boundary'),
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: _saveGeoFence,
            icon: const Icon(LucideIcons.check, color: Colors.greenAccent),
            label: const Text(
              'Save',
              style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.property.location,
              initialZoom: 18.0,
              onTap: _handleTap,
            ),
            children: [
              sl<IMapService>().getTileLayer(
                isDark: isDark,
                isSatellite: _isSatelliteMode,
              ),
              if (polygons.isNotEmpty) PolygonLayer(polygons: polygons),
              if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
              if (markers.isNotEmpty) MarkerLayer(markers: markers),
            ],
          ),

          // Map Control Buttons
          Positioned(
            right: 16,
            top: 100, // Below AppBar
            child: Column(
              children: [
                _buildFloatingButton(
                  icon: _isSatelliteMode ? LucideIcons.map : LucideIcons.layers,
                  theme: theme,
                  onPressed: () {
                    setState(() {
                      _isSatelliteMode = !_isSatelliteMode;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildFloatingButton(
                  icon: LucideIcons.undo2,
                  theme: theme,
                  onPressed: _undoLastPoint,
                ),
                const SizedBox(height: 8),
                _buildFloatingButton(
                  icon: LucideIcons.trash2,
                  theme: theme,
                  onPressed: _clearAllPoints,
                  color: Colors.redAccent,
                ),
              ],
            ),
          ),

          // Instructions overlay
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.info, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tap on the map corners to set the land boundaries. Connect points to close the fence.',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required ThemeData theme,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return FloatingActionButton(
      heroTag: null,
      mini: true,
      backgroundColor: theme.colorScheme.surface,
      onPressed: onPressed,
      child: Icon(icon, color: color ?? theme.colorScheme.onSurface),
    );
  }
}
