import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/user_profile.dart';
import '../../../../core/error/app_exception.dart';
import 'package:google_sign_in/google_sign_in.dart' as google_sign_in;

class AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // Native Google Sign-In helper
  bool _googleSignInInitialized = false;
  final google_sign_in.GoogleSignIn _googleSignIn = google_sign_in.GoogleSignIn.instance;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    
    await _googleSignIn.initialize(
      clientId: dotenv.get('GOOGLE_WEB_CLIENT_ID'),
      serverClientId: dotenv.get('GOOGLE_WEB_CLIENT_ID'), // serverClientId must be the Web Client ID on Android
    );
    _googleSignInInitialized = true;
  }

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

  /// Signs in with Google via Native SDK on Mobile and OAuth on Web.
  /// - Web: redirects back to the current page origin.
  /// - Mobile (Android/iOS): Uses native system dialog and ID token.
  Future<void> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        await _client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: kIsWeb ? Uri.base.toString().split('?').first : null,
          authScreenLaunchMode: LaunchMode.externalApplication,
        );
        return;
      }

      // Native Google Sign-In for Mobile (v7.0.0+ API)
      await _ensureGoogleSignInInitialized();
      final google_sign_in.GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
      if (googleUser == null) return; // User cancelled

      final google_sign_in.GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw AppException(
          'Google Sign-In failed: No ID Token received. Check SHA-1 registration and Web Client ID configuration.',
          code: 'no_id_token',
        );
      }

      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
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
          .single()
          .timeout(const Duration(seconds: 10));
      return UserProfile.fromJson(data);
    } catch (e) {
      debugPrint('AuthRepository: getUserProfile error: $e');
      // If it's a handshake/network error, we might want to know
      if (e.toString().toLowerCase().contains('handshake')) {
         debugPrint('AuthRepository: Handshake failure detected during profile load.');
      }
      // We don't throw here to allow null profiles for new users
      return null;
    }
  }

  Future<List<UserProfile>> getAllProfiles() async {
    try {
      final data = await _client
          .from('profiles')
          .select();
      
      final profiles = <UserProfile>[];
      for (final json in (data as List)) {
        try {
          profiles.add(UserProfile.fromJson(json));
        } catch (e) {
          debugPrint('Error parsing profile for user ${json['id']}: $e');
          // Still add a partial profile if possible or just skip
        }
      }
      return profiles;
    } catch (e) {
      throw AppException.fromSupabase(e);
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
      await _client
          .from('profiles')
          .update(updates)
          .eq('id', userId)
          .timeout(const Duration(seconds: 10));
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
    int? yearsExperience,
    String? governmentIdUrl,
    String? brokerLicenseUrl,
    bool? termsAccepted,
    String? phoneNumber,
    String? about,
    String? officeAddress,
    List<String>? specialties,
  }) async {
    try {
      final updates = {
        if (fullName != null) 'full_name': fullName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (yearsExperience != null) 'years_experience': yearsExperience,
        if (governmentIdUrl != null) 'government_id_url': governmentIdUrl,
        if (brokerLicenseUrl != null) 'broker_license_url': brokerLicenseUrl,
        if (termsAccepted != null) 'terms_accepted': termsAccepted,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (about != null) 'about': about,
        if (officeAddress != null) 'office_address': officeAddress,
        if (specialties != null) 'specialties': specialties,
      };

      // Remove keys with undefined values if they weren't explicitly passed
      if (yearsExperience == null) updates.remove('years_experience');
      if (fullName == null) updates.remove('full_name');
      if (avatarUrl == null) updates.remove('avatar_url');
      if (termsAccepted == null) updates.remove('terms_accepted');
      if (phoneNumber == null) updates.remove('phone_number');
      if (about == null) updates.remove('about');
      if (officeAddress == null) updates.remove('office_address');
      if (specialties == null) updates.remove('specialties');

      await _client.from('profiles').update(updates).eq('id', userId);
    } catch (e) {
      throw AppException.fromSupabase(e);
    }
  }

  Future<void> updateUserStatus(String userId, {bool? isBlocked, bool? isVerified}) async {
    try {
      final updates = {
        if (isBlocked != null) 'is_blocked': isBlocked,
        if (isVerified != null) 'is_verified': isVerified,
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
      debugPrint('Supabase Upload Error (File): $e');
      throw AppException.fromSupabase(e);
    }
  }

  Future<String> uploadDocumentBytes(
    Uint8List bytes,
    String userId,
    String docType,
    String originalName,
  ) async {
    try {
      final fileExt = originalName.split('.').last;
      final fileName = '$userId.${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final path = '$docType/$fileName';
      
      await _client.storage.from('documents').uploadBinary(path, bytes);
      return _client.storage.from('documents').getPublicUrl(path);
    } catch (e) {
      debugPrint('Supabase Upload Error (Bytes): $e');
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
