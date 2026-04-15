import 'package:flutter/material.dart';
import '../models/property.dart';
import 'property_provider.dart';

class VerificationProvider extends ChangeNotifier {
  final PropertyProvider _propertyProvider;

  VerificationProvider(this._propertyProvider);

  // Get all properties that are awaiting admin review
  List<Property> get pendingVerifications {
    return _propertyProvider.properties.where((p) => 
      p.verificationStatus == PropertyVerificationStatus.pendingReview
    ).toList();
  }

  // Agent submits documents for a property
  void submitForVerification(String propertyId, List<LegalDocument> newDocs) {
    final propIndex = _propertyProvider.properties.indexWhere((p) => p.id == propertyId);
    if (propIndex == -1) return;

    final property = _propertyProvider.properties[propIndex];
    
    // Merge new docs with existing ones
    final updatedDocs = List<LegalDocument>.from(property.legalDocuments);
    updatedDocs.addAll(newDocs.map((doc) => LegalDocument(
      title: doc.title,
      documentType: doc.documentType,
      verificationDate: DateTime.now(),
      status: LegalDocumentStatus.pending,
      url: doc.url,
    )));

    // Update property status
    final updatedProperty = property.copyWith(
      legalDocuments: updatedDocs,
      verificationStatus: PropertyVerificationStatus.pendingReview,
      isVerified: false, // Overall verification drops to false until admin reviews
    );

    _propertyProvider.updateProperty(updatedProperty);
    notifyListeners();
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
    final propIndex = _propertyProvider.properties.indexWhere((p) => p.id == propertyId);
    if (propIndex == -1) return;

    final property = _propertyProvider.properties[propIndex];
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
    notifyListeners();
  }

  // Admin marks property as fraud
  void adminMarkFraud(String propertyId) {
    final propIndex = _propertyProvider.properties.indexWhere((p) => p.id == propertyId);
    if (propIndex == -1) return;

    final property = _propertyProvider.properties[propIndex];
    final updatedProperty = property.copyWith(
      verificationStatus: PropertyVerificationStatus.fraudBlocked,
      isActive: false, // Deactivate
      isVerified: false,
    );

    _propertyProvider.updateProperty(updatedProperty);
    notifyListeners();
  }
}
