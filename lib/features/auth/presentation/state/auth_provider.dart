import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/user_profile.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../../core/di/injection_container.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository = sl<AuthRepository>();
  
  User? _user;
  UserProfile? _profile;
  bool _isLoading = true;
  bool _isWaitingForVerification = false;
  StreamSubscription<AuthState>? _authStateSubscription;

  User? get user => _user;
  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isWaitingForVerification => _isWaitingForVerification;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _init();
  }

  void _init() {
    _user = _repository.currentUser;
    if (_user != null) {
      _loadProfile(_user!.id);
    } else {
      _isLoading = false;
      notifyListeners();
    }

    _authStateSubscription = _repository.authStateChanges.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      _user = session?.user;

      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.tokenRefreshed) {
        if (_user != null) {
          _loadProfile(_user!.id);
        }
      } else if (event == AuthChangeEvent.signedOut) {
        _profile = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> _loadProfile(String userId, {bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      _profile = await _repository.getUserProfile(userId);
      
      // Auto-sync Google avatar if missing in profile record
      if (_profile != null && _profile!.avatarUrl == null && _user != null) {
        final googleAvatar = _user!.userMetadata?['avatar_url'] as String?;
        if (googleAvatar != null) {
          await _repository.updateProfile(_user!.id, avatarUrl: googleAvatar);
          _profile = _profile!.copyWith(avatarUrl: googleAvatar);
        }
      }
    } finally {
      if (showLoading) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _repository.signIn(email: email, password: password);
      // Explicitly wait for profile to load before completing login task
      if (response.user != null) {
        _user = response.user;
        await _loadProfile(response.user!.id, showLoading: false);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _repository.signInWithGoogle();
      // On mobile, the browser opens and the session comes back via authStateChanges.
      // Loading state will be cleared by _init() when the auth event fires.
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signUp(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _repository.signUp(email: email, password: password);
      if (response.user != null) {
        _isWaitingForVerification = false; // Disabled by user request
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
  }

  Future<void> updateRole(UserRole role) async {
    if (_user == null) return;
    
    // Prevent Admins/Sadmins from accidentally downgrading themselves
    if (_profile?.role == UserRole.admin || _profile?.role == UserRole.sadmin) {
      if (role != UserRole.admin && role != UserRole.sadmin) {
        debugPrint('AUTH: Blocked role downgrade for Admin/Sadmin.');
        return;
      }
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Preserve verification status if already verified, otherwise reset for new agents
      final bool alreadyVerified = _profile?.isVerified ?? false;
      final isVerified = alreadyVerified || (role != UserRole.agent);
      
      await _repository.updateUserRole(_user!.id, role, isVerified: isVerified);
      _profile = _profile?.copyWith(role: role, isVerified: isVerified) ?? UserProfile(
        id: _user!.id,
        email: _user!.email!,
        role: role,
        isVerified: isVerified,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitApplication({
    required String fullName,
    required int yearsExperience,
    String? governmentIdPath,
    Uint8List? governmentIdBytes,
    String? govIdFileName,
    String? brokerLicensePath,
    Uint8List? brokerLicenseBytes,
    String? licenseFileName,
  }) async {
    if (_user == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Upload Documents (Handle both path/mobile and bytes/web)
      String? govIdUrl;
      if (kIsWeb && governmentIdBytes != null) {
        govIdUrl = await _repository.uploadDocumentBytes(governmentIdBytes, _user!.id, 'id_cards', govIdFileName ?? 'gov_id.jpg');
      } else if (governmentIdPath != null) {
        govIdUrl = await _repository.uploadDocument(governmentIdPath, _user!.id, 'id_cards');
      }

      String? licenseUrl;
      if (kIsWeb && brokerLicenseBytes != null) {
        licenseUrl = await _repository.uploadDocumentBytes(brokerLicenseBytes, _user!.id, 'licences', licenseFileName ?? 'license.jpg');
      } else if (brokerLicensePath != null) {
        licenseUrl = await _repository.uploadDocument(brokerLicensePath, _user!.id, 'licences');
      }

      // 2. Wrap into Profile object
      final updatedProfile = _profile!.copyWith(
        fullName: fullName,
        yearsExperience: yearsExperience,
        governmentIdUrl: govIdUrl ?? _profile?.governmentIdUrl,
        brokerLicenseUrl: licenseUrl ?? _profile?.brokerLicenseUrl,
        termsAccepted: true,
      );

      // 3. Persist to DB
      await _repository.submitProfessionalApplication(updatedProfile);
      
      // 4. Update local state
      _profile = updatedProfile;
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    String? fullName, 
    String? imagePath,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    if (_user == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      String? avatarUrl;
      if (kIsWeb && imageBytes != null) {
        avatarUrl = await _repository.uploadAvatarBytes(imageBytes, _user!.id, imageName ?? 'avatar.jpg');
      } else if (imagePath != null) {
        avatarUrl = await _repository.uploadAvatar(imagePath, _user!.id);
      }

      await _repository.updateProfile(_user!.id, fullName: fullName, avatarUrl: avatarUrl);
      
      _profile = _profile?.copyWith(
        fullName: fullName ?? _profile?.fullName,
        avatarUrl: avatarUrl ?? _profile?.avatarUrl,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
