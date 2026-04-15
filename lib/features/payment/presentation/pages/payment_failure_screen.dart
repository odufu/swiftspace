import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:swiftspace/core/services/audio_manager.dart';

class PaymentFailureScreen extends StatefulWidget {
  final String title;
  final String description;

  const PaymentFailureScreen({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  State<PaymentFailureScreen> createState() => _PaymentFailureScreenState();
}

class _PaymentFailureScreenState extends State<PaymentFailureScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 10).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticIn,
    ));

    _animController.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioManager().triggerHeavyHaptic(context);
      // Play a failure sound if available, otherwise just heavy haptic.
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              AnimatedBuilder(
                animation: _shakeAnim,
                builder: (context, child) {
                  final offset = _shakeAnim.value * 
                    (1 - _animController.value) *
                    (_animController.value * 10 % 2 == 0 ? 1 : -1);
                  return Transform.translate(
                    offset: Offset(offset, 0),
                    child: child,
                  );
                },
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      LucideIcons.xCircle,
                      color: Colors.red,
                      size: 64,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                widget.description,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    AudioManager().playClick(context);
                    AudioManager().triggerHaptic(context);
                    Navigator.of(context).pop(false);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    side: BorderSide(color: theme.colorScheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text('Try Again', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
