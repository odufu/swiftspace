import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:swiftspace/features/property/domain/entities/property.dart';

class FavoritesProvider extends ChangeNotifier {
  final List<String> _favoriteIds = [];
  String? _userId;

  List<String> get favoriteIds => _favoriteIds;

  FavoritesProvider() {
    _loadFavorites();
  }

  // Hook for ChangeNotifierProxyProvider to detect login changes
  void updateUser(String? newUserId) {
    if (_userId != newUserId) {
      _userId = newUserId;
      if (_userId != null) {
        _syncWithSupabase();
      } else {
        // Clear local memory when logged out
        _favoriteIds.clear();
        SharedPreferences.getInstance().then((prefs) => 
            prefs.remove('favorite_properties'));
        notifyListeners();
      }
    }
  }

  Future<void> _syncWithSupabase() async {
    if (_userId == null) return;
    try {
      final response = await Supabase.instance.client
          .from('user_favorites')
          .select('property_id')
          .eq('user_id', _userId!);
          
      final Set<String> cloudIds = response.map((row) => row['property_id'].toString()).toSet();
      
      // Merge with any offline local favorites we clicked before login
      final prefs = await SharedPreferences.getInstance();
      final localSaved = prefs.getStringList('favorite_properties') ?? [];
      
      final Set<String> merged = {...localSaved, ...cloudIds};
      
      _favoriteIds.clear();
      _favoriteIds.addAll(merged);
      await prefs.setStringList('favorite_properties', _favoriteIds);
      notifyListeners();
      
      // Clean up orphaned locals to cloud
      for (var local in localSaved) {
        if (!cloudIds.contains(local)) {
           _pushToggleToSupabase(local, true);
        }
      }
    } catch (e) {
      debugPrint('Failed to sync favorites from Supabase: $e');
    }
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('favorite_properties') ?? [];
    _favoriteIds.addAll(saved);
    notifyListeners();
  }

  Future<void> toggleFavorite(Property property) async {
    final prefs = await SharedPreferences.getInstance();
    final bool isAdding = !_favoriteIds.contains(property.id);
    
    if (isAdding) {
      _favoriteIds.add(property.id);
      
      // Async media cache pulling when loved! 
      if (property.videoUrl != null) {
        DefaultCacheManager().downloadFile(property.videoUrl!).catchError((e) { 
          debugPrint('Video cache error: $e'); 
        });
      }
      if (property.panoramaUrl != null) {
        DefaultCacheManager().downloadFile(property.panoramaUrl!).catchError((e) {
          debugPrint('Panorama cache error: $e');
        });
      }
    } else {
      _favoriteIds.remove(property.id);
    }
    
    await prefs.setStringList('favorite_properties', _favoriteIds);
    notifyListeners();
    
    // Asynchronously push this action to the cloud safely!
    _pushToggleToSupabase(property.id, isAdding);
  }

  Future<void> _pushToggleToSupabase(String propertyId, bool isAdding) async {
    if (_userId == null) return; // Ignore if guest mode
    try {
      if (isAdding) {
        await Supabase.instance.client.from('user_favorites').upsert({
          'user_id': _userId,
          'property_id': propertyId,
        });
      } else {
        await Supabase.instance.client.from('user_favorites')
            .delete()
            .match({'user_id': _userId, 'property_id': propertyId});
      }
    } catch (e) {
      debugPrint('Supabase favorite toggle failed silently to preserve offline sync. Error: $e');
    }
    notifyListeners();
  }

  bool isFavorite(String id) {
    return _favoriteIds.contains(id);
  }
}
