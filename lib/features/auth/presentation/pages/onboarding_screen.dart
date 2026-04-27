import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:swiftspace/features/auth/presentation/pages/email_auth_screen.dart';
import 'package:swiftspace/core/services/audio_manager.dart';
import 'package:swiftspace/core/di/injection_container.dart';
import 'package:swiftspace/core/constants/app_constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _textAnim;

  final List<Map<String, String>> _slides = AppStrings.onboardingSlides;

  @override
  void initState() {
    super.initState();
    _textAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _textAnim.dispose();
    super.dispose();
  }

  void _onPageChanged(int idx) {
    _textAnim.reverse().then((_) {
      if (mounted) {
        setState(() => _currentPage = idx);
        _textAnim.forward();
      }
    });
    sl<AudioManager>().playSwipe(context);
    sl<AudioManager>().triggerHaptic(context);
  }

  void _navigateNext() {
    if (_currentPage < _slides.length - 1) {
      sl<AudioManager>().playClick(context);
      sl<AudioManager>().triggerHaptic(context);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _goToAuth();
    }
  }

  void _skipToLast() {
    sl<AudioManager>().playClick(context);
    sl<AudioManager>().triggerHaptic(context);
    _pageController.animateToPage(
      _slides.length - 1,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  void _goToAuth() {
    sl<AudioManager>().playSuccess(context);
    sl<AudioManager>().triggerHeavyHaptic(context);
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const EmailAuthScreen(),
        transitionsBuilder: (_, anim, _, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.fastOutSlowIn)),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 1024) {
            return _buildDesktopLayout();
          } else {
            return _buildMobileLayout();
          }
        },
      ),
    );
  }

  // ── Mobile/Tablet: full-screen slides with content overlay ──────────────
  Widget _buildMobileLayout() {
    return Stack(
      children: [
        // Sliding background images
        PageView.builder(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          itemCount: _slides.length,
          itemBuilder: (context, index) => _buildSlideBackground(index),
        ),
        // Content overlay
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildPageIndicators(),
                const SizedBox(height: 32),
                _buildSlideText(),
                const SizedBox(height: 48),
                _buildNavButtons(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Desktop: left image panel + right content panel ─────────────────────
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left: full-height image carousel (no controls)
        Expanded(
          flex: 6,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _slides.length,
            itemBuilder: (context, index) => _buildSlideBackground(index),
          ),
        ),
        // Right: content panel
        Expanded(
          flex: 4,
          child: Container(
            color: Colors.black,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 56),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo + App name
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(AppAssets.logo, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          AppConstants.appName,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    _buildPageIndicators(),
                    const SizedBox(height: 32),
                    _buildSlideText(),
                    const SizedBox(height: 48),
                    _buildNavButtons(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlideBackground(int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(_slides[index]['image']!, fit: BoxFit.cover),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.3),
                Colors.black.withValues(alpha: 0.85),
                Colors.black,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.4, 0.8, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      children: List.generate(
        _slides.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(right: 8),
          height: 4,
          width: _currentPage == index ? 28 : 12,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? AppColors.primaryDark
                : Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildSlideText() {
    return FadeTransition(
      opacity: _textAnim,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _slides[_currentPage]['title']!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _slides[_currentPage]['description']!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButtons() {
    return Row(
      children: [
        if (_currentPage < _slides.length - 1)
          TextButton(
            onPressed: _skipToLast,
            child: Text(
              AppStrings.onboardingSkip,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const Spacer(),
        ElevatedButton(
          onPressed: _navigateNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _currentPage == _slides.length - 1
                    ? AppStrings.onboardingGetStarted
                    : AppStrings.onboardingNext,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              const Icon(LucideIcons.arrowRight, size: 18),
            ],
          ),
        ),
      ],
    );
  }
}
