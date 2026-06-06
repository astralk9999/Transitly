import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/mock/mock_data_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/providers/home_habitual_config_provider.dart';
import '../../shared/providers/user_favorites_provider.dart';
import '../../shared/widgets/glass_card.dart';
import 'widgets/widget_appearance_panel.dart';

/// Sub #58 (re-rediseño): "Centro de widgets" con SegmentedButton para
/// elegir tipo, mockup grande estilo widget Android real con los datos
/// reales del usuario, botón "Configurar este widget" y panel de
/// apariencia compartido al pie. Todo inline en una sola pantalla.
class WidgetsConfigScreen extends ConsumerStatefulWidget {
  const WidgetsConfigScreen({super.key});

  @override
  ConsumerState<WidgetsConfigScreen> createState() =>
      _WidgetsConfigScreenState();
}

enum _WidgetType { nextBus, myLine, nfcBalance }

class _WidgetsConfigScreenState extends ConsumerState<WidgetsConfigScreen> {
  _WidgetType _selected = _WidgetType.nextBus;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: c.bgRoot,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textHi),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.widgetsConfigTitle,
            style: TransitTypography.heading(c.textHi)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Selector de tipo de widget.
            Text('Tipo de widget',
                style: TransitTypography.sectionTitle(c.textMid)),
            const SizedBox(height: 8),
            SegmentedButton<_WidgetType>(
              segments: const [
                ButtonSegment(
                  value: _WidgetType.nextBus,
                  icon: Icon(Icons.directions_bus, size: 16),
                  label: Text('Bus'),
                ),
                ButtonSegment(
                  value: _WidgetType.myLine,
                  icon: Icon(Icons.route_outlined, size: 16),
                  label: Text('Línea'),
                ),
                ButtonSegment(
                  value: _WidgetType.nfcBalance,
                  icon: Icon(Icons.credit_card, size: 16),
                  label: Text('Tarjeta'),
                ),
              ],
              selected: {_selected},
              onSelectionChanged: (s) {
                if (s.isNotEmpty) setState(() => _selected = s.first);
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) return c.accent;
                  return c.bgRaised;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.white;
                  }
                  return c.textMid;
                }),
                side: WidgetStateProperty.all(
                  BorderSide(color: c.border, width: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Sub-encabezado: vista previa.
            Row(
              children: [
                Icon(Icons.visibility_outlined,
                    size: 18, color: c.accent),
                const SizedBox(width: 6),
                Text(
                  'Vista previa en la pantalla de inicio',
                  style: TransitTypography.sectionTitle(c.textMid),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Así se verá el widget en tu home con tus datos reales.',
              style: TransitTypography.bodySmall(c.textLo),
            ),
            const SizedBox(height: 12),

            // Mockup grande del widget seleccionado.
            _WidgetMockup(type: _selected, c: c),

            const SizedBox(height: 24),

            // Botón "Configurar este widget" + descripción.
            _ConfigCta(type: _selected, c: c, l10n: l10n),

            const SizedBox(height: 28),

            // Panel de apariencia compartido (afecta a los 3 widgets).
            Row(
              children: [
                Icon(Icons.tune, size: 18, color: c.accent),
                const SizedBox(width: 6),
                Text(
                  'Apariencia (común a todos los widgets)',
                  style: TransitTypography.sectionTitle(c.textMid),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const WidgetAppearancePanel(),

            const SizedBox(height: 24),

            // Sección "Cómo añadir el widget al home".
            _HowToInstallCard(c: c),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mockups visuales de cada widget (estilo widget Android real).
// ---------------------------------------------------------------------------

class _WidgetMockup extends ConsumerWidget {
  const _WidgetMockup({required this.type, required this.c});
  final _WidgetType type;
  final TransitColorScheme c;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Marco "fondo de home" simulado para enmarcar el mockup.
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            c.accent.withValues(alpha: 0.08),
            c.neonPurple.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border, width: 1),
      ),
      child: Center(
        child: switch (type) {
          _WidgetType.nextBus => _NextBusMockup(c: c),
          _WidgetType.myLine => _MyLineMockup(c: c),
          _WidgetType.nfcBalance => _NfcBalanceMockup(c: c),
        },
      ),
    );
  }
}

class _NextBusMockup extends ConsumerWidget {
  const _NextBusMockup({required this.c});
  final TransitColorScheme c;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mockData = ref.watch(mockDataServiceProvider);
    final habitual = ref.watch(homeHabitualConfigProvider);

    String routeCode = '8';
    Color routeColor = c.accent;
    String etaText = '5 min';
    String stopName = 'Plaza del Caballo';
    String summary = 'Luego en 12, 21 min';

    if (habitual.isConfigured) {
      final route = mockData.getRouteById(habitual.routeId!);
      final stop = mockData.getStopById(habitual.stopId!);
      final deps = mockData.getNextDepartures(
          habitual.routeId!, habitual.stopId!, 3);
      if (route != null) {
        routeCode = route.code;
        routeColor = route.routeColor;
      }
      if (stop != null) stopName = stop.name;
      if (deps.isNotEmpty) {
        final now = DateTime.now();
        final nowMin = now.hour * 60 + now.minute;
        final parts = deps.first.departureTime.split(':');
        final depMin = (int.tryParse(parts[0]) ?? 0) * 60 +
            (parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0);
        var eta = depMin - nowMin;
        if (eta < 0) eta += 24 * 60;
        etaText = eta < 1 ? 'Ahora' : '$eta min';
        if (deps.length > 1) {
          summary = 'Luego ${deps.skip(1).map((d) => d.departureTime).join(', ')}';
        }
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF14142A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: routeColor,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                routeCode,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etaText,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFF0F0FA),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stopName.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFAAAAB8),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8888A0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MyLineMockup extends ConsumerWidget {
  const _MyLineMockup({required this.c});
  final TransitColorScheme c;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mockData = ref.watch(mockDataServiceProvider);
    final favs = ref.watch(userFavoritesProvider);

    String routeCode = '12';
    Color routeColor = c.accent;
    String routeName = 'Línea favorita';
    List<String> times = ['08:15', '08:30', '08:45'];

    if (favs.isNotEmpty) {
      final r = mockData.getRouteById(favs.first);
      if (r != null) {
        routeCode = r.code;
        routeColor = r.routeColor;
        routeName = r.name;
        final stops = mockData.getStopsForRoute(r.id);
        if (stops.isNotEmpty) {
          final deps = mockData.getNextDepartures(r.id, stops.first.id, 3);
          if (deps.isNotEmpty) {
            times = deps.map((d) => d.departureTime).toList();
          }
        }
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF14142A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: routeColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    routeCode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  routeName.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFF0F0FA),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...times.take(3).map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: routeColor.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        t,
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFCFCFE4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _NfcBalanceMockup extends StatelessWidget {
  const _NfcBalanceMockup({required this.c});
  final TransitColorScheme c;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF14142A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.credit_card, color: c.accent, size: 22),
              const SizedBox(width: 8),
              const Text(
                'TARJETA',
                style: TextStyle(
                  color: Color(0xFFAAAAB8),
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '€ 7,50',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: c.accent,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Última recarga: hoy 14:32',
            style: TextStyle(
              color: Color(0xFF8888A0),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CTA "Configurar este widget" con descripción según tipo.
// ---------------------------------------------------------------------------
class _ConfigCta extends StatelessWidget {
  const _ConfigCta({
    required this.type,
    required this.c,
    required this.l10n,
  });
  final _WidgetType type;
  final TransitColorScheme c;
  final AppLocalizations l10n;

  String get _label => switch (type) {
        _WidgetType.nextBus => 'Configurar línea + parada',
        _WidgetType.myLine => 'Elegir mi línea favorita',
        _WidgetType.nfcBalance => 'Vincular mi tarjeta NFC',
      };

  String get _description => switch (type) {
        _WidgetType.nextBus =>
          'Elige qué parada vigila el widget y mostrará la próxima salida.',
        _WidgetType.myLine =>
          'El widget mostrará las próximas 3 salidas de tu línea favorita.',
        _WidgetType.nfcBalance =>
          'El widget mostrará el saldo de tu última lectura NFC.',
      };

  String get _route => switch (type) {
        _WidgetType.nextBus => '/widgets-config/next-bus',
        _WidgetType.myLine => '/widgets-config/my-line',
        _WidgetType.nfcBalance => '/widgets-config/nfc-balance',
      };

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: 14,
      fillOpacity: 0.04,
      borderRadius: 12,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_description,
              style: TransitTypography.bodySecondary(c.textMid)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton.icon(
              onPressed: () => context.push(_route),
              icon: const Icon(Icons.settings, size: 18),
              label: Text(_label.toUpperCase()),
              style: FilledButton.styleFrom(
                backgroundColor: c.accent,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Instrucciones cortas para añadir el widget al home Android.
// ---------------------------------------------------------------------------
class _HowToInstallCard extends StatelessWidget {
  const _HowToInstallCard({required this.c});
  final TransitColorScheme c;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: 12,
      fillOpacity: 0.03,
      borderRadius: 12,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: c.accent, size: 18),
              const SizedBox(width: 6),
              Text('Cómo añadirlo al home',
                  style: TransitTypography.sectionTitle(c.textMid)),
            ],
          ),
          const SizedBox(height: 8),
          _Step(c: c, n: 1, text: 'Mantén pulsado un hueco vacío de tu home Android.'),
          _Step(c: c, n: 2, text: 'Toca "Widgets" en el menú que aparece.'),
          _Step(c: c, n: 3, text: 'Busca "Transitly" y elige uno de los 3 widgets.'),
          _Step(c: c, n: 4, text: 'Suéltalo donde quieras y volverá automáticamente con tus datos.'),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.c, required this.n, required this.text});
  final TransitColorScheme c;
  final int n;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$n',
              style: TextStyle(
                color: c.accent,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TransitTypography.bodySecondary(c.textHi)),
          ),
        ],
      ),
    );
  }
}
