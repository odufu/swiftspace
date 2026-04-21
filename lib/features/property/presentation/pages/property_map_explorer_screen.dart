import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:swiftspace/core/di/injection_container.dart';
import 'package:swiftspace/core/services/map_service.dart';
import 'package:swiftspace/features/explore/presentation/widgets/custom_marker.dart';
import 'package:swiftspace/features/property/domain/entities/property.dart';
import 'package:provider/provider.dart';
import 'package:swiftspace/core/theme/theme_provider.dart';

class PropertyMapExplorerScreen extends StatefulWidget {
  final Property property;

  const PropertyMapExplorerScreen({super.key, required this.property});

  @override
  State<PropertyMapExplorerScreen> createState() => _PropertyMapExplorerScreenState();
}

class _PropertyMapExplorerScreenState extends State<PropertyMapExplorerScreen> {
  late MapController _mapController;
  bool _isSatelliteMode = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    List<Marker> markers = [
      Marker(
        point: widget.property.location,
        width: 150,
        height: 100,
        alignment: Alignment.topCenter,
        child: CustomMarkerWidget(
          property: widget.property,
          isSelected: true,
          isBestOffer: false,
        ),
      ),
    ];

    List<Polygon> polygons = [];
    if (widget.property.type == PropertyType.lands &&
        widget.property.geoFencePoints != null &&
        widget.property.geoFencePoints!.isNotEmpty) {
      polygons.add(
        Polygon(
          points: widget.property.geoFencePoints!,
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          borderColor: theme.colorScheme.primary,
          borderStrokeWidth: 3,
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: theme.colorScheme.surface,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.property.location,
              initialZoom: 16.0,
            ),
            children: [
              sl<IMapService>().getTileLayer(
                isDark: isDark,
                isSatellite: _isSatelliteMode,
              ),
              if (polygons.isNotEmpty) PolygonLayer(polygons: polygons),
              MarkerLayer(markers: markers),
            ],
          ),
          
          // Map Type Toggle
          Positioned(
            top: 100,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'prop_map_type_toggle',
              mini: true,
              backgroundColor: theme.colorScheme.surface,
              onPressed: () {
                setState(() {
                  _isSatelliteMode = !_isSatelliteMode;
                });
              },
              child: Icon(
                _isSatelliteMode ? LucideIcons.map : LucideIcons.layers,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
