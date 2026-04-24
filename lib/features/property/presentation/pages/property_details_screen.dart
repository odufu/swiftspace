import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:swiftspace/features/property/domain/entities/property.dart';
import 'package:swiftspace/features/explore/presentation/state/favorites_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:swiftspace/features/media_ai/presentation/pages/video_player_screen.dart';
import 'package:swiftspace/features/media_ai/presentation/pages/virtual_walkthrough_screen.dart';
import 'package:swiftspace/features/auth/presentation/state/user_preferences_provider.dart';
import 'package:swiftspace/features/booking/presentation/state/booking_provider.dart';
import 'package:swiftspace/features/chat/presentation/state/chat_provider.dart';
import 'package:swiftspace/features/property/presentation/state/property_provider.dart';
import 'package:swiftspace/features/booking/domain/entities/booking.dart';
import 'package:swiftspace/shared/widgets/inspection_date_picker.dart';
import 'package:swiftspace/features/chat/presentation/pages/chat_detail_screen.dart';
import 'package:swiftspace/features/booking/presentation/pages/inspection_management_screen.dart';
import 'package:swiftspace/features/booking/presentation/pages/property_management_screen.dart';
import 'package:swiftspace/features/booking/domain/entities/commitment.dart';

import 'package:swiftspace/core/constants/app_constants.dart';
import 'dart:async';
import 'package:swiftspace/core/utils/responsive.dart';

class PropertyDetailsScreen extends StatefulWidget {
  final Property property;

  const PropertyDetailsScreen({super.key, required this.property});

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
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

  late bool _isUnlocked;

  @override
  void initState() {
    super.initState();
    _isUnlocked = !widget.property.isPremium;
    _tooltipTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _currentTooltipIndex =
              (_currentTooltipIndex + 1) % _tooltipPhrases.length;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PropertyProvider>().incrementViews(widget.property.id);
      }
    });
  }

  @override
  void dispose() {
    _tooltipTimer.cancel();
    super.dispose();
  }



  Future<void> _openLocationInGoogleMaps(double lat, double lng) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _showToast(String title, String body, {bool isSuccess = true}) {
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
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isSuccess
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.amber.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isSuccess ? Colors.green : Colors.amber)
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess ? LucideIcons.checkCircle : LucideIcons.bell,
                  color: isSuccess ? Colors.green : Colors.amber[700],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(body,
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _bookInspection(BuildContext context) async {
    // Capture context-dependent references before the async gap
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final navigator = Navigator.of(context);

    final selectedDateTime = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InspectionDatePicker(property: widget.property),
    );

    if (selectedDateTime != null && mounted) {
      final booking = InspectionBooking(
        id: 'BK-${DateTime.now().millisecondsSinceEpoch}',
        property: widget.property,
        dateTime: selectedDateTime,
        status: BookingStatus.confirmed,
      );

      bookingProvider.addBooking(booking);
      _showToast(
        'Inspection Booked!',
        'Agent ${widget.property.agentName} has been notified.',
      );

      navigator.push(
        MaterialPageRoute(
          builder: (_) => PropertyManagementScreen(
            commitment: UnifiedCommitment.fromBooking(booking),
            isAgent: false,
          ),
        ),
      );
    }
  }


  void _showUnlockPaywall() {
    final theme = Theme.of(context);
    final p = widget.property;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        int selectedMethod = 0; // 0=Card, 1=Transfer, 2=USSD
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
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

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFB300), Color(0xFFF57C00)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(LucideIcons.lock,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Unlock Full Access',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              p.title,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // What you unlock
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You\'ll instantly unlock:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: theme.colorScheme.primary),
                        ),
                        const SizedBox(height: 12),
                        ...[
                          (LucideIcons.mapPin, 'Exact address & Google Maps link'),
                          (LucideIcons.phone, 'Direct agent phone & WhatsApp'),
                          (LucideIcons.fileKey2, 'Legal documents & Due Diligence Vault'),
                          (LucideIcons.calendar, 'Book a physical inspection'),
                        ].map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Icon(item.$1,
                                    size: 16,
                                    color: theme.colorScheme.primary),
                                const SizedBox(width: 10),
                                Text(item.$2,
                                    style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Deposit amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Commitment Deposit',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('100% refundable if no deal is made',
                              style: TextStyle(
                                  color: Colors.green[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const Text(
                        '₦5,000',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF57C00)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Payment method selector
                  const Text('Pay with',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildPaymentChip(0, 'Card', LucideIcons.creditCard,
                          selectedMethod, (v) {
                        setModalState(() => selectedMethod = v);
                      }),
                      const SizedBox(width: 10),
                      _buildPaymentChip(1, 'Bank Transfer', LucideIcons.building,
                          selectedMethod, (v) {
                        setModalState(() => selectedMethod = v);
                      }),
                      const SizedBox(width: 10),
                      _buildPaymentChip(
                          2, 'USSD', LucideIcons.smartphone, selectedMethod,
                          (v) {
                        setModalState(() => selectedMethod = v);
                      }),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Pay button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        setState(() => _isUnlocked = true);
                        _showToast(
                          'ðŸ”“ Access Unlocked!',
                          'Deposit received. You now have full access to this listing.',
                        );
                      },
                      icon: const Icon(LucideIcons.shieldCheck, size: 20),
                      label: const Text(
                        'Pay â‚¦5,000 â€” Unlock Now',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF57C00),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      'Secured by SwiftSpace Â· 256-bit encrypted',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
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

  Widget _buildPaymentChip(int value, String label, IconData icon,
      int selected, ValueChanged<int> onSelect) {
    final isSelected = value == selected;
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 18,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.grey[600]),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.property;
    final isMobile = Responsive.isMobile(context);

    if (!isMobile) {
      return _buildDesktopLayout(context, theme, p);
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: theme.colorScheme.surface.withValues(
                  alpha: 0.8,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: theme.colorScheme.onSurface,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: theme.colorScheme.surface.withValues(
                    alpha: 0.8,
                  ),
                  child: Consumer<FavoritesProvider>(
                    builder: (context, favs, child) {
                      final isFav = favs.isFavorite(p.id);
                      return IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav
                              ? Colors.red
                              : theme.colorScheme.onSurface,
                        ),
                        onPressed: () {
                          favs.toggleFavorite(p);
                          // Sync with property provider for analytics demonstration
                          final currentCount = p.favoritesCount;
                          context.read<PropertyProvider>().updateFavoritesCount(
                            p.id,
                            isFav ? currentCount - 1 : currentCount + 1,
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
                  backgroundColor: theme.colorScheme.surface.withValues(
                    alpha: 0.8,
                  ),
                  child: IconButton(
                    icon: Icon(
                      LucideIcons.share,
                      color: theme.colorScheme.onSurface,
                    ),
                    onPressed: () {},
                  ),
                ),
              ),
              Consumer2<BookingProvider, UserPreferencesProvider>(
                builder: (context, provider, userPrefs, child) {
                  final leads = provider.getBookingsForProperty(p.id);
                  if (leads.isEmpty || !userPrefs.isAgent) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                InspectionManagementScreen(property: p),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.bellRing,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${leads.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            Container(color: Colors.grey),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentImageIndex + 1} / ${p.imagesGallery.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Media Controls Overlay (Video & 360 Tour)
                  Positioned(
                    bottom: 72, // above the image counter
                    left: 16,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (p.hasVideo && p.videoUrl != null)
                          GestureDetector(
                            onTap: () {
                              context
                                  .read<PropertyProvider>()
                                  .incrementVideoViews(p.id);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      VideoPlayerScreen(videoUrl: p.videoUrl!),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.play,
                                      color: Colors.white, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    'Watch Video',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (p.has360View) ...[
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      VirtualWalkthroughScreen(property: p),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.3)),
                              ),
                              child: const Icon(LucideIcons.scan,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ],
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // â”€â”€ TIER 1: FREE â€” Property Identity â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    // Badges row
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildBadge(
                          p.type.name.toUpperCase(),
                          theme.colorScheme.primary.withValues(alpha: 0.12),
                          theme.colorScheme.primary,
                        ),
                        if (p.priceTerm == 'buy')
                          _buildBadge(
                            'FOR SALE',
                            Colors.teal.withValues(alpha: 0.12),
                            Colors.teal,
                            icon: LucideIcons.home,
                          ),
                        if (p.isPremium)
                          _buildBadge(
                            'PREMIUM',
                            Colors.amber.withValues(alpha: 0.15),
                            Colors.orange[800]!,
                            icon: LucideIcons.star,
                          )
                        else if (p.isVerified)
                          _buildBadge(
                            'VERIFIED',
                            Colors.green.withValues(alpha: 0.12),
                            Colors.green[700]!,
                            icon: Icons.verified,
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Title + Price row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            p.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              p.formattedPrice,
                              style: TextStyle(
                                color: p.priceTerm == 'buy'
                                    ? Colors.teal
                                    : theme.colorScheme.primary,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (p.priceTerm.isNotEmpty && p.priceTerm != 'buy')
                              Text(
                                'per ${p.priceTerm == 'mo' ? 'month' : p.priceTerm == 'wk' ? 'week' : p.priceTerm}',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 12),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Location row (blurred if locked)
                    Row(
                      children: [
                        Icon(LucideIcons.mapPin,
                            size: 15,
                            color: _isUnlocked
                                ? theme.colorScheme.primary
                                : Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _isUnlocked
                                ? p.locationName
                                : 'Location hidden â€” unlock to reveal',
                            style: TextStyle(
                              color: _isUnlocked
                                  ? Colors.grey[600]
                                  : Colors.grey[400],
                              fontSize: 13,
                              fontStyle: _isUnlocked
                                  ? FontStyle.normal
                                  : FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Key Stats card
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: theme.dividerColor.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                              LucideIcons.bedDouble, '${p.beds}', 'Beds', theme),
                          _buildDividerLine(),
                          _buildStatItem(
                              LucideIcons.bath, '${p.baths}', 'Baths', theme),
                          _buildDividerLine(),
                          _buildStatItem(
                              LucideIcons.maximize,
                              p.totalSquareFootage != null
                                  ? p.totalSquareFootage!.toStringAsFixed(0)
                                  : 'N/A',
                              'sqft',
                              theme),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Description
                    const Text('About this Property',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      p.description,
                      style: const TextStyle(
                          fontSize: 14, height: 1.6, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    // Amenities
                    const Text('Amenities',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: p.amenities.map((a) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color:
                                    theme.dividerColor.withValues(alpha: 0.2)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(a,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w500)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Lister Preview (free â€” name + avatar only)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: theme.dividerColor.withValues(alpha: 0.12)),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor:
                                theme.colorScheme.primary.withValues(alpha: 0.12),
                            child: Icon(LucideIcons.user,
                                color: theme.colorScheme.primary),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.agentName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                                Text(
                                  _isUnlocked ? 'Listed Agent' : 'Contact hidden â€” unlock to call',
                                  style: TextStyle(
                                      color: Colors.grey[500], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          if (_isUnlocked)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildContactIcon(
                                    LucideIcons.phone, Colors.green, () {}),
                                const SizedBox(width: 8),
                                _buildContactIcon(
                                    LucideIcons.messageCircle, Colors.teal,
                                    () {
                                  final chatProvider =
                                      Provider.of<ChatProvider>(context,
                                          listen: false);
                                  chatProvider.createRoom(
                                      p.id,
                                      p.title,
                                      p.imagesGallery.isNotEmpty
                                          ? p.imagesGallery.first
                                          : p.imageUrl,
                                      p.agentName);
                                  final room =
                                      chatProvider.getRoomByProperty(p.id);
                                  if (room != null) {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                ChatDetailScreen(roomId: room.id)));
                                  }
                                }),
                              ],
                            )
                          else
                            GestureDetector(
                              onTap: _showUnlockPaywall,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.amber.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(LucideIcons.lock,
                                    color: Colors.amber, size: 18),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // â”€â”€ TIER 2: PREMIUM GATE CARD (locked) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    if (p.isPremium && !_isUnlocked) ...[
                      Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Background glow
                            Positioned(
                              top: -30,
                              right: -30,
                              child: Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFF57C00)
                                      .withValues(alpha: 0.15),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(22),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF57C00)
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(LucideIcons.lock,
                                            color: Color(0xFFF57C00),
                                            size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Premium Access Required',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            Text(
                                              'Refundable commitment deposit',
                                              style: TextStyle(
                                                  color: Color(0xFFFFB74D),
                                                  fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  // What's locked
                                  ...[
                                    (LucideIcons.mapPin,
                                        'Exact address & neighbourhood map'),
                                    (LucideIcons.phone,
                                        'Direct agent phone & WhatsApp'),
                                    (LucideIcons.fileKey2,
                                        'Legal documents & Due Diligence Vault'),
                                    (LucideIcons.calendar,
                                        'Book a physical inspection'),
                                  ].map(
                                    (item) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: Row(
                                        children: [
                                          Icon(item.$1,
                                              size: 15,
                                              color: const Color(0xFFF57C00)),
                                          const SizedBox(width: 10),
                                          Text(item.$2,
                                              style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _showUnlockPaywall,
                                      icon: const Icon(LucideIcons.shieldCheck,
                                          size: 18),
                                      label: const Text(
                                        'Unlock Full Access â€” â‚¦5,000',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFF57C00),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Center(
                                    child: Text(
                                      '100% refundable if no deal is made',
                                      style: TextStyle(
                                          color: Color(0xFF81C784),
                                          fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // â”€â”€ TIER 3: UNLOCKED CONTENT â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    if (_isUnlocked) ...[
                      // Exact Location + Maps
                      _buildSectionHeader(LucideIcons.mapPin, 'Location'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(LucideIcons.mapPin,
                                    color: Colors.blue, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    p.locationName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon:
                                    const Icon(LucideIcons.map, size: 16),
                                label: const Text('Open in Google Maps'),
                                onPressed: () => _openLocationInGoogleMaps(
                                  p.location.latitude,
                                  p.location.longitude,
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue[700],
                                  side:
                                      BorderSide(color: Colors.blue[300]!),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Structure & Vital Signs
                      _buildSectionHeader(
                          LucideIcons.activity, 'Structure & Vital Signs'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: theme.dividerColor
                                  .withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow(LucideIcons.calendar,
                                'Year Built', p.yearBuilt?.toString() ?? 'N/A'),
                            _buildDetailRow(LucideIcons.construction,
                                'Foundation', p.foundationType ?? 'Standard'),
                            _buildDetailRow(
                              LucideIcons.waves,
                              'Flooding History',
                              p.floodingHistory
                                  ? 'History Flagged'
                                  : 'None Reported',
                              valueColor: p.floodingHistory
                                  ? Colors.red
                                  : Colors.green,
                            ),
                            const Divider(height: 24),
                            _buildDetailRow(LucideIcons.zap, 'Avg. Electricity',
                                '${p.electricitySupplyHours.toInt()} hrs/day'),
                            _buildDetailRow(LucideIcons.map, 'Road Distance',
                                '${p.proximityToRoadMeters} meters'),
                            _buildDetailRow(LucideIcons.activity,
                                'Nearest Hospital',
                                '${p.proximityToHospitalKm.toStringAsFixed(1)} km'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Due Diligence Vault
                      _buildDueDiligenceVault(p, theme),
                      const SizedBox(height: 28),

                      // Legal & Authenticity
                      _buildSectionHeader(
                          LucideIcons.shieldCheck, 'Legal & Authenticity'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.08)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (p.legalDocuments.isEmpty &&
                                !p.hasCertificateOfOccupancy &&
                                !p.hasSurveyPlan)
                              _buildLegalItem(
                                LucideIcons.fileQuestion,
                                'Standard Documentation',
                                'Being Verified',
                                Colors.grey,
                              )
                            else ...[
                              if (p.hasCertificateOfOccupancy)
                                _buildLegalItem(LucideIcons.scrollText,
                                    'Cert. of Occupancy', 'AVAILABLE',
                                    Colors.green),
                              if (p.hasGovernorsConsent)
                                _buildLegalItem(LucideIcons.fileCheck,
                                    "Governor's Consent", 'AVAILABLE',
                                    Colors.green),
                              if (p.hasSurveyPlan)
                                _buildLegalItem(LucideIcons.map, 'Survey Plan',
                                    'AVAILABLE', Colors.green),
                              if (p.hasBuildingPlanApproval)
                                _buildLegalItem(LucideIcons.building,
                                    'Building Approval', 'AVAILABLE',
                                    Colors.green),
                              ...p.legalDocuments.map(
                                (doc) => Padding(
                                  padding:
                                      const EdgeInsets.only(top: 8.0),
                                  child: _buildLegalItem(
                                    doc.title.contains('Survey')
                                        ? LucideIcons.map
                                        : doc.title.contains('Deed')
                                            ? LucideIcons.fileSignature
                                            : LucideIcons.scrollText,
                                    doc.title,
                                    doc.isVerified ? 'Verified' : 'Pending',
                                    doc.isVerified
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                            if (p.hasLawyerVerifiedTerms) ...[
                              const Divider(height: 20),
                              _buildLegalItem(
                                  LucideIcons.shieldCheck,
                                  'Lawyer Verified Terms',
                                  'AUTHENTIC',
                                  Colors.teal),
                            ],
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _showTermsModal(context, p),
                                icon: const Icon(LucideIcons.gavel, size: 15),
                                label: const Text(
                                    "Read Lawyer's Terms & Conditions"),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // How to Own (buy listings only)
                      if (p.priceTerm == 'buy') ...[
                        HomeOwnershipOptionsWidget(property: p),
                        const SizedBox(height: 24),
                      ],
                    ],

                    const SizedBox(height: 100), // space for bottom bar
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: _isUnlocked
              ? Row(
                  children: [
                    // Message agent
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            color:
                                theme.dividerColor.withValues(alpha: 0.2)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: IconButton(
                        icon: const Icon(LucideIcons.messageSquare),
                        onPressed: () {
                          final chatProvider = Provider.of<ChatProvider>(
                              context,
                              listen: false);
                          chatProvider.createRoom(
                              p.id,
                              p.title,
                              p.imagesGallery.isNotEmpty
                                  ? p.imagesGallery.first
                                  : p.imageUrl,
                              p.agentName);
                          final room =
                              chatProvider.getRoomByProperty(p.id);
                          if (room != null) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => ChatDetailScreen(
                                        roomId: room.id)));
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final bookings =
                              Provider.of<BookingProvider>(context,
                                      listen: false)
                                  .getBookingsForProperty(p.id);
                          if (bookings.isNotEmpty) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => PropertyManagementScreen(
                                        commitment:
                                            UnifiedCommitment.fromBooking(
                                                bookings.first),
                                        isAgent: false)));
                          } else {
                            _bookInspection(context);
                          }
                        },
                        icon: const Icon(LucideIcons.calendar, size: 18),
                        label: const Text('Book Inspection',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                )
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showUnlockPaywall,
                    icon: const Icon(LucideIcons.lock, size: 18),
                    label: const Text(
                      'Unlock Premium Access â€” â‚¦5,000',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF57C00),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
        ),
      ),
    );
  }



  // ─── New helper widgets ─────────────────────────────────────────────────

  Widget _buildBadge(String label, Color bg, Color fg,
      {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                  color: fg, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      IconData icon, String value, String label, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 20),
        const SizedBox(height: 6),
        Text(value,
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label,
            style: TextStyle(color: Colors.grey[500], fontSize: 11)),
      ],
    );
  }

  Widget _buildDividerLine() {
    return Container(width: 1, height: 40, color: Colors.grey.withValues(alpha: 0.2));
  }

  Widget _buildContactIcon(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(title,
            style:
                const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? valueColor}) {

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }

  Widget _buildLegalItem(
    IconData icon,
    String title,
    String status,
    Color color, {
    String? url,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: (url != null) ? () async {
        if (!_isUnlocked) {
          _showUnlockPaywall();
          return;
        }
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      } : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                  if (url != null)
                    Text(
                      _isUnlocked ? 'Tap to view document' : 'Locked â€¢ Premium Access Required',
                      style: TextStyle(
                        fontSize: 10, 
                        color: _isUnlocked ? theme.colorScheme.primary : Colors.amber[800],
                        fontWeight: _isUnlocked ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  if (url != null)
                    Icon(
                      _isUnlocked ? LucideIcons.externalLink : LucideIcons.lock, 
                      size: 10, 
                      color: color
                    ),
                  if (url != null) const SizedBox(width: 4),
                  Text(
                    status,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
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

  Widget _buildDueDiligenceVault(Property p, ThemeData theme) {
    String vaultModeText = 'Unverified property. Documents not available.';
    Color vaultColor = Colors.grey;
    IconData vaultIcon = LucideIcons.shieldAlert;

    if (p.verificationStatus == PropertyVerificationStatus.verified) {
      vaultModeText = '100% Verified. All legal documents are authenticated.';
      vaultColor = Colors.green;
      vaultIcon = LucideIcons.shieldCheck;
    } else if (p.verificationStatus ==
        PropertyVerificationStatus.pendingReview) {
      vaultModeText = 'Documents under review by Admin.';
      vaultColor = Colors.orange;
      vaultIcon = LucideIcons.clock;
    } else if (p.verificationStatus ==
        PropertyVerificationStatus.issuesFlagged) {
      vaultModeText = 'Discrepancies found during verification.';
      vaultColor = Colors.red;
      vaultIcon = LucideIcons.alertTriangle;
    } else if (p.verificationStatus ==
        PropertyVerificationStatus.fraudBlocked) {
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
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
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
              const Text(
                'Due Diligence Vault',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
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
                    style: TextStyle(
                      color: vaultColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (p.legalDocuments.isNotEmpty || p.coOfOUrl != null || p.surveyPlanUrl != null) ...[
            const Text(
              'Available Documents:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            // Custom checklist docs from URLs
            if (p.coOfOUrl != null)
              _buildLegalItem(LucideIcons.fileCheck, 'C of O', 'AVAILABLE', Colors.blue, url: p.coOfOUrl),
            if (p.governorsConsentUrl != null)
              _buildLegalItem(LucideIcons.fileCheck, 'Governor\'s Consent', 'AVAILABLE', Colors.blue, url: p.governorsConsentUrl),
            if (p.surveyPlanUrl != null)
              _buildLegalItem(LucideIcons.map, 'Survey Plan', 'AVAILABLE', Colors.blue, url: p.surveyPlanUrl),
            if (p.deedOfAssignmentUrl != null)
              _buildLegalItem(LucideIcons.fileSignature, 'Deed of Assignment', 'AVAILABLE', Colors.blue, url: p.deedOfAssignmentUrl),
            if (p.buildingPlanApprovalUrl != null)
              _buildLegalItem(LucideIcons.clipboardCheck, 'Building Plan Approval', 'AVAILABLE', Colors.blue, url: p.buildingPlanApprovalUrl),
            if (p.soilTestReportUrl != null)
              _buildLegalItem(LucideIcons.fileText, 'Soil Test Report', 'AVAILABLE', Colors.blue, url: p.soilTestReportUrl),
            if (p.structuralIntegrityReportUrl != null)
              _buildLegalItem(LucideIcons.shieldCheck, 'Structural Report', 'AVAILABLE', Colors.blue, url: p.structuralIntegrityReportUrl),
              
            // Legacy/Admin verified documents
            ...p.legalDocuments.map(
              (doc) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildLegalItem(
                  LucideIcons.fileText,
                  doc.title,
                  doc.status.name.toUpperCase(),
                  doc.status == LegalDocumentStatus.verified
                      ? Colors.green
                      : (doc.status == LegalDocumentStatus.rejected
                            ? Colors.red
                            : Colors.grey),
                  url: doc.url,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(LucideIcons.messageSquare, size: 18),
              label: const Text('Request Clarification'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                final chatProvider = Provider.of<ChatProvider>(
                  context,
                  listen: false,
                );
                chatProvider.createRoom(
                  p.id,
                  p.title,
                  p.imagesGallery.isNotEmpty
                      ? p.imagesGallery.first
                      : p.imageUrl,
                  p.agentName,
                );
                final room = chatProvider.getRoomByProperty(p.id);
                if (room != null) {
                  // Can Optionally add a message to chat room here
                  chatProvider.sendMessage(
                    room.id,
                    "Hi, I'd like to request clarity on some legal documents for this property.",
                    'user',
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatDetailScreen(roomId: room.id),
                    ),
                  );
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Message attached. Proceeding to chat...'),
                  ),
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
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.gavel,
                      color: Colors.teal,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Terms & Conditions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Property: ${p.title}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
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
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.info,
                            color: Colors.blue,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'These terms were provided by the agent\'s legal representative and verified by SwiftSpace.',
                              style: TextStyle(
                                color: Colors.blue[900],
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      p.termsAndConditions ??
                          'Standard rental and purchase terms apply. Please contact the agent for detailed legal documentation.',
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.7,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal[700]!, Colors.teal[900]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            LucideIcons.shieldCheck,
                            color: Colors.white,
                            size: 32,
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Authenticity Guaranteed',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'SwiftSpace verifies that this document matches the property title.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'I Understand',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
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
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }



  Widget _buildDesktopLayout(
    BuildContext context,
    ThemeData theme,
    Property p,
  ) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          p.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          _buildDesktopFavoriteButton(p),
          const SizedBox(width: 8),
          _buildDesktopShareButton(),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Media & Description
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDesktopGallery(p),
                    const SizedBox(height: 48),
                    _buildDesktopDescription(theme, p),
                    const SizedBox(height: 48),
                    _buildDesktopLocation(theme, p),
                  ],
                ),
              ),
              const SizedBox(width: 64),
              // Right: Sticky Info & CTAs
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDesktopInfoCard(theme, p),
                    const SizedBox(height: 32),
                    _buildDesktopAgentCard(theme, p),
                    const SizedBox(height: 32),
                    _buildDesktopCTAs(theme, p),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopFavoriteButton(Property p) {
    return Consumer<FavoritesProvider>(
      builder: (context, favs, child) {
        final isFav = favs.isFavorite(p.id);
        return IconButton(
          icon: Icon(
            isFav ? Icons.favorite : Icons.favorite_border,
            color: isFav ? Colors.red : null,
          ),
          onPressed: () {
            favs.toggleFavorite(p);
            final currentCount = p.favoritesCount;
            context.read<PropertyProvider>().updateFavoritesCount(
              p.id,
              isFav ? currentCount - 1 : currentCount + 1,
            );
          },
        );
      },
    );
  }

  Widget _buildDesktopShareButton() {
    return IconButton(icon: const Icon(LucideIcons.share2), onPressed: () {});
  }

  Widget _buildDesktopGallery(Property p) {
    return Container(
      height: 600,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            itemCount: p.imagesGallery.length,
            onPageChanged: (i) => setState(() => _currentImageIndex = i),
            itemBuilder: (context, index) => CachedNetworkImage(
              imageUrl: p.imagesGallery[index],
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            bottom: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentImageIndex + 1} / ${p.imagesGallery.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopDescription(ThemeData theme, Property p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          p.description,
          style: TextStyle(color: Colors.grey[700], fontSize: 16, height: 1.8),
        ),
        const SizedBox(height: 40),
        const Divider(),
        const SizedBox(height: 40),
        HomeOwnershipOptionsWidget(property: p),
      ],
    );
  }

  Widget _buildDesktopInfoCard(ThemeData theme, Property p) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'â‚¦${p.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 36,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(LucideIcons.mapPin, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                p.locationName,
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFeatureIcon(LucideIcons.bed, '${p.beds} Beds', theme),
              _buildFeatureIcon(LucideIcons.bath, '${p.baths} Baths', theme),
              _buildFeatureIcon(LucideIcons.maximize, 'Standard', theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopAgentCard(ThemeData theme, Property p) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Icon(LucideIcons.user, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Swift Space Verified Agent',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Real Estate Specialist',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              LucideIcons.messageCircle,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLocation(ThemeData theme, Property p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          height: 400,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.grey[200],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                'https://api.placeholder.com/1200/800?text=Property+Location+Map',
                fit: BoxFit.cover,
              ),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => _openLocationInGoogleMaps(
                    p.location.latitude,
                    p.location.longitude,
                  ),
                  icon: const Icon(LucideIcons.map),
                  label: const Text('Open in Google Maps'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopCTAs(ThemeData theme, Property p) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton.icon(
            icon: const Icon(LucideIcons.messageSquare),
            onPressed: () {
              if (!_isUnlocked) {
                _showUnlockPaywall();
              } else {
                _bookInspection(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 0,
            ),
            label: const Text(
              'Contact & Inspection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 64,
          child: OutlinedButton.icon(
            icon: const Icon(LucideIcons.heart),
            onPressed: () {
              context.read<FavoritesProvider>().toggleFavorite(p);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              side: BorderSide(color: theme.colorScheme.primary, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            label: Consumer<FavoritesProvider>(
              builder: (context, favs, _) => Text(
                favs.isFavorite(p.id)
                    ? 'Remove from Favorites'
                    : 'Add to Favorites',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—
// â•‘  HOW TO OWN THIS HOME â€” Nigerian Homeownership Pathways     â•‘
// â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class HomeOwnershipOptionsWidget extends StatefulWidget {
  final Property property;
  const HomeOwnershipOptionsWidget({super.key, required this.property});

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
        '4. Enjoy up to â‚¦15M loan at 6% interest for 30 years',
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
          'Pay monthly as if renting. A portion goes toward your equity. Own fully after the agreed term â€” no huge deposit needed.',
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
          'Negotiate a staged payment plan directly with the developer or seller â€” no bank required. Common for off-plan or estate properties.',
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
        '1. Apply on app â€” no physical visit needed',
        '2. Upload ID, payslips, and bank statements',
        '3. AI-powered credit scoring for faster decision',
        '4. Disbursement directly to seller within 7â€“14 days',
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
          'Living abroad? FMBN and several banks offer diaspora mortgage products â€” apply in foreign currency and repay from overseas accounts.',
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
          'Ditch the annual bulk payment. Pay for your rent monthly like a subscription through ${AppConstants.appName} partnered landlords.',
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
          'Find verified roommates to share the cost of this property. ${AppConstants.appName} matches you with compatible housemates.',
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
    final List<_OwnershipOption> currentOptions = isBuy
        ? _options
        : _rentOptions;

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
                  colors: [AppColors.primaryDark, AppColors.primaryLight],
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Pick the pathway that fits your pocket',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
              color: AppColors.primaryDark.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primaryDark.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.calculator,
                  size: 14,
                  color: Color(0xFF1EB476),
                ),
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
                      ),
                    ]
                  : [],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() => _selected = isExpanded ? -1 : i),
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
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: opt.badgeColor.withValues(
                                          alpha: 0.12,
                                        ),
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
                          color: opt.color.withValues(alpha: 0.2),
                          height: 1,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          opt.summary,
                          style: const TextStyle(fontSize: 13.5, height: 1.55),
                        ),
                        const SizedBox(height: 14),
                        // Steps
                        ...opt.steps.map(
                          (step) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.only(
                                    top: 5,
                                    right: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: opt.color,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    step,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (opt.ctaUrl != null) {
                                launchUrl(
                                  Uri.parse(opt.ctaUrl!),
                                  mode: LaunchMode.externalApplication,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${opt.label} request sent to agent!',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: opt.color,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: opt.color,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              opt.cta,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
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
      return 'â‚¦${(emi / 1000000).toStringAsFixed(1)}M';
    }
    return 'â‚¦${(emi / 1000).toStringAsFixed(0)}k';
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
