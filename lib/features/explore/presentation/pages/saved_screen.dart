import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:swiftspace/features/explore/presentation/state/favorites_provider.dart';
import 'package:swiftspace/features/property/domain/entities/property.dart';
import 'package:swiftspace/features/property/presentation/pages/property_details_screen.dart';
import 'package:swiftspace/features/property/presentation/state/property_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:swiftspace/core/utils/responsive.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favProvider = Provider.of<FavoritesProvider>(context);
    final allProperties = Provider.of<PropertyProvider>(context).properties;

    // Filter properties based on the saved IDs in local storage AND if they are still active
    final savedProperties = allProperties.where((p) => favProvider.isFavorite(p.id) && p.isActive).toList();

    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Properties', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: savedProperties.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.heartCrack, size: 80, color: theme.dividerColor),
                  const SizedBox(height: 24),
                  Text(
                    'No saved properties yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hit the heart icon on properties you like to save them here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                  )
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop ? 3 : (isTablet ? 2 : 1),
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                mainAxisExtent: isMobile ? 120 : 340,
              ),
              itemCount: savedProperties.length,
              itemBuilder: (context, index) {
                final prop = savedProperties[index];
                return _SavedPropertyCard(prop: prop, isMobile: isMobile);
              },
            ),
    );
  }
}

class _SavedPropertyCard extends StatelessWidget {
  final Property prop;
  final bool isMobile;

  const _SavedPropertyCard({required this.prop, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favProvider = Provider.of<FavoritesProvider>(context);

    if (isMobile) {
      return GestureDetector(
        onTap: () => _navigateToDetails(context),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Hero(
                tag: 'saved-${prop.id}',
                child: ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                  child: CachedNetworkImage(
                    imageUrl: prop.imageUrl,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            prop.type.name.toUpperCase(),
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            icon: const Icon(LucideIcons.heart, color: Colors.red, size: 18),
                            onPressed: () => favProvider.toggleFavorite(prop),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        prop.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(LucideIcons.bedDouble, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text('${prop.beds}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                          const SizedBox(width: 12),
                          Icon(LucideIcons.bath, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text('${prop.baths}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        prop.formattedPrice,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      );
    }

    // Tablet & Desktop Card Layout
    return GestureDetector(
      onTap: () => _navigateToDetails(context),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: 'saved-${prop.id}',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: CachedNetworkImage(
                      imageUrl: prop.imageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    child: IconButton(
                      icon: const Icon(LucideIcons.heart, color: Colors.red),
                      onPressed: () => favProvider.toggleFavorite(prop),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      prop.type.name.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prop.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(LucideIcons.mapPin, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          prop.locationName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildFeature(LucideIcons.bedDouble, '${prop.beds}'),
                          const SizedBox(width: 16),
                          _buildFeature(LucideIcons.bath, '${prop.baths}'),
                        ],
                      ),
                      Text(
                        prop.formattedPrice,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  void _navigateToDetails(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) => PropertyDetailsScreen(property: prop),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}
