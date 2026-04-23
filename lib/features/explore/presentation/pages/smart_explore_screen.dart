import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:animate_do/animate_do.dart';
import 'package:swiftspace/core/constants/app_constants.dart';
import 'package:swiftspace/features/property/domain/entities/property.dart';
import 'package:swiftspace/features/property/presentation/state/property_provider.dart';
import 'package:swiftspace/features/auth/presentation/state/user_preferences_provider.dart';
import 'package:swiftspace/features/property/presentation/pages/property_details_screen.dart';

class SmartExploreScreen extends StatefulWidget {
  const SmartExploreScreen({super.key});

  @override
  State<SmartExploreScreen> createState() => _SmartExploreScreenState();
}

class _SmartExploreScreenState extends State<SmartExploreScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context);
    final prefs = Provider.of<UserPreferencesProvider>(context);
    final properties = propertyProvider.liveProperties;

    // AI Recommendation Logic
    final recommendations = _getAIRecommendations(properties, prefs);
    final regularList = properties.where((p) => !recommendations.contains(p)).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildSmartHeader(prefs),
            _buildSearchBar(),
            _buildHorizontalSuggestions(recommendations),
            _buildSectionHeader('Top Picks for You'),
            _buildSmartGrid(regularList),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartHeader(UserPreferencesProvider prefs) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              duration: const Duration(milliseconds: 500),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good Morning!',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const Text(
                        'Find your perfect spot',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.sparkles, color: AppColors.primaryLight, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: FadeInUp(
          duration: const Duration(milliseconds: 600),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.search, color: Colors.grey, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Try "3 bed in Maitama under 50M"',
                      hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const Icon(LucideIcons.slidersHorizontal, color: AppColors.primaryLight, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalSuggestions(List<Property> recommendations) {
    if (recommendations.isEmpty) return const SliverToBoxAdapter(child: SizedBox());

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
            child: Row(
              children: [
                Icon(LucideIcons.zap, color: Colors.amber, size: 18),
                SizedBox(width: 8),
                Text(
                  'AI Recommendations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 280,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: recommendations.length,
              itemBuilder: (context, index) {
                return _buildRecommendationCard(recommendations[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(Property property, int index) {
    return FadeInRight(
      delay: Duration(milliseconds: 200 * index),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PropertyDetailsScreen(property: property)),
        ),
        child: Container(
          width: 220,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        image: DecorationImage(
                          image: NetworkImage(property.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.sparkles, color: Colors.amber, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              '98% Match',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      property.locationName,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₦${_formatPrice(property.price)}',
                          style: TextStyle(
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Icon(LucideIcons.arrowUpRight, color: Colors.grey[400], size: 16),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'See All',
              style: TextStyle(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartGrid(List<Property> properties) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        itemBuilder: (context, index) {
          return _buildGridCard(properties[index]);
        },
        childCount: properties.length,
      ),
    );
  }

  Widget _buildGridCard(Property property) {
    return FadeInUp(
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PropertyDetailsScreen(property: property)),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Image.network(
                  property.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₦${_formatPrice(property.price)}',
                      style: TextStyle(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(LucideIcons.mapPin, size: 10, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            property.locationName,
                            style: TextStyle(color: Colors.grey[500], fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return price.toStringAsFixed(0);
  }

  List<Property> _getAIRecommendations(List<Property> properties, UserPreferencesProvider prefs) {
    // Basic recommendation logic
    final scored = properties.map((p) {
      double score = 100.0;
      if (p.price < prefs.minPrice || p.price > prefs.maxPrice) score -= 20;
      if (prefs.preferredType != null && p.type != prefs.preferredType) score -= 30;
      if (p.isVerified) score += 10;
      if (p.isPremium) score += 15;
      return MapEntry(p, score);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.take(5).map((e) => e.key).toList();
  }
}
