import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:swiftspace/features/property/domain/entities/property.dart';
import 'package:swiftspace/features/property/presentation/state/property_provider.dart';
import 'package:swiftspace/features/explore/presentation/state/favorites_provider.dart';
import 'package:swiftspace/features/property/presentation/pages/property_details_screen.dart';
import 'package:swiftspace/features/auth/presentation/state/user_preferences_provider.dart';
import 'package:swiftspace/core/services/audio_manager.dart';
import 'package:swiftspace/core/di/injection_container.dart';

class TikTokExploreScreen extends StatefulWidget {
  const TikTokExploreScreen({super.key});

  @override
  State<TikTokExploreScreen> createState() => _TikTokExploreScreenState();
}

class _TikTokExploreScreenState extends State<TikTokExploreScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only show live properties representing feed
    final properties = Provider.of<PropertyProvider>(context).liveProperties;

    // Filter to only active and feed-ready properties (optional extra filtering here)
    if (properties.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(LucideIcons.home, color: Colors.white54, size: 48),
              SizedBox(height: 16),
              Text('No properties found.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: properties.length,
        itemBuilder: (context, index) {
          final prop = properties[index];
          return _TikTokFeedItem(property: prop);
        },
      ),
    );
  }
}

class _TikTokFeedItem extends StatefulWidget {
  final Property property;

  const _TikTokFeedItem({required this.property});

  @override
  State<_TikTokFeedItem> createState() => _TikTokFeedItemState();
}

class _TikTokFeedItemState extends State<_TikTokFeedItem> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    if (widget.property.videoUrl != null) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.property.videoUrl!));
    await _videoController!.initialize();
    _videoController!.setLooping(true);
    _videoController!.setVolume(_isMuted ? 0.0 : 1.0);
    if (mounted) {
      setState(() {
        _isVideoInitialized = true;
      });
      _videoController!.play();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final isFavorite = favoritesProvider.isFavorite(widget.property.id);

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Background Media (Video or Image)
        if (_videoController != null && _isVideoInitialized)
          GestureDetector(
            onTap: () {
              if (_videoController!.value.isPlaying) {
                _videoController!.pause();
              } else {
                _videoController!.play();
              }
            },
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            ),
          )
        else
          CachedNetworkImage(
            imageUrl: widget.property.imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.grey[900]),
            errorWidget: (context, url, error) => Container(color: Colors.grey[900]),
          ),

        // Gradient darkening at the bottom
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.6, 1.0],
              ),
            ),
          ),
        ),

        // 2. Info Overlay (Bottom Left)
        Positioned(
          left: 16,
          bottom: 24, // above nav bar spacing
          right: 80, // give space for action buttons
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                   Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(4)),
                      child: Text(
                        widget.property.type.name.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                   ),
                   const SizedBox(width: 8),
                   if (widget.property.isPremium)
                     Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(4)),
                        child: const Row(
                          children: [
                            Icon(LucideIcons.star, color: Colors.white, size: 10),
                            SizedBox(width: 4),
                            Text('PREMIUM', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ]
                        ),
                     )
                   else if (widget.property.isVerified)
                     Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(4)),
                        child: const Row(
                          children: [
                            Icon(Icons.verified, color: Colors.white, size: 10),
                            SizedBox(width: 4),
                            Text('VERIFIED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ]
                        ),
                     ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.property.title,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, height: 1.2),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(LucideIcons.mapPin, color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.property.locationName,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.property.formattedPrice,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        // 3. Actions Overlay (Right Sidebar)
        Positioned(
          right: 8,
          bottom: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  image: widget.property.listerLogoUrl != null
                      ? DecorationImage(image: CachedNetworkImageProvider(widget.property.listerLogoUrl!), fit: BoxFit.cover)
                      : null,
                ),
                child: widget.property.listerLogoUrl == null ? const Icon(LucideIcons.user, color: Colors.white) : null,
              ),
              const SizedBox(height: 24),
              
              // Like Button
              GestureDetector(
                onTap: () {
                  sl<AudioManager>().playClick(context);
                  favoritesProvider.toggleFavorite(widget.property);
                },
                child: Column(
                  children: [
                    Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.white,
                      size: 38,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.property.favoritesCount + (isFavorite ? 1 : 0)}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // View Details Button
              GestureDetector(
                onTap: () {
                  sl<AudioManager>().playClick(context);
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => PropertyDetailsScreen(property: widget.property)),
                  );
                },
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                      child: const Icon(LucideIcons.info, color: Colors.white, size: 22),
                    ),
                    const SizedBox(height: 4),
                    const Text('Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Mute Button
              if (_videoController != null && _isVideoInitialized)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isMuted = !_isMuted;
                      _videoController!.setVolume(_isMuted ? 0.0 : 1.0);
                    });
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                        child: Icon(_isMuted ? LucideIcons.volumeX : LucideIcons.volume2, color: Colors.white, size: 22),
                      ),
                      const SizedBox(height: 4),
                      Text(_isMuted ? 'Muted' : 'Sound', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        
        // 4. Safe Area Top header
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Discover For You',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, shadows: [Shadow(blurRadius: 10, color: Colors.black)]),
              ),
              IconButton(
                icon: const Icon(LucideIcons.filter, color: Colors.white),
                onPressed: () {
                   // Pop up filters if needed (Can hook into existing Grid grid filters logic)
                },
              ),
            ],
          ),
        )
      ],
    );
  }
}
