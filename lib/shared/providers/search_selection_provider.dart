import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// Sub B1.1: representa la última selección del buscador (parada o
/// lugar) que el mapa debe centrar + marcar con un pin destacado.
///
/// El buscador escribe aquí en lugar de pasar `extra: LatLng`, porque
/// `/home/mapa` es una pestaña dentro de StatefulShellRoute y el extra
/// se pierde entre rebuilds. Un provider sobrevive a los rebuilds.
class SearchSelection {
  const SearchSelection({
    required this.position,
    required this.title,
    this.subtitle,
    this.icon = Icons.location_on,
    this.color,
    required this.id,
    this.pushPath,
    this.routeId,
  });

  final LatLng position;
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? color;

  /// Id único para detectar cambios aunque la misma posición se
  /// seleccione dos veces (por ejemplo: "stop-1234").
  final String id;

  /// Ruta opcional a la que navegar si el usuario pulsa "Ver detalles"
  /// en la tarjeta del pin. `null` = sin detalle (lugar genérico).
  final String? pushPath;

  /// Si es una selección de línea, el id de la ruta para que el mapa
  /// la resalte (polilínea destacada). `null` = no resaltar nada.
  final String? routeId;
}

/// `null` = sin selección activa.
final searchSelectionProvider = StateProvider<SearchSelection?>((_) => null);
