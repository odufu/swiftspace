import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:swiftspace/models/property.dart';
import 'package:swiftspace/providers/property_provider.dart';
import 'package:swiftspace/screens/property_details_screen.dart';

class AdvancedExploreScreen extends StatefulWidget {
  const AdvancedExploreScreen({Key? key}) : super(key: key);

  @override
  State<AdvancedExploreScreen> createState() => _AdvancedExploreScreenState();
}

class _AdvancedExploreScreenState extends State<AdvancedExploreScreen> {
  String? _selectedCompanyFilter;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<PropertyType> _selectedTypes = {};

  List<Property> get _filteredProperties {
    final allProperties = Provider.of<PropertyProvider>(context, listen: false).properties;

    return allProperties.where((p) {
      if (!p.isActive) return false;

      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        final queryParts = _searchQuery.split(' ');
        matchesSearch = queryParts.every((part) =>
            p.title.toLowerCase().contains(part) ||
            p.locationName.toLowerCase().contains(part) ||
            p.description.toLowerCase().contains(part) ||
            p.type.name.toLowerCase().contains(part) ||
            p.listerName.toLowerCase().contains(part) ||
            (p.companyName?.toLowerCase().contains(part) ?? false));
      }

      final matchesType = _selectedTypes.isEmpty || _selectedTypes.contains(p.type);

      bool matchesCompany = true;
      if (_selectedCompanyFilter != null) {
        matchesCompany = p.companyName == _selectedCompanyFilter;
      }

      return matchesSearch && matchesType && matchesCompany;
    }).toList();
  }

  Widget _buildCompanyFilterDropdown(ThemeData theme) {
    final allProperties = Provider.of<PropertyProvider>(context, listen: false).properties;
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            child: Text('All Companies & Agents', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      placeholder: (context, url) => const Icon(Icons.apartment, size: 20),
                      errorWidget: (context, url, error) => const Icon(Icons.apartment, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 12),
                            SizedBox(width: 4),
                            Text('4.8 · Premium Partner', style: TextStyle(fontSize: 10, color: Colors.grey)),
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
      appBar: AppBar(
        title: const Text('Advanced Explore', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search properties...',
                    prefixIcon: const Icon(LucideIcons.search),
                    filled: true,
                    fillColor: theme.scaffoldBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildCompanyFilterDropdown(theme),
                // Optionally add property type chips here
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: PropertyType.values.map((type) {
                      final isSelected = _selectedTypes.contains(type);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(type.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTypes.add(type);
                              } else {
                                _selectedTypes.remove(type);
                              }
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: props.isEmpty
                ? Center(
                    child: Text(
                      'No properties found matching your criteria.',
                      style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.73,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: props.length,
                    itemBuilder: (context, index) {
                      final prop = props[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              transitionDuration: const Duration(milliseconds: 300),
                              pageBuilder: (context, animation, secondaryAnimation) =>
                                  PropertyDetailsScreen(property: prop),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
                                          child: const Icon(LucideIcons.shieldCheck, color: Colors.teal, size: 14),
                                        ),
                                      ),
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
                                        color: prop.priceTerm == 'buy' ? const Color(0xFF1EB476) : theme.colorScheme.onSurface,
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
                                    Row(
                                      children: [
                                        Icon(
                                          prop.listerType == ListerType.owner
                                              ? LucideIcons.user
                                              : prop.listerType == ListerType.developer
                                                  ? LucideIcons.building2
                                                  : LucideIcons.briefcase,
                                          size: 12,
                                          color: theme.colorScheme.primary.withValues(alpha: 0.7),
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
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
