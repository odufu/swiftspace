import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../agent/presentation/pages/agent_dashboard_screen.dart';
import 'package:swiftspace/main.dart';
import '../state/auth_provider.dart';
import 'role_selection_screen.dart';
import 'super_admin_dashboard.dart';
import '../../domain/models/user_profile.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/audio_manager.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/ui_utils.dart';

class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> with SingleTickerProviderStateMixin {
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
    setState(() {
      _isLogin = !_isLogin;
    });
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
        if (authProvider.profile == null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
          );
        } else {
          final role = authProvider.profile!.role;
          final isProfessional = role == UserRole.agent || 
                               role == UserRole.owner || 
                               role == UserRole.developer || 
                               role == UserRole.company;

          final screen = role == UserRole.sadmin
              ? const SuperAdminDashboard()
              : (isProfessional ? const AgentDashboardScreen() : const MainLayout());

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => screen),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        UiUtils.showError(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Container(
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
                child: _buildAuthView(theme, authProvider),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthView(ThemeData theme, AuthProvider authProvider) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
          ),
          const SizedBox(height: 8),
          Text(
            _isLogin 
                ? 'Sign in to your Swift Space account' 
                : 'Join the premium real estate network',
            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 48),
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
            onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
            validator: (v) => v!.length >= 6 ? null : 'Too short',
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: authProvider.isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: authProvider.isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(_isLogin ? 'Login' : 'Sign Up', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: _toggleAuthMode,
            child: Text(
              _isLogin ? "Don't have an account? Sign Up" : "Already have an account? Login",
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
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
      textAlign: TextAlign.start,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: isPassword 
            ? IconButton(
                icon: Icon(obscureText ? LucideIcons.eye : LucideIcons.eyeOff, size: 20),
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
