import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'map_config.dart';

class TransitMap extends StatelessWidget {
  const TransitMap({
    super.key,
    required this.isDark,
    this.center,
    this.zoom,
    this.controller,
    this.additionalLayers = const [],
  });

  final bool isDark;
  final LatLng? center;
  final double? zoom;
  final MapController? controller;
  final List<Widget> additionalLayers;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: center ?? MapConfig.defaultCenter,
        initialZoom: zoom ?? MapConfig.defaultZoom,
        minZoom: MapConfig.minZoom,
        maxZoom: MapConfig.maxZoom,
      ),
      children: [
        TileLayer(
          urlTemplate: MapConfig.tileUrl(isDark),
          subdomains: MapConfig.subdomains,
          retinaMode: true,
        ),
        ...additionalLayers,
      ],
    );
  }
}
