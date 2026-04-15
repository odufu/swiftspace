import 'package:flutter/material.dart';
import '../models/property.dart';
import 'package:lucide_icons/lucide_icons.dart';


class CustomMarkerWidget extends StatefulWidget {
  final Property property;
  final bool isSelected;
  final bool isBestOffer;

  const CustomMarkerWidget({
    super.key,
    required this.property,
    this.isSelected = false,
    this.isBestOffer = false,
  });

  @override
  State<CustomMarkerWidget> createState() => _CustomMarkerWidgetState();
}

class _CustomMarkerWidgetState extends State<CustomMarkerWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimationScale;
  late Animation<double> _pulseAnimationOpacity;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimationScale = Tween<double>(begin: 0.8, end: 3.5).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _pulseAnimationOpacity = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    if (widget.isBestOffer || widget.isSelected) {
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(CustomMarkerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasPulsing = oldWidget.isBestOffer || oldWidget.isSelected;
    final isPulsing = widget.isBestOffer || widget.isSelected;
    
    if (isPulsing && !wasPulsing) {
      _pulseController.repeat();
    } else if (!isPulsing && wasPulsing) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Returns a color representing the property TYPE category
  Color _getTypeColor() {
    if (widget.isBestOffer) return const Color(0xFFFF2A5F);
    switch (widget.property.type) {
      case PropertyType.shops:
      case PropertyType.shopInAMall:
        return Colors.orange;
      case PropertyType.officeSpace:
      case PropertyType.coWorkingSpace:
        return Colors.blue;
      case PropertyType.commercialProperties:
      case PropertyType.warehouse:
        return Colors.blueGrey;
      case PropertyType.flatsAndApartments:
        return Colors.teal;
      case PropertyType.lands:
        return const Color(0xFF8D6E63); // Brown
      case PropertyType.semiDetachedBungalows:
      case PropertyType.detachedBungalows:
      case PropertyType.terracedBungalows:
        return Colors.green;
      case PropertyType.semiDetachedDuplex:
      case PropertyType.detachedDuplex:
      case PropertyType.terracedDuplex:
        return Colors.deepPurple;
      case PropertyType.house:
        return const Color(0xFF168153);
    }
  }

  /// Returns an icon matching the property type
  IconData _getTypeIcon() {
    switch (widget.property.type) {
      case PropertyType.shops:
      case PropertyType.shopInAMall:
        return LucideIcons.shoppingBag;
      case PropertyType.officeSpace:
      case PropertyType.coWorkingSpace:
        return LucideIcons.briefcase;
      case PropertyType.commercialProperties:
      case PropertyType.warehouse:
        return LucideIcons.building;
      case PropertyType.lands:
        return LucideIcons.layoutDashboard;
      case PropertyType.flatsAndApartments:
        return LucideIcons.building2;
      default:
        return LucideIcons.home;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = _getTypeColor();
    final typeIcon = _getTypeIcon();

    final isDarkBackground = widget.isSelected || widget.isBestOffer;

    final bgColor = isDarkBackground
        ? baseColor.withValues(alpha: 0.9)
        : colorScheme.surface.withValues(alpha: 0.95);

    final textColor = isDarkBackground ? Colors.white : baseColor;
    final borderColor = baseColor;

    final markerContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isSelected ? 14 : 10,
            vertical: widget.isSelected ? 8 : 5,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isSelected ? Colors.white : borderColor,
              width: widget.isSelected ? 2.5 : 1.5,
            ),
            boxShadow: [
              if (widget.isSelected)
                BoxShadow(
                  color: baseColor.withValues(alpha: 0.6),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Type icon
              Icon(
                widget.isSelected ? LucideIcons.mapPin : typeIcon,
                color: widget.isSelected ? Colors.amberAccent : textColor,
                size: 13,
              ),
              const SizedBox(width: 4),
              // Price
              Text(
                widget.property.formattedPrice,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: widget.isSelected ? 14 : 12,
                ),
              ),
              // /priceTerm suffix
              if (widget.property.priceTerm.isNotEmpty && widget.property.priceTerm != 'buy')
                Text(
                  '/${widget.property.priceTerm}',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                  ),
                ),
              if (widget.property.hasLawyerVerifiedTerms)
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Icon(
                    LucideIcons.shieldCheck,
                    color: isDarkBackground ? Colors.tealAccent : Colors.teal,
                    size: 13,
                  ),
                ),
            ],
          ),
        ),
        Container(width: 2, height: 8, color: borderColor),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: borderColor,
            border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor, width: 1.5),
          ),
        ),
      ],
    );

    if (!(widget.isBestOffer || widget.isSelected)) return markerContent;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Positioned(
          bottom: -15,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimationScale.value,
                child: Opacity(
                  opacity: _pulseAnimationOpacity.value,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isSelected
                          ? Colors.blueAccent.withValues(alpha: 0.5)
                          : baseColor.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: -15,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              double delayedScale = _pulseAnimationScale.value - 0.8;
              if (delayedScale < 0.8) delayedScale = 0.8;
              return Transform.scale(
                scale: delayedScale,
                child: Opacity(
                  opacity: _pulseAnimationOpacity.value * 0.8,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: widget.isSelected
                              ? Colors.white
                              : Colors.amberAccent,
                          width: 2),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        markerContent,
      ],
    );
  }
}
