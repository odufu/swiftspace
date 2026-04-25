import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:swiftspace/core/constants/app_constants.dart';

/// Interface for Map Service to abstract map providers and configurations.
abstract class IMapService {
  TileLayer getTileLayer({required bool isDark, required bool isSatellite});
}

/// Implementation of IMapService using FlutterMap and CachedNetworkImage.
class FlutterMapService implements IMapService {
  static const String darkUrl =
      'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
  static const String lightUrl =
      'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';

  @override
  TileLayer getTileLayer({required bool isDark, required bool isSatellite}) {
    final urlTemplate = isSatellite
        ? AppConstants.mapUrlSatellite
        : (isDark ? darkUrl : lightUrl);

    return TileLayer(
      urlTemplate: urlTemplate,
      tileProvider: CachedTileProvider(),
      userAgentPackageName: 'com.swiftspace.app',
      maxZoom: 19,
    );
  }
}

/// A custom TileProvider that uses cached_network_image for persistent offline support.
class CachedTileProvider extends TileProvider {
  CachedTileProvider();

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return CachedNetworkImageProvider(
      options.urlTemplate!
          .replaceAll('{x}', coordinates.x.toString())
          .replaceAll('{y}', coordinates.y.toString())
          .replaceAll('{z}', coordinates.z.toString())
          .replaceAll('{s}', options.subdomains.isNotEmpty ? options.subdomains[0] : ''),
    );
  }
}
