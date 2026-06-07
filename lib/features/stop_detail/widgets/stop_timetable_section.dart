import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../data/stop_timetable/stop_timetable_provider.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/transit_chip.dart';

/// Sección de HORARIOS de una parada: por cada línea que pasa, su horario
/// completo del día seleccionado (entre semana / sábado). Verano no publica
/// domingos/festivos. Usa los horarios exactos por parada cargados desde los
/// PDFs oficiales (RPC stop_timetable_by_name). Si no hay datos exactos para
/// esta parada, no pinta nada (la pantalla mantiene "próximas llegadas").
class StopTimetableSection extends ConsumerStatefulWidget {
  const StopTimetableSection({super.key, required this.stopName});

  final String stopName;

  @override
  ConsumerState<StopTimetableSection> createState() =>
      _StopTimetableSectionState();
}

class _StopTimetableSectionState extends ConsumerState<StopTimetableSection> {
  late String _day = _todayDayType();

  static const _dayLabels = {
    'weekday': 'Entre semana',
    'saturday': 'Sábado',
    'sunday_holiday': 'Domingo/festivo',
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

  int _nowMinutes() {
    final n = DateTime.now();
    return n.hour * 60 + n.minute;
  }

  int _toMinutes(String hhmm) {
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
    final async = ref.watch(stopTimetableProvider(widget.stopName));

    return async.maybeWhen(
      orElse: () => const SizedBox.shrink(),
      data: (tt) {
        if (tt.isEmpty) return const SizedBox.shrink();
        // Si el día seleccionado no tiene datos, cae al primero disponible.
        final days = tt.availableDays;
        final day = tt.forDay(_day).isNotEmpty
            ? _day
            : (days.isNotEmpty ? days.first : _day);
        final lines = tt.forDay(day);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text('HORARIOS POR LÍNEA',
                  style: TransitTypography.sectionTitle(c.textMid)),
            ),
            const SizedBox(height: 10),
            _daySelector(c, days),
            const SizedBox(height: 12),
            if (lines.isEmpty)
              Text(
                _day == 'sunday_holiday'
                    ? 'Sin servicio los domingos y festivos en verano.'
                    : 'Sin horario disponible para este día.',
                style: TransitTypography.bodySecondary(c.textMid),
              )
            else
              ...lines.map((l) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _lineBlock(c, l),
                  )),
            Divider(height: 32, thickness: 0.5, color: c.border),
          ],
        );
      },
    );
  }

  Widget _daySelector(TransitColorScheme c, List<String> available) {
    // Mostramos siempre entre semana y sábado; domingo solo si hay datos.
    final days = <String>['weekday', 'saturday'];
    if (available.contains('sunday_holiday')) days.add('sunday_holiday');
    return Wrap(
      spacing: 8,
      children: days.map((d) {
        final selected = d == _day;
        return Pressable(
          onTap: () => setState(() => _day = d),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? c.accent.withValues(alpha: 0.15)
                  : c.bgRaised.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: selected ? c.accent : c.border),
            ),
            child: Text(
              _dayLabels[d]!,
              style: TransitTypography.bodySmall(
                  selected ? c.accent : c.textMid),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _lineBlock(TransitColorScheme c, LineTimes l) {
    final nowM = _nowMinutes();
    final color = _hex(l.color, c.accent);
    final isToday = _day == _todayDayType();
    final nextIdx = isToday
        ? l.times.indexWhere((t) => _toMinutes(t) >= nowM)
        : -1;

    return Column(
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
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            for (var i = 0; i < l.times.length; i++)
              Text(
                l.times[i],
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 13,
                  fontWeight: i == nextIdx ? FontWeight.w700 : FontWeight.w500,
                  color: i == nextIdx
                      ? c.accent
                      : (isToday && _toMinutes(l.times[i]) < nowM
                          ? c.textLo
                          : c.textHi),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
