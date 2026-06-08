import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/responsive_scaffold.dart';

class SearchTab extends ConsumerStatefulWidget {
  const SearchTab({super.key});

  @override
  ConsumerState<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<SearchTab> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final padding = ResponsiveScaffold.screenPadding(context);

    // DESACTIVADO (2026-06-08): el planificador "buscar ruta" (desde/hasta)
    // no funciona de forma fiable todavía. Se muestra un aviso en su lugar.
    // El formulario y el motor (RouteSearchBar + /route-plan) se conservan en
    // el código para retomarlos. Ver docs/DESACTIVADO.md.
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ContentConstraints(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              children: [
                Expanded(
                  child: EmptyState(
                    'Búsqueda de rutas en mantenimiento',
                    'El planificador de trayectos (origen → destino) estará '
                        'disponible pronto. Mientras tanto, consulta las líneas '
                        'y sus horarios desde el mapa o el inicio.',
                    icon: Icons.construction_outlined,
                  ),
                ),
                _buildSuggestLink(c),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestLink(TransitColorScheme c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () => context.push('/suggestions/new'),
        child: Text(
          '¿No encuentras tu ruta? Sugiere que la añadamos →',
          style: TransitTypography.bodySecondary(c.accent),
        ),
      ),
    );
  }
}
