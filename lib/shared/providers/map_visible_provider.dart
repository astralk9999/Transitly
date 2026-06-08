import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `true` cuando la pestaña del mapa (`/home/mapa`) es la pantalla visible
/// superior. Lo actualiza el `redirect` global del router en cada cambio de
/// ruta.
///
/// Se usa para SUPRIMIR el fondo shader animado mientras el mapa está a la
/// vista: en algunos dispositivos el fragment shader del fondo y el
/// `FlutterMap` no pueden coexistir de forma sostenida y la app crashea /
/// el fondo se corrompe. Como el mapa tapa el fondo igualmente, ocultarlo
/// ahí no tiene coste visual. Sobre un detalle (ruta opaca) el mapa no se
/// pinta, así que ahí el fondo SÍ se muestra.
final mapVisibleProvider = StateProvider<bool>((_) => false);
