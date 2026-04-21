import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:swiftspace/core/constants/app_constants.dart';
import 'package:swiftspace/features/property/domain/entities/property.dart';
import 'package:swiftspace/features/property/presentation/state/property_provider.dart';
import 'package:swiftspace/features/agent/presentation/pages/agent_property_edit_screen.dart';
import 'package:swiftspace/features/agent/presentation/pages/property_onboarding_screen.dart';
import 'package:swiftspace/core/services/audio_manager.dart';
import 'package:swiftspace/core/di/injection_container.dart';

import 'package:swiftspace/features/auth/presentation/state/auth_provider.dart';

class MyPropertiesTab extends StatelessWidget {
  const MyPropertiesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer2<AuthProvider, PropertyProvider>(
        builder: (context, auth, provider, child) {
          final userId = auth.user?.id ?? '';
          final properties = provider.getPropertiesForLister(userId);
          
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'My Listings',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(LucideIcons.filter, size: 14, color: theme.colorScheme.primary),
                                const SizedBox(width: 6),
                                Text(
                                  'Filter',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage and optimize your property portfolio.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              
              if (properties.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.home, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No listings yet.',
                          style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                             sl<AudioManager>().playClick(context);
                             Navigator.push(context, MaterialPageRoute(builder: (_) => const PropertyOnboardingScreen()));
                          },
                          child: Text('Add your first property', style: TextStyle(color: theme.colorScheme.primary)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _PropertyCard(property: properties[index]),
                      childCount: properties.length,
                    ),
                  ),
                ),
                
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          sl<AudioManager>().playClick(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PropertyOnboardingScreen()),
          );
        },
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        elevation: 4,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(LucideIcons.plus),
        label: const Text(
          'NEW LISTING',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final Property property;

  const _PropertyCard({required this.property});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = property.isActive ? Colors.green : Colors.grey;
    final statusLabel = property.isActive ? 'ACTIVE' : 'OFF MARKET';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              sl<AudioManager>().playClick(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AgentPropertyEditScreen(propertyId: property.id),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Hero(
                        tag: 'prop-${property.id}',
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            image: DecorationImage(
                              image: CachedNetworkImageProvider(property.imageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            property.type.name.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          property.title,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.2),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          property.locationName,
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                             _buildStat(LucideIcons.eye, '${property.viewsCount}'),
                             const SizedBox(width: 12),
                             _buildStat(LucideIcons.heart, '${property.favoritesCount}'),
                             const SizedBox(width: 12),
                             _buildStat(LucideIcons.playCircle, '${property.videoViewsCount}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(LucideIcons.chevronRight, size: 20, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
