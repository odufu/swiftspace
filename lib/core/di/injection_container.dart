import 'package:get_it/get_it.dart';
import 'package:swiftspace/core/services/cloudinary_service.dart';
import 'package:swiftspace/core/services/audio_manager.dart';
import 'package:swiftspace/core/services/map_service.dart';
import 'package:swiftspace/features/auth/data/repositories/auth_repository.dart';
import 'package:swiftspace/core/services/connectivity_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:swiftspace/features/explore/domain/services/ai_recommendation_service.dart';
import 'package:swiftspace/features/explore/data/services/supabase_ai_recommendation_service.dart';

final sl = GetIt.instance;

Future<void> initGlobalDI() async {
  // Services
  sl.registerLazySingleton<AudioManager>(() => AudioManager());
  sl.registerLazySingleton<CloudinaryService>(() => CloudinaryService());
  sl.registerLazySingleton<IMapService>(() => FlutterMapService());
  sl.registerLazySingleton<AuthRepository>(() => AuthRepository());
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityService());

  sl.registerLazySingleton<IAiRecommendationService>(
    () => SupabaseAiRecommendationService(Supabase.instance.client),
  );

  // You can add more global services here
}
