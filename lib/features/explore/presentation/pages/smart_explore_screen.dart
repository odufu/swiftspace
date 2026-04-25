import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:swiftspace/core/constants/app_constants.dart';
import 'package:swiftspace/features/property/domain/entities/property.dart';
import 'package:swiftspace/features/property/presentation/pages/property_details_screen.dart';
import 'package:swiftspace/core/di/injection_container.dart';
import 'package:swiftspace/features/explore/domain/services/ai_recommendation_service.dart';
import 'package:swiftspace/features/explore/presentation/pages/grid_explore_screen.dart';
import 'package:swiftspace/features/explore/presentation/pages/map_explore_screen.dart';
import 'package:swiftspace/features/explore/presentation/pages/tiktok_explore_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final List<Property>? properties;

  ChatMessage({required this.text, required this.isUser, this.properties});
}

enum _CuratedViewMode { grid, map, swipe }

class SmartExploreScreen extends StatefulWidget {
  const SmartExploreScreen({super.key});

  @override
  State<SmartExploreScreen> createState() => _SmartExploreScreenState();
}

class _SmartExploreScreenState extends State<SmartExploreScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final IAiRecommendationService _aiService = sl<IAiRecommendationService>();

  final List<ChatMessage> _messages = [
    ChatMessage(
      text:
          'Hi there! 👋 I\'m your SwiftSpace AI. Describe your ideal property — budget, location, type — and I\'ll find the best matches for you.',
      isUser: false,
    ),
  ];

  bool _isLoading = false;

  // Curated panel state
  List<Property>? _curatedProperties;
  bool _showCuratedPanel = false;
  _CuratedViewMode _curatedViewMode = _CuratedViewMode.grid;
  late AnimationController _panelController;
  late Animation<Offset> _panelSlide;

  @override
  void initState() {
    super.initState();
    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _panelSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _panelController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    _panelController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 300,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final query = _chatController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: query, isUser: true));
      _isLoading = true;
    });
    _chatController.clear();
    _scrollToBottom();

    try {
      final results = await _aiService.getRecommendations(query);

      setState(() {
        _isLoading = false;
        if (results.isEmpty) {
          _messages.add(ChatMessage(
            text:
                "I couldn't find any exact matches for that. Try broadening your search or adjusting your budget.",
            isUser: false,
          ));
        } else {
          _messages.add(ChatMessage(
            text:
                "Found ${results.length} properties that match your criteria. Here are your top picks:",
            isUser: false,
            properties: results,
          ));
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages.add(ChatMessage(
          text: "Sorry, I ran into an error. Please try again.",
          isUser: false,
        ));
      });
    }
    _scrollToBottom();
  }

  void _openCuratedPanel(List<Property> properties) {
    setState(() {
      _curatedProperties = properties;
      _showCuratedPanel = true;
    });
    _panelController.forward();
  }

  void _closeCuratedPanel() {
    _panelController.reverse().then((_) {
      setState(() {
        _showCuratedPanel = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          // ── Main Chat ──────────────────────────────────────────────────
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isLoading) {
                      return _buildLoadingBubble();
                    }
                    return _buildChatBubble(_messages[index]);
                  },
                ),
              ),
              _buildChatInput(),
            ],
          ),

          // ── Curated Panel (slides up over chat) ───────────────────────
          if (_showCuratedPanel && _curatedProperties != null)
            SlideTransition(
              position: _panelSlide,
              child: _buildCuratedPanel(_curatedProperties!),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 16, 20, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryLight, Colors.purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SwiftSpace AI',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              Text('Ask me anything about properties',
                  style: TextStyle(
                      color: Colors.grey[500], fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return FadeInUp(
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius:
                BorderRadius.circular(18).copyWith(bottomLeft: const Radius.circular(4)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primaryLight),
              ),
              SizedBox(width: 12),
              Text('Searching properties...',
                  style: TextStyle(color: Colors.black54, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: Column(
        crossAxisAlignment:
            message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Align(
            alignment:
                message.isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78),
              margin: const EdgeInsets.only(bottom: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: message.isUser
                    ? const LinearGradient(
                        colors: [AppColors.primaryLight, Colors.purple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: message.isUser ? null : Colors.grey[100],
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomRight: message.isUser
                      ? const Radius.circular(4)
                      : null,
                  bottomLeft: !message.isUser
                      ? const Radius.circular(4)
                      : null,
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black87,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (message.properties != null && message.properties!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildPropertiesCarousel(message.properties!),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildPropertiesCarousel(List<Property> properties) {
    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: properties.length + 1, // +1 for "View All" card
        itemBuilder: (context, index) {
          if (index == properties.length) {
            return _buildViewAllCard(properties);
          }
          return _buildPropertyCard(properties[index]);
        },
      ),
    );
  }

  Widget _buildViewAllCard(List<Property> allProperties) {
    return GestureDetector(
      onTap: () => _openCuratedPanel(allProperties),
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryLight.withValues(alpha: 0.12),
              Colors.purple.withValues(alpha: 0.12),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.primaryLight.withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryLight, Colors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.layoutGrid, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 12),
            const Text(
              'Explore All\nCurated',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.primaryLight,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Grid · Map · Swipe',
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyCard(Property property) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => PropertyDetailsScreen(property: property)),
      ),
      child: Container(
        width: 210,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: CachedNetworkImage(
                  imageUrl: property.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₦${_formatPrice(property.price)}',
                      style: const TextStyle(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(LucideIcons.mapPin,
                            size: 11, color: Colors.grey[500]),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            property.locationName,
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Curated Full-Screen Panel ──────────────────────────────────────────

  Widget _buildCuratedPanel(List<Property> properties) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          _buildPanelHeader(properties),
          Expanded(child: _buildActiveView(properties)),
        ],
      ),
    );
  }

  Widget _buildPanelHeader(List<Property> properties) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 12, 20, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _closeCuratedPanel,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(LucideIcons.chevronDown, size: 20, color: isDark ? Colors.white : Colors.black87),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Curated Picks',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                Text('${properties.length} properties matched',
                    style:
                        TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
          _buildViewModeDropdown(),
        ],
      ),
    );
  }

  Widget _buildViewModeDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    IconData currentIcon;
    switch (_curatedViewMode) {
      case _CuratedViewMode.grid:
        currentIcon = LucideIcons.layoutGrid;
      case _CuratedViewMode.map:
        currentIcon = LucideIcons.map;
      case _CuratedViewMode.swipe:
        currentIcon = LucideIcons.playSquare;
    }

    return PopupMenuButton<_CuratedViewMode>(
      initialValue: _curatedViewMode,
      onSelected: (mode) => setState(() => _curatedViewMode = mode),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? Colors.grey[900] : Colors.white,
      offset: const Offset(0, 45),
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryLight, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryLight.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(currentIcon, size: 18, color: Colors.white),
            const SizedBox(width: 6),
            const Icon(LucideIcons.chevronDown, size: 14, color: Colors.white),
          ],
        ),
      ),
      itemBuilder: (context) => [
        _buildPopupMenuItem(_CuratedViewMode.grid, LucideIcons.layoutGrid, 'Grid View'),
        _buildPopupMenuItem(_CuratedViewMode.map, LucideIcons.map, 'Map View'),
        _buildPopupMenuItem(_CuratedViewMode.swipe, LucideIcons.playSquare, 'Swipe View'),
      ],
    );
  }

  PopupMenuItem<_CuratedViewMode> _buildPopupMenuItem(
      _CuratedViewMode mode, IconData icon, String label) {
    final isSelected = _curatedViewMode == mode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return PopupMenuItem(
      value: mode,
      child: Row(
        children: [
          Icon(icon, size: 18, color: isSelected ? AppColors.primaryLight : (isDark ? Colors.grey[400] : Colors.grey[600])),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primaryLight : (isDark ? Colors.white : Colors.black87),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveView(List<Property> properties) {
    switch (_curatedViewMode) {
      case _CuratedViewMode.grid:
        return GridExploreScreen(curatedProperties: properties);
      case _CuratedViewMode.map:
        return MapExploreScreen(curatedProperties: properties);
      case _CuratedViewMode.swipe:
        return TikTokExploreScreen(curatedProperties: properties);
    }
  }

  Widget _buildChatInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  width: 1,
                ),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: AppColors.primaryLight.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                ],
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.sparkles, 
                      size: 18, 
                      color: AppColors.primaryLight.withValues(alpha: 0.7)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Describe your ideal property...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isLoading ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: _isLoading
                    ? null
                    : const LinearGradient(
                        colors: [AppColors.primaryLight, Colors.purple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: _isLoading 
                    ? (isDark ? Colors.grey[800] : Colors.grey[300]) 
                    : null,
                shape: BoxShape.circle,
                boxShadow: _isLoading ? null : [
                  BoxShadow(
                    color: AppColors.primaryLight.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(LucideIcons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000) return '${(price / 1000000).toStringAsFixed(1)}M';
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)}K';
    return price.toStringAsFixed(0);
  }
}
