import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:swiftspace/features/auth/presentation/pages/phone_auth_screen.dart';
import 'package:swiftspace/core/services/audio_manager.dart';
import 'package:swiftspace/core/constants/app_constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = AppStrings.onboardingSlides;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Images
          PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) {
              setState(() => _currentPage = idx);
              AudioManager().playSwipe(context);
              AudioManager().triggerHaptic(context);
            },
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _slides[index]['image']!,
                    fit: BoxFit.cover,
                  ),
                  // Dark Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.4),
                          Colors.black.withValues(alpha: 0.9),
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
            },
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Indicators
                  Row(
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 4,
                        width: _currentPage == index ? 24 : 12,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primaryDark
                              : Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Text
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Column(
                      key: ValueKey<int>(_currentPage),
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
                  ),
                  const SizedBox(height: 48),

                  // Buttons
                  Row(
                    children: [
                      if (_currentPage < _slides.length - 1)
                        TextButton(
                          onPressed: () {
                            AudioManager().playClick(context);
                            AudioManager().triggerHaptic(context);
                            _pageController.animateToPage(
                              _slides.length - 1,
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeInOut,
                            );
                          },
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
                        onPressed: () {
                          if (_currentPage < _slides.length - 1) {
                            AudioManager().playClick(context);
                            AudioManager().triggerHaptic(context);
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            AudioManager().playSuccess(context);
                            AudioManager().triggerHeavyHaptic(context);
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder: (_, _, _) => const PhoneAuthScreen(),
                                transitionsBuilder: (_, anim, _, child) {
                                  return SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(1.0, 0.0),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(
                                        parent: anim, curve: Curves.fastOutSlowIn)),
                                    child: child,
                                  );
                                },
                              ),
                            );
                          }
                        },
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
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(LucideIcons.arrowRight, size: 18),
                          ],
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
    );
  }
}
