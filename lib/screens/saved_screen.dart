import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/favorites_provider.dart';
import '../models/property.dart';
import '../screens/property_details_screen.dart';
import '../providers/property_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favProvider = Provider.of<FavoritesProvider>(context);
    final allProperties = Provider.of<PropertyProvider>(context).properties;

    // Filter properties based on the saved IDs in local storage AND if they are still active
    final savedProperties = allProperties.where((p) => favProvider.isFavorite(p.id) && p.isActive).toList();

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
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: savedProperties.length,
              itemBuilder: (context, index) {
                final prop = savedProperties[index];
                return GestureDetector(
                  onTap: () {
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
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
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
                          tag: prop.id,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                            child: CachedNetworkImage(
                              imageUrl: prop.imageUrl,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 120,
                                height: 120,
                                color: Colors.grey[200],
                                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 120,
                                height: 120,
                                color: Colors.grey,
                                child: const Icon(Icons.image_not_supported),
                              ),
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
                                      icon: const Icon(LucideIcons.heart, color: Colors.red),
                                      onPressed: () {
                                        favProvider.toggleFavorite(prop);
                                      },
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
                                const SizedBox(height: 8),
                                Text(
                                  '${prop.formattedPrice}${prop.priceTerm.isNotEmpty ? "/${prop.priceTerm}" : ""}',
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
              },
            ),
    );
  }
}
