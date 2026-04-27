import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:swiftspace/core/constants/app_constants.dart';
import 'package:swiftspace/core/services/audio_manager.dart';
import 'package:swiftspace/core/di/injection_container.dart';
import 'package:swiftspace/core/utils/ui_utils.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

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
  final _urlController = TextEditingController();
  bool _isDetecting = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentLocation = widget.initialLocation;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    setState(() => _isDetecting = true);
    sl<AudioManager>().playClick(context);

    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) UiUtils.showError(context, 'Location services are disabled.');
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) UiUtils.showError(context, 'Location permissions are denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) UiUtils.showError(context, 'Location permissions are permanently denied.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      final newLoc = LatLng(position.latitude, position.longitude);
      
      _updateLocation(newLoc);
      _mapController.move(newLoc, 16);
      
      if (mounted) UiUtils.showSuccess(context, 'Location detected successfully!');
    } catch (e) {
      if (mounted) UiUtils.showError(context, 'Failed to detect location: $e');
    } finally {
      if (mounted) setState(() => _isDetecting = false);
    }
  }

  Future<void> _parseAndSetUrl(String value) async {
    if (value.isEmpty) return;

    // Pattern to look for lat,lng in various Google Maps formats
    final latLngPattern = RegExp(r'([-+]?\d+\.\d+),\s?([-+]?\d+\.\d+)');
    var match = latLngPattern.firstMatch(value);

    // If no direct coordinate match but it's a maps link (shortened), resolve it
    if (match == null && (value.contains('goo.gl') || value.contains('google.com/maps'))) {
      setState(() => _isDetecting = true);
      try {
        var currentUrl = value;
        int redirects = 0;
        
        while (redirects < 3) {
          final uri = Uri.tryParse(currentUrl);
          if (uri == null) break;

          // We use GET and don't follow redirects automatically so we can read the location header
          final request = http.Request('GET', uri)..followRedirects = false;
          final response = await http.Client().send(request).timeout(const Duration(seconds: 10));
          
          final locationHeader = response.headers['location'];
          if (locationHeader != null) {
            currentUrl = locationHeader;
            match = latLngPattern.firstMatch(currentUrl);
            if (match != null) break; // Found coordinates!
            redirects++;
          } else {
            break; // No more redirects
          }
        }
      } catch (e) {
        debugPrint('URL Resolution Error: $e');
        if (mounted) {
           UiUtils.showError(context, 'Could not automatically resolve this link. Please enter coordinates manually.');
        }
        return;
      } finally {
        if (mounted) setState(() => _isDetecting = false);
      }
    }

    if (match != null) {
      final lat = double.tryParse(match.group(1)!);
      final lng = double.tryParse(match.group(2)!);

      if (lat != null && lng != null) {
        final newLoc = LatLng(lat, lng);
        _updateLocation(newLoc);
        _mapController.move(newLoc, 16);
        sl<AudioManager>().playSuccess(context);
        UiUtils.showSuccess(context, 'Coordinates extracted from link!');
        _urlController.clear();
        FocusScope.of(context).unfocus();
        return;
      }
    } 
    
    if (mounted) {
      UiUtils.showError(context, 'Could not extract valid coordinates (lat/lng) from this link.');
    }
  }

  void _updateLocation(LatLng loc) {
    setState(() {
      _currentLocation = loc;
    });
    widget.onLocationChanged(loc);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Integrity Warning Banner
        _buildIntegrityWarning(theme),
        const SizedBox(height: 24),

        const Text('Precise Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        const Text('Use one of the methods below to pin the exact property location. Accuracy is mandatory.', style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 24),

        // Method 1: URL Entry
        TextField(
          controller: _urlController,
          decoration: InputDecoration(
            labelText: 'Paste Google Maps Link',
            hintText: 'https://www.google.com/maps/...',
            prefixIcon: const Icon(LucideIcons.link),
            suffixIcon: IconButton(
              icon: const Icon(LucideIcons.arrowRight),
              onPressed: () => _parseAndSetUrl(_urlController.text),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: _parseAndSetUrl,
        ),
        const SizedBox(height: 16),

        // Method 2: Auto-detect
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isDetecting ? null : _detectLocation,
            icon: _isDetecting 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(LucideIcons.locateFixed),
            label: Text(_isDetecting ? 'DETECTING...' : 'USE MY CURRENT LOCATION'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Visual Confirmation Map
        Stack(
          children: [
            Container(
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLocation,
                    initialZoom: 15,
                    onPositionChanged: (position, hasGesture) {
                      if (hasGesture && position.center != null) {
                        _updateLocation(position.center!);
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
              ),
            ),
            // Static Center Pin
            IgnorePointer(
              child: SizedBox(
                height: 300,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 35),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
                          child: const Text('PIN POSITION', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                        Icon(LucideIcons.mapPin, color: AppColors.primaryLight, size: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
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

  Widget _buildIntegrityWarning(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.shieldAlert, color: AppColors.error, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Integrity & Compliance',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Providing an incorrect or random location is a violation of operation guidelines. Listings found with fraudulent coordinates will be flagged and removed.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[800], height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
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
