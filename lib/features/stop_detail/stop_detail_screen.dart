import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../data/mock/mock_data_service.dart';
import '../../shared/providers/route_lookup_providers.dart';
import '../feedback/route_feedback_sheet.dart';
import '../incidents/report_incident_sheet.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/transit_chip.dart';
import 'widgets/stop_timetable_section.dart';

class StopDetailScreen extends ConsumerWidget {
  const StopDetailScreen({super.key, required this.stopId});

  final String stopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final mockData = ref.watch(mockDataServiceProvider);
    final stop = mockData.getStopById(stopId);

    if (stop == null) {
      return Scaffold(
        backgroundColor: c.bgRoot,
        body: Center(child: Text(AppLocalizations.of(context).stopDetailNotFound)),
      );
    }

    // Find all routes that pass through this stop
    final stopToRoutes = ref.watch(stopToRouteCodesProvider);
    final routesAtStop = stopToRoutes[stopId] ?? const <String>[];

    final padding = ResponsiveScaffold.screenPadding(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          ContentConstraints(
        child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(padding, 0, padding, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 48),

                // ── BACK ──
                Align(
                  alignment: Alignment.centerLeft,
                  child: Tooltip(
                    message: AppLocalizations.of(context).actionBack,
                    child: GestureDetector(
                      onTap: () => context.pop(),
                      child:
                          Icon(Icons.arrow_back, size: 24, color: c.textMid),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── 1. HEADER ──
                Semantics(
                  header: true,
                  child: Text(
                    stop.name.toUpperCase(),
                    style: TransitTypography.heading(c.textHi),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stop.municipality} · ${stop.officialCode}',
                  style: TransitTypography.subheading(c.textMid),
                ),
                const SizedBox(height: 12),

                // Service icons
                Row(
                  children: [
                    if (stop.hasShelter) _serviceIcon(c, Icons.home, 'Marquesina'),
                    if (stop.isAccessible)
                      _serviceIcon(c, Icons.accessible, 'Accesible'),
                    if (stop.hasBench)
                      _serviceIcon(c, Icons.event_seat, 'Banco'),
                  ],
                ),

                Divider(height: 32, thickness: 0.5, color: c.border),

                // ── HORARIOS (fuente única: próxima llegada + horario completo
                // por línea desde datos oficiales; estimación para el resto) ──
                StopTimetableSection(stopId: stopId, stopName: stop.name),

                // ── 3. LÍNEAS QUE PASAN ──
                Semantics(
                  header: true,
                  child: Text(AppLocalizations.of(context).stopLinesHeader,
                      style: TransitTypography.sectionTitle(c.textMid)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: routesAtStop.map((routeId) {
                    final route = mockData.getRouteById(routeId);
                    if (route == null) return const SizedBox.shrink();
                    return TransitChip(
                      route.code,
                      color: route.routeColor,
                      onTap: () => context.push('/route/$routeId'),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // ── 4. ACCIONES ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _actionButton(
                      context,
                      c,
                      Icons.warning_amber,
                      'Reportar',
                      onTap: () => showReportIncidentSheet(context, ref: ref, stop: stop),
                    ),
                    _actionButton(
                      context,
                      c,
                      Icons.edit,
                      'Mejorar',
                      onTap: () => showRouteFeedbackSheet(context, ref: ref, stop: stop),
                    ),
                    _actionButton(
                      context,
                      c,
                      Icons.share,
                      'Compartir',
                      onTap: () async {
                        final code = stop.officialCode.isNotEmpty
                            ? ' (${stop.officialCode})'
                            : '';
                        final coords =
                            '${stop.lat.toStringAsFixed(5)},${stop.lng.toStringAsFixed(5)}';
                        await Share.share(
                          'Parada de bus$code: ${stop.name}\n'
                          'Ubicación: https://www.google.com/maps/search/?api=1&query=$coords',
                          subject: 'Parada ${stop.name}',
                        );
                      },
                    ),
                    _actionButton(
                      context,
                      c,
                      Icons.navigation,
                      'Cómo llegar',
                      onTap: () async {
                        // Abre la app de mapas del dispositivo con
                        // direcciones a la parada. Google Maps URL
                        // intent funciona en Android (Google Maps app)
                        // y cae a la web en otros casos.
                        final url = Uri.parse(
                          'https://www.google.com/maps/dir/?api=1'
                          '&destination=${stop.lat},${stop.lng}'
                          '&travelmode=walking',
                        );
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url,
                              mode: LaunchMode.externalApplication);
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No se pudo abrir Maps'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── 5. SUGERENCIA ──
                GestureDetector(
                  onTap: () => context.push('/suggestions/new'),
                  child: Text(
                    '¿Pasa por aquí una línea que no aparece? →',
                    style: TransitTypography.bodySecondary(c.accent),
                  ),
                ),

                const SizedBox(height: 16),
              ]),
            ),
          ),
        ],
      ),
      ),
        ],
      ),
    );
  }

  Widget _serviceIcon(TransitColorScheme c, IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Icon(icon, size: 16, color: c.textMid),
          const SizedBox(height: 2),
          Text(label, style: TransitTypography.bodySmall(c.textMid)),
        ],
      ),
    );
  }

  Widget _actionButton(
    BuildContext context,
    TransitColorScheme c,
    IconData icon,
    String label, {
    VoidCallback? onTap,
  }) {
    return Tooltip(
      message: label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap ??
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Semantics(
                      liveRegion: true,
                      label: AppLocalizations.of(context).generalComingSoon(label),
                      child: Text(AppLocalizations.of(context).generalComingSoon(label)),
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: c.bgRaised,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.border, width: 0.5),
                ),
                child: Icon(icon, size: 18, color: c.textHi),
              ),
              const SizedBox(height: 4),
              Text(label, style: TransitTypography.bodySmall(c.textMid)),
            ],
          ),
        ),
      ),
    );
  }
}
