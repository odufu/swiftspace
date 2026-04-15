import 'package:flutter/material.dart';
import 'package:swiftspace/features/property/domain/entities/property.dart';

class PropertyProvider with ChangeNotifier {
  List<Property> _properties = [];

  PropertyProvider() {
    // Initialize with mock data
    _properties = List.from(mockProperties);
  }

  List<Property> get properties {
    return _properties
        .where((p) => p.verificationStatus != PropertyVerificationStatus.fraudBlocked)
        .toList();
  }

  List<Property> get myProperties {
    // For this mock app, we'll assume the currently logged in agent 
    // is one of the listers. We'll just return all for demonstration 
    // or filter by a specific name if needed.
    return _properties;
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
}
