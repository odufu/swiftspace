import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import '../../domain/entities/property.dart';

class SocialProofBar extends StatelessWidget {
  final int views;
  final int favorites;

  const SocialProofBar({
    super.key,
    required this.views,
    required this.favorites,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          _buildStat(LucideIcons.eye, '$views views this week'),
          const SizedBox(width: 24),
          _buildStat(LucideIcons.heart, '$favorites favorites'),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'POPULAR',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.blue),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class AmenitiesGrid extends StatelessWidget {
  final List<String> amenities;

  const AmenitiesGrid({super.key, required this.amenities});

  IconData _getAmenityIcon(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('wifi') || lowerName.contains('internet'))
      return LucideIcons.wifi;
    if (lowerName.contains('pool')) return LucideIcons.waves;
    if (lowerName.contains('gym') || lowerName.contains('fitness'))
      return LucideIcons.dumbbell;
    if (lowerName.contains('park')) return LucideIcons.parkingCircle;
    if (lowerName.contains('security')) return LucideIcons.shieldCheck;
    if (lowerName.contains('ac') || lowerName.contains('condition'))
      return LucideIcons.thermometerSnowflake;
    if (lowerName.contains('water')) return LucideIcons.droplets;
    if (lowerName.contains('power') || lowerName.contains('light'))
      return LucideIcons.zap;
    if (lowerName.contains('kitchen')) return LucideIcons.utensils;
    if (lowerName.contains('balcony')) return LucideIcons.layout;
    if (lowerName.contains('cctv')) return LucideIcons.camera;
    return LucideIcons.checkCircle2;
  }

  @override
  Widget build(BuildContext context) {
    if (amenities.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Features & Amenities',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: amenities.length,
          itemBuilder: (context, index) {
            final amenity = amenities[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  Icon(
                    _getAmenityIcon(amenity),
                    size: 16,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      amenity,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class NeighborhoodInfo extends StatelessWidget {
  final Property property;

  const NeighborhoodInfo({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Neighborhood & Utilities',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              _buildInfoRow(
                LucideIcons.zap,
                'Electricity Supply',
                '${property.electricitySupplyHours.toStringAsFixed(1)} hrs average',
                Colors.amber,
              ),
              const Divider(height: 32, color: Colors.white10),
              _buildInfoRow(
                LucideIcons.droplets,
                'Water Supply',
                property.hasRunningWater
                    ? 'Active Running Water'
                    : 'Not Provided',
                Colors.blue,
              ),
              const Divider(height: 32, color: Colors.white10),
              _buildInfoRow(
                LucideIcons.map,
                'Proximity to Main Road',
                '${property.proximityToRoadMeters}m distance',
                Colors.green,
              ),
              const Divider(height: 32, color: Colors.white10),
              _buildInfoRow(
                LucideIcons.activity,
                'Medical Access',
                '${property.proximityToHospitalKm.toStringAsFixed(1)}km to Hospital',
                Colors.redAccent,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class FinancialBreakdown extends StatelessWidget {
  final Property property;

  const FinancialBreakdown({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Financial Transparency',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Expected standard fees to be paid for this listing:',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.withOpacity(0.05),
                Colors.purple.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              _buildFeeItem('Caution/Security Fee', property.appliesCautionFee),
              _buildFeeItem('Agency/Service Fee', property.appliesAgencyFee),
              _buildFeeItem('Legal/Agreement Fee', property.appliesLegalFee),
              _buildFeeItem(
                'Annual Service Charge',
                property.appliesServiceFee,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeeItem(String label, bool applies) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            applies ? LucideIcons.checkCircle2 : LucideIcons.xCircle,
            color: applies ? Colors.greenAccent : Colors.white24,
            size: 18,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: applies ? Colors.white : Colors.white30,
              fontSize: 14,
              fontWeight: applies ? FontWeight.w500 : FontWeight.normal,
              decoration: applies ? null : TextDecoration.lineThrough,
            ),
          ),
          const Spacer(),
          if (applies)
            const Text(
              'Required',
              style: TextStyle(
                color: Colors.greenAccent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            const Text(
              'No Fee',
              style: TextStyle(color: Colors.white24, fontSize: 11),
            ),
        ],
      ),
    );
  }
}

class TechnicalSpecs extends StatelessWidget {
  final Property property;

  const TechnicalSpecs({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Technical Specifications',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildSpecCard(
              'Year Built',
              property.yearBuilt?.toString() ?? 'N/A',
              LucideIcons.calendar,
            ),
            _buildSpecCard(
              'Total Area',
              '${property.totalSquareFootage?.toInt() ?? "---"} sqft',
              LucideIcons.ruler,
            ),
            _buildSpecCard(
              'Foundation',
              property.foundationType ?? 'Standard',
              LucideIcons.layers,
            ),
            _buildSpecCard(
              'Status',
              property.isActive ? 'Available' : 'Off Market',
              LucideIcons.info,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpecCard(String label, String value, IconData icon) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blueAccent, size: 16),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
