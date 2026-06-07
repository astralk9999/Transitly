import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../data/stop_timetable/stop_timetable_provider.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/transit_chip.dart';

/// Abre el horario COMPLETO de todas las líneas que pasan por la parada, con
/// selector de día. Pensado como vista "tabla horaria" a pantalla casi
/// completa (bottom sheet expandible), distinta de la vista resumida de la
/// pantalla de parada.
Future<void> showStopFullTimetableSheet(
  BuildContext context, {
  required String stopId,
  required String stopName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _StopFullTimetableSheet(stopId: stopId, stopName: stopName),
  );
}

class _StopFullTimetableSheet extends ConsumerStatefulWidget {
  const _StopFullTimetableSheet({required this.stopId, required this.stopName});

  final String stopId;
  final String stopName;

  @override
  ConsumerState<_StopFullTimetableSheet> createState() => _State();
}

class _State extends ConsumerState<_StopFullTimetableSheet> {
  late String _day = _todayDayType();

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

  int _toM(String t) {
    final p = t.split(':');
    if (p.length < 2) return -1;
    return (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
  }

  Color _hex(String hex, Color fb) {
    try {
      final h = hex.replaceFirst('#', '');
      return Color(int.parse('FF${h.length == 6 ? h : '977DDF'}', radix: 16));
    } catch (_) {
      return fb;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final async = ref.watch(stopTimetableProvider(widget.stopName));

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return GlassCard(
          blur: 30,
          fillOpacity: 0.14,
          borderRadius: 24,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.textLo.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: c.accent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Horario de la parada',
                              style: TransitTypography.bodyPrimary(c.textHi)
                                  .copyWith(fontWeight: FontWeight.w700)),
                          Text(widget.stopName,
                              style: TransitTypography.bodySmall(c.textMid),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: c.textMid),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _daySelector(c),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: async.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => Center(
                    child: Text('No se pudo cargar el horario',
                        style: TransitTypography.bodySecondary(c.textMid)),
                  ),
                  data: (tt) {
                    final lines = tt.forDay(_day);
                    if (lines.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            _day == 'sunday_holiday'
                                ? 'Sin servicio los domingos y festivos en verano para estas líneas.'
                                : 'Sin horario oficial cargado para este día.',
                            textAlign: TextAlign.center,
                            style: TransitTypography.bodySecondary(c.textMid),
                          ),
                        ),
                      );
                    }
                    return ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      children: lines.map((l) => _lineTable(c, l)).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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

  Widget _lineTable(TransitColorScheme c, LineTimes l) {
    final color = _hex(l.color, c.accent);
    final isToday = _day == _todayDayType();
    final nowM = _nowM();
    final nextIdx = isToday ? l.times.indexWhere((t) => _toM(t) >= nowM) : -1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TransitChip(l.code, color: color),
              const SizedBox(width: 10),
              Text('${l.times.length} pasos',
                  style: TransitTypography.bodySmall(c.textLo)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < l.times.length; i++)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: i == nextIdx
                        ? c.accent.withValues(alpha: 0.18)
                        : c.bgRaised.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: i == nextIdx ? c.accent : c.border),
                  ),
                  child: Text(
                    l.times[i],
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 13,
                      fontWeight:
                          i == nextIdx ? FontWeight.w700 : FontWeight.w500,
                      color: i == nextIdx
                          ? c.accent
                          : (isToday && _toM(l.times[i]) < nowM
                              ? c.textLo
                              : c.textHi),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
