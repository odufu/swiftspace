import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PremiumBadge extends StatelessWidget {
  final double fontSize;
  final double iconSize;
  final EdgeInsets padding;
  final bool showShadow;

  const PremiumBadge({
    super.key,
    this.fontSize = 10,
    this.iconSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB300), Color(0xFFF57C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: const Color(0xFFF57C00).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.crown, color: Colors.white, size: iconSize),
          const SizedBox(width: 6),
          Text(
            'PREMIUM',
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
