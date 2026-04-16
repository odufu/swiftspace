import 'package:get_it/get_it.dart';
import 'package:swiftspace/core/services/audio_manager.dart';
import 'package:swiftspace/core/services/map_service.dart';
import 'package:swiftspace/features/auth/data/repositories/auth_repository.dart';

final sl = GetIt.instance;

Future<void> initGlobalDI() async {
  // Services
  sl.registerLazySingleton<AudioManager>(() => AudioManager());
  sl.registerLazySingleton<IMapService>(() => FlutterMapService());
  sl.registerLazySingleton<AuthRepository>(() => AuthRepository());

  // You can add more global services here
}
