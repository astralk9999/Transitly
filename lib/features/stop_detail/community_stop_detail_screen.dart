import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../shared/models/stop_model.dart';
import '../../shared/providers/search_selection_provider.dart';
import '../../shared/providers/user_favorites_provider.dart';
import '../../shared/providers/user_routes_for_map_provider.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/route_favorite_toast.dart';
import '../../shared/widgets/transit_chip.dart';

/// Detalle de una parada de COMUNIDAD, con el MISMO formato que las paradas
/// oficiales de Jerez (mismo fondo, cabecera y tarjetas de horario): muestra
/// SOLO lo de esta parada — por cada línea que pasa, sus horas de paso por
/// la parada (no el recorrido completo de la ruta), con selector de día y
/// lista expandible. La próxima llegada se resalta.
class CommunityStopDetailScreen extends ConsumerStatefulWidget {
  const CommunityStopDetailScreen({super.key, required this.stopId});

  final String stopId;

  @override
  ConsumerState<CommunityStopDetailScreen> createState() =>
      _CommunityStopDetailScreenState();
}

class _CommunityStopDetailScreenState
    extends ConsumerState<CommunityStopDetailScreen> {
  late String _day = _todayBucket();
  final Set<String> _expanded = {};

  static const _dayOrder = ['weekday', 'saturday', 'sunday_holiday'];
  static const _dayLabels = {
    'weekday': 'Entre semana',
    'saturday': 'Sábado',
    'sunday_holiday': 'Domingo',
  };

  static String _todayBucket() {
    switch (DateTime.now().weekday) {
      case DateTime.saturday:
        return 'saturday';
      case DateTime.sunday:
        return 'sunday_holiday';
      default:
        return 'weekday';
    }
  }

  int _nowM() {
    final n = DateTime.now();
    return n.hour * 60 + n.minute;
  }

  int _toM(String hhmm) {
    final p = hhmm.split(':');
    if (p.length < 2) return -1;
    return (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final async = ref.watch(communityStopTimetableProvider(widget.stopId));
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
                        child: GestureDetector(
                          onTap: () => context.pop(),
                          child: Icon(Icons.arrow_back,
                              size: 24, color: c.textMid),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...async.when(
                        loading: () => [
                          const SizedBox(height: 80),
                          const Center(child: CircularProgressIndicator()),
                        ],
                        error: (_, __) => [
                          Text('No se pudo cargar la parada',
                              style: TransitTypography.bodyPrimary(c.textMid)),
                        ],
                        data: (tt) => tt == null
                            ? [
                                Text('Parada no encontrada',
                                    style: TransitTypography.heading(c.textHi)),
                              ]
                            : _content(c, tt),
                      ),
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

  List<Widget> _content(TransitColorScheme c, CommunityStopTimetable tt) {
    final isFav = ref.watch(userFavoriteStopsProvider).contains(widget.stopId);
    return [
      // ── HEADER ── (estrella idéntica a las paradas oficiales: toggle +
      // toast "Añadida/Quitada de favoritas").
      Row(
        children: [
          Expanded(
            child: Text(tt.stopName.toUpperCase(),
                style: TransitTypography.heading(c.textHi)),
          ),
          IconButton(
            icon: Icon(isFav ? Icons.star : Icons.star_border, color: c.accent),
            tooltip: isFav ? 'Quitar de favoritas' : 'Añadir a favoritas',
            onPressed: () {
              ref
                  .read(userFavoriteStopsProvider.notifier)
                  .toggleStop(widget.stopId);
              showStopFavoriteToast(
                context,
                stop: StopModel(
                  id: widget.stopId,
                  name: tt.stopName,
                  officialCode: '',
                  lat: tt.lat,
                  lng: tt.lng,
                  municipality: '',
                ),
                added: !isFav,
              );
            },
          ),
        ],
      ),
      const SizedBox(height: 6),
      _communityBadge(),
      Divider(height: 32, thickness: 0.5, color: c.border),

      // ── HORARIOS (solo de esta parada) ──
      Text('HORARIOS', style: TransitTypography.sectionTitle(c.textMid)),
      const SizedBox(height: 12),
      if (tt.lines.isEmpty)
        Text('Esta parada no tiene horarios registrados',
            style: TransitTypography.bodySecondary(c.textMid))
      else ...[
        _daySelector(c),
        const SizedBox(height: 14),
        ...tt.lines.map((l) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _lineCard(c, l),
            )),
      ],

      Divider(height: 32, thickness: 0.5, color: c.border),

      // ── LÍNEAS QUE PASAN ──
      Text('LÍNEAS', style: TransitTypography.sectionTitle(c.textMid)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: tt.lines
            .map((l) => TransitChip(
                  l.code,
                  color: l.color,
                  onTap: () => context.push('/community/route/${l.routeId}'),
                ))
            .toList(),
      ),
      const SizedBox(height: 24),

      // ── ACCIÓN: ver en mapa ──
      Center(
        child: Pressable(
          onTap: () {
            ref.read(searchSelectionProvider.notifier).state = SearchSelection(
              id: 'community-stop-${widget.stopId}',
              position: LatLng(tt.lat, tt.lng),
              title: tt.stopName,
              subtitle: 'Parada de la comunidad',
              icon: Icons.directions_bus,
              color: const Color(0xFF4CAF50),
            );
            context.go('/home/mapa');
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
                child: Icon(Icons.map_outlined, size: 18, color: c.textHi),
              ),
              const SizedBox(height: 4),
              Text('Ver en mapa',
                  style: TransitTypography.bodySmall(c.textMid)),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
    ];
  }

  Widget _communityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.groups_outlined, size: 13, color: Color(0xFF4CAF50)),
          const SizedBox(width: 5),
          Text('PARADA DE LA COMUNIDAD',
              style: TransitTypography.bodySmall(const Color(0xFF4CAF50))
                  .copyWith(fontSize: 10.5, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  // ── Selector de día (idéntico al oficial) ──
  Widget _daySelector(TransitColorScheme c) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.bgRaised.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: _dayOrder.map((d) {
          final selected = d == _day;
          return Expanded(
            child: Pressable(
              onTap: () => setState(() => _day = d),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: selected ? c.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  _dayLabels[d]!,
                  style: TransitTypography.bodySmall(
                          selected ? Colors.white : c.textMid)
                      .copyWith(
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Tarjeta de línea con horario de ESTA parada (idéntica a la oficial) ──
  Widget _lineCard(TransitColorScheme c, CommunityStopLine l) {
    final times = l.hoursByDay[_day] ?? const <String>[];
    final isToday = _day == _todayBucket();
    final nowM = _nowM();
    final nextIdx = isToday ? times.indexWhere((t) => _toM(t) >= nowM) : -1;
    final nextTime =
        nextIdx >= 0 ? times[nextIdx] : (times.isNotEmpty ? times.first : null);
    final countdown = (nextIdx >= 0) ? _toM(times[nextIdx]) - nowM : null;
    final expanded = _expanded.contains(l.code);

    return GlassCard(
      blur: 12,
      fillOpacity: 0.05,
      borderRadius: 14,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Pressable(
            onTap: () => setState(() {
              expanded ? _expanded.remove(l.code) : _expanded.add(l.code);
            }),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  TransitChip(l.code, color: l.color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.name,
                            style: TransitTypography.bodyPrimary(c.textHi),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(
                            times.isEmpty
                                ? 'sin paso este día'
                                : '${times.length} pasos · comunidad',
                            style: TransitTypography.bodySmall(c.textLo)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (nextTime != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(nextTime,
                            style: GoogleFonts.ibmPlexMono(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: countdown != null ? c.accent : c.textHi,
                            )),
                        if (countdown != null)
                          Text(countdown <= 0 ? 'llegando' : 'en $countdown min',
                              style: TransitTypography.bodySmall(
                                  countdown <= 10 ? c.accent : c.textMid))
                        else if (isToday)
                          Text('sin más hoy',
                              style: TransitTypography.bodySmall(c.textLo)),
                      ],
                    ),
                  if (times.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(Icons.expand_more, color: c.textMid),
                    ),
                  ],
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState:
                expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < times.length; i++)
                    Text(
                      times[i],
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 13,
                        fontWeight:
                            i == nextIdx ? FontWeight.w700 : FontWeight.w500,
                        color: i == nextIdx
                            ? c.accent
                            : (isToday && _toM(times[i]) < nowM
                                ? c.textLo
                                : c.textHi),
                      ),
                    ),
                ],
              ),
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
