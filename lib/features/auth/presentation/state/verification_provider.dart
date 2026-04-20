import 'package:flutter/material.dart';
import 'package:swiftspace/features/property/domain/entities/property.dart';
import 'package:swiftspace/features/property/presentation/state/property_provider.dart';
import 'package:swiftspace/features/auth/data/repositories/auth_repository.dart';
import 'package:swiftspace/features/auth/domain/models/user_profile.dart';

class VerificationProvider extends ChangeNotifier {
  final PropertyProvider _propertyProvider;
  final AuthRepository _authRepository;

  VerificationProvider(this._propertyProvider, this._authRepository);

  List<Property> get pendingVerifications {
    return _propertyProvider.properties.where((p) => 
      p.verificationStatus == PropertyVerificationStatus.pendingReview
    ).toList();
  }

  // List of pending professional requests fetched from Supabase
  List<UserProfile> _pendingRequests = [];
  bool _isRequestsLoading = false;

  List<UserProfile> get pendingRequests => List.unmodifiable(_pendingRequests);
  bool get isRequestsLoading => _isRequestsLoading;

  Future<void> loadPendingRequests() async {
    _isRequestsLoading = true;
    notifyListeners();

    try {
      _pendingRequests = await _authRepository.getPendingProfessionalRequests();
    } catch (e) {
      debugPrint('Error loading pending requests: $e');
    } finally {
      _isRequestsLoading = false;
      notifyListeners();
    }
  }

  Future<void> approveProfessional(String userId) async {
    try {
      // Upon approval, explicitly set role to AGENT and mark as VERIFIED
      await _authRepository.updateUserRole(userId, UserRole.agent, isVerified: true);
      _pendingRequests.removeWhere((a) => a.id == userId);
      debugPrint('SADMIN: User $userId APPROVED for agent status.');
      notifyListeners();
    } catch (e) {
      debugPrint('Error approving professional: $e');
    }
  }

  Future<void> rejectProfessional(String userId) async {
    try {
      await _authRepository.updateUserRole(userId, UserRole.user);
      _pendingRequests.removeWhere((a) => a.id == userId);
      debugPrint('SADMIN: User $userId REJECTED and reset to USER in Supabase.');
      notifyListeners();
    } catch (e) {
      debugPrint('Error rejecting professional: $e');
    }
  }

  // Agent submits documents for a property
  void submitForVerification(String propertyId, List<LegalDocument> newDocs) {
    try {
      final property = _propertyProvider.getPropertyById(propertyId);
      if (property == null) return;
      
      // Merge new docs with existing ones (ensure no duplicates by title for simplicity)
      final existingTitles = property.legalDocuments.map((d) => d.title).toSet();
      final filteredNewDocs = newDocs.where((doc) => !existingTitles.contains(doc.title)).toList();
      
      final updatedDocs = List<LegalDocument>.from(property.legalDocuments);
      updatedDocs.addAll(filteredNewDocs);

      // Update property status
      final updatedProperty = property.copyWith(
        legalDocuments: updatedDocs,
        verificationStatus: PropertyVerificationStatus.pendingReview,
        isVerified: false, 
      );

      _propertyProvider.updateProperty(updatedProperty);
      debugPrint('Verification: Submitting property $propertyId for review with ${newDocs.length} new docs.');
      notifyListeners();
    } catch (e) {
      debugPrint('Verification Error (submit): $e');
    }
  }

  // Admin verifies a single document
  void adminVerifyDocument(String propertyId, String docTitle) {
    _updateDocumentStatus(propertyId, docTitle, LegalDocumentStatus.verified, null);
  }

  // Admin rejects a single document
  void adminRejectDocument(String propertyId, String docTitle, String reason) {
    _updateDocumentStatus(propertyId, docTitle, LegalDocumentStatus.rejected, reason);
  }

  // Helper to update doc status and check if property should be fully verified
  void _updateDocumentStatus(String propertyId, String docTitle, LegalDocumentStatus status, String? feedback) {
    try {
      final property = _propertyProvider.getPropertyById(propertyId);
      if (property == null) return;

      final updatedDocs = property.legalDocuments.map((doc) {
        if (doc.title == docTitle) {
          return LegalDocument(
            title: doc.title,
            documentType: doc.documentType,
            verificationDate: DateTime.now(),
            url: doc.url,
            status: status,
            adminFeedback: feedback,
          );
        }
        return doc;
      }).toList();

      // Check overall status
      final hasPending = updatedDocs.any((d) => d.status == LegalDocumentStatus.pending);
      final hasRejected = updatedDocs.any((d) => d.status == LegalDocumentStatus.rejected);
      
      PropertyVerificationStatus newPropStatus = property.verificationStatus;
      bool isOverallVerified = property.isVerified;

      if (!hasPending && hasRejected) {
        newPropStatus = PropertyVerificationStatus.issuesFlagged;
        isOverallVerified = false;
      } else if (!hasPending && !hasRejected && updatedDocs.isNotEmpty) {
        newPropStatus = PropertyVerificationStatus.verified;
        isOverallVerified = true;
      }

      final updatedProperty = property.copyWith(
        legalDocuments: updatedDocs,
        verificationStatus: newPropStatus,
        isVerified: isOverallVerified,
      );

      _propertyProvider.updateProperty(updatedProperty);
      debugPrint('Verification: Document "$docTitle" for property $propertyId updated to ${status.name}. Overall status: ${newPropStatus.name}');
      notifyListeners();
    } catch (e) {
      debugPrint('Verification Error (doc update): $e');
    }
  }

  // Admin marks property as fraud
  void adminMarkFraud(String propertyId) {
    try {
      final property = _propertyProvider.getPropertyById(propertyId);
      if (property == null) return;

      final updatedProperty = property.copyWith(
        verificationStatus: PropertyVerificationStatus.fraudBlocked,
        isActive: false, 
        isVerified: false,
      );

      _propertyProvider.updateProperty(updatedProperty);
      debugPrint('Verification CAUTION: Property $propertyId marked as FRAUD.');
      notifyListeners();
    } catch (e) {
      debugPrint('Verification Error (fraud mark): $e');
    }
  }
}
