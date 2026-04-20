import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:swiftspace/core/constants/app_constants.dart';
import 'core/theme/theme_provider.dart';
import 'features/explore/presentation/state/favorites_provider.dart';
import 'features/explore/presentation/pages/explore_screen.dart';
import 'features/explore/presentation/pages/saved_screen.dart';
import 'features/auth/presentation/pages/user_profile_screen.dart';
import 'features/auth/presentation/state/user_preferences_provider.dart';
import 'features/booking/presentation/state/booking_provider.dart';
import 'features/chat/presentation/state/chat_provider.dart';
import 'core/services/audio_manager.dart';
import 'features/auth/presentation/pages/splash_screen.dart';
import 'features/booking/presentation/pages/property_hub_screen.dart';
import 'features/property/presentation/state/property_provider.dart';
import 'features/negotiation/presentation/state/negotiation_provider.dart';
import 'features/auth/presentation/state/auth_provider.dart';
import 'features/auth/presentation/state/verification_provider.dart';
import 'features/auth/presentation/state/admin_provider.dart';
import 'features/savings/presentation/state/savings_provider.dart';
import 'features/savings/presentation/pages/savings_screen.dart';
import 'core/utils/responsive.dart';


import 'package:swiftspace/core/services/supabase_service.dart';
import 'package:swiftspace/core/di/injection_container.dart';
import 'package:swiftspace/features/auth/data/repositories/auth_repository.dart';

import 'dart:ui';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase with basic error handling
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Supabase Initialization Error: $e');
    // We continue so the app can at least show the NoInternet screen if needed
  }

  // Initialize Dependency Injection
  await initGlobalDI();
  
  // Configure GoogleFonts to not crash on fetch errors
  // This helps when the device is offline
  GoogleFonts.config.allowRuntimeFetching = true;

  // Global error handler for Flutter frame-work errors
  FlutterError.onError = (details) {
    if (details.exception.toString().contains('SocketException') || 
        details.exception.toString().contains('google_fonts')) {
      debugPrint('Network/Font warning (Handled): ${details.exception}');
      return;
    }
    FlutterError.presentError(details);
  };

  // Global error handler for asynchronous errors (not caught by Flutter)
  PlatformDispatcher.instance.onError = (error, stack) {
    if (error.toString().contains('SocketException') || 
        error.toString().contains('google_fonts')) {
      debugPrint('Async Network warning (Handled): $error');
      return true;
    }
    return false;
  };

  sl<AudioManager>().init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => UserPreferencesProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => PropertyProvider()),
        ChangeNotifierProvider(create: (_) => NegotiationProvider()),
        ChangeNotifierProvider(create: (_) => SavingsProvider()),
        ChangeNotifierProxyProvider<PropertyProvider, VerificationProvider>(
          create: (context) => VerificationProvider(
            Provider.of<PropertyProvider>(context, listen: false),
            sl<AuthRepository>(),
          ),
          update: (context, propertyProvider, previous) => 
              previous ?? VerificationProvider(propertyProvider, sl<AuthRepository>()),
        ),
        ChangeNotifierProxyProvider<PropertyProvider, AdminProvider>(
          create: (context) => AdminProvider(
            sl<AuthRepository>(),
            Provider.of<PropertyProvider>(context, listen: false),
          ),
          update: (context, propertyProvider, previous) => 
              previous ?? AdminProvider(sl<AuthRepository>(), propertyProvider),
        ),
      ],
      child: const SwiftSpaceApp(),
    ),
  );
}

class SwiftSpaceApp extends StatelessWidget {
  const SwiftSpaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.backgroundLight,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primaryLight,
          secondary: AppColors.secondary,
          surface: AppColors.surfaceLight,
          onSurface: AppColors.textPrimaryLight,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.backgroundDark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryDark,
          secondary: AppColors.secondary,
          surface: AppColors.surfaceDark,
          onSurface: AppColors.textPrimaryDark,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final List<Widget> _screens = [
    const ExploreScreen(),
    const SavedScreen(),
    const PropertyHubScreen(),
    const VaultScreen(),
    const UserProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final prefs = Provider.of<UserPreferencesProvider>(context);
    final isMobile = Responsive.isMobile(context);
    
    return Scaffold(
      body: Row(
        children: [
          if (!isMobile)
            NavigationRail(
              selectedIndex: prefs.currentTabIndex,
              onDestinationSelected: (index) => prefs.setTabIndex(index),
              labelType: NavigationRailLabelType.all,
              backgroundColor: colorScheme.surface,
              selectedIconTheme: IconThemeData(color: colorScheme.primary),
              unselectedIconTheme: IconThemeData(color: colorScheme.onSurface.withValues(alpha: 0.5)),
              selectedLabelTextStyle: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              unselectedLabelTextStyle: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 10,
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(LucideIcons.compass),
                  label: Text(AppStrings.navExplore),
                ),
                NavigationRailDestination(
                  icon: Icon(LucideIcons.heart),
                  label: Text(AppStrings.navFavorite),
                ),
                NavigationRailDestination(
                  icon: Icon(LucideIcons.layoutDashboard),
                  label: Text(AppStrings.navHub),
                ),
                NavigationRailDestination(
                  icon: Icon(LucideIcons.landmark),
                  label: Text(AppStrings.navVault),
                ),
                NavigationRailDestination(
                  icon: Icon(LucideIcons.user),
                  label: Text(AppStrings.navProfile),
                ),
              ],
            ),
          Expanded(
            child: IndexedStack(
              index: prefs.currentTabIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: isMobile 
        ? BottomNavigationBar(
            currentIndex: prefs.currentTabIndex,
            onTap: (index) => prefs.setTabIndex(index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: colorScheme.surface,
            selectedItemColor: colorScheme.primary,
            unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.5),
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 10),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(LucideIcons.compass),
                label: AppStrings.navExplore,
              ),
              BottomNavigationBarItem(
                icon: Icon(LucideIcons.heart),
                label: AppStrings.navFavorite,
              ),
              BottomNavigationBarItem(
                icon: Icon(LucideIcons.layoutDashboard),
                label: AppStrings.navHub,
              ),
              BottomNavigationBarItem(
                icon: Icon(LucideIcons.landmark),
                label: AppStrings.navVault,
              ),
              BottomNavigationBarItem(
                icon: Icon(LucideIcons.user),
                label: AppStrings.navProfile,
              ),
            ],
          )
        : null,
    );
  }
}
