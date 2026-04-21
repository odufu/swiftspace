import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftspace/features/property/domain/entities/property.dart';

enum ExploreViewType { grid, tiktok, map }

class UserPreferencesProvider extends ChangeNotifier {
  double _minPrice = 0;
  double _maxPrice = 5000000;
  PropertyType? _preferredType;
  int _currentTabIndex = 0;
  String? _mapFocusPropertyId;
  bool _isAgent = false;
  ExploreViewType _preferredExploreView = ExploreViewType.grid;

  // Getters
  int get currentTabIndex => _currentTabIndex;
  ExploreViewType get preferredExploreView => _preferredExploreView;
  String? get mapFocusPropertyId => _mapFocusPropertyId;
  bool get isAgent => _isAgent;

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  void setMapFocusProperty(String? id) {
    _mapFocusPropertyId = id;
    notifyListeners();
  }

  void toggleAgentMode(bool value) {
    _isAgent = value;
    notifyListeners();
  }
  String _preferredLocation = '';
  
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;
  List<String> _bestOfferPriorities = ['price', 'road', 'utilities', 'hospital'];

  double get minPrice => _minPrice;
  double get maxPrice => _maxPrice;
  PropertyType? get preferredType => _preferredType;
  String get preferredLocation => _preferredLocation;
  bool get soundEnabled => _soundEnabled;
  bool get hapticsEnabled => _hapticsEnabled;
  List<String> get bestOfferPriorities => List.unmodifiable(_bestOfferPriorities);

  UserPreferencesProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _minPrice = prefs.getDouble('push_minPrice') ?? 0;
    _maxPrice = prefs.getDouble('push_maxPrice') ?? 5000000;
    final typeIndex = prefs.getInt('push_preferredType');
    if (typeIndex != null && typeIndex >= 0 && typeIndex < PropertyType.values.length) {
      _preferredType = PropertyType.values[typeIndex];
    }
    _preferredLocation = prefs.getString('push_preferredLocation') ?? '';
    _soundEnabled = prefs.getBool('setting_soundEnabled') ?? true;
    _hapticsEnabled = prefs.getBool('setting_hapticsEnabled') ?? true;
    _bestOfferPriorities = prefs.getStringList('bestOfferPriorities') ?? ['price', 'road', 'utilities', 'hospital'];
    
    final viewIndex = prefs.getInt('setting_exploreViewType');
    if (viewIndex != null && viewIndex >= 0 && viewIndex < ExploreViewType.values.length) {
      _preferredExploreView = ExploreViewType.values[viewIndex];
    }
    
    notifyListeners();
  }

  Future<void> updatePreferences({
    required double minPrice,
    required double maxPrice,
    required PropertyType? type,
    required String location,
  }) async {
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    _preferredType = type;
    _preferredLocation = location;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('push_minPrice', minPrice);
    await prefs.setDouble('push_maxPrice', maxPrice);
    if (type != null) {
      await prefs.setInt('push_preferredType', type.index);
    } else {
      await prefs.remove('push_preferredType');
    }
    await prefs.setString('push_preferredLocation', location);
    
    notifyListeners();
  }

  Future<void> updateBestOfferPriorities(List<String> newPriorities) async {
    _bestOfferPriorities = List.from(newPriorities);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('bestOfferPriorities', _bestOfferPriorities);
    notifyListeners();
  }

  Future<void> toggleSound(bool value) async {
    _soundEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setting_soundEnabled', value);
    notifyListeners();
  }

  Future<void> toggleHaptics(bool value) async {
    _hapticsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setting_hapticsEnabled', value);
    notifyListeners();
  }

  Future<void> setExploreView(ExploreViewType type) async {
    _preferredExploreView = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('setting_exploreViewType', type.index);
    notifyListeners();
  }
}
