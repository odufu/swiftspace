import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:swiftspace/core/constants/app_constants.dart';
import 'package:swiftspace/core/services/audio_manager.dart';
import 'package:swiftspace/core/di/injection_container.dart';

class LocationPickerComponent extends StatefulWidget {
  final LatLng initialLocation;
  final Function(LatLng) onLocationChanged;

  const LocationPickerComponent({
    super.key,
    required this.initialLocation,
    required this.onLocationChanged,
  });

  @override
  State<LocationPickerComponent> createState() => _LocationPickerComponentState();
}

class _LocationPickerComponentState extends State<LocationPickerComponent> {
  late MapController _mapController;
  late LatLng _currentLocation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentLocation = widget.initialLocation;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pin Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        const Text('Drag the map to position the pin exactly on the property location.', style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 16),
        Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLocation,
                    initialZoom: 15,
                    onPositionChanged: (position, hasGesture) {
                      if (hasGesture && position.center != null) {
                        setState(() {
                          _currentLocation = position.center!;
                        });
                        widget.onLocationChanged(_currentLocation);
                      }
                    },
                    onMapEvent: (event) {
                      if (event is MapEventMoveEnd) {
                        sl<AudioManager>().triggerHaptic(context);
                      }
                    },
                  ),
                    children: [
                      if (isDark)
                        ColorFiltered(
                          colorFilter: const ColorFilter.matrix([
                            -1.0, 0.0, 0.0, 0.0, 255.0,
                            0.0, -1.0, 0.0, 0.0, 255.0,
                            0.0, 0.0, -1.0, 0.0, 255.0,
                            0.0, 0.0, 0.0, 1.0, 0.0,
                          ]),
                          child: TileLayer(
                            urlTemplate: AppConstants.mapUrlStandard,
                            userAgentPackageName: 'com.swiftspace.app',
                          ),
                        )
                      else
                        TileLayer(
                          urlTemplate: AppConstants.mapUrlStandard,
                          userAgentPackageName: 'com.swiftspace.app',
                        ),
                    ],
                ),
                // Static Center Pin
                IgnorePointer(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 35),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
                            child: const Text('PROPERTY LOCATION', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                          ),
                          Icon(LucideIcons.mapPin, color: AppColors.primaryLight, size: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
           children: [
              _buildCoordField('Latitude', _currentLocation.latitude.toStringAsFixed(6)),
              const SizedBox(width: 12),
              _buildCoordField('Longitude', _currentLocation.longitude.toStringAsFixed(6)),
           ],
        ),
      ],
    );
  }

  Widget _buildCoordField(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
