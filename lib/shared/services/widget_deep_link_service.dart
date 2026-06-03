import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/app_logger.dart';

class WidgetDeepLinkService {
  WidgetDeepLinkService(this._goRouter);
  final GoRouter _goRouter;
  StreamSubscription<Uri?>? _sub;
  static const _logTag = 'WidgetDeepLink';

  static const _validPaths = <String>{
    '/home/inicio',
    '/home/mapa',
    '/home/tarjeta',
    '/home/buscar',
    '/home/perfil',
  };

  /// Procesa el URI con el que se abrió la app en cold start.
  Future<void> handleColdStart() async {
    try {
      final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (uri != null) {
        _route(uri);
      }
    } catch (e) {
      AppLogger.warn(_logTag, 'handleColdStart failed', e);
    }
  }

  /// Escucha clicks en el widget con la app en background.
  void startListening() {
    _sub = HomeWidget.widgetClicked.listen((uri) {
      if (uri != null) _route(uri);
    });
  }

  void _route(Uri uri) {
    // Reconstruimos el path con segments para evitar doble slash si
    // algún OEM devuelve host vacío (origen sospechoso de los 404).
    final segments = <String>[
      if (uri.host.isNotEmpty) uri.host,
      ...uri.pathSegments,
    ];
    final path = '/${segments.join('/')}';
    final target =
        _validPaths.contains(path) ? path : '/home/inicio';
    AppLogger.info(_logTag, 'deep link: $uri → $target');
    // postFrameCallback evita race si el listener dispara antes de que
    // GoRouter haya completado su primer build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _goRouter.go(target);
    });
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
