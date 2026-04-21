import 'package:flutter/material.dart';
import 'package:panorama_viewer/panorama_viewer.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:swiftspace/features/property/domain/entities/property.dart';
import 'package:swiftspace/features/property/domain/entities/virtual_tour.dart';
import 'package:swiftspace/core/constants/app_constants.dart';
import 'package:swiftspace/core/utils/ui_utils.dart';

class TourMapperScreen extends StatefulWidget {
  final Property property;
  final VirtualTour? initialTour;

  const TourMapperScreen({
    super.key,
    required this.property,
    this.initialTour,
  });

  @override
  State<TourMapperScreen> createState() => _TourMapperScreenState();
}

class _TourMapperScreenState extends State<TourMapperScreen> {
  late VirtualTour _currentTour;
  String? _selectedNodeId;
  bool _isMapperMode = true; // True if we are placing hotspots

  @override
  void initState() {
    super.initState();
    // Initialize tour from property or create a new one based on imagesGallery
    if (widget.initialTour != null) {
      _currentTour = widget.initialTour!;
      _selectedNodeId = _currentTour.startNodeId;
    } else {
      // Create a default tour nodes from the property's gallery
      // For this prototype, we'll assume the gallery contains 360 photos
      final Map<String, TourNode> nodes = {};
      String? firstId;
      
      for (int i = 0; i < widget.property.imagesGallery.length; i++) {
        final id = 'node_${i + 1}';
        if (i == 0) firstId = id;
        
        nodes[id] = TourNode(
          id: id,
          panoramaUrl: widget.property.imagesGallery[i],
          name: 'Station ${i + 1}',
          hotspots: [],
        );
      }
      
      _currentTour = VirtualTour(
        nodes: nodes,
        startNodeId: firstId ?? '',
      );
      _selectedNodeId = firstId;
    }
  }

  void _addHotspot(double longitude, double latitude) {
    if (_selectedNodeId == null) return;

    // Show dialog to choose destination node
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Link to Room',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Select where this portal leads to:'),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: ListView(
                  children: _currentTour.nodes.values
                      .where((node) => node.id != _selectedNodeId)
                      .map((node) {
                    return ListTile(
                      leading: const Icon(LucideIcons.image),
                      title: Text(node.name),
                      trailing: const Icon(LucideIcons.chevronRight),
                      onTap: () {
                        Navigator.pop(context);
                        _saveHotspot(longitude, latitude, node.id);
                      },
                    );
                  }).toList(),
                ),
              ),
              if (_currentTour.nodes.length <= 1)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Add more 360 photos to create links.'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _saveHotspot(double longitude, double latitude, String targetNodeId) {
    setState(() {
      final currentNode = _currentTour.nodes[_selectedNodeId]!;
      final newHotspot = TourHotspot(
        latitude: latitude,
        longitude: longitude,
        targetNodeId: targetNodeId,
        label: 'To ${_currentTour.nodes[targetNodeId]?.name}',
      );
      
      final updatedHotspots = List<TourHotspot>.from(currentNode.hotspots)..add(newHotspot);
      
      _currentTour.nodes[_selectedNodeId!] = TourNode(
        id: currentNode.id,
        panoramaUrl: currentNode.panoramaUrl,
        name: currentNode.name,
        hotspots: updatedHotspots,
      );
    });
    
    UiUtils.showSuccess(context, 'Portal placed successfully');
  }

  void _removeHotspot(TourHotspot hotspot) {
    setState(() {
      final currentNode = _currentTour.nodes[_selectedNodeId]!;
      final updatedHotspots = List<TourHotspot>.from(currentNode.hotspots)..remove(hotspot);
      
      _currentTour.nodes[_selectedNodeId!] = TourNode(
        id: currentNode.id,
        panoramaUrl: currentNode.panoramaUrl,
        name: currentNode.name,
        hotspots: updatedHotspots,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentNode = _currentTour.nodes[_selectedNodeId];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: CircleAvatar(
          backgroundColor: Colors.black.withValues(alpha: 0.5),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            currentNode?.name ?? 'Mapper',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context, _currentTour);
            },
            icon: const Icon(LucideIcons.check, color: Colors.white),
            label: const Text('Save Tour', style: TextStyle(color: Colors.white)),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          if (currentNode != null)
            PanoramaViewer(
              key: ValueKey(currentNode.id),
              onTap: (lon, lat, global) {
                if (_isMapperMode) _addHotspot(lon, lat);
              },
              hotspots: currentNode.hotspots.map((h) {
                return Hotspot(
                  latitude: h.latitude,
                  longitude: h.longitude,
                  width: 60.0,
                  height: 60.0,
                  widget: _buildHotspotMarker(h),
                );
              }).toList(),
              child: Image.network(currentNode.panoramaUrl),
            ),
          
          // Mapper Overlay HUD
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Mode Toggle
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildModeButton(
                        label: 'Stamp Mode',
                        icon: LucideIcons.plusCircle,
                        isActive: _isMapperMode,
                        onTap: () => setState(() => _isMapperMode = true),
                      ),
                      _buildModeButton(
                        label: 'Preview Mode',
                        icon: LucideIcons.playCircle,
                        isActive: !_isMapperMode,
                        onTap: () => setState(() => _isMapperMode = false),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Node Selector (Drawer for stations)
                Container(
                  height: 100,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _currentTour.nodes.values.map((node) {
                      final isSelected = node.id == _selectedNodeId;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedNodeId = node.id),
                        child: Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryLight : Colors.transparent,
                              width: 2,
                            ),
                            image: DecorationImage(
                              image: NetworkImage(node.panoramaUrl),
                              fit: BoxFit.cover,
                              colorFilter: isSelected ? null : ColorFilter.mode(Colors.black.withValues(alpha: 0.5), BlendMode.darken),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              node.name.split(' ').last,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          if (_isMapperMode)
            const Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: IgnorePointer(
                child: Center(
                  child: Column(
                    children: [
                      Icon(LucideIcons.mousePointer, color: Colors.white, size: 32),
                      SizedBox(height: 8),
                      Text(
                        'Tap anywhere to place a portal',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 4, color: Colors.black)]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHotspotMarker(TourHotspot hotspot) {
    return GestureDetector(
      onTap: () {
        if (!_isMapperMode) {
          setState(() {
             _selectedNodeId = hotspot.targetNodeId;
          });
        }
      },
      onLongPress: () {
        if (_isMapperMode) {
          _removeHotspot(hotspot);
          UiUtils.showInfo(context, 'Portal removed');
        }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.8),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4),
              ],
            ),
            child: Icon(
              _isMapperMode ? LucideIcons.trash2 : LucideIcons.moveUp,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              hotspot.label,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
