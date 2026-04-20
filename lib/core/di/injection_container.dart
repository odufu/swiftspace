import 'package:get_it/get_it.dart';
import 'package:swiftspace/core/services/audio_manager.dart';
import 'package:swiftspace/core/services/map_service.dart';
import 'package:swiftspace/features/auth/data/repositories/auth_repository.dart';
import 'package:swiftspace/core/services/connectivity_service.dart';
import 'package:swiftspace/features/auth/presentation/state/admin_provider.dart';

final sl = GetIt.instance;

Future<void> initGlobalDI() async {
  // Services
  sl.registerLazySingleton<AudioManager>(() => AudioManager());
  sl.registerLazySingleton<IMapService>(() => FlutterMapService());
  sl.registerLazySingleton<AuthRepository>(() => AuthRepository());
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  sl.registerLazySingleton(() => AdminProvider(sl()));

  // You can add more global services here
}
