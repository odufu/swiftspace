import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftspace/features/auth/presentation/state/user_preferences_provider.dart';
import 'package:swiftspace/features/explore/presentation/pages/grid_explore_screen.dart';
import 'package:swiftspace/features/explore/presentation/pages/tiktok_explore_screen.dart';
import 'package:swiftspace/features/explore/presentation/pages/map_explore_screen.dart';
import 'package:swiftspace/features/explore/presentation/pages/smart_explore_screen.dart';

class MainExploreTab extends StatelessWidget {
  const MainExploreTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserPreferencesProvider>(
      builder: (context, prefs, child) {
        switch (prefs.preferredExploreView) {
          case ExploreViewType.tiktok:
            return const TikTokExploreScreen();
          case ExploreViewType.map:
            return const MapExploreScreen();
          case ExploreViewType.smart:
            return const SmartExploreScreen();
          case ExploreViewType.grid:
            return const GridExploreScreen();
        }
      },
    );
  }
}
