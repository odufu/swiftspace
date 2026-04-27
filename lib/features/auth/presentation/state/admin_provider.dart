import 'package:flutter/material.dart';
import 'package:swiftspace/features/auth/domain/models/user_profile.dart';
import 'package:swiftspace/features/auth/data/repositories/auth_repository.dart';
import 'package:swiftspace/features/property/presentation/state/property_provider.dart';

class AdminProvider with ChangeNotifier {
  final AuthRepository _authRepository;
  final PropertyProvider _propertyProvider;

  List<UserProfile> _allUsers = [];
  bool _isLoading = false;
  String? _error;

  AdminProvider(this._authRepository, this._propertyProvider) {
    fetchAllData();
  }

  List<UserProfile> get allUsers => _allUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filtered lists
  List<UserProfile> get realtors => _allUsers.where((u) => 
    // Any role that isn't a standard 'user' is considered a realtor/pro or applicant
    u.role != UserRole.user || 
    (u.governmentIdUrl != null || u.brokerLicenseUrl != null)
  ).toList();

  List<UserProfile> get regularUsers => _allUsers.where((u) => 
    u.role == UserRole.user && 
    (u.governmentIdUrl == null && u.brokerLicenseUrl == null)
  ).toList();

  Future<void> fetchAllData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allUsers = await _authRepository.getAllProfiles();
      // Ensure properties are loaded as well for stats
      await _propertyProvider.fetchProperties();
    } catch (e) {
      _error = e.toString();
      debugPrint('AdminProvider Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleUserStatus(String userId, bool block) async {
    try {
      await _authRepository.updateUserStatus(userId, isBlocked: block);
      final index = _allUsers.indexWhere((u) => u.id == userId);
      if (index != -1) {
        // UserProfile now has isBlocked field, so we update the local state and refresh
        await fetchAllData();
      }
    } catch (e) {
      debugPrint('Error toggling user status: $e');
    }
  }

  // Dashboard Stats
  int get totalUsers => _allUsers.length;
  int get totalRealtors => realtors.length;
  int get totalProperties => _propertyProvider.totalProperties;
  int get pendingVerifications => _allUsers.where((u) => !u.isVerified && u.role != UserRole.user).length;
}
