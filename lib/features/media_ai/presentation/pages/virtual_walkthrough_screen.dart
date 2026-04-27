import 'package:flutter/material.dart';
import 'package:panorama_viewer/panorama_viewer.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:swiftspace/core/services/audio_manager.dart';
import 'package:swiftspace/core/di/injection_container.dart';
import 'package:swiftspace/features/property/domain/entities/property.dart';
import 'package:swiftspace/features/property/domain/entities/virtual_tour.dart';

class VirtualWalkthroughScreen extends StatefulWidget {
  final Property? property;
  final VirtualTour? customTour;

  const VirtualWalkthroughScreen({
    super.key,
    this.property,
    this.customTour,
  });

  @override
  State<VirtualWalkthroughScreen> createState() => _VirtualWalkthroughScreenState();
}

class _VirtualWalkthroughScreenState extends State<VirtualWalkthroughScreen> {
  late VirtualTour _tour;
  String? _currentNodeId;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    _initializeTour();
  }

  void _initializeTour() {
    if (widget.customTour != null) {
      _tour = widget.customTour!;
    } else if (widget.property?.virtualTour != null) {
      _tour = widget.property!.virtualTour!;
    } else {
      // Fallback/Demo data if no tour exists
      _tour = _getDemoTour();
    }
    _currentNodeId = _tour.startNodeId;
  }

  VirtualTour _getDemoTour() {
    return VirtualTour(
      nodes: {
        'entrance': TourNode(
          id: 'entrance',
          name: 'Main Entrance',
          panoramaUrl: 'https://raw.githubusercontent.com/mchome/panorama_viewer/master/example/assets/panorama.jpg',
          hotspots: [
            TourHotspot(latitude: 0, longitude: 0, targetNodeId: 'living', label: 'Enter Hall'),
          ],
        ),
        'living': TourNode(
          id: 'living',
          name: 'Grand Living Room',
          panoramaUrl: 'https://raw.githubusercontent.com/mchome/panorama_viewer/master/example/assets/panorama2.jpg',
          hotspots: [
            TourHotspot(latitude: 0, longitude: 180, targetNodeId: 'entrance', label: 'Back to Door'),
          ],
        ),
      },
      startNodeId: 'entrance',
    );
  }

  void _moveToNode(String nodeId) {
    if (_isTransitioning) return;
    
    setState(() => _isTransitioning = true);
    
    sl<AudioManager>().playSwipe(context);
    sl<AudioManager>().triggerHaptic(context);

    // Short delay for transition feel
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _currentNodeId = nodeId;
          _isTransitioning = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentNode = _tour.nodes[_currentNodeId];

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('3D Virtual Walkthrough', style: TextStyle(color: Colors.white, fontSize: 12)),
            Text(currentNode?.name ?? 'Loading...', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          if (currentNode != null)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: _isTransitioning ? 0.0 : 1.0,
              child: PanoramaViewer(
                key: ValueKey(currentNode.id),
                animSpeed: 0.1,
                sensorControl: SensorControl.orientation,
                hotspots: currentNode.hotspots.map((h) {
                  return Hotspot(
                    latitude: h.latitude,
                    longitude: h.longitude,
                    width: 60,
                    height: 60,
                    widget: _buildHotspotMarker(h),
                  );
                }).toList(),
                child: Image.network(currentNode.panoramaUrl),
              ),
            ),

          if (_isTransitioning)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            
          // HUD indicators
          Positioned(
            bottom: 30,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                   const Icon(LucideIcons.compass, color: Colors.white, size: 16),
                   const SizedBox(width: 8),
                   Text(
                     'Drag to look around',
                     style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                   ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotspotMarker(TourHotspot hotspot) {
    return GestureDetector(
      onTap: () => _moveToNode(hotspot.targetNodeId),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                 BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
              ],
            ),
            child: const Icon(LucideIcons.chevronUp, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          Container(
             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
             decoration: BoxDecoration(
               color: Colors.black.withValues(alpha: 0.6),
               borderRadius: BorderRadius.circular(4),
             ),
             child: Text(
               hotspot.label,
               style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
             ),
          ),
        ],
      ),
    );
  }
}
