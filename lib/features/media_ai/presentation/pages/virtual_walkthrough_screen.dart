import 'package:flutter/material.dart';
import 'package:panorama_viewer/panorama_viewer.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:swiftspace/core/services/audio_manager.dart';

class WalkthroughNode {
  final String id;
  final String name;
  final String panoramaUrl;
  final Map<String, String> availableMoves; // 'forward': 'node2', 'left': 'node3'

  WalkthroughNode({
    required this.id,
    required this.name,
    required this.panoramaUrl,
    required this.availableMoves,
  });
}

class VirtualWalkthroughScreen extends StatefulWidget {
  const VirtualWalkthroughScreen({super.key});

  @override
  State<VirtualWalkthroughScreen> createState() => _VirtualWalkthroughScreenState();
}

class _VirtualWalkthroughScreenState extends State<VirtualWalkthroughScreen> {
  // Sample prototype nodes
  late List<WalkthroughNode> _nodes;
  late WalkthroughNode _currentNode;

  @override
  void initState() {
    super.initState();
    _nodes = [
      WalkthroughNode(
        id: 'entrance',
        name: 'Entrance Hall',
        panoramaUrl: 'https://raw.githubusercontent.com/mchome/panorama_viewer/master/example/assets/panorama.jpg',
        availableMoves: {'forward': 'living_room'},
      ),
      WalkthroughNode(
        id: 'living_room',
        name: 'Living Room',
        panoramaUrl: 'https://raw.githubusercontent.com/mchome/panorama_viewer/master/example/assets/panorama2.jpg',
        availableMoves: {'back': 'entrance', 'left': 'kitchen', 'forward': 'master_bedroom'},
      ),
      WalkthroughNode(
        id: 'kitchen',
        name: 'Kitchen & Dining',
        panoramaUrl: 'https://raw.githubusercontent.com/mchome/panorama_viewer/master/example/assets/panorama.jpg',
        availableMoves: {'right': 'living_room'},
      ),
      WalkthroughNode(
        id: 'master_bedroom',
        name: 'Master Bedroom',
        panoramaUrl: 'https://raw.githubusercontent.com/mchome/panorama_viewer/master/example/assets/panorama2.jpg',
        availableMoves: {'back': 'living_room'},
      ),
    ];
    _currentNode = _nodes.first;
  }

  void _moveToNode(String direction) {
    if (_currentNode.availableMoves.containsKey(direction)) {
      final String nextNodeId = _currentNode.availableMoves[direction]!;
      final nextNode = _nodes.firstWhere((n) => n.id == nextNodeId);

      AudioManager().playSwipe(context);
      AudioManager().triggerHaptic(context);

      setState(() {
        _currentNode = nextNode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Virtual Walkthrough', style: TextStyle(color: Colors.white, fontSize: 14)),
            Text(_currentNode.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // The actual panorama
          // Using Key ensures the widget completely rebuilds the view for the new URL
          PanoramaViewer(
            key: ValueKey(_currentNode.id),
            animSpeed: 0.1,
            sensorControl: SensorControl.orientation,
            child: Image.network(_currentNode.panoramaUrl),
          ),

          // Custom Navigation HUD Overlay
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Forward Arrow
                    _buildNavButton(LucideIcons.arrowUp, 'forward'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Left Arrow
                        _buildNavButton(LucideIcons.arrowLeft, 'left'),
                        const SizedBox(width: 48), // Space for center
                        // Right Arrow
                        _buildNavButton(LucideIcons.arrowRight, 'right'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Back Arrow
                    _buildNavButton(LucideIcons.arrowDown, 'back'),
                  ],
                ),
              ),
            ),
          ),
          
          // Map Icon indicator top right
          Positioned(
             top: 100,
             right: 16,
             child: Container(
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(
                 color: const Color(0xFF1EB476).withValues(alpha: 0.8),
                 shape: BoxShape.circle,
               ),
               child: const Icon(LucideIcons.map, color: Colors.white, size: 20),
             ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, String direction) {
    final bool isAvailable = _currentNode.availableMoves.containsKey(direction);
    return GestureDetector(
      onTap: isAvailable ? () => _moveToNode(direction) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isAvailable ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isAvailable ? Colors.white : Colors.white.withValues(alpha: 0.1),
            width: isAvailable ? 2 : 1,
          ),
        ),
        child: Icon(
          icon,
          color: isAvailable ? Colors.white : Colors.white.withValues(alpha: 0.2),
          size: 24,
        ),
      ),
    );
  }
}
