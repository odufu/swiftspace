import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/user_profile.dart';
import '../../../../core/error/app_exception.dart';

class AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signUp(email: email, password: password);
    } catch (e) {
      throw AppException.fromSupabase(e);
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw AppException.fromSupabase(e);
    }
  }

  /// Signs in with Google via Supabase OAuth on all platforms.
  /// - Web: redirects back to the current page origin.
  /// - Mobile (Android/iOS): redirects via deep link back into the app.
  /// No Firebase or google-services.json required.
  Future<void> signInWithGoogle() async {
    try {
      final redirectTo = kIsWeb
          ? Uri.base.origin
          : 'com.swiftspace.app://login-callback';

      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      // OAuth opens the browser; the session is restored via authStateChanges
      // once the user completes sign-in and is redirected back.
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException.fromSupabase(e);
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return UserProfile.fromJson(data);
    } catch (e) {
      // We don't throw here to allow null profiles for new users
      return null;
    }
  }

  Future<void> createUserProfile(UserProfile profile) async {
    try {
      await _client.from('profiles').upsert(profile.toJson());
    } catch (e) {
      throw AppException.fromSupabase(e);
    }
  }

  Future<void> updateUserRole(
    String userId,
    UserRole role, {
    bool? isVerified,
  }) async {
    try {
      final updates = {
        'role': role.name,
        if (isVerified != null) 'is_verified': isVerified,
      };
      await _client.from('profiles').update(updates).eq('id', userId);
    } catch (e) {
      throw AppException.fromSupabase(e);
    }
  }

  Future<String> uploadAvatar(String filePath, String userId) async {
    try {
      final file = File(filePath);
      final fileExt = filePath.split('.').last;
      final fileName =
          '$userId.${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final path = 'avatars/$fileName';

      await _client.storage.from('avatars').upload(path, file);
      return _client.storage.from('avatars').getPublicUrl(path);
    } catch (e) {
      throw AppException.fromSupabase(e);
    }
  }

  Future<String> uploadAvatarBytes(
    Uint8List bytes,
    String userId,
    String fileName,
  ) async {
    try {
      final path = 'avatars/$fileName';
      await _client.storage.from('avatars').uploadBinary(path, bytes);
      return _client.storage.from('avatars').getPublicUrl(path);
    } catch (e) {
      throw AppException.fromSupabase(e);
    }
  }

  Future<void> updateProfile(
    String userId, {
    String? fullName,
    String? avatarUrl,
  }) async {
    try {
      final updates = {
        if (fullName != null) 'full_name': fullName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };
      await _client.from('profiles').update(updates).eq('id', userId);
    } catch (e) {
      throw AppException.fromSupabase(e);
    }
  }

  Future<AuthResponse> verifyEmailOTP({
    required String email,
    required String token,
  }) async {
    try {
      return await _client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.signup,
      );
    } catch (e) {
      throw AppException.fromSupabase(e);
    }
  }

  Future<List<UserProfile>> getPendingProfessionalRequests() async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .neq('role', 'user')
          .eq('is_verified', false);

      return (data as List).map((json) => UserProfile.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching pending requests: $e');
      return [];
    }
  }

  Future<String> uploadDocument(
    String filePath,
    String userId,
    String docType,
  ) async {
    try {
      final file = File(filePath);
      final fileExt = filePath.split('.').last;
      final fileName =
          '$userId.${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final path = '$docType/$fileName';

      await _client.storage.from('documents').upload(path, file);
      return _client.storage.from('documents').getPublicUrl(path);
    } catch (e) {
      throw AppException.fromSupabase(e);
    }
  }

  Future<String> uploadDocumentBytes(
    Uint8List bytes,
    String userId,
    String docType,
    String fileName,
  ) async {
    try {
      final path = '$docType/$fileName';
      await _client.storage.from('documents').uploadBinary(path, bytes);
      return _client.storage.from('documents').getPublicUrl(path);
    } catch (e) {
      throw AppException.fromSupabase(e);
    }
  }

  Future<void> submitProfessionalApplication(UserProfile profile) async {
    try {
      final updates = {
        'full_name': profile.fullName,
        'years_experience': profile.yearsExperience,
        'government_id_url': profile.governmentIdUrl,
        'broker_license_url': profile.brokerLicenseUrl,
        'terms_accepted': profile.termsAccepted,
        'updated_at': DateTime.now().toIso8601String(),
      };
      await _client.from('profiles').update(updates).eq('id', profile.id);
    } catch (e) {
      throw AppException.fromSupabase(e);
    }
  }

  Future<void> updateProfessionalVerification(
    String userId,
    bool verified,
  ) async {
    try {
      await _client
          .from('profiles')
          .update({'is_verified': verified})
          .eq('id', userId);
    } catch (e) {
      throw AppException.fromSupabase(e);
    }
  }
}
