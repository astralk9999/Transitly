import 'package:latlong2/latlong.dart';

import '../../core/env.dart';

class MapConfig {
  MapConfig._();

  static const _maptilerBase = 'https://api.maptiler.com/maps';

  static const _maptilerSlugs = {
    'streets': 'streets-v2',
    'basic': 'basic-v2',
    'bright': 'bright-v2',
    'dark': 'dataviz-dark',
    'light': 'dataviz-light',
  };

  static const mapStyles = {
    'streets': 'voyager',
    'basic': 'standard',
    'bright': 'light',
    'dark': 'dark',
    'light': 'positron',
  };

  static String tileUrl(String style, {String? apiKey}) {
    final key = apiKey ?? Env.mapTilerApiKey;
    if (key != null && key.isNotEmpty) {
      final slug = _maptilerSlugs[style] ?? _maptilerSlugs['streets']!;
      return '$_maptilerBase/$slug/{z}/{x}/{y}@2x.png?key=$key';
    }
    final fallback = mapStyles[style] ?? 'voyager';
    switch (fallback) {
      case 'standard':
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case 'dark':
        return 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png';
      case 'positron':
        return 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png';
      case 'voyager':
        return 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png';
      case 'light':
        return 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager_nolabels/{z}/{x}/{y}@2x.png';
      default:
        return 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png';
    }
  }

  static const subdomains = ['a', 'b', 'c', 'd'];

  static final defaultCenter = const LatLng(36.6850, -6.1261);
  static const defaultZoom = 13.0;
  static const minZoom = 8.0;
  static const maxZoom = 18.0;
}
