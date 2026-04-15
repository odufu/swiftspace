import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../models/property.dart';

class FavoritesProvider extends ChangeNotifier {
  final List<String> _favoriteIds = [];

  List<String> get favoriteIds => _favoriteIds;

  FavoritesProvider() {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('favorite_properties') ?? [];
    _favoriteIds.addAll(saved);
    notifyListeners();
  }

  Future<void> toggleFavorite(Property property) async {
    final prefs = await SharedPreferences.getInstance();
    if (_favoriteIds.contains(property.id)) {
      _favoriteIds.remove(property.id);
    } else {
      _favoriteIds.add(property.id);
      
      // Async media cache pulling when loved! 
      if (property.videoUrl != null) {
        DefaultCacheManager().downloadFile(property.videoUrl!).catchError((e) { 
          debugPrint('Video cache error: $e'); 
          throw e; // or we can just omit catchError, unhandled async doesn't crash the app here, it's just a future. Let's just use try-catch inside an async operation wrapper.
        });
      }
      if (property.panoramaUrl != null) {
        DefaultCacheManager().downloadFile(property.panoramaUrl!).catchError((e) {
          debugPrint('Panorama cache error: $e');
          throw e;
        });
      }
    }
    await prefs.setStringList('favorite_properties', _favoriteIds);
    notifyListeners();
  }

  bool isFavorite(String id) {
    return _favoriteIds.contains(id);
  }
}
