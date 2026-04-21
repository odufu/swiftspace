import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftspace/core/di/injection_container.dart';
import 'package:swiftspace/core/services/cloudinary_service.dart';
import '../../domain/entities/property.dart';
import '../../data/repositories/property_repository.dart';

class PropertyProvider extends ChangeNotifier {
  final PropertyRepository _repository;
  final CloudinaryService _cloudinary = sl<CloudinaryService>();
  
  List<Property> _properties = [];
  bool _isLoading = false;
  String? _error;

  // Background Upload State
  final Map<String, double> _uploadProgress = {};
  final Map<String, String> _uploadedUrls = {};
  final Map<String, String> _uploadErrors = {};
  final Map<String, Future<void>> _activeUploadTasks = {}; // Added for synchronization
  String _activePropertyId = const Uuid().v4();

  PropertyProvider({PropertyRepository? repository}) 
      : _repository = repository ?? PropertyRepository(Supabase.instance.client) {
    fetchProperties();
    _loadDraft();
  }

  List<Property> get properties => _properties;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Map<String, double> get uploadProgress => _uploadProgress;
  Map<String, String> get uploadedUrls => _uploadedUrls;
  bool get isUploading => _uploadProgress.values.any((p) => p < 1.0 && p > 0);

  // Restored Getters
  List<Property> get myProperties => _properties; // In a full app, this might filter by current user
  List<Property> get liveProperties => _properties.where((p) => !p.isTest).toList();
  List<Property> get testProperties => _properties.where((p) => p.isTest).toList();

  // Statistics for the dashboard
  int get totalProperties => _properties.length;
  int get activeProperties => _properties.where((p) => p.isActive).length;
  int get verifiedProperties => _properties.where((p) => p.isVerified).length;

  Future<void> fetchProperties() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _properties = await _repository.getProperties(includeTest: true);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching properties: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Background Media Uploads ---

  Future<void> startUpload(XFile file, {bool isVideo = false}) async {
    final identifier = file.path;
    
    // If already uploaded or uploading, don't start a new one
    if (_uploadedUrls.containsKey(identifier) || _activeUploadTasks.containsKey(identifier)) {
      debugPrint('Upload already in progress or finished for: $identifier');
      return;
    }

    _uploadProgress[identifier] = 0.01; 
    notifyListeners();

    final uploadFuture = _performUpload(file, isVideo);
    _activeUploadTasks[identifier] = uploadFuture;
    
    await uploadFuture;
    _activeUploadTasks.remove(identifier);
    notifyListeners();
  }

  Future<void> _performUpload(XFile file, bool isVideo) async {
    final identifier = file.path;
    try {
      final folder = 'properties/$_activePropertyId';
      final url = await _cloudinary.uploadMedia(
        file: file,
        folder: folder,
        isVideo: isVideo,
        onProgress: (progress) {
          _uploadProgress[identifier] = progress;
          notifyListeners();
        },
      );

      if (url != null) {
        _uploadedUrls[identifier] = url;
        _uploadProgress[identifier] = 1.0;
        debugPrint('Upload Success: $identifier -> $url');
      } else {
        _uploadErrors[identifier] = 'Failed to upload';
        _uploadProgress[identifier] = 0.0;
        debugPrint('Upload Failed (Null URL): $identifier');
      }
    } catch (e) {
      _uploadErrors[identifier] = e.toString();
      _uploadProgress[identifier] = 0.0;
      debugPrint('Upload Error Exception: $e');
    }
    _saveDraft();
  }

  void removeMedia(String identifier) {
    _uploadProgress.remove(identifier);
    _uploadedUrls.remove(identifier);
    _uploadErrors.remove(identifier);
    _activeUploadTasks.remove(identifier);
    notifyListeners();
    _saveDraft();
  }

  // --- Draft Management ---

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draftData = {
      'propertyId': _activePropertyId,
      'uploadedUrls': _uploadedUrls,
      'mediaPaths': _uploadProgress.keys.toList(),
    };
    await prefs.setString('property_draft', jsonEncode(draftData));
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draftStr = prefs.getString('property_draft');
    if (draftStr != null) {
      try {
        final data = jsonDecode(draftStr);
        _activePropertyId = data['propertyId'];
        if (data['uploadedUrls'] != null) {
          _uploadedUrls.addAll(Map<String, String>.from(data['uploadedUrls']));
          for (var url in _uploadedUrls.values) {
            final key = _uploadedUrls.keys.firstWhere((k) => _uploadedUrls[k] == url, orElse: () => '');
            if (key.isNotEmpty) _uploadProgress[key] = 1.0;
          }
        }
        notifyListeners();
      } catch (e) {
        debugPrint('Error loading draft: $e');
      }
    }
  }

  Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('property_draft');
    _activePropertyId = const Uuid().v4();
    _uploadProgress.clear();
    _uploadedUrls.clear();
    _uploadErrors.clear();
    _activeUploadTasks.clear();
    notifyListeners();
  }

  // --- Property Creation ---

  Future<bool> createProperty({
    required Property property,
    required List<XFile> images,
    required String listerId,
    XFile? video,
    XFile? planImage,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('Starting Property Creation for ${images.length} images...');
      
      // 1. Gather all tasks that must be finished (either already running or to be started)
      final List<Future<void>> requiredTasks = [];

      void addOrWait(XFile? file, {bool isVideo = false}) {
        if (file == null) return;
        final path = file.path;
        
        if (_uploadedUrls.containsKey(path)) {
           debugPrint('File already uploaded: $path');
           return;
        }

        if (_activeUploadTasks.containsKey(path)) {
          debugPrint('Waiting for existing upload: $path');
          requiredTasks.add(_activeUploadTasks[path]!);
        } else {
          debugPrint('Starting new upload for creation: $path');
          requiredTasks.add(startUpload(file, isVideo: isVideo));
        }
      }

      for (var img in images) addOrWait(img);
      addOrWait(video, isVideo: true);
      addOrWait(planImage);

      // 2. Wait for all relevant uploads to complete
      if (requiredTasks.isNotEmpty) {
        debugPrint('Waiting for ${requiredTasks.length} active upload tasks...');
        await Future.wait(requiredTasks);
      }

      // 3. Final verification of URLs
      final imageUrls = images.map((img) => _uploadedUrls[img.path]).whereType<String>().toList();
      
      if (imageUrls.isEmpty) {
        debugPrint('Final Verification Failed. Uploaded Map: $_uploadedUrls');
        debugPrint('Selected Image Paths: ${images.map((img) => img.path).toList()}');
        throw Exception('No images were successfully uploaded. Please try again.');
      }

      final videoUrl = video != null ? _uploadedUrls[video.path] : null;
      final planUrl = planImage != null ? _uploadedUrls[planImage.path] : null;

      final finalProperty = property.copyWith(
        id: _activePropertyId,
        imageUrl: imageUrls.first,
        imagesGallery: imageUrls,
        videoUrl: videoUrl,
        hasVideo: videoUrl != null,
        planImageUrl: planUrl,
        verificationStatus: PropertyVerificationStatus.pendingReview,
        listerId: listerId,
      );

      await _repository.insertProperty(finalProperty);
      _properties.insert(0, finalProperty);
      await clearDraft();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Property Creation Error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  // --- Helper Methods ---

  void toggleFavorite(String propertyId) {
    final index = _properties.indexWhere((p) => p.id == propertyId);
    if (index != -1) {
      _properties[index] = _properties[index].copyWith(
        favoritesCount: _properties[index].favoritesCount + 1,
      );
      notifyListeners();
    }
  }

  Property? getPropertyById(String id) {
    try {
      return _properties.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  void incrementViews(String id) {
    final index = _properties.indexWhere((p) => p.id == id);
    if (index != -1) {
      _properties[index] = _properties[index].copyWith(
        viewsCount: _properties[index].viewsCount + 1,
      );
      notifyListeners();
    }
  }

  void incrementVideoViews(String id) {
    final index = _properties.indexWhere((p) => p.id == id);
    if (index != -1) {
      _properties[index] = _properties[index].copyWith(
        videoViewsCount: _properties[index].videoViewsCount + 1,
      );
      notifyListeners();
    }
  }

  void updateFavoritesCount(String id, int count) {
    final index = _properties.indexWhere((p) => p.id == id);
    if (index != -1) {
      _properties[index] = _properties[index].copyWith(
        favoritesCount: count,
      );
      notifyListeners();
    }
  }

  void updateProperty(Property updatedProperty) {
    final index = _properties.indexWhere((p) => p.id == updatedProperty.id);
    if (index != -1) {
      _properties[index] = updatedProperty;
      notifyListeners();
    }
  }

  void togglePropertyStatus(String id) {
    final index = _properties.indexWhere((p) => p.id == id);
    if (index != -1) {
      _properties[index] = _properties[index].copyWith(
        isActive: !_properties[index].isActive,
      );
      notifyListeners();
    }
  }

  void deleteProperty(String id) {
    _properties.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}
