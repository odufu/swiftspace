import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:swiftspace/main.dart';
import 'package:swiftspace/features/auth/presentation/state/auth_provider.dart';
import 'package:swiftspace/features/auth/presentation/pages/role_selection_screen.dart';
import 'package:swiftspace/features/auth/presentation/pages/operations/operations_dashboard.dart';
import 'package:swiftspace/features/auth/presentation/state/admin_provider.dart';
import 'package:swiftspace/features/auth/presentation/pages/super_admin_dashboard.dart';
import 'package:swiftspace/features/auth/domain/models/user_profile.dart';
import 'package:swiftspace/core/constants/app_constants.dart';
import 'package:swiftspace/core/services/audio_manager.dart';
import 'package:swiftspace/core/di/injection_container.dart';
import 'package:swiftspace/core/utils/ui_utils.dart';
import 'package:swiftspace/core/utils/responsive.dart';

class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLogin = true;
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() => _isLogin = !_isLogin);
    _animController.reset();
    _animController.forward();
    sl<AudioManager>().playClick(context);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    sl<AudioManager>().playClick(context);

    try {
      if (_isLogin) {
        await authProvider.login(_emailController.text, _passwordController.text);
        if (mounted && authProvider.isAuthenticated) {
          UiUtils.showSuccess(context, 'Signed in successfully!');
        }
      } else {
        await authProvider.signUp(_emailController.text, _passwordController.text);
        if (mounted && authProvider.isAuthenticated) {
          UiUtils.showSuccess(context, 'Account created successfully!');
        } else if (mounted) {
          UiUtils.showInfo(context, 'Please sign in with your new account.');
          setState(() => _isLogin = true);
        }
      }
      if (mounted && authProvider.isAuthenticated) {
        _handleSuccessfulAuth(authProvider);
      }
    } catch (e) {
      if (mounted) UiUtils.showError(context, e.toString());
    }
  }

  void _handleSuccessfulAuth(AuthProvider authProvider) {
    if (authProvider.profile == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      );
    } else {
      final role = authProvider.profile!.role;
      final isAdmin = role == UserRole.admin || role == UserRole.sadmin;
      if (isAdmin) {
        Provider.of<AdminProvider>(context, listen: false).fetchAllData();
      }
      final screen = isAdmin ? const OperationsDashboard() : const RoleSelectionScreen();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => screen),
        (route) => false,
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    sl<AudioManager>().playClick(context);
    try {
      await authProvider.signInWithGoogle();
      if (!kIsWeb && mounted && authProvider.isAuthenticated) {
        UiUtils.showSuccess(context, 'Signed in with Google successfully!');
        _handleSuccessfulAuth(authProvider);
      }
    } catch (e) {
      if (mounted) UiUtils.showError(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 1024) {
            return _buildDesktopLayout(authProvider);
          } else if (constraints.maxWidth >= 600) {
            return _buildTabletLayout(authProvider);
          } else {
            return _buildMobileLayout(authProvider);
          }
        },
      ),
    );
  }

  // ── Mobile: full-screen gradient form ─────────────────────────────────
  Widget _buildMobileLayout(AuthProvider authProvider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF121212), const Color(0xFF1A1A1A)]
              : [const Color(0xFFF8F9FA), Colors.white],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: _buildFormContent(theme, authProvider),
            ),
          ),
        ),
      ),
    );
  }

  // ── Tablet: floating card, centered on gradient background ─────────────
  Widget _buildTabletLayout(AuthProvider authProvider) {
    final theme = Theme.of(context);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A3A5C), Color(0xFF0D2137)],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              elevation: 24,
              shadowColor: Colors.black45,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: _buildFormContent(theme, authProvider),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Desktop: split-screen branding + form ─────────────────────────────
  Widget _buildDesktopLayout(AuthProvider authProvider) {
    final theme = Theme.of(context);
    return Row(
      children: [
        // Left branding panel
        Expanded(
          flex: 5,
          child: _buildBrandingPanel(),
        ),
        // Right form panel
        Expanded(
          flex: 4,
          child: Container(
            color: theme.colorScheme.surface,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: _buildFormContent(theme, authProvider),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandingPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A3A5C), Color(0xFF0B4F6C), Color(0xFF01BAEF)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -80,
            left: -80,
            child: _decorCircle(320, Colors.white.withValues(alpha: 0.04)),
          ),
          Positioned(
            bottom: -60,
            right: -60,
            child: _decorCircle(280, Colors.white.withValues(alpha: 0.06)),
          ),
          Positioned(
            top: 200,
            right: -40,
            child: _decorCircle(180, Colors.white.withValues(alpha: 0.04)),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(64),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(AppAssets.logo, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  AppConstants.appName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'The premium AI-powered real estate\nplatform for modern living.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 18,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 56),
                // Feature pills
                ...[
                  ('✦', 'AI-powered semantic property search'),
                  ('✦', 'Instant deal negotiation & booking'),
                  ('✦', 'Verified agents & secure transactions'),
                ].map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      children: [
                        Text(
                          item.$1,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item.$2,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _decorCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  // ── Shared form content ────────────────────────────────────────────────
  Widget _buildFormContent(ThemeData theme, AuthProvider authProvider) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isLogin ? LucideIcons.logIn : LucideIcons.userPlus,
              size: 48,
              color: AppColors.primaryLight,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            _isLogin ? 'Welcome Back' : 'Create Account',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _isLogin
                ? 'Sign in to your Swift Space account'
                : 'Join the premium real estate network',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: LucideIcons.mail,
            validator: (v) => v!.contains('@') ? null : 'Invalid email',
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _passwordController,
            label: 'Password',
            icon: LucideIcons.lock,
            isPassword: true,
            obscureText: _obscurePassword,
            onTogglePassword: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            validator: (v) => v!.length >= 6 ? null : 'Too short',
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: authProvider.isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: authProvider.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _isLogin ? 'Login' : 'Sign Up',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: _toggleAuthMode,
            child: Text(
              _isLogin
                  ? "Don't have an account? Sign Up"
                  : "Already have an account? Login",
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Divider(color: theme.dividerColor.withValues(alpha: 0.2))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(child: Divider(color: theme.dividerColor.withValues(alpha: 0.2))),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 56,
            child: OutlinedButton(
              onPressed: authProvider.isLoading ? null : _signInWithGoogle,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GoogleIcon(size: 22),
                  const SizedBox(width: 12),
                  const Text(
                    'Continue with Google',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? LucideIcons.eye : LucideIcons.eyeOff,
                  size: 20,
                ),
                onPressed: onTogglePassword,
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: theme.colorScheme.surface,
      ),
    );
  }
}

/// Pure-Flutter Google "G" logo — no network required.
class _GoogleIcon extends StatelessWidget {
  final double size;
  const _GoogleIcon({this.size = 24});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _GoogleGPainter());
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width / 2;

    _drawArc(canvas, cx, cy, r, -0.52, 1.60, const Color(0xFF4285F4));
    _drawArc(canvas, cx, cy, r, 1.08, 0.80, const Color(0xFF34A853));
    _drawArc(canvas, cx, cy, r, 1.88, 0.80, const Color(0xFFFBBC05));
    _drawArc(canvas, cx, cy, r, 2.68, 0.95, const Color(0xFFEA4335));
    canvas.drawCircle(Offset(cx, cy), r * 0.63, Paint()..color = Colors.white);
    final Paint barPaint = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTRB(cx, cy - r * 0.152, cx + r * 0.98, cy + r * 0.152),
      barPaint,
    );
  }

  void _drawArc(Canvas canvas, double cx, double cy, double r,
      double startAngle, double sweepAngle, Color color) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = r * 0.37
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.815),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
