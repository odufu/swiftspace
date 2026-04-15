import 'package:flutter/material.dart';
import 'dart:async';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:swiftspace/core/services/audio_manager.dart';

class AiCameraMappingScreen extends StatefulWidget {
  const AiCameraMappingScreen({super.key});

  @override
  State<AiCameraMappingScreen> createState() => _AiCameraMappingScreenState();
}

class _AiCameraMappingScreenState extends State<AiCameraMappingScreen> with TickerProviderStateMixin {
  int _mappingProgress = 0;
  bool _isMapping = false;
  bool _isComplete = false;
  Timer? _mappingTimer;
  
  late final AnimationController _scanController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
       vsync: this,
       duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanController.dispose();
    _pulseController.dispose();
    _mappingTimer?.cancel();
    super.dispose();
  }

  void _startMapping() {
    setState(() {
      _isMapping = true;
      _mappingProgress = 0;
    });

    AudioManager().playClick(context);

    // Simulate mapping process
    _mappingTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (_mappingProgress >= 100) {
        timer.cancel();
        _finishMapping();
      } else {
        setState(() {
          _mappingProgress += 2;
        });
        
        if (_mappingProgress % 10 == 0) {
           AudioManager().triggerHaptic(context);
        }
      }
    });
  }

  void _finishMapping() {
    setState(() {
      _isMapping = false;
      _isComplete = true;
    });
    
    AudioManager().playSuccess(context);
    AudioManager().triggerHeavyHaptic(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Simulated Camera Background (using a blurred image or plain color for prototype)
          Container(
             decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
                )
             ),
          ),
          
          // Grid Overlay
          CustomPaint(
            painter: _GridPainter(progress: _scanController),
          ),
          
          // UI Elements
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context, _isComplete), // Return whether successful
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(LucideIcons.camera, color: Colors.greenAccent, size: 16),
                            SizedBox(width: 8),
                            Text('AI Scanner Active', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48), // spacer
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Instructions & Status
                if (!_isMapping && !_isComplete) ...[
                   const Icon(LucideIcons.scanLine, color: Colors.white, size: 60),
                   const SizedBox(height: 24),
                   const Text(
                     'Stand in the center of the room.',
                     style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                   ),
                   const SizedBox(height: 8),
                   const Text(
                     'Slowly pan your camera around to map this node.',
                     style: TextStyle(color: Colors.white70, fontSize: 14),
                   ),
                   const SizedBox(height: 40),
                   GestureDetector(
                     onTap: _startMapping,
                     child: AnimatedBuilder(
                       animation: _pulseController,
                       builder: (context, child) {
                         return Container(
                           width: 80,
                           height: 80,
                           decoration: BoxDecoration(
                             shape: BoxShape.circle,
                             color: Colors.white.withValues(alpha: 0.3 + (_pulseController.value * 0.3)),
                             border: Border.all(color: Colors.white, width: 4),
                           ),
                           child: Center(
                             child: Container(
                               width: 60,
                               height: 60,
                               decoration: const BoxDecoration(
                                 shape: BoxShape.circle,
                                 color: Colors.white,
                               ),
                             ),
                           ),
                         );
                       }
                     ),
                   ),
                ],
                
                if (_isMapping) ...[
                  // Progress UI
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: _mappingProgress / 100,
                          strokeWidth: 8,
                          backgroundColor: Colors.white24,
                          color: Colors.greenAccent,
                        ),
                      ),
                      Text(
                        '$_mappingProgress%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Generating Map...',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Keep moving slowly.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 40),
                ],

                if (_isComplete) ...[
                   const Icon(Icons.check_circle, color: Colors.greenAccent, size: 80),
                   const SizedBox(height: 24),
                   const Text(
                     'Node Mapped Successfully!',
                     style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                   ),
                   const SizedBox(height: 48),
                   ElevatedButton(
                     onPressed: () => Navigator.pop(context, true),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.greenAccent,
                       foregroundColor: Colors.black,
                       padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                     ),
                     child: const Text('Save Node', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                   ),
                   const SizedBox(height: 40),
                ],
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Animation<double> progress;

  _GridPainter({required this.progress}) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent.withValues(alpha: 0.2)
      ..strokeWidth = 1.0;

    // Draw Grid
    const step = 40.0;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
    
    // Draw scanning laser
    final laserY = size.height * progress.value;
    final laserPaint = Paint()
      ..color = Colors.greenAccent.withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      
    canvas.drawLine(Offset(0, laserY), Offset(size.width, laserY), laserPaint);
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => true;
}
