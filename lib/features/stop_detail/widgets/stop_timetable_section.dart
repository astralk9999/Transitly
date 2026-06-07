import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../data/mock/mock_data_service.dart';
import '../../../data/stop_timetable/stop_timetable_provider.dart';
import '../../../shared/providers/route_lookup_providers.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/transit_chip.dart';

/// Sección de HORARIOS de una parada. Fuente única para evitar el desfase entre
/// "próximas llegadas" estimadas y el horario real: para cada línea que pasa,
/// muestra la próxima llegada y el horario completo del día seleccionado a
/// partir de los datos exactos (RPC stop_timetable_by_name). Las líneas que
/// aún no tienen horario exacto cargado se listan aparte como estimación.
class StopTimetableSection extends ConsumerStatefulWidget {
  const StopTimetableSection({
    super.key,
    required this.stopId,
    required this.stopName,
  });

  final String stopId;
  final String stopName;

  @override
  ConsumerState<StopTimetableSection> createState() =>
      _StopTimetableSectionState();
}

class _StopTimetableSectionState extends ConsumerState<StopTimetableSection> {
  late String _day = _todayDayType();
  final Set<String> _expanded = {};

  static const _dayOrder = ['weekday', 'saturday', 'sunday_holiday'];
  static const _dayLabels = {
    'weekday': 'Entre semana',
    'saturday': 'Sábado',
    'sunday_holiday': 'Domingo',
  };

  static String _todayDayType() {
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

  Color _hex(String hex, Color fallback) {
    try {
      final h = hex.replaceFirst('#', '');
      return Color(int.parse('FF${h.length == 6 ? h : '977DDF'}', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final mockData = ref.watch(mockDataServiceProvider);
    final routesAtStop =
        ref.watch(stopToRouteCodesProvider)[widget.stopId] ?? const <String>[];
    final exact = ref
        .watch(stopTimetableProvider(widget.stopName))
        .valueOrNull;

    // Líneas con horario exacto para el día seleccionado, indexadas por código.
    final exactByCode = <String, LineTimes>{
      for (final l in (exact?.forDay(_day) ?? const <LineTimes>[])) l.code: l,
    };
    final exactCodes = {
      for (final d in _dayOrder)
        for (final l in (exact?.forDay(d) ?? const <LineTimes>[])) l.code,
    };

    // Particiona las líneas de la parada en exactas vs estimadas.
    final exactRoutes = <_RouteRef>[];
    final estimatedRoutes = <_RouteRef>[];
    for (final id in routesAtStop) {
      final r = mockData.getRouteById(id);
      if (r == null) continue;
      final rref = _RouteRef(id: id, code: r.code, name: r.name, color: r.routeColor);
      (exactCodes.contains(r.code) ? exactRoutes : estimatedRoutes).add(rref);
    }
    exactRoutes.sort((a, b) => a.code.compareTo(b.code));
    estimatedRoutes.sort((a, b) => a.code.compareTo(b.code));

    if (exactRoutes.isEmpty && estimatedRoutes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text('HORARIOS',
              style: TransitTypography.sectionTitle(c.textMid)),
        ),
        const SizedBox(height: 12),
        if (exactRoutes.isNotEmpty) ...[
          _daySelector(c),
          const SizedBox(height: 14),
          ...exactRoutes.map((r) {
            final line = exactByCode[r.code];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _exactCard(c, r, line),
            );
          }),
        ],
        if (estimatedRoutes.isNotEmpty) ...[
          if (exactRoutes.isNotEmpty) const SizedBox(height: 6),
          _estimatedBlock(c, mockData, estimatedRoutes),
        ],
        Divider(height: 32, thickness: 0.5, color: c.border),
      ],
    );
  }

  // ── Selector de día ────────────────────────────────────────────────
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

  // ── Tarjeta de línea con horario exacto ────────────────────────────
  Widget _exactCard(TransitColorScheme c, _RouteRef r, LineTimes? line) {
    final color = line != null ? _hex(line.color, r.color) : r.color;
    final times = line?.times ?? const <String>[];
    final isToday = _day == _todayDayType();
    final nowM = _nowM();
    final nextIdx = isToday ? times.indexWhere((t) => _toM(t) >= nowM) : -1;
    final nextTime = nextIdx >= 0 ? times[nextIdx] : (times.isNotEmpty ? times.first : null);
    final countdown = (nextIdx >= 0) ? _toM(times[nextIdx]) - nowM : null;
    final expanded = _expanded.contains(r.code);

    return GlassCard(
      blur: 12,
      fillOpacity: 0.05,
      borderRadius: 14,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Pressable(
            onTap: () => setState(() {
              expanded ? _expanded.remove(r.code) : _expanded.add(r.code);
            }),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  TransitChip(r.code, color: color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.name,
                            style: TransitTypography.bodyPrimary(c.textHi),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('${times.length} pasos · horario oficial',
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
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(Icons.expand_more, color: c.textMid),
                  ),
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

  // ── Bloque de líneas sin horario exacto (estimación) ───────────────
  Widget _estimatedBlock(
      TransitColorScheme c, MockDataService mockData, List<_RouteRef> routes) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 13, color: c.textLo),
              const SizedBox(width: 6),
              Text('Otras líneas · horario estimado',
                  style: TransitTypography.bodySmall(c.textLo)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: routes.map((r) {
              final deps = mockData.getNextDepartures(r.id, widget.stopId, 1);
              final next = deps.isNotEmpty ? deps.first.departureTime : '--:--';
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: c.bgRaised.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TransitChip(r.code, color: r.color),
                    const SizedBox(width: 8),
                    Text('~$next',
                        style: GoogleFonts.ibmPlexMono(
                            fontSize: 12, color: c.textMid)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _RouteRef {
  _RouteRef({required this.id, required this.code, required this.name, required this.color});
  final String id;
  final String code;
  final String name;
  final Color color;
}
