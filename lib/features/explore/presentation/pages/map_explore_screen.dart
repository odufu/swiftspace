import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:swiftspace/core/services/audio_manager.dart';
import 'dart:ui';
import 'package:swiftspace/core/theme/theme_provider.dart';
import 'package:swiftspace/core/constants/app_constants.dart';
import 'package:swiftspace/features/property/domain/entities/property.dart';
import 'package:swiftspace/features/explore/presentation/widgets/custom_marker.dart';
import 'package:swiftspace/features/property/presentation/widgets/property_snippet.dart';
import 'package:swiftspace/features/property/presentation/pages/property_details_screen.dart';
import 'package:swiftspace/features/explore/presentation/pages/advanced_explore_screen.dart';
import 'package:swiftspace/features/auth/presentation/state/user_preferences_provider.dart';
import 'package:swiftspace/core/services/ai_recommendation_service.dart';
import 'package:swiftspace/features/negotiation/presentation/widgets/best_offer_card.dart';
import 'package:swiftspace/core/utils/responsive.dart';
import 'package:swiftspace/features/property/presentation/state/property_provider.dart';
import 'package:swiftspace/core/di/injection_container.dart';
import 'package:swiftspace/core/services/map_service.dart';
import 'package:swiftspace/features/chat/presentation/state/notification_provider.dart';
import 'package:swiftspace/features/chat/domain/entities/notification.dart';

class MapExploreScreen extends StatefulWidget {
  const MapExploreScreen({super.key});

  @override
  State<MapExploreScreen> createState() => _MapExploreScreenState();
}

class _MapExploreScreenState extends State<MapExploreScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  // Route animation controller
  late final AnimationController _mapAnimController = AnimationController(
    duration: const Duration(milliseconds: 600),
    vsync: this,
  );

  LatLng _center = const LatLng(9.1538, 7.3220);
  Property? _selectedProperty;
  LatLng? _searchPin;
  LatLng? _userLocation;
  String _searchQuery = '';

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  bool _isSatelliteMode = false;
  final Set<String> _selectedTerms = {'mo', 'yr', 'buy'};
  RangeValues _priceRange = const RangeValues(10000, 5000000);

  bool _sortByBestOffer = false;
  double _bestOfferRadius = 5.0; // km
  Map<String, String> _aiReasonings = {};

  // New Filter & Priority State
  final Set<PropertyType> _selectedTypes = {};
  final List<String> _userPriorities = [
    'price',
    'road',
    'utilities',
    'hospital',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showAreaOfInterestPrompt();
    });
  }

  @override
  void dispose() {
    _mapAnimController.dispose();
    super.dispose();
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    if (_mapAnimController.isAnimating) _mapAnimController.stop();
    _mapAnimController.reset();

    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.camera.zoom,
      end: destZoom,
    );

    final animation = CurvedAnimation(
      parent: _mapAnimController,
      curve: Curves.fastOutSlowIn,
    );

    _mapAnimController.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    _mapAnimController.forward();
  }

  Future<LatLng?> _fetchCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    final position = await Geolocator.getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
  }

  Widget _buildPriorityChip(
    String label,
    String id,
    ThemeData theme,
    StateSetter setModalState,
  ) {
    final isSelected = _userPriorities.contains(id);
    final index = _userPriorities.indexOf(id);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
      avatar: isSelected
          ? CircleAvatar(
              radius: 10,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                '${index + 1}',
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            )
          : null,
      onSelected: (selected) {
        setModalState(() {
          if (selected) {
            _userPriorities.add(id);
          } else {
            _userPriorities.remove(id);
          }
        });
        setState(() {});
      },
    );
  }

  void _showAreaOfInterestPrompt() {
    Navigator.of(context)
        .push(
          PageRouteBuilder(
            opaque: false,
            barrierDismissible: false,
            transitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (ctx, animation, _) => const AreaOfInterestSheet(),
            transitionsBuilder: (ctx, animation, _, child) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeIn,
                ),
                child: child,
              );
            },
          ),
        )
        .then((selectedLocation) async {
          if (selectedLocation != null) {
            if (selectedLocation == 'current') {
              final loc = await _fetchCurrentLocation();
              if (loc != null) {
                setState(() {
                  _userLocation = loc;
                  _center = loc;
                  _animatedMapMove(loc, 13.0);
                });
              }
            } else if (selectedLocation is LatLng) {
              setState(() {
                _center = selectedLocation;
                _searchPin = selectedLocation;
                _animatedMapMove(selectedLocation, 13.0);
              });
            }
          }
        });
  }

  void _onSearchSubmit(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
    
    // Animate map to the first property found in search results
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final results = _filteredProperties;
      if (results.isNotEmpty) {
        _animatedMapMove(results.first.location, 13.0);
      }
    });
  }

  void _showPropertySnippet(Property property) {
    setState(() {
      _selectedProperty = property;
    });

    // Play "Pop" sound
    sl<AudioManager>().playClick(context);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Snippet',
      barrierColor: Colors.black.withValues(alpha: 0.3),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: PropertySnippet(property: property),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curvedAnim = CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutBack,
        );
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 5 * anim1.value,
            sigmaY: 5 * anim1.value,
          ),
          child: FadeTransition(
            opacity: anim1,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnim),
              child: child,
            ),
          ),
        );
      },
    ).then((_) {
      setState(() {
        _selectedProperty = null;
      });
    });
  }

  // --- Filter Logic ---
  List<Property> get _filteredProperties {
    final allProperties = Provider.of<PropertyProvider>(
      context,
      listen: false,
    ).properties;

    final list = allProperties.where((p) {
      // ONLY SHOW ACTIVE PROPERTIES FOR CLIENT DISCOVERY
      if (!p.isActive) return false;

      final matchesTerm =
          _selectedTerms.isEmpty || _selectedTerms.contains(p.priceTerm);
      // For rental properties, apply price filter. For 'buy', use a much wider range
      final isBuy = p.priceTerm == 'buy';
      final matchesPrice = isBuy
          ? true // always show buy listings regardless of rental price slider
          : p.price >= _priceRange.start && p.price <= _priceRange.end;

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

      final matchesType =
          _selectedTypes.isEmpty || _selectedTypes.contains(p.type);

      return matchesTerm && matchesPrice && matchesSearch && matchesType;
    }).toList();

    final refPoint = _searchPin ?? _userLocation ?? _center;

    if (_sortByBestOffer) {
      // *** Restrict to radius around current map focus ***
      final List<Property> inRadius = list.where((p) {
        final distMeters = Geolocator.distanceBetween(
          refPoint.latitude,
          refPoint.longitude,
          p.location.latitude,
          p.location.longitude,
        );
        return (distMeters / 1000.0) <= _bestOfferRadius;
      }).toList();

      // Fall back to full list if no properties in radius (avoid empty results)
      final candidates = inRadius.isNotEmpty ? inRadius : list;

      final result = AiRecommendationService.rankProperties(
        properties: candidates,
        priorities: _userPriorities.isNotEmpty
            ? _userPriorities
            : ['price', 'road', 'utilities', 'hospital'],
      );

      // Store reasonings briefly - Note: In a production app, this would be in a provider
      _aiReasonings = result.reasonings;

      // Rebuild list: best-offer candidates first, then the rest
      final sortedCandidates = result.rankedProperties;
      final remaining = list
          .where((p) => !sortedCandidates.contains(p))
          .toList();

      // Default sort for remaining is proximity
      remaining.sort((a, b) {
        final distA = Geolocator.distanceBetween(
          refPoint.latitude,
          refPoint.longitude,
          a.location.latitude,
          a.location.longitude,
        );
        final distB = Geolocator.distanceBetween(
          refPoint.latitude,
          refPoint.longitude,
          b.location.latitude,
          b.location.longitude,
        );
        return distA.compareTo(distB);
      });

      return [...sortedCandidates, ...remaining];
    } else {
      list.sort((a, b) {
        final distA = Geolocator.distanceBetween(
          refPoint.latitude,
          refPoint.longitude,
          a.location.latitude,
          a.location.longitude,
        );
        final distB = Geolocator.distanceBetween(
          refPoint.latitude,
          refPoint.longitude,
          b.location.latitude,
          b.location.longitude,
        );
        return distA.compareTo(distB); // Closer distance first
      });
    }

    return list;
  }

  void _simulatePushNotification() {
    // Show a realistic looking faux push notification overlay after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      final overlay = Overlay.of(context);
      late OverlayEntry entry;

      entry = OverlayEntry(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onVerticalDragEnd: (_) => entry.remove(),
                onTap: () => entry.remove(),
                child: TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 400),
                  tween: Tween<double>(begin: -100, end: 0),
                  builder: (context, double value, child) {
                    return Transform.translate(
                      offset: Offset(0, value),
                      child: child,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            LucideIcons.home,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Swift Space Alerts',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'A new property matching your price limits just got listed nearby. Tap to view!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'now',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );

      overlay.insert(entry);

      // Auto dismiss after 6 seconds
      Future.delayed(const Duration(seconds: 6), () {
        if (entry.mounted) entry.remove();
      });
    });
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Filters',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton.icon(
                                icon: const Icon(
                                  LucideIcons.bellRing,
                                  size: 18,
                                ),
                                label: const Text('Notify Me'),
                                style: TextButton.styleFrom(
                                  foregroundColor: theme.colorScheme.primary,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  
                                  final noteProvider = Provider.of<NotificationProvider>(context, listen: false);
                                  noteProvider.addNotification(NotificationModel(
                                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                                    title: 'Price Alert Active',
                                    message: 'We will notify you immediately when a property matching these filters is listed.',
                                    type: NotificationType.match,
                                    timestamp: DateTime.now(),
                                    isRead: false,
                                  ));

                                  ScaffoldMessenger.of(
                                    this.context,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Alert created! We will notify you when a match is found.',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  _simulatePushNotification();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          const Text(
                            'Listing Type',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ...['day', 'wk', 'mo', 'yr'].map((term) {
                                final isSelected = _selectedTerms.contains(
                                  term,
                                );
                                return ChoiceChip(
                                  label: Text('Per $term'),
                                  selected: isSelected,
                                  selectedColor: theme.colorScheme.primary
                                      .withValues(alpha: 0.2),
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  onSelected: (selected) {
                                    setModalState(() {
                                      if (selected) {
                                        _selectedTerms.add(term);
                                      } else {
                                        _selectedTerms.remove(term);
                                      }
                                    });
                                    setState(() {});
                                  },
                                );
                              }),
                              // Buy chip — distinct teal color to signal purchase
                              Builder(
                                builder: (context) {
                                  final isSelected = _selectedTerms.contains(
                                    'buy',
                                  );
                                  return FilterChip(
                                    avatar: Icon(
                                      LucideIcons.home,
                                      size: 14,
                                      color: isSelected
                                          ? Colors.teal
                                          : Colors.grey,
                                    ),
                                    label: const Text('BUY'),
                                    selected: isSelected,
                                    selectedColor: Colors.teal.withValues(
                                      alpha: 0.2,
                                    ),
                                    checkmarkColor: Colors.teal,
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? Colors.teal
                                          : theme.colorScheme.onSurface,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    onSelected: (selected) {
                                      setModalState(() {
                                        if (selected) {
                                          _selectedTerms.add('buy');
                                        } else {
                                          _selectedTerms.remove('buy');
                                        }
                                      });
                                      setState(() {});
                                    },
                                  );
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),
                          const Text(
                            'Property Category',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: PropertyType.values.map((type) {
                              final isSelected = _selectedTypes.contains(type);
                              return FilterChip(
                                label: Text(type.displayName),
                                selected: isSelected,
                                selectedColor: theme.colorScheme.primary
                                    .withValues(alpha: 0.2),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                onSelected: (selected) {
                                  setModalState(() {
                                    if (selected) {
                                      _selectedTypes.add(type);
                                    } else {
                                      _selectedTypes.remove(type);
                                    }
                                  });
                                  setState(() {});
                                },
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 24),
                          const Text(
                            'Optimization',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            activeThumbColor: theme.colorScheme.primary,
                            title: const Text('Sort by Best Offer'),
                            subtitle: const Text(
                              'AI ranks properties based on your chosen scouting priorities.',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: _sortByBestOffer,
                            onChanged: (val) {
                              setModalState(() => _sortByBestOffer = val);
                              setState(() {
                                // If turning on AI Best Offer, quickly animate to the top suggested home
                                if (val) {
                                  final results = _filteredProperties;
                                  if (results.isNotEmpty) {
                                    _animatedMapMove(results.first.location, 14.5);
                                  }
                                }
                              });
                            },
                          ),
                          if (_sortByBestOffer) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.05,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            LucideIcons.radar,
                                            color: theme.colorScheme.primary,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Search Radius',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary
                                              .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          '${_bestOfferRadius.toStringAsFixed(0)} km',
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Only properties within this distance from your focused area will be ranked as Best Offer.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Slider(
                                    value: _bestOfferRadius,
                                    min: 1,
                                    max: 50,
                                    divisions: 49,
                                    activeColor: theme.colorScheme.primary,
                                    label:
                                        '${_bestOfferRadius.toStringAsFixed(0)} km',
                                    onChanged: (val) {
                                      setModalState(
                                        () => _bestOfferRadius = val,
                                      );
                                      setState(() {});
                                    },
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
                                    child: Divider(),
                                  ),
                                  const Text(
                                    'AI SCOUTING PRIORITIES',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _buildPriorityChip(
                                        '💰 Price',
                                        'price',
                                        theme,
                                        setModalState,
                                      ),
                                      _buildPriorityChip(
                                        '🛣️ Road Access',
                                        'road',
                                        theme,
                                        setModalState,
                                      ),
                                      _buildPriorityChip(
                                        '⚡ Utilities',
                                        'utilities',
                                        theme,
                                        setModalState,
                                      ),
                                      _buildPriorityChip(
                                        '🏥 Healthcare',
                                        'hospital',
                                        theme,
                                        setModalState,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'The order of selection determines importance.',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[500],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '1 km',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                      Text(
                                        '50 km',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Price Range',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '₦${(_priceRange.start / 1000).toStringAsFixed(0)}k - ₦${(_priceRange.end / 1000).toStringAsFixed(0)}k+',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          RangeSlider(
                            values: _priceRange,
                            min: 10000,
                            max: 5000000,
                            divisions: 100,
                            activeColor: theme.colorScheme.primary,
                            inactiveColor: theme.colorScheme.primary.withValues(
                              alpha: 0.2,
                            ),
                            onChanged: (values) {
                              setModalState(() => _priceRange = values);
                              setState(() {});
                            },
                          ),

                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                final results = _filteredProperties;
                                if (results.isNotEmpty) {
                                  _animatedMapMove(results.first.location, 13.0);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Show ${_filteredProperties.length} Homes',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAISuggestions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        final prefs = Provider.of<UserPreferencesProvider>(
          context,
          listen: false,
        );
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.sparkles,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'AI Best Offer Recommendations',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Personalize Suggestions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Drag to reorder what matters most to you. The AI will prioritize listings based on this order.',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),

                      // Local state for priorities in the modal
                      StatefulBuilder(
                        builder: (context, setModalState) {
                          final currentPriorities = prefs.bestOfferPriorities;

                          return Container(
                            height: 260,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ReorderableListView(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              children: currentPriorities.map((priority) {
                                String label = '';
                                IconData icon = Icons.circle;
                                switch (priority) {
                                  case 'price':
                                    label = 'Affordability (Price)';
                                    icon = LucideIcons.banknote;
                                    break;
                                  case 'road':
                                    label = 'Proximity to Road';
                                    icon = LucideIcons.map;
                                    break;
                                  case 'utilities':
                                    label = '24/7 Power & Water';
                                    icon = LucideIcons.zap;
                                    break;
                                  case 'hospital':
                                    label = 'Proximity to Hospital';
                                    icon = LucideIcons.cross;
                                    break;
                                }

                                return ListTile(
                                  key: ValueKey(priority),
                                  leading: Icon(
                                    icon,
                                    color: Colors.purple,
                                    size: 20,
                                  ),
                                  title: Text(
                                    label,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    LucideIcons.gripVertical,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                );
                              }).toList(),
                              onReorder: (oldIndex, newIndex) {
                                if (newIndex > oldIndex) newIndex -= 1;
                                final List<String> items = List.from(
                                  currentPriorities,
                                );
                                final item = items.removeAt(oldIndex);
                                items.insert(newIndex, item);

                                // Update provider and trigger local rebuild
                                prefs.updateBestOfferPriorities(items);
                                setModalState(() {});
                                // Also trigger ExploreScreen rebuild to update suggestions immediately
                                setState(() {});
                              },
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(LucideIcons.check),
                          label: const Text(
                            'Apply Priorities',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final prefs = Provider.of<UserPreferencesProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final isMobile = Responsive.isMobile(context);

    // Check for requested property focus from other screens
    if (prefs.mapFocusPropertyId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final propId = prefs.mapFocusPropertyId;
        if (propId != null) {
          final property = Provider.of<PropertyProvider>(context, listen: false)
              .properties
              .where((p) => p.id == propId)
              .firstOrNull;
          if (property != null) {
            setState(() {
              _selectedProperty = property;
            });
            if (isMobile) {
              _sheetController.animateTo(
                0.15, // Snap back to peek to show map
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
            _animatedMapMove(property.location, 15.0);
            prefs.setMapFocusProperty(null); // Clear focus request
          }
        }
      });
    }

    if (!isMobile) {
      return Scaffold(
        body: Row(
          children: [
            // Left Sidebar: Filters & List
            Container(
              width: 420,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Sidebar Header
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(
                                        LucideIcons.mapPin,
                                        color: theme.colorScheme.primary,
                                        size: 20,
                                      ),
                                      onPressed: _showAreaOfInterestPrompt,
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: _searchController,
                                        onSubmitted: _onSearchSubmit,
                                        decoration: const InputDecoration(
                                          hintText: 'Search properties...',
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: _showFilterModal,
                              icon: const Icon(LucideIcons.slidersHorizontal),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildAISuggestionsChip(isDark),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(child: _buildGridView(theme, ScrollController())),
                ],
              ),
            ),
            // Right Side: Map
            Expanded(
              child: Stack(
                children: [
                  _buildMapView(isDark),
                  Positioned(
                    top: 24,
                    left: 24,
                    child: Row(
                      children: [
                        _buildFloatingIconBtn(
                          isDark ? LucideIcons.sun : LucideIcons.moon,
                          () => themeProvider.toggleTheme(!isDark),
                          theme,
                        ),
                        const SizedBox(width: 12),
                        _buildFloatingIconBtn(
                          _isSatelliteMode
                              ? LucideIcons.map
                              : LucideIcons.layers,
                          () => setState(
                            () => _isSatelliteMode = !_isSatelliteMode,
                          ),
                          theme,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 24,
                    top: 24,
                    child: Column(
                      children: [
                        _buildFloatingIconBtn(LucideIcons.crosshair, () async {
                          final loc = await _fetchCurrentLocation();
                          if (loc != null) {
                            setState(() {
                              _userLocation = loc;
                              _animatedMapMove(loc, 13.0);
                            });
                          }
                        }, theme),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              IconButton(
                                icon: const Icon(LucideIcons.plus),
                                onPressed: () => _animatedMapMove(
                                  _mapController.camera.center,
                                  _mapController.camera.zoom + 1,
                                ),
                              ),
                              Divider(height: 1, indent: 8, endIndent: 8),
                              IconButton(
                                icon: const Icon(LucideIcons.minus),
                                onPressed: () => _animatedMapMove(
                                  _mapController.camera.center,
                                  _mapController.camera.zoom - 1,
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
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background - Persistent Map
          _buildMapView(isDark),

          // Top Search Bar and Action Row
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(25),
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
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                LucideIcons.mapPin,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                              onPressed: _showAreaOfInterestPrompt,
                            ),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onSubmitted: _onSearchSubmit,
                                decoration: const InputDecoration(
                                  hintText:
                                      'Search location, type, or developer...',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _showFilterModal,
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(25),
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
                            Icon(
                              LucideIcons.slidersHorizontal,
                              color: theme.colorScheme.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Filters',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildAISuggestionsChip(isDark),
              ],
            ),
          ),

          // Floating Controls
          Positioned(
            right: 16,
            top: 170,
            child: Column(
              children: [
                GestureDetector(
                  onTap: () async {
                    final loc = await _fetchCurrentLocation();
                    if (loc != null) {
                      setState(() {
                        _userLocation = loc;
                        _animatedMapMove(loc, 13.0);
                      });
                    }
                  },
                  child: _buildFloatingIcon(LucideIcons.crosshair, theme),
                ),
                const SizedBox(height: 12),
                Container(
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
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.plus),
                        onPressed: () {
                          _animatedMapMove(
                            _mapController.camera.center,
                            _mapController.camera.zoom + 1,
                          );
                        },
                      ),
                      Container(
                        height: 1,
                        width: 30,
                        color: theme.dividerColor.withValues(alpha: 0.1),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.minus),
                        onPressed: () {
                          _animatedMapMove(
                            _mapController.camera.center,
                            _mapController.camera.zoom - 1,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Theme Toggle Left Side
          Positioned(
            top: 160,
            left: 16,
            child: FloatingActionButton(
              heroTag: 'theme_toggle',
              mini: true,
              backgroundColor: theme.colorScheme.surface,
              onPressed: () {
                themeProvider.toggleTheme(!isDark);
              },
              child: Icon(
                isDark ? LucideIcons.sun : LucideIcons.moon,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          // Map Type Toggle (Satellite/Normal)
          Positioned(
            top: 220,
            left: 16,
            child: FloatingActionButton(
              heroTag: 'map_type_toggle',
              mini: true,
              backgroundColor: theme.colorScheme.surface,
              onPressed: () {
                setState(() {
                  _isSatelliteMode = !_isSatelliteMode;
                });
              },
              child: Icon(
                _isSatelliteMode ? LucideIcons.map : LucideIcons.layers,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),

          // Draggable Peek Sheet (Grid View)
          _buildDraggableSheet(theme, isDark),

          // Grid/Map View Toggle (Bottom Right)
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'grid_map_toggle',
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              onPressed: () {
                if (_sheetController.isAttached) {
                  final isExpanded = _sheetController.size > 0.5;
                  _sheetController.animateTo(
                    isExpanded ? 0.15 : 0.95,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                  );
                }
              },
              child: AnimatedBuilder(
                animation: _sheetController,
                builder: (context, _) {
                  final isExpanded =
                      _sheetController.isAttached &&
                      _sheetController.size > 0.5;
                  return Icon(
                    isExpanded ? LucideIcons.map : LucideIcons.layoutGrid,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAISuggestionsChip(bool isDark) {
    return GestureDetector(
      onTap: _showAISuggestions,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.purple.withValues(alpha: isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.purple.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.sparkles, color: Colors.purple, size: 14),
            const SizedBox(width: 6),
            Text(
              'AI Insights Available',
              style: TextStyle(
                color: isDark ? Colors.purple[200] : Colors.purple[800],
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingIconBtn(
    IconData icon,
    VoidCallback onTap,
    ThemeData theme,
  ) {
    return FloatingActionButton(
      heroTag: null,
      mini: true,
      backgroundColor: theme.colorScheme.surface,
      elevation: 4,
      onPressed: onTap,
      child: Icon(icon, color: theme.colorScheme.onSurface, size: 18),
    );
  }

  Widget _buildDraggableSheet(ThemeData theme, bool isDark) {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.35,
      minChildSize: 0.15,
      maxChildSize: 0.95,
      snap: true,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(child: _buildGridView(theme, scrollController)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapView(bool isDark) {
    List<Marker> markers = _filteredProperties.asMap().entries.map((entry) {
      final index = entry.key;
      final prop = entry.value;
      final isSelected = _selectedProperty?.id == prop.id;
      final isBestOffer = _sortByBestOffer && index == 0;

      return Marker(
        point: prop.location,
        width: 150,
        height: 100,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: () => _showPropertySnippet(prop),
          child: CustomMarkerWidget(
            property: prop,
            isSelected: isSelected,
            isBestOffer: isBestOffer,
          ),
        ),
      );
    }).toList();

    // Search pin
    if (_searchPin != null) {
      markers.add(
        Marker(
          point: _searchPin!,
          width: 40,
          height: 40,
          alignment: Alignment.topCenter,
          child: const Icon(Icons.location_on, color: Colors.amber, size: 40),
        ),
      );
    }

    // User location dot (Simple version for flutter_map)
    if (_userLocation != null) {
      markers.add(
        Marker(
          point: _userLocation!,
          width: 24,
          height: 24,
          alignment: Alignment.center,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(initialCenter: _center, initialZoom: 13.0),
      children: [
        sl<IMapService>().getTileLayer(
          isDark: isDark,
          isSatellite: _isSatelliteMode,
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }

  Widget _buildGridView(ThemeData theme, ScrollController scrollController) {
    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(LucideIcons.compass, size: 18),
              label: const Text('Explore Advanced Grid Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdvancedExploreScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          if (_filteredProperties.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No properties found matching filters.',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.only(bottom: 100),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.73,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _filteredProperties.length,
                itemBuilder: (context, index) {
                  final prop = _filteredProperties[index];
                  final isBestOfferIdx = _sortByBestOffer && index == 0;

                  if (isBestOfferIdx) {
                    return BestOfferCard(
                      property: prop,
                      reasoning:
                          _aiReasonings[prop.id] ??
                          "Top match for your interests.",
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            transitionDuration: const Duration(
                              milliseconds: 300,
                            ),
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    PropertyDetailsScreen(property: prop),
                            transitionsBuilder:
                                (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                },
                          ),
                        );
                      },
                    );
                  }

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 300),
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  PropertyDetailsScreen(property: prop),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
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
                            // Image part
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
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                            width: double.infinity,
                                            color: Colors.grey[300],
                                            child: const Icon(
                                              Icons.image_not_supported,
                                            ),
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
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: prop.formattedPrice,
                                        style: TextStyle(
                                          color: prop.priceTerm == 'buy'
                                              ? const Color(
                                                  0xFF1EB476,
                                                ) // Teal-ish primary
                                              : theme.colorScheme.onSurface,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      if (prop.priceTerm.isNotEmpty &&
                                          prop.priceTerm != 'buy')
                                        TextSpan(
                                          text: '/${prop.priceTerm}',
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurface,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        )
                                      else if (prop.priceTerm == 'buy')
                                        const TextSpan(
                                          text: ' • SALE',
                                          style: TextStyle(
                                            color: Color(0xFF1EB476),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  prop.type.displayName,
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  prop.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      LucideIcons.bedDouble,
                                      size: 12,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${prop.beds}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      LucideIcons.bath,
                                      size: 12,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${prop.baths}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      prop.listerType == ListerType.owner
                                          ? LucideIcons.user
                                          : prop.listerType ==
                                                ListerType.developer
                                          ? LucideIcons.building2
                                          : LucideIcons.briefcase,
                                      size: 12,
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.7),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        prop.listerType == ListerType.agent
                                            ? prop.listerName
                                            : (prop.companyName ??
                                                  prop.listerName),
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

  Widget _buildFloatingIcon(IconData icon, ThemeData theme) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(icon, color: theme.colorScheme.onSurface, size: 20),
      ),
    );
  }
}

// Full-screen immersive location onboarding screen
class AreaOfInterestSheet extends StatefulWidget {
  const AreaOfInterestSheet({super.key});

  @override
  State<AreaOfInterestSheet> createState() => _AreaOfInterestSheetState();
}

class _AreaOfInterestSheetState extends State<AreaOfInterestSheet>
    with TickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  bool _isSearchFocused = false;

  late final AnimationController _bgAnim;
  late final AnimationController _contentAnim;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;

  final List<Map<String, dynamic>> _locations = [
    {
      'name': 'Lagos',
      'sub': 'Nigeria • 15 properties',
      'loc': const LatLng(6.5244, 3.3792),
    },
    {
      'name': 'Abuja',
      'sub': 'FCT • 37 properties',
      'loc': const LatLng(9.1538, 7.3220),
    },
    {
      'name': 'Port Harcourt',
      'sub': 'Rivers • 42 properties',
      'loc': const LatLng(4.8156, 7.0498),
    },
    {
      'name': 'Ikeja',
      'sub': 'Lagos • 8 properties',
      'loc': const LatLng(6.5965, 3.3421),
    },
    {
      'name': 'Lekki',
      'sub': 'Lagos • 11 properties',
      'loc': const LatLng(6.4698, 3.5852),
    },
    {
      'name': 'Kano',
      'sub': 'Kano State • 5 properties',
      'loc': const LatLng(12.0022, 8.5920),
    },
  ];

  @override
  void initState() {
    super.initState();
    _bgAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _contentAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _fadeIn = CurvedAnimation(parent: _contentAnim, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _contentAnim, curve: Curves.easeOutCubic),
        );
  }

  @override
  void dispose() {
    _bgAnim.dispose();
    _contentAnim.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    if (_query.isEmpty) return _locations;
    return _locations
        .where(
          (l) =>
              l['name'].toString().toLowerCase().contains(
                _query.toLowerCase(),
              ) ||
              l['sub'].toString().toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Animated deep dark gradient background
          AnimatedBuilder(
            animation: _bgAnim,
            builder: (ctx, _) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(
                        const Color(0xFF0A0E1A),
                        const Color(0xFF0D1620),
                        _bgAnim.value,
                      )!,
                      Color.lerp(
                        const Color(0xFF0F1A2E),
                        const Color(0xFF081018),
                        _bgAnim.value,
                      )!,
                      Color.lerp(
                        const Color(0xFF0A1424),
                        const Color(0xFF0E1830),
                        _bgAnim.value,
                      )!,
                    ],
                  ),
                ),
              );
            },
          ),

          // Subtle dot-grid pattern overlay
          Opacity(
            opacity: 0.06,
            child: Image.network(
              'https://www.transparenttextures.com/patterns/diagmonds.png',
              width: size.width,
              height: size.height,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),

          // Glowing accent blob top-right
          Positioned(
            top: -80,
            right: -80,
            child: AnimatedBuilder(
              animation: _bgAnim,
              builder: (ctx, _) {
                final opacity = 0.12 + _bgAnim.value * 0.08;
                return Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primaryDark.withValues(alpha: opacity),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Glowing accent blob bottom-left
          Positioned(
            bottom: -60,
            left: -60,
            child: AnimatedBuilder(
              animation: _bgAnim,
              builder: (ctx, _) {
                final opacity = 0.08 + (1 - _bgAnim.value) * 0.08;
                return Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primaryLight.withValues(alpha: opacity),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Content
          SafeArea(
            child: SlideTransition(
              position: _slideIn,
              child: FadeTransition(
                opacity: _fadeIn,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 28,
                    right: 28,
                    top: 40,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo / brand
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1EB476), Color(0xFF0F5A3F)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Image.asset(
                              'assets/logo.png',
                              width: 22,
                              height: 22,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            AppConstants.appName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 48),

                      // Headline
                      const Text(
                        'Where would you\nlike to explore?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Find your next home, land, or investment.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Search field
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: _isSearchFocused ? 0.12 : 0.07,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isSearchFocused
                                ? AppColors.primaryDark
                                : Colors.white.withValues(alpha: 0.1),
                            width: 1.5,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.search,
                              color: _isSearchFocused
                                  ? AppColors.primaryDark
                                  : Colors.white.withValues(alpha: 0.5),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Focus(
                                onFocusChange: (f) =>
                                    setState(() => _isSearchFocused = f),
                                child: TextField(
                                  controller: _searchCtrl,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                  cursorColor: AppColors.primaryDark,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Search city or area...',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.35,
                                      ),
                                      fontSize: 15,
                                    ),
                                  ),
                                  onChanged: (v) => setState(() => _query = v),
                                ),
                              ),
                            ),
                            if (_query.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchCtrl.clear();
                                  setState(() => _query = '');
                                },
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white.withValues(alpha: 0.4),
                                  size: 18,
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Use current location button
                      GestureDetector(
                        onTap: () => Navigator.pop(context, 'current'),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(
                                0xFF1EB476,
                              ).withValues(alpha: 0.5),
                            ),
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryDark.withValues(alpha: 0.12),
                                AppColors.primaryLight.withValues(alpha: 0.08),
                              ],
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(
                                    0xFF1EB476,
                                  ).withValues(alpha: 0.2),
                                ),
                                child: const Icon(
                                  LucideIcons.crosshair,
                                  color: Color(0xFF1EB476),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Use My Current Location',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Show properties near me',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.45,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Section label
                      Text(
                        _query.isEmpty ? 'POPULAR LOCATIONS' : 'SEARCH RESULTS',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Location list
                      Expanded(
                        child: _filtered.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      LucideIcons.mapPin,
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      size: 40,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No locations found',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                itemCount: _filtered.length,
                                separatorBuilder: (_, _) => Divider(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  height: 1,
                                ),
                                itemBuilder: (ctx, i) {
                                  final loc = _filtered[i];
                                  return _LocationTile(
                                    name: loc['name'] as String,
                                    sub: loc['sub'] as String,
                                    onTap: () =>
                                        Navigator.pop(context, loc['loc']),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationTile extends StatefulWidget {
  final String name;
  final String sub;
  final VoidCallback onTap;
  const _LocationTile({
    required this.name,
    required this.sub,
    required this.onTap,
  });

  @override
  State<_LocationTile> createState() => _LocationTileState();
}

class _LocationTileState extends State<_LocationTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _hovering = true),
      onTapUp: (_) {
        setState(() => _hovering = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _hovering
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
              child: Icon(
                LucideIcons.mapPin,
                color: Colors.white.withValues(alpha: 0.5),
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.sub,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.25),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
