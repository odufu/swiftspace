import 'dart:async';
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

  Future<void> _loadProfile(String userId) async {
    _isLoading = true;
    notifyListeners();

    _profile = await _repository.getUserProfile(userId);
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _repository.signIn(email: email, password: password);
    } finally {
      _isLoading = false;
      notifyListeners();
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
    _isLoading = true;
    notifyListeners();
    
    try {
      final isVerified = (role == UserRole.agent) ? false : true;
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
    required String governmentIdPath,
    required String brokerLicensePath,
  }) async {
    if (_user == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Upload Documents to specialized folders
      final govIdUrl = await _repository.uploadDocument(governmentIdPath, _user!.id, 'id_cards');
      final licenseUrl = await _repository.uploadDocument(brokerLicensePath, _user!.id, 'licences');

      // 2. Wrap into Profile object
      final updatedProfile = _profile!.copyWith(
        fullName: fullName,
        yearsExperience: yearsExperience,
        governmentIdUrl: govIdUrl,
        brokerLicenseUrl: licenseUrl,
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

  Future<void> updateProfile({String? fullName, String? imagePath}) async {
    if (_user == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      String? avatarUrl;
      if (imagePath != null) {
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
