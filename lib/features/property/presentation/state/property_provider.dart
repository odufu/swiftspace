import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/property.dart';
import '../../data/repositories/property_repository.dart';

class PropertyProvider extends ChangeNotifier {
  final PropertyRepository _repository;
  
  List<Property> _properties = [];
  bool _isLoading = false;
  String? _error;

  PropertyProvider({PropertyRepository? repository}) 
      : _repository = repository ?? PropertyRepository(Supabase.instance.client) {
    fetchProperties();
  }

  List<Property> get properties => _properties;
  List<Property> get myProperties => _properties;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filtered lists
  List<Property> get liveProperties => _properties.where((p) => !p.isTest).toList();
  List<Property> get testProperties => _properties.where((p) => p.isTest).toList();

  Future<void> fetchProperties() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _properties = await _repository.getProperties(includeTest: true);
    } catch (e) {
      _error = e.toString();
      // On error, we might want to show some notification
      debugPrint('Error fetching properties: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleFavorite(String propertyId) {
    try {
      final index = _properties.indexWhere((p) => p.id == propertyId);
      if (index != -1) {
        // In a real app, this would call the repository
        _properties[index] = _properties[index].copyWith(
          favoritesCount: _properties[index].favoritesCount + 1,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
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

  // Statistics for the dashboard
  int get totalProperties => _properties.length;
  int get activeProperties => _properties.where((p) => p.isActive).length;
  int get verifiedProperties => _properties.where((p) => p.isVerified).length;

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

  void updateFavoritesCount(String id, int count) {
    final index = _properties.indexWhere((p) => p.id == id);
    if (index != -1) {
      _properties[index] = _properties[index].copyWith(
        favoritesCount: count,
      );
      notifyListeners();
    }
  }
}
