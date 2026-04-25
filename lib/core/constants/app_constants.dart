import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Swift Space';
  static const String appVersion = '0.1.0';
  static const String appDescription = 'Real Estate Reimagined for Nigeria';

  // Map URLs
  static const String mapUrlSatellite = 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
  static const String mapUrlStandard = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
}

class AppAssets {
  static const String logo = 'assets/logo.png';
  
  // Sounds
  static const String soundBoot = 'assets/sounds/boot.mp3';
  static const String soundClick = 'assets/sounds/click.mp3';
  static const String soundSuccess = 'assets/sounds/success.mp3';
  static const String soundSwipe = 'assets/sounds/swipe.mp3';
}

class AppColors {
  // Brand Colors
  static const Color primaryLight = Color(0xFF0F5A3F); 
  static const Color primaryDark = Color(0xFF1EB476);
  static const Color secondary = Color(0xFF168153);
  
  // Status Colors
  static const Color success = Color(0xFF1EB476);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFB300);
  
  // UI Colors - Light
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color surfaceLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF1E1E1E);
  static const Color textSecondaryLight = Color(0xFF757575);
  
  // UI Colors - Dark
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textPrimaryDark = Colors.white;
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
}

class AppStrings {
  // Navigation
  static const String navExplore = 'EXPLORE';
  static const String navFavorite = 'FAVORITE';
  static const String navHub = 'HUB';
  static const String navVault = 'VAULT';
  static const String navProfile = 'PROFILE';

  // Onboarding
  static const String onboardingSkip = 'Skip';
  static const String onboardingNext = 'Next';
  static const String onboardingGetStarted = 'Get Started';

  static const List<Map<String, String>> onboardingSlides = [
    {
      'image': 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800&q=80',
      'title': 'Find Your Dream Home\nin Nigeria',
      'description': 'Discover top-tier properties across Abuja, Lagos, and PH with our immersive 3D map.'
    },
    {
      'image': 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800&q=80',
      'title': 'Innovative Ownership\nPathways',
      'description': 'From NHF Mortgages to Rent-to-Own. Find a pathway that fits your financial goals.'
    },
    {
      'image': 'https://images.unsplash.com/photo-1600047509807-ba8f99d2cdde?w=800&q=80',
      'title': 'Exclusive Off-Market\nDeals',
      'description': 'Get AI-curated "Best Offers" tailored to your preferences, delivered instantly.'
    },
  ];
}
