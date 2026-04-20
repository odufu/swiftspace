import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:swiftspace/features/property/presentation/state/property_provider.dart';
import 'package:swiftspace/features/auth/presentation/state/verification_provider.dart';
import 'package:swiftspace/features/property/domain/entities/property.dart';

class PropertiesSection extends StatelessWidget {
  const PropertiesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final pp = Provider.of<PropertyProvider>(context);
    final vp = Provider.of<VerificationProvider>(context);
    final properties = pp.properties;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Property Inventory', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
                mainAxisSpacing: 24,
                crossAxisSpacing: 24,
                childAspectRatio: 0.85,
              ),
              itemCount: properties.length,
              itemBuilder: (context, index) {
                final property = properties[index];
                return _buildPropertyCard(context, property, pp, vp);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(BuildContext context, Property property, PropertyProvider pp, VerificationProvider vp) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageHeader(property),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(property.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(property.listerName, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 16),
                _buildStatusRow(property),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => pp.togglePropertyStatus(property.id),
                        child: Text(property.isActive ? 'Deactivate' : 'Activate'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(LucideIcons.ban, color: Colors.red),
                      onPressed: () => vp.adminMarkFraud(property.id),
                      tooltip: 'Mark as Fraud',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageHeader(Property property) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Stack(
        children: [
          Image.network(property.imageUrl, height: 160, width: double.infinity, fit: BoxFit.cover),
          if (property.isVerified)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                child: const Icon(LucideIcons.check, color: Colors.white, size: 14),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(Property property) {
    return Row(
      children: [
        _buildBadge(
          property.isActive ? 'ACTIVE' : 'INACTIVE',
          property.isActive ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 8),
        _buildBadge(
          property.verificationStatus.name.toUpperCase(),
          _getVerificationColor(property.verificationStatus),
        ),
      ],
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Color _getVerificationColor(PropertyVerificationStatus status) {
    switch (status) {
      case PropertyVerificationStatus.verified: return Colors.blue;
      case PropertyVerificationStatus.pendingReview: return Colors.orange;
      case PropertyVerificationStatus.fraudBlocked: return Colors.red;
      default: return Colors.grey;
    }
  }
}
