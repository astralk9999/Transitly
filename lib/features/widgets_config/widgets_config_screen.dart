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
import '../../shared/providers/widget_appearance_config_provider.dart';
import '../../shared/widgets/background_wrapper.dart';
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

    return BackgroundWrapper(
      child: Scaffold(
      // Transparente para que se vea el BackgroundWrapper externo
      // (fondo configurado en Apariencia: smoke, aurora, balatro, etc).
      backgroundColor: Colors.transparent,
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mockups visuales de cada widget (estilo widget Android real).
// ---------------------------------------------------------------------------

/// Resolver de paleta del MOCKUP según la opción del usuario en el panel.
/// Cuando cambia el `WidgetTheme`, el preview cambia de fondo/texto.
class _MockupPalette {
  const _MockupPalette({
    required this.bg,
    required this.textHi,
    required this.textMid,
    required this.textLo,
  });
  final Color bg;
  final Color textHi;
  final Color textMid;
  final Color textLo;

  static _MockupPalette resolve(
      WidgetTheme theme, bool systemIsDark, Color accent) {
    bool dark;
    switch (theme) {
      case WidgetTheme.light:
        dark = false;
      case WidgetTheme.dark:
        dark = true;
      case WidgetTheme.auto:
        dark = systemIsDark;
      case WidgetTheme.brand:
        return _MockupPalette(
          bg: accent,
          textHi: Colors.white,
          textMid: Colors.white.withValues(alpha: 0.85),
          textLo: Colors.white.withValues(alpha: 0.7),
        );
    }
    return dark
        ? const _MockupPalette(
            bg: Color(0xFF14142A),
            textHi: Color(0xFFF0F0FA),
            textMid: Color(0xFFAAAAB8),
            textLo: Color(0xFF8888A0),
          )
        : const _MockupPalette(
            bg: Color(0xFFFAFAFA),
            textHi: Color(0xFF14142A),
            textMid: Color(0xFF555575),
            textLo: Color(0xFF8888A0),
          );
  }
}

/// Dimensiones del mockup según la opción de tamaño.
class _MockupDimens {
  const _MockupDimens({
    required this.padding,
    required this.height,
    required this.badgeSize,
    required this.fontEta,
    required this.maxTimes,
  });
  final double padding;
  final double? height;
  final double badgeSize;
  final double fontEta;
  final int maxTimes;

  static _MockupDimens of(WidgetSize size) {
    switch (size) {
      case WidgetSize.small:
        return const _MockupDimens(
          padding: 10,
          height: 80,
          badgeSize: 40,
          fontEta: 18,
          maxTimes: 1,
        );
      case WidgetSize.medium:
        return const _MockupDimens(
          padding: 14,
          height: null,
          badgeSize: 56,
          fontEta: 26,
          maxTimes: 3,
        );
      case WidgetSize.large:
        return const _MockupDimens(
          padding: 18,
          height: null,
          badgeSize: 64,
          fontEta: 32,
          maxTimes: 5,
        );
    }
  }
}

class _WidgetMockup extends ConsumerWidget {
  const _WidgetMockup({required this.type, required this.c});
  final _WidgetType type;
  final TransitColorScheme c;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // El preview reacciona en directo al panel de apariencia.
    final cfg = ref.watch(widgetAppearanceConfigProvider);
    final systemIsDark = Theme.of(context).brightness == Brightness.dark;
    final palette =
        _MockupPalette.resolve(cfg.theme, systemIsDark, c.accent);
    final dimens = _MockupDimens.of(cfg.size);

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
      child: Column(
        children: [
          Center(
            child: switch (type) {
              _WidgetType.nextBus => _NextBusMockup(
                  c: c, palette: palette, dimens: dimens),
              _WidgetType.myLine => _MyLineMockup(
                  c: c, palette: palette, dimens: dimens),
              _WidgetType.nfcBalance => _NfcBalanceMockup(
                  palette: palette, dimens: dimens, accent: c.accent),
            },
          ),
          const SizedBox(height: 10),
          // Etiqueta con la config activa para que el usuario sepa qué
          // tamaño / tema está viendo en el preview.
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _ConfigBadge(
                  c: c,
                  icon: Icons.aspect_ratio,
                  text: switch (cfg.size) {
                    WidgetSize.small => 'Tamaño S',
                    WidgetSize.medium => 'Tamaño M',
                    WidgetSize.large => 'Tamaño L',
                  }),
              _ConfigBadge(
                  c: c,
                  icon: Icons.palette_outlined,
                  text: switch (cfg.theme) {
                    WidgetTheme.auto => 'Tema auto',
                    WidgetTheme.light => 'Tema claro',
                    WidgetTheme.dark => 'Tema oscuro',
                    WidgetTheme.brand => 'Tema marca',
                  }),
              _ConfigBadge(
                  c: c,
                  icon: Icons.update,
                  text: 'Refresco ${cfg.refreshMinutes} min'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConfigBadge extends StatelessWidget {
  const _ConfigBadge({required this.c, required this.icon, required this.text});
  final TransitColorScheme c;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.accent.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c.accent),
          const SizedBox(width: 4),
          Text(
            text,
            style: TransitTypography.bodySmall(c.accent).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NextBusMockup extends ConsumerWidget {
  const _NextBusMockup({
    required this.c,
    required this.palette,
    required this.dimens,
  });
  final TransitColorScheme c;
  final _MockupPalette palette;
  final _MockupDimens dimens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mockData = ref.watch(mockDataServiceProvider);
    final habitual = ref.watch(homeHabitualConfigProvider);

    String routeCode = '8';
    Color routeColor = c.accent;
    String etaText = '5 min';
    String stopName = 'Plaza del Caballo';
    List<String> followingTimes = ['12 min', '21 min'];

    if (habitual.isConfigured) {
      final route = mockData.getRouteById(habitual.routeId!);
      final stop = mockData.getStopById(habitual.stopId!);
      final deps = mockData.getNextDepartures(
          habitual.routeId!, habitual.stopId!, 5);
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
        followingTimes =
            deps.skip(1).map((d) => d.departureTime).toList();
      }
    }

    return Container(
      width: double.infinity,
      height: dimens.height,
      padding: EdgeInsets.all(dimens.padding),
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: dimens.badgeSize,
            height: dimens.badgeSize,
            decoration: BoxDecoration(
              color: routeColor,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                routeCode,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: dimens.badgeSize * 0.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SizedBox(width: dimens.padding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  etaText,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: dimens.fontEta,
                    fontWeight: FontWeight.w800,
                    color: palette.textHi,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stopName.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: palette.textMid,
                    letterSpacing: 1,
                  ),
                ),
                // Solo el size M y L muestran las siguientes salidas.
                // El size S es compacto y solo ETA + parada.
                if (dimens.maxTimes >= 2 && followingTimes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Luego ${followingTimes.take(dimens.maxTimes - 1).join(', ')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: palette.textLo,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MyLineMockup extends ConsumerWidget {
  const _MyLineMockup({
    required this.c,
    required this.palette,
    required this.dimens,
  });
  final TransitColorScheme c;
  final _MockupPalette palette;
  final _MockupDimens dimens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mockData = ref.watch(mockDataServiceProvider);
    final favs = ref.watch(userFavoritesProvider);

    String routeCode = '12';
    Color routeColor = c.accent;
    String routeName = 'Línea favorita';
    List<String> times = ['08:15', '08:30', '08:45', '09:00', '09:15'];

    if (favs.isNotEmpty) {
      final r = mockData.getRouteById(favs.first);
      if (r != null) {
        routeCode = r.code;
        routeColor = r.routeColor;
        routeName = r.name;
        final stops = mockData.getStopsForRoute(r.id);
        if (stops.isNotEmpty) {
          final deps = mockData.getNextDepartures(r.id, stops.first.id, 5);
          if (deps.isNotEmpty) {
            times = deps.map((d) => d.departureTime).toList();
          }
        }
      }
    }

    return Container(
      width: double.infinity,
      height: dimens.height,
      padding: EdgeInsets.all(dimens.padding),
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: dimens.badgeSize * 0.75,
                height: dimens.badgeSize * 0.75,
                decoration: BoxDecoration(
                  color: routeColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    routeCode,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: dimens.badgeSize * 0.32,
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
                  style: TextStyle(
                    color: palette.textHi,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...times.take(dimens.maxTimes).map(
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
                          color: palette.textMid,
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
  const _NfcBalanceMockup({
    required this.palette,
    required this.dimens,
    required this.accent,
  });
  final _MockupPalette palette;
  final _MockupDimens dimens;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: dimens.height,
      padding: EdgeInsets.all(dimens.padding),
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(Icons.credit_card, color: accent, size: 22),
              const SizedBox(width: 8),
              Text(
                'TARJETA',
                style: TextStyle(
                  color: palette.textMid,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: dimens.padding * 0.6),
          Text(
            '€ 7,50',
            style: GoogleFonts.ibmPlexMono(
              fontSize: dimens.fontEta,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          // Solo M y L muestran la última recarga.
          if (dimens.maxTimes >= 2) ...[
            const SizedBox(height: 2),
            Text(
              'Última recarga: hoy 14:32',
              style: TextStyle(
                color: palette.textLo,
                fontSize: 11,
              ),
            ),
          ],
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
