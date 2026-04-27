import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:swiftspace/features/property/domain/entities/property.dart';
import 'package:swiftspace/features/property/presentation/state/property_provider.dart';
import 'package:swiftspace/features/property/presentation/pages/property_details_screen.dart';
import 'package:swiftspace/features/agent/presentation/pages/professional_profile_screen.dart';

import 'package:swiftspace/features/explore/presentation/pages/map_explore_screen.dart';
import 'package:swiftspace/features/auth/presentation/state/user_preferences_provider.dart';
import 'package:swiftspace/features/chat/domain/entities/notification.dart';
import 'package:swiftspace/features/chat/presentation/state/chat_provider.dart';
import 'package:swiftspace/features/chat/presentation/state/notification_provider.dart';
import 'package:swiftspace/core/presentation/widgets/common/badge_icon.dart';
import 'package:swiftspace/shared/widgets/notification_sheet.dart';
import 'package:swiftspace/shared/widgets/explore_filter_sheet.dart';
import 'package:swiftspace/core/presentation/widgets/common/premium_badge.dart';

class GridExploreScreen extends StatefulWidget {
  final List<Property>? curatedProperties;
  const GridExploreScreen({Key? key, this.curatedProperties}) : super(key: key);

  @override
  State<GridExploreScreen> createState() => _GridExploreScreenState();
}

class _GridExploreScreenState extends State<GridExploreScreen> {
  String? _selectedCompanyFilter;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Property> get _filteredProperties {
    if (widget.curatedProperties != null) return widget.curatedProperties!;

    final propertyProvider = Provider.of<PropertyProvider>(context);
    final userPrefs = Provider.of<UserPreferencesProvider>(context);
    final allProperties = propertyProvider.properties;

    return allProperties.where((p) {
      if (!p.isActive) return false;

      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        final queryParts = _searchQuery.split(' ');
        matchesSearch = queryParts.every(
          (part) =>
              p.title.toLowerCase().contains(part) ||
              p.locationName.toLowerCase().contains(part) ||
              p.description.toLowerCase().contains(part) ||
              p.type.name.toLowerCase().contains(part) ||
              p.listerName.toLowerCase().contains(part) ||
              (p.companyName?.toLowerCase().contains(part) ?? false),
        );
      }

      // Filter by preferences set in the sheet
      final matchesType =
          userPrefs.preferredType == null || p.type == userPrefs.preferredType;
      final matchesPrice =
          p.price >= userPrefs.minPrice && p.price <= userPrefs.maxPrice;
      final matchesLocation =
          userPrefs.preferredLocation.isEmpty ||
          p.locationName.toLowerCase().contains(
            userPrefs.preferredLocation.toLowerCase(),
          );

      return matchesSearch && matchesType && matchesPrice && matchesLocation;
    }).toList();
  }

  Widget _buildCompanyFilterDropdown(ThemeData theme) {
    final allProperties = Provider.of<PropertyProvider>(context).properties;
    final companies = <String, String>{}; // companyName -> logoUrl
    for (var p in allProperties) {
      if (p.listerType == ListerType.realEstateCompany &&
          p.companyName != null &&
          p.listerLogoUrl != null) {
        companies[p.companyName!] = p.listerLogoUrl!;
      }
    }

    if (companies.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String?>(
        value: _selectedCompanyFilter,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: theme.colorScheme.surface,
          hintText: 'Filter by Registered Companies',
          prefixIcon: const Icon(LucideIcons.building2),
        ),
        isExpanded: true,
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text(
              'All Companies & Agents',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...companies.entries.map((e) {
            return DropdownMenuItem<String?>(
              value: e.key,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: e.value,
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const Icon(Icons.apartment, size: 20),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.apartment, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          e.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 12),
                            SizedBox(width: 4),
                            Text(
                              '4.8 · Premium Partner',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
        onChanged: (val) {
          setState(() {
            _selectedCompanyFilter = val;
          });
        },
      ),
    );
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final props = _filteredProperties;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Single Row for Search + Messages + Notifications
                  Row(
                    children: [
                      if (Navigator.canPop(context))
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: IconButton(
                            icon: const Icon(LucideIcons.arrowLeft),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search properties...',
                            prefixIcon: const Icon(
                              LucideIcons.search,
                              size: 18,
                            ),
                            filled: true,
                            fillColor: theme.scaffoldBackgroundColor,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => ExploreFilterSheet.show(context),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            LucideIcons.sliders,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      Consumer2<ChatProvider, NotificationProvider>(
                        builder: (context, chat, note, child) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              BadgeIcon(
                                icon: LucideIcons.messageSquare,
                                count: chat.totalUnreadCount,
                                onPressed: () =>
                                    Provider.of<UserPreferencesProvider>(
                                      context,
                                      listen: false,
                                    ).setTabIndex(2),
                              ),
                              BadgeIcon(
                                icon: LucideIcons.bell,
                                count: note.unreadCount,
                                onPressed: () =>
                                    NotificationSheet.show(context),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child:
                  Provider.of<PropertyProvider>(context).isLoading &&
                      props.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : props.isEmpty
                  ? Center(
                      child: Text(
                        'No properties found matching your criteria.',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 280,
                            childAspectRatio: 0.73,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: props.length + 1,
                      itemBuilder: (context, index) {
                        final userPrefs = Provider.of<UserPreferencesProvider>(
                          context,
                        );
                        final bestOffer = Provider.of<PropertyProvider>(context)
                            .getBestOffer(
                              userPrefs.bestOfferPriorities,
                              minPrice: userPrefs.minPrice,
                              maxPrice: userPrefs.maxPrice,
                              type: userPrefs.preferredType,
                              location: userPrefs.preferredLocation,
                            );

                        if (index == 0) {
                          return _buildBestOfferCard(context, bestOffer);
                        }

                        final prop = props[index - 1];
                        // Don't show the best offer twice if it's in the list
                        if (bestOffer != null && prop.id == bestOffer.id) {
                          return const SizedBox.shrink(); // Or just let it be, but let's shrink for now or just skip
                        }
                        return _buildPropertyCard(context, prop, theme);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBestOfferCard(BuildContext context, Property? best) {
    final theme = Theme.of(context);
    if (best == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PropertyDetailsScreen(property: best),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                LucideIcons.sparkles,
                size: 100,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.sparkles,
                          color: Colors.white,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "AI BEST OFFER",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        best.formattedPrice,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (best.isPremium)
                        const PremiumBadge(
                          fontSize: 8,
                          iconSize: 10,
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    best.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.mapPin,
                        color: Colors.white70,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          best.locationName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
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

  Widget _buildPropertyCard(
    BuildContext context,
    Property prop,
    ThemeData theme,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (context, animation, secondaryAnimation) =>
                PropertyDetailsScreen(property: prop),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        );
      },
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Hero(
                    tag: prop.id,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: prop.imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: double.infinity,
                          color: Colors.grey[200],
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: double.infinity,
                          color: Colors.grey[300],
                        ),
                      ),
                    ),
                  ),
                  if (prop.hasLawyerVerifiedTerms)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.shieldCheck,
                          color: Colors.teal,
                          size: 14,
                        ),
                      ),
                    ),
                  if (prop.isPremium)
                    const Positioned(top: 8, left: 8, child: PremiumBadge()),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prop.formattedPrice,
                    style: TextStyle(
                      color: prop.priceTerm == 'buy'
                          ? const Color(0xFF1EB476)
                          : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    prop.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfessionalProfileScreen(
                            listerId: prop.listerId ?? '',
                            listerName: prop.listerName,
                            listerType: prop.listerType,
                            companyName: prop.companyName,
                            listerLogoUrl: prop.listerLogoUrl,
                            isVerified: prop.isVerified,
                            agentPhone: '',
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Icon(
                          prop.listerType == ListerType.owner
                              ? LucideIcons.user
                              : prop.listerType == ListerType.developer
                              ? LucideIcons.building2
                              : LucideIcons.briefcase,
                          size: 12,
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            prop.companyName ?? prop.listerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
