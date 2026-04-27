import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftspace/features/auth/presentation/state/auth_provider.dart';
import 'package:swiftspace/features/auth/presentation/pages/role_selection_screen.dart';
import 'package:swiftspace/features/auth/presentation/pages/onboarding_screen.dart';
import 'package:swiftspace/features/auth/presentation/pages/super_admin_dashboard.dart';
import 'package:swiftspace/core/services/audio_manager.dart';
import 'package:swiftspace/features/auth/domain/models/user_profile.dart';
import 'package:swiftspace/core/di/injection_container.dart';
import 'package:swiftspace/features/auth/presentation/pages/operations/operations_dashboard.dart';
import 'package:swiftspace/features/auth/presentation/state/admin_provider.dart';
import 'package:swiftspace/core/services/connectivity_service.dart';
import 'package:swiftspace/features/auth/presentation/pages/no_internet_screen.dart';
import 'package:swiftspace/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:swiftspace/core/constants/app_constants.dart';
import 'package:swiftspace/main.dart';
import 'package:swiftspace/features/agent/presentation/pages/professional_dashboard_screen.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _animController.forward();

    // Play boot sound and haptics after a tiny delay to ensure Provider is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sl<AudioManager>().playBoot(context);
      sl<AudioManager>().triggerHeavyHaptic(context);
    });

    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // 1. Check Connectivity First
    final connectivity = sl<ConnectivityService>();
    final hasInternet = await connectivity.hasInternet();

    if (!hasInternet) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => NoInternetScreen(
              onRetry: () {
                // Restart navigation check
                _checkAuthAndNavigate();
              },
            ),
          ),
        );
      }
      return;
    }

    // 2. We skip Supabase initialization here as it's now handled by RootApp in main.dart


    // Wait for the animation + artificial delay
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isAuthenticated) {
      if (authProvider.profile == null) {
        // Logged in but no profile (role) yet?
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
        );
      } else {
        final role = authProvider.profile!.role;
        final isAdmin = role == UserRole.admin || role == UserRole.sadmin;

        if (isAdmin) {
          Provider.of<AdminProvider>(context, listen: false).fetchAllData();
        }

        Widget screen;
        if (isAdmin) {
          screen = const OperationsDashboard();
        } else if (role == UserRole.user) {
          screen = const MainLayout();
        } else {
          screen = const ProfessionalDashboardScreen();
        }

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 800),
            pageBuilder: (_, _, _) => screen,
            transitionsBuilder: (_, animation, _, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    } else {
      // Guest Browsing: Navigate to MainLayout instead of OnboardingScreen
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, _, _) => const MainLayout(),
          transitionsBuilder: (_, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryLight, // SwiftSpace Primary
      body: Center(
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnim.value,
              child: Opacity(
                opacity: _fadeAnim.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            AppAssets.logo,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      AppConstants.appName,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
