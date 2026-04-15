import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/property.dart';
import '../providers/favorites_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'video_player_screen.dart';
import 'virtual_walkthrough_screen.dart';
import 'payment_success_screen.dart';
import 'payment_failure_screen.dart';
import 'escrow_payment_screen.dart';
import '../providers/user_preferences_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/property_provider.dart';
import '../models/booking.dart';
import '../widgets/inspection_date_picker.dart';
import 'chat_detail_screen.dart';
import 'inspection_management_screen.dart';
import 'property_management_screen.dart';
import '../models/commitment.dart';
import 'dart:async';

class PropertyDetailsScreen extends StatefulWidget {
  final Property property;

  const PropertyDetailsScreen({
    super.key,
    required this.property,
  });

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  bool _agentRevealed = false;
  bool _inspectionPaid = false;
  int _currentImageIndex = 0;
  
  late Timer _tooltipTimer;
  int _currentTooltipIndex = 0;
  final List<String> _tooltipPhrases = [
    'Explore the neighborhood',
    'See nearby schools',
    'Check commute time',
    'View on map',
    'Navigate to property',
    'Explore surroundings',
  ];

  @override
  void initState() {
    super.initState();
    _tooltipTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _currentTooltipIndex = (_currentTooltipIndex + 1) % _tooltipPhrases.length;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyProvider>().incrementViews(widget.property.id);
    });
  }

  @override
  void dispose() {
    _tooltipTimer.cancel();
    super.dispose();
  }

  Widget _buildMetricBadge(IconData icon, String label, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _openLocationInGoogleMaps(double lat, double lng) async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _simulatePaymentFlow(String title, String successDesc, int amount, VoidCallback onSuccess) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.green),
              const SizedBox(height: 20),
              Text(
                'Processing ₦$amount...',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please wait while we secure your request securely.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );

    // Simulate network delay
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      
      // Simulate random failure (10% chance)
      final bool isSuccess = DateTime.now().millisecond % 10 != 0;

      if (isSuccess) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentSuccessScreen(
              title: '$title Successful!',
              description: successDesc,
            ),
          ),
        );
        if (result == true) {
          onSuccess();
        }
      } else {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PaymentFailureScreen(
              title: 'Payment Failed',
              description: 'Your bank declined the transaction. Please try again.',
            ),
          ),
        );
      }
    });
  }

  void _showMockNotification(String title, String body) {
    if (!mounted) return;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 4),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))
            ],
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(LucideIcons.bell, color: theme.colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(body, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPremiumActions() {
    final theme = Theme.of(context);
    final isBuy = widget.property.priceTerm == 'buy';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Premium Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Access high-value tools to secure this property.', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              const SizedBox(height: 24),
              
              // Action 1: Inspection (via Escrow)
              if (!_inspectionPaid)
                _buildActionTile(
                  icon: LucideIcons.shieldCheck,
                  title: 'Book Verified Inspection',
                  subtitle: 'Funds held in escrow — released only after visit.',
                  price: '₦5,000',
                  color: Colors.teal,
                  onTap: () async {
                    Navigator.pop(sheetContext); // Close actions sheet
                    // Show Date/Time Picker first
                    final selectedDateTime = await showModalBottomSheet<DateTime>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => InspectionDatePicker(
                        property: widget.property,
                      ),
                    );

                    if (selectedDateTime != null && mounted) {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EscrowPaymentScreen(
                            propertyTitle: widget.property.title,
                            location: widget.property.locationName,
                            propertyImage: widget.property.imagesGallery.isNotEmpty ? widget.property.imagesGallery.first : widget.property.imageUrl,
                            amount: 5000,
                            dealType: 'Inspection Fee',
                          ),
                        ),
                      );
                      
                      if (!mounted) return;

                      if (result == true) {
                        // Save booking
                        final booking = InspectionBooking(
                          id: 'BK-${DateTime.now().millisecondsSinceEpoch}',
                          property: widget.property,
                          dateTime: selectedDateTime,
                          status: BookingStatus.confirmed, // Payment confirms it
                        );
                        
                        Provider.of<BookingProvider>(context, listen: false).addBooking(booking);
                        
                        setState(() {
                          _inspectionPaid = true;
                        });

                        // Show a simple snackbar/toast for confirmation
                        _showMockNotification(
                          'Booking Confirmed!', 
                          'Agent ${widget.property.agentName} has been notified for ${booking.formattedDate} at ${booking.formattedTime}.'
                        );

                        // Route immediately to the management hub so the user can chat and track progress
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PropertyManagementScreen(
                              commitment: UnifiedCommitment.fromBooking(booking),
                              isAgent: false,
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),

              // Action 2: Direct Contact
              _buildActionTile(
                icon: LucideIcons.userCheck,
                title: 'Direct Landlord Contact',
                subtitle: 'Bypass agents and save up to 10% on agency fees.',
                price: '₦5,000',
                color: Color(0xFF6C63FF),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _simulatePaymentFlow('Contact Unlocked', 'You now have direct access to the landlord. Check your messages.', 5000, () {
                    if (!mounted) return;
                    // Success logic
                  });
                },
              ),

              // Action 3: Legal Search (Only for purchase)
              if (isBuy)
                _buildActionTile(
                  icon: LucideIcons.scale,
                  title: 'Title Legal Search',
                  subtitle: 'Avoid land scams. Get a verified property report.',
                  price: '₦15,000',
                  color: Color(0xFFF7C948),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _simulatePaymentFlow('Title Search Initiated', 'Our legal team will email the comprehensive property report within 48 hours.', 15000, () {
                      // Success logic
                    });
                  },
                ),
                
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionTile({required IconData icon, required String title, required String subtitle, required String price, required Color color, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(price, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.property;
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.8),
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.8),
                  child: Consumer<FavoritesProvider>(
                    builder: (context, favs, child) {
                      final isFav = favs.isFavorite(p.id);
                      return IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.red : theme.colorScheme.onSurface,
                        ),
                        onPressed: () {
                          favs.toggleFavorite(p);
                          // Sync with property provider for analytics demonstration
                          final currentCount = p.favoritesCount;
                          context.read<PropertyProvider>().updateFavoritesCount(
                            p.id, 
                            isFav ? currentCount - 1 : currentCount + 1
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.8),
                  child: IconButton(
                    icon: Icon(LucideIcons.share, color: theme.colorScheme.onSurface),
                    onPressed: () {},
                  ),
                ),
              ),
              Consumer2<BookingProvider, UserPreferencesProvider>(
                builder: (context, provider, userPrefs, child) {
                  final leads = provider.getBookingsForProperty(p.id);
                  if (leads.isEmpty || !userPrefs.isAgent) return const SizedBox.shrink();
                  
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => InspectionManagementScreen(property: p)));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.bellRing, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text('${leads.length}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    itemCount: p.imagesGallery.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final child = CachedNetworkImage(
                        imageUrl: p.imagesGallery[index],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (context, url, error) => Container(color: Colors.grey),
                      );
                      if (index == 0) {
                        return Hero(tag: p.id, child: child);
                      }
                      return child;
                    },
                  ),
                  // Image Counter Indicator
                  Positioned(
                    bottom: 30,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentImageIndex + 1} / ${p.imagesGallery.length}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  
                  // 360 Virtual Tour Overlay
                  if (p.priceTerm == 'buy')
                    Positioned(
                      top: 100, // Below App Bar
                      right: 16,
                      child: InkWell(
                        onTap: () {
                           Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const VirtualWalkthroughScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.scan, color: Colors.white, size: 16),
                              SizedBox(width: 8),
                              Text(
                                '360° Tour',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Block
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      p.type.name.toUpperCase(),
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (p.priceTerm == 'buy')
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.teal.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.teal, width: 0.5),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(LucideIcons.home, color: Colors.teal, size: 13),
                                          const SizedBox(width: 4),
                                          const Text(
                                            'FOR SALE',
                                            style: TextStyle(
                                              color: Colors.teal,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (p.isVerified)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.amber, width: 0.5),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.verified, color: Colors.orange, size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            'VERIFIED',
                                            style: TextStyle(
                                              color: Colors.orange[800],
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Consumer<PropertyProvider>(
                                builder: (context, provider, _) {
                                  final sp = provider.getPropertyById(widget.property.id) ?? widget.property;
                                  return Row(
                                    children: [
                                      _buildMetricBadge(LucideIcons.eye, '${sp.viewsCount}', theme),
                                      const SizedBox(width: 8),
                                      _buildMetricBadge(LucideIcons.heart, '${sp.favoritesCount}', theme),
                                      const SizedBox(width: 8),
                                      _buildMetricBadge(LucideIcons.playCircle, '${sp.videoViewsCount}', theme),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              Text(
                                p.title,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(LucideIcons.mapPin, size: 16, color: theme.colorScheme.primary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      p.locationName,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              p.formattedPrice,
                              style: TextStyle(
                                color: p.priceTerm == 'buy' ? Colors.teal : theme.colorScheme.primary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (p.priceTerm.isNotEmpty && p.priceTerm != 'buy')
                              Text(
                                'per ${p.priceTerm == 'mo' ? 'month' : p.priceTerm == 'wk' ? 'week' : p.priceTerm}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              )
                            else if (p.priceTerm == 'buy')
                              Text(
                                'Outright Purchase',
                                style: TextStyle(
                                  color: Colors.teal[700],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Quick Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildFeatureIcon(LucideIcons.bedDouble, '${p.beds} Beds', theme),
                        _buildFeatureIcon(LucideIcons.bath, '${p.baths} Baths', theme),
                        _buildFeatureIcon(LucideIcons.maximize, '1,200 sqft', theme),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Media Chips
                    if (p.hasVideo || p.has360View || p.planImageUrl != null) ...[
                      const Text(
                        'Media & Plans',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          if (p.hasVideo && p.videoUrl != null) 
                            _buildMediaChip(LucideIcons.video, 'Video Tour', Colors.red, theme, onTap: () {
                              context.read<PropertyProvider>().incrementVideoViews(p.id);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerScreen(videoUrl: p.videoUrl!)));
                            }),
                          if (p.has360View && p.panoramaUrl != null) 
                            _buildMediaChip(LucideIcons.rotate3d, '360° View', Colors.blue, theme, onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const VirtualWalkthroughScreen()));
                            }),
                          if (p.planImageUrl != null) 
                            _buildMediaChip(LucideIcons.map, 'Floor Plan', Colors.purple, theme),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Amenities Wrap
                    const Text(
                      'Amenities',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: p.amenities.map((a) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(a, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    // Overview
                    const Text(
                      'Overview',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      p.description,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                    const SizedBox(height: 32),

                     // Legal & Documents Section
                    const Text(
                      'Legal & Authenticity',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (p.legalDocuments.isEmpty)
                            _buildLegalItem(
                              LucideIcons.fileQuestion, 
                              'Standard Documentation', 
                              'Being Verified', 
                              Colors.grey,
                            )
                          else
                            ...p.legalDocuments.map((doc) => Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: _buildLegalItem(
                                doc.title.contains('Survey') ? LucideIcons.map : 
                                doc.title.contains('Deed') ? LucideIcons.fileSignature : 
                                LucideIcons.scrollText, 
                                doc.title, 
                                doc.isVerified ? 'Verified' : 'Pending',
                                doc.isVerified ? Colors.green : Colors.orange,
                              ),
                            )),
                          
                          if (p.hasLawyerVerifiedTerms) ...[
                            const Divider(height: 24),
                            _buildLegalItem(
                              LucideIcons.shieldCheck, 
                              'Lawyer Verified Terms', 
                              'AUTHENTIC', 
                              Colors.teal,
                            ),
                          ],
                          
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _showTermsModal(context, p),
                              icon: const Icon(LucideIcons.gavel, size: 16),
                              label: const Text('Read Lawyer\'s Terms & Conditions'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Agent Block (Monetization 1)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                         color: theme.colorScheme.surface,
                         borderRadius: BorderRadius.circular(16),
                         boxShadow: [
                           BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))
                         ],
                         border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Listed By', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              if (p.listerType == ListerType.realEstateCompany && p.listerLogoUrl != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: p.listerLogoUrl!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else
                                CircleAvatar(
                                  radius: 25,
                                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                                  child: Icon(LucideIcons.user, color: theme.colorScheme.primary),
                                ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _agentRevealed 
                                                ? (p.listerType == ListerType.realEstateCompany ? (p.companyName ?? p.agentName) : p.agentName) 
                                                : 'Details Hidden',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (p.listerType == ListerType.realEstateCompany)
                                          Container(
                                            margin: const EdgeInsets.only(left: 4),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                                            child: const Text('PREMIUM', style: TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold)),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _agentRevealed ? p.agentPhone : '*** *** ****',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              if (_agentRevealed)
                                IconButton(
                                  icon: const Icon(LucideIcons.phone, color: Colors.green),
                                  onPressed: () {},
                                )
                            ],
                          ),
                          if (!_agentRevealed) ...[
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Icon(LucideIcons.unlock, size: 18),
                                label: const Text('Reveal Agent (₦100)'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  foregroundColor: theme.colorScheme.primary,
                                  side: BorderSide(color: theme.colorScheme.primary),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {
                                  _simulatePaymentFlow('Agent Unlock', 'Agent contact details are now visible.', 100, () {
                                    setState(() {
                                      _agentRevealed = true;
                                    });
                                  });
                                },
                              ),
                            )
                          ]
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildDueDiligenceVault(p, theme),
                    // ── HOW TO OWN: only for 'buy' listings ─────────────────
                    if (p.priceTerm == 'buy') ...[
                      const SizedBox(height: 32),
                      HomeOwnershipOptionsWidget(
                        property: p,
                        onSimulatePayment: _simulatePaymentFlow,
                      ),
                    ],
                    const SizedBox(height: 24),

                    // 3D Map & Sharing Block (Monetization 2)
                    Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(top: 24),
                      decoration: BoxDecoration(
                         color: theme.colorScheme.surface,
                         borderRadius: BorderRadius.circular(16),
                         boxShadow: [
                           BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))
                         ],
                         border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Live 3D Map & Transport', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 16),
                          if (!_inspectionPaid) ...[
                            Container(
                              height: 120,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                                // Using a placeholder static map to signify hidden precise location
                                image: const DecorationImage(
                                  image: CachedNetworkImageProvider('https://maps.googleapis.com/maps/api/staticmap?center=9.0,7.0&zoom=10&size=600x300&maptype=roadmap'),
                                  fit: BoxFit.cover,
                                  colorFilter: ColorFilter.mode(Colors.grey, BlendMode.saturation),
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
                                  child: const Text('Exact Map unlocked after booking', style: TextStyle(color: Colors.white, fontSize: 12)),
                                ),
                              ),
                            ),
                          ] else ...[
                            // Unlocked state
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Icon(LucideIcons.map, size: 18),
                                label: const Text('Open in Google Maps (3D)'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  foregroundColor: Colors.blue[700],
                                  side: BorderSide(color: Colors.blue[700]!),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {
                                  _openLocationInGoogleMaps(p.location.latitude, p.location.longitude);
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(LucideIcons.share2, size: 18),
                                label: const Text('Share to Uber, Bolt, WhatsApp...'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {
                                  SharePlus.instance.share(ShareParams(text: 'Check out this property location for our scheduled inspection on Swift Space: https://www.google.com/maps/search/?api=1&query=${p.location.latitude},${p.location.longitude}'));
                                },
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                    const SizedBox(height: 120), // padding for bottom bar
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
             // Contact / Message stub button
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(16)
              ),
              child: IconButton(
                icon: const Icon(LucideIcons.messageSquare),
                onPressed: () {
                  final chatProvider = Provider.of<ChatProvider>(context, listen: false);
                  chatProvider.createRoom(
                    widget.property.id,
                    widget.property.title,
                    widget.property.imagesGallery.isNotEmpty ? widget.property.imagesGallery.first : widget.property.imageUrl,
                    widget.property.agentName,
                  );
                  final room = chatProvider.getRoomByProperty(widget.property.id);
                  if (room != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatDetailScreen(roomId: room.id),
                      ),
                    );
                  }
                },
              )
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _inspectionPaid
                  ? ElevatedButton.icon(
                      onPressed: () {
                         final bookings = Provider.of<BookingProvider>(context, listen: false).getBookingsForProperty(widget.property.id);
                         if (bookings.isNotEmpty) {
                           Navigator.push(
                             context,
                             MaterialPageRoute(
                               builder: (_) => PropertyManagementScreen(
                                 commitment: UnifiedCommitment.fromBooking(bookings.first),
                                 isAgent: false,
                               ),
                             ),
                           );
                         }
                      },
                      icon: const Icon(LucideIcons.arrowRightCircle, size: 18),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      label: const Text('Manage Inspection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    )
                  : ElevatedButton.icon(
                      onPressed: _showPremiumActions,
                      icon: const Icon(LucideIcons.zap, size: 18),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      label: const Text('Take Action', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(anim),
                  child: child,
                ),
              ),
              child: Container(
                key: ValueKey(_currentTooltipIndex),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _tooltipPhrases[_currentTooltipIndex],
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            FloatingActionButton(
              heroTag: 'map_fab_${p.id}',
              onPressed: () {
                final pPrefs = Provider.of<UserPreferencesProvider>(context, listen: false);
                pPrefs.setMapFocusProperty(p.id);
                pPrefs.setTabIndex(0); // Go to Explore
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              child: const Icon(LucideIcons.map),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalItem(IconData icon, String title, String status, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
          child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildDueDiligenceVault(Property p, ThemeData theme) {
    String vaultModeText = 'Unverified property. Documents not available.';
    Color vaultColor = Colors.grey;
    IconData vaultIcon = LucideIcons.shieldAlert;

    if (p.verificationStatus == PropertyVerificationStatus.verified) {
      vaultModeText = '100% Verified. All legal documents are authenticated.';
      vaultColor = Colors.green;
      vaultIcon = LucideIcons.shieldCheck;
    } else if (p.verificationStatus == PropertyVerificationStatus.pendingReview) {
      vaultModeText = 'Documents under review by Admin.';
      vaultColor = Colors.orange;
      vaultIcon = LucideIcons.clock;
    } else if (p.verificationStatus == PropertyVerificationStatus.issuesFlagged) {
      vaultModeText = 'Discrepancies found during verification.';
      vaultColor = Colors.red;
      vaultIcon = LucideIcons.alertTriangle;
    } else if (p.verificationStatus == PropertyVerificationStatus.fraudBlocked) {
      vaultModeText = 'Caution: Action paused on this property.';
      vaultColor = Colors.black;
      vaultIcon = LucideIcons.ban;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))
        ],
        border: Border.all(color: vaultColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.fileKey2, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Due Diligence Vault', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: vaultColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: vaultColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(vaultIcon, color: vaultColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    vaultModeText,
                    style: TextStyle(color: vaultColor, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (p.legalDocuments.isNotEmpty) ...[
            const Text('Documents:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            ...p.legalDocuments.map((doc) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildLegalItem(LucideIcons.fileText, doc.title, doc.status.name.toUpperCase(), doc.status == LegalDocumentStatus.verified ? Colors.green : (doc.status == LegalDocumentStatus.rejected ? Colors.red : Colors.grey)),
            )),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(LucideIcons.messageSquare, size: 18),
              label: const Text('Request Clarification'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final chatProvider = Provider.of<ChatProvider>(context, listen: false);
                chatProvider.createRoom(
                  p.id,
                  p.title,
                  p.imagesGallery.isNotEmpty ? p.imagesGallery.first : p.imageUrl,
                  p.agentName,
                );
                final room = chatProvider.getRoomByProperty(p.id);
                if (room != null) {
                  // Can Optionally add a message to chat room here
                  chatProvider.sendMessage(
                    room.id, 
                    "Hi, I'd like to request clarity on some legal documents for this property.", 
                    'user'
                  );
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatDetailScreen(roomId: room.id),
                    ),
                  );
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message attached. Proceeding to chat...'))
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showTermsModal(BuildContext context, Property p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                   Container(
                     padding: const EdgeInsets.all(10),
                     decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                     child: const Icon(LucideIcons.gavel, color: Colors.teal, size: 24),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         const Text('Terms & Conditions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                         Text('Property: ${p.title}', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                       ],
                     ),
                   ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.info, color: Colors.blue, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'These terms were provided by the agent\'s legal representative and verified by SwiftSpace.',
                              style: TextStyle(color: Colors.blue[900], fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      p.termsAndConditions ?? 'Standard rental and purchase terms apply. Please contact the agent for detailed legal documentation.',
                      style: const TextStyle(fontSize: 15, height: 1.7, letterSpacing: 0.2),
                    ),
                    const SizedBox(height: 40),
                    Container(
                       padding: const EdgeInsets.all(20),
                       decoration: BoxDecoration(
                         gradient: LinearGradient(colors: [Colors.teal[700]!, Colors.teal[900]!], begin: Alignment.topLeft, end: Alignment.bottomRight),
                         borderRadius: BorderRadius.circular(16),
                       ),
                       child: const Row(
                         children: [
                           Icon(LucideIcons.shieldCheck, color: Colors.white, size: 32),
                           SizedBox(width: 16),
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text('Authenticity Guaranteed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                 SizedBox(height: 4),
                                 Text('SwiftSpace verifies that this document matches the property title.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                               ],
                             ),
                           ),
                         ],
                       ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('I Understand', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureIcon(IconData icon, String label, ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildMediaChip(IconData icon, String label, Color color, ThemeData theme, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ╔══════════════════════════════════════════════════════════════╗
// ║  HOW TO OWN THIS HOME — Nigerian Homeownership Pathways     ║
// ╚══════════════════════════════════════════════════════════════╝
class HomeOwnershipOptionsWidget extends StatefulWidget {
  final Property property;
  final void Function(String, String, int, VoidCallback)? onSimulatePayment;
  const HomeOwnershipOptionsWidget({super.key, required this.property, this.onSimulatePayment});

  @override
  State<HomeOwnershipOptionsWidget> createState() =>
      _HomeOwnershipOptionsWidgetState();
}

class _HomeOwnershipOptionsWidgetState
    extends State<HomeOwnershipOptionsWidget> {
  int _selected = -1; // expanded card index

  static final List<_OwnershipOption> _options = [
    _OwnershipOption(
      icon: LucideIcons.building2,
      color: Color(0xFF1EB476),
      label: 'NHF Mortgage',
      badge: 'Govt. Backed',
      badgeColor: Color(0xFF1EB476),
      headline: 'National Housing Fund',
      summary:
          'Contribute monthly via your employer. After 6 months you qualify for a low-interest Federal Mortgage Bank loan.',
      steps: [
        '1. Register with Federal Mortgage Bank of Nigeria (FMBN)',
        '2. Contribute 2.5% of monthly salary through employer',
        '3. Apply after 6 months of contributions',
        '4. Enjoy up to ₦15M loan at 6% interest for 30 years',
      ],
      cta: 'Check Eligibility',
      ctaUrl: 'https://fmbn.gov.ng',
    ),
    _OwnershipOption(
      icon: LucideIcons.refreshCw,
      color: Color(0xFF6C63FF),
      label: 'Rent-to-Own',
      badge: 'No Upfront',
      badgeColor: Color(0xFF6C63FF),
      headline: 'Rent Today, Own Tomorrow',
      summary:
          'Pay monthly as if renting. A portion goes toward your equity. Own fully after the agreed term — no huge deposit needed.',
      steps: [
        '1. Agree rent-to-own price and term with seller/agent',
        '2. Pay monthly installments (includes equity portion)',
        '3. Optional lump-sum top-up to change term',
        '4. Transfer of title upon full payment',
      ],
      cta: 'Request Rent-to-Own',
      ctaUrl: null,
    ),
    _OwnershipOption(
      icon: LucideIcons.calendarDays,
      color: Color(0xFFFF7043),
      label: 'Installment Plan',
      badge: 'Flexible',
      badgeColor: Color(0xFFFF7043),
      headline: 'Pay in Tranches',
      summary:
          'Negotiate a staged payment plan directly with the developer or seller — no bank required. Common for off-plan or estate properties.',
      steps: [
        '1. Pay initial deposit (typically 30%)',
        '2. Balance spread over 6, 12, 24 or 36 months',
        '3. Title document released on final payment',
        '4. Possession often granted on 50% payment',
      ],
      cta: 'Explore Installment',
      ctaUrl: null,
    ),
    _OwnershipOption(
      icon: LucideIcons.users,
      color: Color(0xFF00B0FF),
      label: 'Cooperative Housing',
      badge: 'Group Power',
      badgeColor: Color(0xFF00B0FF),
      headline: 'Buy Through a Co-op',
      summary:
          'Join or form a housing cooperative. Pool resources with colleagues or community members to unlock bulk-purchase pricing.',
      steps: [
        '1. Join a registered cooperative society (workplace or community)',
        '2. Contribute to the cooperative fund',
        '3. Ballot or queue for property allocation',
        '4. Repay your share at subsidised cooperative rates',
      ],
      cta: 'Find a Co-op',
      ctaUrl: null,
    ),
    _OwnershipOption(
      icon: LucideIcons.smartphone,
      color: Color(0xFFF7C948),
      label: 'Digital Mortgage',
      badge: 'Fintech',
      badgeColor: Color(0xFFF7C948),
      headline: 'Mobile-First Home Loans',
      summary:
          'Platforms like LagosHoms, Bricks Capital, and Coreum offer fast digital mortgage applications processed in days, not months.',
      steps: [
        '1. Apply on app — no physical visit needed',
        '2. Upload ID, payslips, and bank statements',
        '3. AI-powered credit scoring for faster decision',
        '4. Disbursement directly to seller within 7–14 days',
      ],
      cta: 'Apply Digitally',
      ctaUrl: 'https://brickscapital.ng',
    ),
    _OwnershipOption(
      icon: Icons.handshake_outlined,
      color: Color(0xFFEC407A),
      label: 'Diaspora Mortgage',
      badge: 'For Abroad',
      badgeColor: Color(0xFFEC407A),
      headline: 'Own From Anywhere',
      summary:
          'Living abroad? FMBN and several banks offer diaspora mortgage products — apply in foreign currency and repay from overseas accounts.',
      steps: [
        '1. Open a non-resident NHF/diaspora account',
        '2. Fund account in USD, GBP, or EUR',
        '3. Engage a local legal representative for paperwork',
        '4. Property managed by trusted agent until return',
      ],
      cta: 'Diaspora Info',
      ctaUrl: 'https://fmbn.gov.ng',
    ),
  ];

  static final List<_OwnershipOption> _rentOptions = [
    _OwnershipOption(
      icon: LucideIcons.wallet,
      color: Color(0xFF1EB476),
      label: 'Monthly Rent',
      badge: 'Pay As You Go',
      badgeColor: Color(0xFF1EB476),
      headline: 'Monthly Rental Payment',
      summary:
          'Ditch the annual bulk payment. Pay for your rent monthly like a subscription through Swift Space partnered landlords.',
      steps: [
        '1. Complete identity and income verification',
        '2. Pay first month\'s rent and security deposit',
        '3. Move in immediately',
        '4. Set up auto-debit for subsequent months',
      ],
      cta: 'Apply for Monthly Rent',
      ctaUrl: null,
    ),
    _OwnershipOption(
      icon: LucideIcons.users,
      color: Color(0xFF6C63FF),
      label: 'Co-Living',
      badge: 'Shared',
      badgeColor: Color(0xFF6C63FF),
      headline: 'Split the Bills',
      summary:
          'Find verified roommates to share the cost of this property. Swift Space matches you with compatible housemates.',
      steps: [
        '1. Opt-in for co-living matching',
        '2. Review roommate profiles and chat',
        '3. Sign a split-lease agreement',
        '4. Move in together and share expenses',
      ],
      cta: 'Find Roommates',
      ctaUrl: null,
    ),
    _OwnershipOption(
      icon: LucideIcons.repeat,
      color: Color(0xFFFF7043),
      label: 'Lease Financing',
      badge: 'Loans',
      badgeColor: Color(0xFFFF7043),
      headline: 'Rent Now, Pay Later',
      summary:
          'Need help with the annual rent? Our fintech partners can pay your landlord upfront while you repay them monthly.',
      steps: [
        '1. Apply for Rent-Now-Pay-Later',
        '2. Get approval within 24 hours',
        '3. Partner pays your landlord in full',
        '4. Repay partner over 12 months with minimal interest',
      ],
      cta: 'Check Eligibility',
      ctaUrl: 'https://www.kwaba.ng/', // Example fintech
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final bool isBuy = widget.property.priceTerm == 'buy';
    final List<_OwnershipOption> currentOptions = isBuy ? _options : _rentOptions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1EB476), Color(0xFF0F5A3F)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.key, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isBuy ? 'How to Own This Home' : 'How to Rent This Home',
                    style:
                        const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Pick the pathway that fits your pocket',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Monthly estimate chip
        if (isBuy) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1EB476).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF1EB476).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.calculator,
                    size: 14, color: Color(0xFF1EB476)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Est. monthly payment: ${_formatMonthly(widget.property.price)} /mo (25yr, 8%)',
                    style: const TextStyle(
                      color: Color(0xFF1EB476),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Option cards
        ...List.generate(currentOptions.length, (i) {
          final opt = currentOptions[i];
          final isExpanded = _selected == i;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: isExpanded
                  ? opt.color.withValues(alpha: isDark ? 0.12 : 0.06)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isExpanded
                    ? opt.color.withValues(alpha: 0.5)
                    : theme.dividerColor.withValues(alpha: 0.15),
                width: isExpanded ? 1.5 : 1,
              ),
              boxShadow: isExpanded
                  ? [
                      BoxShadow(
                        color: opt.color.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () =>
                    setState(() => _selected = isExpanded ? -1 : i),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: opt.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(opt.icon, color: opt.color, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      opt.label,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: isExpanded ? opt.color : null,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: opt.badgeColor
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        opt.badge,
                                        style: TextStyle(
                                          color: opt.badgeColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  opt.headline,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 250),
                            child: Icon(
                              LucideIcons.chevronDown,
                              color: isExpanded ? opt.color : Colors.grey,
                              size: 18,
                            ),
                          ),
                        ],
                      ),

                      // Expanded detail
                      if (isExpanded) ...[
                        const SizedBox(height: 14),
                        Divider(
                            color: opt.color.withValues(alpha: 0.2), height: 1),
                        const SizedBox(height: 14),
                        Text(
                          opt.summary,
                          style: const TextStyle(
                            fontSize: 13.5,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Steps
                        ...opt.steps.map((step) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.only(
                                        top: 5, right: 8),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: opt.color,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      step,
                                      style: const TextStyle(
                                          fontSize: 13, height: 1.4),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (opt.ctaUrl != null) {
                                launchUrl(Uri.parse(opt.ctaUrl!),
                                    mode: LaunchMode.externalApplication);
                              } else {
                                if (widget.onSimulatePayment != null) {
                                  widget.onSimulatePayment!(
                                    '${opt.label} Application',
                                    'Your application fee was paid successfully. An agent will contact you shortly.',
                                    1500, // Monetization logic filter fee
                                    () {},
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          '${opt.label} request sent to agent!'),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: opt.color,
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: opt.color,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              opt.cta,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }


  String _formatMonthly(double price) {
    // Simple EMI estimate: P * r*(1+r)^n / ((1+r)^n - 1)  at 8% p.a. / 25 yr
    const double rMonthly = 0.08 / 12;
    final int n = 25 * 12;
    final emi = price * rMonthly * (1 + rMonthly * n) / (rMonthly * n);
    if (emi >= 1000000) {
      return '₦${(emi / 1000000).toStringAsFixed(1)}M';
    }
    return '₦${(emi / 1000).toStringAsFixed(0)}k';
  }
}

class _OwnershipOption {
  final IconData icon;
  final Color color;
  final String label;
  final String badge;
  final Color badgeColor;
  final String headline;
  final String summary;
  final List<String> steps;
  final String cta;
  final String? ctaUrl;

  const _OwnershipOption({
    required this.icon,
    required this.color,
    required this.label,
    required this.badge,
    required this.badgeColor,
    required this.headline,
    required this.summary,
    required this.steps,
    required this.cta,
    required this.ctaUrl,
  });
}

