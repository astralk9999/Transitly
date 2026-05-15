import 'package:latlong2/latlong.dart';

import '../../core/env.dart';

class MapConfig {
  MapConfig._();

  static const _maptilerBase = 'https://api.maptiler.com/maps';

  static const mapStyles = {
    'streets': 'streets-v2',
    'basic': 'basic-v2',
    'bright': 'bright-v2',
    'dark': 'dataviz-dark',
    'light': 'dataviz-light',
  };

  static String tileUrl(String style, {String? apiKey}) {
    final key = apiKey ?? Env.mapTilerApiKey;
    if (key != null && key.isNotEmpty) {
      final slug = mapStyles[style] ?? mapStyles['streets']!;
      return '$_maptilerBase/$slug/{z}/{x}/{y}@2x.png?key=$key';
    }
    return _cartoUrl(style);
  }

  static String _cartoUrl(String style) {
    final isDark = style == 'dark' || style == 'streets';
    final tilePath = isDark
        ? 'dark_nolabels'
        : 'light_nolabels';
    return 'https://{s}.basemaps.cartocdn.com/$tilePath/{z}/{x}/{y}@2x.png';
  }

  static const subdomains = ['a', 'b', 'c', 'd'];

  static final defaultCenter = const LatLng(36.6850, -6.1261);
  static const defaultZoom = 13.0;
  static const minZoom = 8.0;
  static const maxZoom = 18.0;
}
