import 'package:latlong2/latlong.dart';

class MapConfig {
  MapConfig._();

  static const darkTileUrl =
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png';
  static const lightTileUrl =
      'https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}@2x.png';
  static const subdomains = ['a', 'b', 'c', 'd'];

  static final defaultCenter = const LatLng(36.6850, -6.1261);
  static const defaultZoom = 13.0;
  static const minZoom = 8.0;
  static const maxZoom = 18.0;

  static String tileUrl(bool isDark) => isDark ? darkTileUrl : lightTileUrl;
}
