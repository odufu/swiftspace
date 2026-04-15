import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'theme_provider.dart';
import 'providers/favorites_provider.dart';
import 'screens/explore_screen.dart';
import 'screens/saved_screen.dart';
import 'screens/user_profile_screen.dart';
import 'providers/user_preferences_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/chat_provider.dart';
import 'services/audio_manager.dart';
import 'screens/splash_screen.dart';
import 'screens/property_hub_screen.dart';
import 'providers/property_provider.dart';
import 'providers/negotiation_provider.dart';
import 'providers/verification_provider.dart';
import 'providers/savings_provider.dart';
import 'screens/savings_screen.dart';

import 'dart:ui';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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

  AudioManager().init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => UserPreferencesProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => PropertyProvider()),
        ChangeNotifierProvider(create: (_) => NegotiationProvider()),
        ChangeNotifierProvider(create: (_) => SavingsProvider()),
        ChangeNotifierProxyProvider<PropertyProvider, VerificationProvider>(
          create: (context) => VerificationProvider(Provider.of<PropertyProvider>(context, listen: false)),
          update: (context, propertyProvider, previous) => previous ?? VerificationProvider(propertyProvider),
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
      title: 'Swift Space',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF0F5A3F), // Dark green primary
          secondary: Color(0xFF168153),
          surface: Colors.white,
          onSurface: Color(0xFF1E1E1E),
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1EB476), // Lighter green for dark mode accessibility
          secondary: Color(0xFF168153),
          surface: Color(0xFF1E1E1E),
          onSurface: Colors.white,
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
    
    return Scaffold(
      body: IndexedStack(
        index: prefs.currentTabIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
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
            label: 'EXPLORE',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.heart),
            label: 'FAVORITE',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.layoutDashboard),
            label: 'HUB',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.landmark),
            label: 'VAULT',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.user),
            label: 'PROFILE',
          ),
        ],
      ),
    );
  }
}
