import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';

import 'package:swiftspace/features/property/domain/entities/property.dart';
import 'package:swiftspace/features/explore/presentation/state/favorites_provider.dart';
import 'package:swiftspace/features/property/presentation/state/property_provider.dart';
import 'package:swiftspace/features/media_ai/presentation/pages/video_player_screen.dart';
import 'package:swiftspace/features/media_ai/presentation/pages/virtual_walkthrough_screen.dart';
import 'package:swiftspace/shared/widgets/premium_paywall_v2.dart';

import 'package:swiftspace/shared/widgets/inspection_date_picker.dart';
import 'package:swiftspace/features/booking/presentation/state/booking_provider.dart';
import 'package:swiftspace/features/booking/domain/entities/booking.dart';
import 'package:swiftspace/features/booking/presentation/pages/property_management_screen.dart';
import 'package:swiftspace/features/booking/domain/entities/commitment.dart';
import 'package:swiftspace/features/agent/presentation/pages/professional_profile_screen.dart';

import 'package:swiftspace/features/property/presentation/widgets/property_feature_widgets.dart';

class PropertyDetailsScreen extends StatefulWidget {
  final Property property;

  const PropertyDetailsScreen({super.key, required this.property});

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  int _currentImageIndex = 0;
  late bool _isUnlocked;

  @override
  void initState() {
    super.initState();
    _isUnlocked = !widget.property.isPremium;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PropertyProvider>().incrementViews(widget.property.id);
      }
    });
  }

  void _handleUnlock() {
    Navigator.pop(context); // Close paywall
    setState(() => _isUnlocked = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔓 Exclusive Access Unlocked!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _bookInspection(BuildContext context) async {
    final bookingProvider = Provider.of<BookingProvider>(
      context,
      listen: false,
    );
    final navigator = Navigator.of(context);
    final selectedDateTime = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InspectionDatePicker(property: widget.property),
    );
    if (selectedDateTime != null && context.mounted) {
      final booking = InspectionBooking(
        id: 'BK-${DateTime.now().millisecondsSinceEpoch}',
        property: widget.property,
        dateTime: selectedDateTime,
        status: BookingStatus.confirmed,
      );
      bookingProvider.addBooking(booking);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inspection Booked!'),
          backgroundColor: Colors.green,
        ),
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

  // AI Chat State
  final List<Map<String, String>> _chatHistory = [];
  bool _isAsking = false;

  void _showAiAssistant() {
    final TextEditingController _chatController = TextEditingController();
    final ScrollController _scrollController = ScrollController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> _sendMessage() async {
            final query = _chatController.text.trim();
            if (query.isEmpty) return;

            setModalState(() {
              _chatHistory.add({'role': 'user', 'text': query});
              _isAsking = true;
              _chatController.clear();
            });

            // Scroll to bottom
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });

            try {
              final response = await Supabase.instance.client.functions.invoke(
                'property-ai-chat',
                body: {'query': query, 'property': widget.property.toMap()},
              );

              if (response.status == 200) {
                final aiText = response.data['response'] as String;
                setModalState(() {
                  _chatHistory.add({'role': 'ai', 'text': aiText});
                });
              } else {
                setModalState(() {
                  _chatHistory.add({
                    'role': 'ai',
                    'text':
                        "I'm sorry, I'm having trouble connecting to my brain right now. Please try again or contact the agent directly.",
                  });
                });
              }
            } catch (e) {
              setModalState(() {
                _chatHistory.add({
                  'role': 'ai',
                  'text':
                      "Oops! Something went wrong. You might want to ask the agent directly.",
                });
              });
            } finally {
              setModalState(() => _isAsking = false);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              });
            }
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.sparkles,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Property Assistant',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Ask anything about this listing',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(LucideIcons.x, color: Colors.white60),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                const Divider(color: Colors.white12, height: 1),

                // Chat History
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(24),
                    itemCount: _chatHistory.length + (_isAsking ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _chatHistory.length) {
                        return _buildLoadingBubble();
                      }

                      final msg = _chatHistory[index];
                      final isUser = msg['role'] == 'user';

                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isUser
                                ? Colors.blue
                                : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20).copyWith(
                              bottomRight: isUser
                                  ? const Radius.circular(4)
                                  : null,
                              bottomLeft: !isUser
                                  ? const Radius.circular(4)
                                  : null,
                            ),
                          ),
                          child: Text(
                            msg['text']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Input
                Container(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    16,
                    24,
                    16 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E293B),
                    border: Border(top: BorderSide(color: Colors.white12)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _chatController,
                          autofocus: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'e.g. Is this area prone to flooding?',
                            hintStyle: const TextStyle(color: Colors.white30),
                            border: InputBorder.none,
                            fillColor: Colors.white.withOpacity(0.05),
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: Colors.blue,
                                width: 1,
                              ),
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _sendMessage,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
            (i) => Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: const BoxDecoration(
                color: Colors.white30,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.property;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildImmersiveHeader(p, theme),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPropertyHeader(p),
                      const SizedBox(height: 24),
                      _buildQuickStats(p),
                      const SizedBox(height: 24),
                      SocialProofBar(
                        views: p.viewsCount,
                        favorites: p.favoritesCount,
                      ),
                      const SizedBox(height: 32),
                      AmenitiesGrid(amenities: p.amenities),
                      const SizedBox(height: 32),
                      _buildDescription(p),
                      const SizedBox(height: 32),
                      NeighborhoodInfo(property: p),
                      const SizedBox(height: 32),
                      FinancialBreakdown(property: p),
                      const SizedBox(height: 32),
                      TechnicalSpecs(property: p),
                      const SizedBox(height: 32),
                      if (p.isPremium && !_isUnlocked)
                        _buildLockedPremiumSection()
                      else
                        _buildUnlockedFeatures(p),
                      const SizedBox(height: 120), // Padding for bottom bar
                    ],
                  ),
                ),
              ),
            ],
          ),

          // AI Action Bar overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildAiActionBar(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildImmersiveHeader(Property p, ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      backgroundColor: theme.colorScheme.surface,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _buildGlassIcon(
          LucideIcons.arrowLeft,
          () => Navigator.pop(context),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Consumer<FavoritesProvider>(
            builder: (context, favs, child) {
              final isFav = favs.isFavorite(p.id);
              return _buildGlassIcon(
                isFav ? Icons.favorite : Icons.favorite_border,
                () => favs.toggleFavorite(p),
                color: isFav ? Colors.redAccent : Colors.white,
              );
            },
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              itemCount: p.imagesGallery.length,
              onPageChanged: (index) =>
                  setState(() => _currentImageIndex = index),
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: p.imagesGallery[index],
                  fit: BoxFit.cover,
                  colorBlendMode: BlendMode.darken,
                  color: Colors.black.withValues(
                    alpha: 0.2,
                  ), // Darken for premium look
                );
              },
            ),

            // Gradient overlay for bottom blending
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 150,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      theme.colorScheme.surface,
                      theme.colorScheme.surface.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Image Counter
            Positioned(
              bottom: 24,
              right: 24,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: Colors.black.withValues(alpha: 0.3),
                    child: Text(
                      '${_currentImageIndex + 1} / ${p.imagesGallery.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Media Controls
            Positioned(
              bottom: 24,
              left: 24,
              child: Row(
                children: [
                  if (p.hasVideo && p.videoUrl != null)
                    _buildMediaButton(
                      icon: LucideIcons.play,
                      label: 'Video Tour',
                      color: Colors.redAccent,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              VideoPlayerScreen(videoUrl: p.videoUrl!),
                        ),
                      ),
                    ),
                  if (p.has360View) ...[
                    const SizedBox(width: 12),
                    _buildMediaButton(
                      icon: LucideIcons.scan,
                      label: '360° View',
                      color: Colors.blueAccent,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VirtualWalkthroughScreen(property: p),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassIcon(
    IconData icon,
    VoidCallback onTap, {
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(10),
            color: Colors.black.withValues(alpha: 0.3),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: color.withValues(alpha: 0.2),
            child: Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyHeader(Property p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (p.isPremium)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.gem, color: Colors.amber, size: 14),
                SizedBox(width: 6),
                Text(
                  'Premium Exclusive',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        Text(
          p.title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(LucideIcons.mapPin, size: 16, color: Colors.grey[500]),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _isUnlocked ? p.locationName : 'Location protected (Premium)',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          '₦${p.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'\\B(?=(\\d{3})+(?!\\d))'), (match) => ',')}',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Color(0xFFF57C00),
          ),
        ),
        Text(
          p.priceTerm.toUpperCase(),
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(Property p) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatCard(LucideIcons.bedDouble, '${p.beds}', 'Beds'),
        _buildStatCard(LucideIcons.bath, '${p.baths}', 'Baths'),
        _buildStatCard(
          LucideIcons.ruler,
          '${p.totalSquareFootage?.toInt() ?? "---"}',
          'sqft',
        ),
        _buildStatCard(
          LucideIcons.calendar,
          '${p.yearBuilt ?? "---"}',
          'Built',
        ),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription(Property p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About this property',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          p.description,
          style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.6),
        ),
      ],
    );
  }

  Widget _buildLockedPremiumSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.lock, color: Colors.amber, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Premium Listing',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock to see exact location, due diligence documents, and agent contact details.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              PremiumPaywallV2.show(
                context,
                propertyTitle: widget.property.title,
                onUnlock: _handleUnlock,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Unlock Access - ₦5,000',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockedFeatures(Property p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDocumentsSection(p),
        const SizedBox(height: 32),
        _buildDueDiligenceSection(p),
        const SizedBox(height: 32),
        const Text(
          'Agent Information',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfessionalProfileScreen(
                  listerId: p.listerId ?? '',
                  listerName: p.listerName,
                  agentPhone: p.agentPhone,
                  listerType: p.listerType,
                  companyName: p.companyName,
                  listerLogoUrl: p.listerLogoUrl,
                  isVerified: p.isVerified,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                Hero(
                  tag: 'lister_avatar_${p.listerId}',
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white12,
                    backgroundImage: p.listerLogoUrl != null
                        ? CachedNetworkImageProvider(p.listerLogoUrl!)
                        : null,
                    child: p.listerLogoUrl == null
                        ? const Icon(LucideIcons.user, color: Colors.white70)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            p.listerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: Colors.white,
                            ),
                          ),
                          if (p.isVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified, color: Colors.blue, size: 16),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p.companyName ?? 'Independent Agent',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.phone, color: Colors.green, size: 20),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsSection(Property p) {
    final docs = [
      if (p.hasCertificateOfOccupancy)
        ('Certificate of Occupancy', p.coOfOUrl, LucideIcons.fileText),
      if (p.hasGovernorsConsent)
        ("Governor's Consent", p.governorsConsentUrl, LucideIcons.fileCheck),
      if (p.hasSurveyPlan)
        ('Survey Plan', p.surveyPlanUrl, LucideIcons.map),
      if (p.hasDeedOfAssignment)
        ('Deed of Assignment', p.deedOfAssignmentUrl, LucideIcons.scroll),
      if (p.hasBuildingPlanApproval)
        ('Building Plan Approval', p.buildingPlanApprovalUrl, LucideIcons.home),
      ...p.legalDocuments.map((ld) => (ld.title, ld.url, LucideIcons.file)),
    ];

    if (docs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(LucideIcons.files, color: Colors.blue, size: 22),
            SizedBox(width: 10),
            Text(
              'Attached Documents',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            separatorBuilder: (context, index) =>
                const Divider(color: Colors.white12, height: 1),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final hasUrl = doc.$2 != null;

              return ListTile(
                leading: Icon(doc.$3, color: Colors.white70, size: 20),
                title: Text(
                  doc.$1,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                trailing: hasUrl
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(LucideIcons.eye, color: Colors.blue, size: 14),
                          ],
                        ),
                      )
                    : Text(
                        'Available on request',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                onTap: () => _showDocumentViewer(doc.$1, doc.$2),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showDocumentViewer(String title, String? url) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          leading: IconButton(
            icon: const Icon(LucideIcons.x, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (url != null)
              IconButton(
                icon: const Icon(LucideIcons.externalLink, color: Colors.white),
                onPressed: () => _launchUrl(url),
              ),
          ],
        ),
        body: Center(
          child: url == null
              ? _buildMissingDocumentContent()
              : _buildDocumentContent(url),
        ),
      ),
    );
  }

  Widget _buildMissingDocumentContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.alertCircle, color: Colors.amber, size: 64),
        ),
        const SizedBox(height: 24),
        const Text(
          'Available on Request',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'This document has been verified but is not yet available for public download. Please contact the agent to request a copy.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 40),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(LucideIcons.phone, size: 18),
          label: const Text('Contact Agent'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentContent(String url) {
    final isImage = url.toLowerCase().contains('.jpg') ||
        url.toLowerCase().contains('.jpeg') ||
        url.toLowerCase().contains('.png') ||
        url.toLowerCase().contains('.webp');

    if (isImage) {
      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: CachedNetworkImage(
          imageUrl: url,
          placeholder: (context, url) =>
              const CircularProgressIndicator(color: Colors.blue),
          errorWidget: (context, url, error) => const Icon(
            LucideIcons.imageOff,
            color: Colors.white24,
            size: 48,
          ),
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(LucideIcons.fileText, color: Colors.blue, size: 64),
        const SizedBox(height: 24),
        const Text(
          'PDF Document',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap the external icon to view this document.',
          style: TextStyle(color: Colors.white.withOpacity(0.5)),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () => _launchUrl(url),
          icon: const Icon(LucideIcons.externalLink, size: 18),
          label: const Text('Open Externally'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open document'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _buildDueDiligenceSection(Property p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(LucideIcons.shieldCheck, color: Colors.green, size: 22),
            SizedBox(width: 10),
            Text(
              'Due Diligence',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (p.hasSoilTestReport)
              _buildDueDiligenceChip('Soil Test', LucideIcons.testTube),
            if (p.hasStructuralIntegrityReport)
              _buildDueDiligenceChip('Structural Integrity', LucideIcons.anchor),
            if (p.hasLawyerVerifiedTerms)
              _buildDueDiligenceChip('Lawyer Verified', LucideIcons.gavel),
            _buildDueDiligenceChip(
              p.floodingHistory ? 'Flood History' : 'No Flood History',
              LucideIcons.droplets,
              color: p.floodingHistory ? Colors.redAccent : Colors.green,
            ),
          ],
        ),
        if (p.dueDiligenceNotes != null && p.dueDiligenceNotes!.isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(LucideIcons.info, color: Colors.green, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Internal Notes',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  p.dueDiligenceNotes!,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDueDiligenceChip(String label, IconData icon,
      {Color color = Colors.green}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiActionBar(ThemeData theme) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.8),
            border: Border(
              top: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
          ),
          child: Row(
            children: [
              // AI Button
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: _showAiAssistant,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6A11CB).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.bot, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Ask AI',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Book Inspection Button
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () => _bookInspection(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF57C00),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF57C00).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Book Inspection',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
