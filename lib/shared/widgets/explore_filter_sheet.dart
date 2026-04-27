import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:swiftspace/features/property/domain/entities/property.dart';
import 'package:swiftspace/features/auth/presentation/state/user_preferences_provider.dart';

class ExploreFilterSheet extends StatefulWidget {
  const ExploreFilterSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ExploreFilterSheet(),
    );
  }

  @override
  State<ExploreFilterSheet> createState() => _ExploreFilterSheetState();
}

class _ExploreFilterSheetState extends State<ExploreFilterSheet> {
  late double _minPrice;
  late double _maxPrice;
  PropertyType? _selectedType;
  late String _location;
  late List<String> _priorities;

  @override
  void initState() {
    super.initState();
    final prefs = context.read<UserPreferencesProvider>();
    _minPrice = prefs.minPrice;
    _maxPrice = prefs.maxPrice;
    _selectedType = prefs.preferredType;
    _location = prefs.preferredLocation;
    _priorities = List.from(prefs.bestOfferPriorities);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Filter Properties",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    // Reset logic
                  },
                  child: const Text("Reset"),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Property Type
            const Text("Shop Type", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: PropertyType.values.map((type) {
                  final isSelected = _selectedType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(type.displayName),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedType = selected ? type : null);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Location
            const Text("Location", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                hintText: "Enter area, city or estate...",
                prefixIcon: const Icon(LucideIcons.mapPin, size: 18),
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => _location = val,
            ),
            const SizedBox(height: 24),

            // Price Range
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Price Range", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  "₦${(_minPrice / 1000).toStringAsFixed(0)}k - ₦${(_maxPrice / 1000).toStringAsFixed(0)}k",
                  style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            RangeSlider(
              values: RangeValues(_minPrice, _maxPrice),
              min: 0,
              max: 10000000,
              divisions: 100,
              onChanged: (values) {
                setState(() {
                  _minPrice = values.start;
                  _maxPrice = values.end;
                });
              },
            ),
            const SizedBox(height: 24),

            // AI Priority Checklist
            Row(
              children: [
                Icon(LucideIcons.sparkles, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                const Text("AI Best Offer Priorities", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              "Drag to reorder what matters most to you. Our AI will suggest the 'Best Offer' card based on this.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: _priorities.asMap().entries.map((entry) {
                  final index = entry.key;
                  final priority = entry.value;
                  return Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          radius: 12,
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                          child: Text("${index + 1}", style: TextStyle(fontSize: 10, color: theme.colorScheme.primary)),
                        ),
                        title: Text(priority[0].toUpperCase() + priority.substring(1), style: const TextStyle(fontSize: 14)),
                        trailing: const Icon(LucideIcons.gripVertical, size: 18, color: Colors.grey),
                      ),
                      if (index < _priorities.length - 1)
                        const Divider(height: 1),
                    ],
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final prefs = context.read<UserPreferencesProvider>();
                  prefs.updatePreferences(
                    minPrice: _minPrice,
                    maxPrice: _maxPrice,
                    type: _selectedType,
                    location: _location,
                  );
                  prefs.updateBestOfferPriorities(_priorities);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Apply Filters"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
