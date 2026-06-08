import 'package:flutter/material.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/transit_button.dart';
import 'wizard_models.dart';

/// Paso de horarios — rejilla por parada (estilo cuadro COMUJESA).
///
/// Una fila por parada; a su derecha, muchas horas (chips) a las que el bus
/// pasa por esa parada. Cada "columna" de horas equivale a una expedición.
/// Selector de tipo de día arriba. Botón para generar por frecuencia
/// (rellena automáticamente con un desfase entre paradas) y casilla de
/// servicio a demanda. Sustituye los 4 modos confusos anteriores.
class StepSchedules extends StatefulWidget {
  const StepSchedules({
    super.key,
    required this.schedules,
    required this.stops,
    required this.onChanged,
  });

  final List<WizardSchedule> schedules;
  final List<WizardStop> stops;
  final VoidCallback onChanged;

  @override
  State<StepSchedules> createState() => _StepSchedulesState();
}

const _dayTypes = [
  'weekday',
  'saturday',
  'sunday',
  'holiday',
  'every_day',
];
const _dayLabels = {
  'weekday': 'Laborables',
  'saturday': 'Sábados',
  'sunday': 'Domingos',
  'holiday': 'Festivos',
  'every_day': 'Todos los días',
};

class _StepSchedulesState extends State<StepSchedules> {
  String _dayType = 'weekday';
  bool _onDemand = false;

  /// Horas de un stop en el día activo, ordenadas.
  List<WizardSchedule> _forStop(String stopId) => widget.schedules
      .where((s) => s.dayType == _dayType && s.originStopId == stopId)
      .toList()
    ..sort((a, b) => a.departureTime.compareTo(b.departureTime));

  Future<void> _addTime(WizardStop stop) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 7, minute: 0),
    );
    if (picked == null) return;
    final t =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    // Evita duplicados en la misma parada/día.
    final exists = widget.schedules.any((s) =>
        s.dayType == _dayType &&
        s.originStopId == stop.stopId &&
        s.departureTime == t);
    if (!exists) {
      widget.schedules.add(WizardSchedule(
        dayType: _dayType,
        departureTime: t,
        originStopId: stop.stopId,
      ));
      widget.onChanged();
      setState(() {});
    }
  }

  void _removeTime(WizardSchedule s) {
    widget.schedules.remove(s);
    widget.onChanged();
    setState(() {});
  }

  void _clearDay() {
    widget.schedules
        .removeWhere((s) => s.dayType == _dayType);
    widget.onChanged();
    setState(() {});
  }

  Future<void> _generateFrequency() async {
    final result = await showModalBottomSheet<_FreqResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FrequencySheet(),
    );
    if (result == null) return;
    // Genera expediciones desde 'from' hasta 'to' cada 'interval' min; cada
    // expedición pasa por la parada i a hora_salida + i*offset.
    var t = result.fromMin;
    while (t <= result.toMin) {
      for (var i = 0; i < widget.stops.length; i++) {
        final m = (t + i * result.offsetMin) % (24 * 60);
        final time =
            '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
        final stopId = widget.stops[i].stopId;
        final exists = widget.schedules.any((s) =>
            s.dayType == _dayType &&
            s.originStopId == stopId &&
            s.departureTime == time);
        if (!exists) {
          widget.schedules.add(WizardSchedule(
            dayType: _dayType,
            departureTime: time,
            originStopId: stopId,
          ));
        }
      }
      t += result.interval;
    }
    widget.onChanged();
    setState(() {});
  }

  int get _dayTotalTimes =>
      widget.schedules.where((s) => s.dayType == _dayType).length;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    if (widget.stops.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Añade paradas primero en el paso anterior para poder fijar sus horarios.',
            textAlign: TextAlign.center,
            style: TransitTypography.bodySecondary(c.textMid),
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Horarios', style: TransitTypography.heading(c.textHi)),
              const SizedBox(height: 4),
              Text(
                'Escribe las horas a las que el bus pasa por cada parada. '
                'Puedes meter muchas horas — como un cuadro de COMUJESA.',
                style: TransitTypography.bodySecondary(c.textMid),
              ),
              const SizedBox(height: 12),
              // Servicio a demanda.
              Pressable(
                onTap: () => setState(() => _onDemand = !_onDemand),
                child: Row(
                  children: [
                    Icon(
                        _onDemand
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        color: _onDemand ? c.accent : c.textMid,
                        size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Servicio a demanda (sin horario fijo)',
                          style: TransitTypography.bodyPrimary(c.textHi)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_onDemand)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'La ruta operará solo bajo petición. No se guardarán horarios fijos; '
                  'añade los detalles de contacto en la descripción.',
                  textAlign: TextAlign.center,
                  style: TransitTypography.bodySecondary(c.textMid),
                ),
              ),
            ),
          )
        else ...[
          // Selector de día.
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final d in _dayTypes) ...[
                  _dayChip(c, d),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          // Acciones.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TransitButton(
                    label: 'Generar por frecuencia',
                    icon: Icons.repeat,
                    isPrimary: false,
                    isSmall: true,
                    onPressed: _generateFrequency,
                  ),
                ),
                const SizedBox(width: 8),
                if (_dayTotalTimes > 0)
                  TransitButton(
                    label: 'Vaciar día',
                    icon: Icons.delete_sweep_outlined,
                    isDanger: true,
                    isSmall: true,
                    onPressed: _clearDay,
                  ),
              ],
            ),
          ),
          // Rejilla por parada.
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: widget.stops.length,
              itemBuilder: (_, i) => _stopRow(c, widget.stops[i], i),
            ),
          ),
        ],
      ],
    );
  }

  Widget _dayChip(TransitColorScheme c, String d) {
    final selected = _dayType == d;
    final count = widget.schedules.where((s) => s.dayType == d).length;
    return Pressable(
      onTap: () => setState(() => _dayType = d),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.accent.withValues(alpha: 0.18) : c.bgRaised,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? c.accent : c.border,
              width: selected ? 1.2 : 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_dayLabels[d] ?? d,
                style: TransitTypography.bodySmall(
                    selected ? c.accent : c.textMid)),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: (selected ? c.accent : c.textMid)
                      .withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$count',
                    style: TransitTypography.bodySmall(
                        selected ? c.accent : c.textMid)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stopRow(TransitColorScheme c, WizardStop stop, int index) {
    final times = _forStop(stop.stopId);
    final isFirst = index == 0;
    final isLast = index == widget.stops.length - 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: c.bgRaised,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border, width: 0.5),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isFirst
                        ? c.stateOnTime
                        : isLast
                            ? c.stateCancelled
                            : c.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Text('${index + 1}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(stop.name,
                      style: TransitTypography.bodyPrimary(c.textHi),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                Text('${times.length} h',
                    style: TransitTypography.bodySmall(c.textLo)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in times)
                  GestureDetector(
                    onTap: () => _removeTime(s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: c.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: c.accent.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(s.departureTime,
                              style: TransitTypography.bodyPrimary(c.textHi)),
                          const SizedBox(width: 4),
                          Icon(Icons.close, size: 13, color: c.textMid),
                        ],
                      ),
                    ),
                  ),
                // Botón añadir hora.
                Pressable(
                  onTap: () => _addTime(stop),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: c.bgInput,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: c.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 15, color: c.accent),
                        const SizedBox(width: 3),
                        Text('Hora',
                            style: TransitTypography.bodySmall(c.accent)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FreqResult {
  _FreqResult(this.fromMin, this.toMin, this.interval, this.offsetMin);
  final int fromMin;
  final int toMin;
  final int interval;
  final int offsetMin;
}

class _FrequencySheet extends StatefulWidget {
  const _FrequencySheet();
  @override
  State<_FrequencySheet> createState() => _FrequencySheetState();
}

class _FrequencySheetState extends State<_FrequencySheet> {
  TimeOfDay _from = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _to = const TimeOfDay(hour: 23, minute: 0);
  final _interval = TextEditingController(text: '30');
  final _offset = TextEditingController(text: '2');

  @override
  void dispose() {
    _interval.dispose();
    _offset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = TransitColorScheme.of(
        Theme.of(context).brightness == Brightness.dark);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: c.bgElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: c.border, width: 0.5),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Generar por frecuencia',
                    style: TransitTypography.heading(c.textHi)),
                const SizedBox(height: 4),
                Text(
                    'Crea expediciones cada N minutos. Cada parada se rellena '
                    'con un desfase respecto a la salida.',
                    style: TransitTypography.bodySmall(c.textMid)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _timeField(c, 'Desde', _from,
                          (t) => setState(() => _from = t)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _timeField(
                          c, 'Hasta', _to, (t) => setState(() => _to = t)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _numField(
                            c, 'Cada (min)', _interval)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _numField(
                            c, 'Min entre paradas', _offset)),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style:
                            FilledButton.styleFrom(backgroundColor: c.accent),
                        onPressed: _submit,
                        child: const Text('Generar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    final interval = int.tryParse(_interval.text) ?? 0;
    final offset = int.tryParse(_offset.text) ?? 0;
    if (interval <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Intervalo inválido')));
      return;
    }
    final fromMin = _from.hour * 60 + _from.minute;
    var toMin = _to.hour * 60 + _to.minute;
    if (toMin < fromMin) toMin += 24 * 60;
    Navigator.pop(context, _FreqResult(fromMin, toMin, interval, offset));
  }

  Widget _timeField(TransitColorScheme c, String label, TimeOfDay value,
      ValueChanged<TimeOfDay> onPick) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TransitTypography.bodySmall(c.textMid)),
        const SizedBox(height: 6),
        Pressable(
          onTap: () async {
            final p = await showTimePicker(context: context, initialTime: value);
            if (p != null) onPick(p);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: c.bgRaised,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border, width: 0.5),
            ),
            child: Text(
                '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}',
                style: TransitTypography.bodyPrimary(c.textHi)),
          ),
        ),
      ],
    );
  }

  Widget _numField(
      TransitColorScheme c, String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TransitTypography.bodySmall(c.textMid)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: c.bgRaised,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border, width: 0.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            style: TransitTypography.bodyPrimary(c.textHi),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
