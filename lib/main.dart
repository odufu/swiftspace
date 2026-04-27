import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:swiftspace/core/constants/app_constants.dart';
import 'package:swiftspace/core/theme/theme_provider.dart';
import 'package:swiftspace/features/explore/presentation/state/favorites_provider.dart';
import 'package:swiftspace/features/explore/presentation/pages/main_explore_tab.dart';
import 'package:swiftspace/features/explore/presentation/pages/saved_screen.dart';
import 'package:swiftspace/features/auth/presentation/pages/user_profile_screen.dart';
import 'package:swiftspace/features/auth/presentation/state/user_preferences_provider.dart';
import 'package:swiftspace/features/booking/presentation/state/booking_provider.dart';
import 'package:swiftspace/features/chat/presentation/state/chat_provider.dart';
import 'package:swiftspace/shared/widgets/notification_sheet.dart';
import 'package:swiftspace/core/services/audio_manager.dart';
import 'package:swiftspace/features/auth/presentation/pages/splash_screen.dart';
import 'package:swiftspace/features/booking/presentation/pages/property_hub_screen.dart';
import 'package:swiftspace/features/property/presentation/state/property_provider.dart';
import 'package:swiftspace/features/negotiation/presentation/state/negotiation_provider.dart';
import 'package:swiftspace/features/auth/presentation/state/auth_provider.dart';
import 'package:swiftspace/features/auth/presentation/state/verification_provider.dart';
import 'package:swiftspace/features/auth/presentation/state/admin_provider.dart';
import 'package:swiftspace/features/savings/presentation/state/savings_provider.dart';
import 'package:swiftspace/features/savings/presentation/pages/savings_screen.dart';
import 'package:swiftspace/core/utils/responsive.dart';
import 'package:swiftspace/features/chat/presentation/state/notification_provider.dart';
import 'package:swiftspace/core/presentation/widgets/common/badge_icon.dart';

import 'package:swiftspace/core/services/supabase_service.dart';
import 'package:swiftspace/core/di/injection_container.dart';
import 'package:swiftspace/features/auth/data/repositories/auth_repository.dart';

import 'dart:ui';

import 'shared/widgets/guest_auth_placeholder.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Register DI immediately (it's sync and fast)
  initGlobalDI();

  // Configure GoogleFonts to use local assets
  GoogleFonts.config.allowRuntimeFetching = false;

  runApp(const RootApp());
}

class RootApp extends StatefulWidget {
  const RootApp({super.key});

  @override
  State<RootApp> createState() => _RootAppState();
}

class _RootAppState extends State<RootApp> {
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // 1. Load env
      await dotenv.load(fileName: ".env");

      // 2. Initialize Supabase
      await SupabaseService.initialize().timeout(const Duration(seconds: 10));

      // 3. Initialize Audio
      await sl<AudioManager>().init();

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint('Initialization Error: $e');
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: AppColors.primaryLight,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.alertTriangle, color: Colors.white, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to connect to servers.\nPlease check your connection.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _error = null;
                      _initialize();
                    }),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: InitializingSplash(),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProxyProvider<AuthProvider, FavoritesProvider>(
          create: (_) => FavoritesProvider(),
          update: (_, auth, previous) =>
              (previous ?? FavoritesProvider())..updateUser(auth.user?.id),
        ),
        ChangeNotifierProvider(create: (_) => UserPreferencesProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => PropertyProvider()),
        ChangeNotifierProvider(create: (_) => NegotiationProvider()),
        ChangeNotifierProvider(create: (_) => SavingsProvider()),
        ChangeNotifierProxyProvider<PropertyProvider, VerificationProvider>(
          create: (context) => VerificationProvider(
            Provider.of<PropertyProvider>(context, listen: false),
            sl<AuthRepository>(),
          ),
          update: (context, propertyProvider, previous) =>
              previous ??
              VerificationProvider(propertyProvider, sl<AuthRepository>()),
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
    );
  }
}

class InitializingSplash extends StatelessWidget {
  const InitializingSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryLight,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Text(
                  'S',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryLight,
                    fontFamily: 'Outfit',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppConstants.appName,
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
  List<Widget> _buildScreens(bool isAuthenticated) {
    return [
      const MainExploreTab(),
      isAuthenticated
          ? const SavedScreen()
          : const GuestAuthPlaceholder(
              title: 'Your Saved Homes',
              subtitle:
                  'Sign in to save properties and keep track of your favorite listings.',
              icon: LucideIcons.heart,
            ),
      isAuthenticated
          ? const PropertyHubScreen()
          : const GuestAuthPlaceholder(
              title: 'Agent Connect',
              subtitle:
                  'Log in to chat with agents, book inspections, and manage your deals.',
              icon: LucideIcons.messageSquare,
            ),
      isAuthenticated
          ? const VaultScreen()
          : const GuestAuthPlaceholder(
              title: 'Secure Vault',
              subtitle:
                  'Access your documents and financial records securely after signing in.',
              icon: LucideIcons.shieldCheck,
            ),
      isAuthenticated
          ? const UserProfileScreen()
          : const GuestAuthPlaceholder(
              title: 'Join SwiftSpace',
              subtitle:
                  'Create a profile to manage your preferences and start your property journey.',
              icon: LucideIcons.user,
            ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final prefs = Provider.of<UserPreferencesProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isMobile = Responsive.isMobile(context);
    final screens = _buildScreens(auth.isAuthenticated);

    return PopScope(
      canPop: prefs.currentTabIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          prefs.setTabIndex(0);
        }
      },
      child: Scaffold(
        appBar: prefs.currentTabIndex == 0
            ? null
            : AppBar(
                title: Text(
                  AppConstants.appName,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    letterSpacing: -1,
                    color: colorScheme.primary,
                  ),
                ),
                backgroundColor: colorScheme.surface,
                elevation: 0,
                actions: [
                  Consumer2<ChatProvider, NotificationProvider>(
                    builder: (context, chat, note, child) {
                      return Row(
                        children: [
                          BadgeIcon(
                            icon: LucideIcons.messageSquare,
                            count: chat.totalUnreadCount,
                            onPressed: () {
                              if (!auth.isAuthenticated) {
                                LoginSheet.show(context);
                                return;
                              }
                              // Navigate to chat/hub or show popup
                              prefs.setTabIndex(
                                2,
                              ); // Goes to Property Hub (Index 2)
                            },
                          ),
                          BadgeIcon(
                            icon: LucideIcons.bell,
                            count: note.unreadCount,
                            onPressed: () {
                              if (!auth.isAuthenticated) {
                                LoginSheet.show(context);
                                return;
                              }
                              // Show notification sheet
                              NotificationSheet.show(context);
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                      );
                    },
                  ),
                ],
              ),
        body: Row(
          children: [
            if (!isMobile)
              NavigationRail(
                selectedIndex: prefs.currentTabIndex,
                onDestinationSelected: (index) => prefs.setTabIndex(index),
                labelType: NavigationRailLabelType.all,
                backgroundColor: colorScheme.surface,
                selectedIconTheme: IconThemeData(color: colorScheme.primary),
                unselectedIconTheme: IconThemeData(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
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
                children: screens,
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
                unselectedItemColor: colorScheme.onSurface.withValues(
                  alpha: 0.5,
                ),
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 10,
                ),
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
      ),
    );
  }
}
