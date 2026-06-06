import 'package:flutter/material.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_spacing.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/transit_button.dart';
import '../../../shared/widgets/transit_input.dart';
import 'wizard_models.dart';

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

class _StepSchedulesState extends State<StepSchedules> {
  String _mode = 'fixed';

  static const _modeOptions = ['fixed', 'frequency', 'relative', 'on_demand'];
  static const _modeLabels = {
    'fixed': 'Horas fijas',
    'frequency': 'Frecuencia',
    'relative': 'Por parada',
    'on_demand': 'A demanda',
  };

  static const _dayTypeLabels = {
    'weekday': 'L-V',
    'saturday': 'Sábado',
    'sunday': 'Domingo',
    'holiday': 'Festivo',
    'summer': 'Verano',
    'winter': 'Invierno',
    'every_day': 'Todos los días',
  };

  static const _dayTypeIcons = {
    'weekday': Icons.work,
    'saturday': Icons.weekend,
    'sunday': Icons.self_improvement,
    'holiday': Icons.celebration,
    'summer': Icons.wb_sunny,
    'winter': Icons.ac_unit,
    'every_day': Icons.calendar_today,
  };

  void _addSchedule(WizardSchedule schedule) {
    widget.schedules.add(schedule);
    widget.onChanged();
  }

  void _removeSchedule(int index) {
    widget.schedules.removeAt(index);
    widget.onChanged();
  }

  void _showAddScheduleModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = TransitColorScheme.of(isDark);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _AddScheduleSheet(
        onScheduleCreated: (s) {
          _addSchedule(s);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showFrequencyModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = TransitColorScheme.of(isDark);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _FrequencySheet(
        onGenerated: (schedules) {
          for (final s in schedules) {
            widget.schedules.add(s);
          }
          widget.onChanged();
          Navigator.pop(ctx);
        },
      ),
    );
  }

  List<Widget> _buildRelativeMode(TransitColorScheme colors) {
    if (widget.stops.isEmpty) {
      return [
        Text('Añade paradas primero en el paso 2',
            style: TransitTypography.bodySecondary(colors.textMid)),
      ];
    }
    return [
      Text(
        'Define la hora a la que el bus pasa por cada parada. Pulsa "Guardar" para crear los horarios.',
        style: TransitTypography.bodySecondary(colors.textMid),
      ),
      const SizedBox(height: 12),
      TransitButton(
        label: 'Abrir editor',
        icon: Icons.schedule,
        isPrimary: false,
        onPressed: _showPerStopSheet,
      ),
    ];
  }

  void _showPerStopSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = TransitColorScheme.of(isDark);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _PerStopSheet(
        stops: widget.stops,
        onGenerated: (perStop, dayTypes) {
          // Por cada (parada, día) creamos una entrada con
          // origin_stop_id = stopId y la hora correspondiente. El
          // modelo actual no tiene una tabla de "stop_times" así que
          // reutilizamos schedules con origin para representar el
          // paso por esa parada.
          for (final day in dayTypes) {
            for (final entry in perStop.entries) {
              final stopId = entry.key;
              final time = entry.value;
              if (time.isEmpty) continue;
              widget.schedules.add(WizardSchedule(
                dayType: day,
                departureTime: time,
                originStopId: stopId,
                notes: 'Paso por parada',
              ));
            }
          }
          widget.onChanged();
          Navigator.pop(ctx);
        },
      ),
    );
  }

  List<Widget> _buildOnDemandMode(TransitColorScheme colors) {
    return [
      Text('El servicio opera solo bajo petición.',
          style: TransitTypography.bodySecondary(colors.textMid)),
      const SizedBox(height: 8),
      Text(
          'Añade notas con información de contacto o cómo solicitarlo.',
          style: TransitTypography.bodySmall(colors.textLo)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = TransitColorScheme.of(isDark);

    final grouped = <String, List<WizardSchedule>>{};
    for (var i = 0; i < widget.schedules.length; i++) {
      final s = widget.schedules[i];
      grouped.putIfAbsent(s.dayType, () => []).add(s);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(TransitSpacing.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Horarios de salida',
                style: TransitTypography.heading(colors.textHi),
              ),
              const SizedBox(height: TransitSpacing.space4),
              Text(
                'Define las horas de salida para cada tipo de día.',
                style: TransitTypography.bodySecondary(colors.textMid),
              ),
              const SizedBox(height: TransitSpacing.space16),
              Row(
                children: [
                  for (final m in _modeOptions)
                    Padding(
                      padding: const EdgeInsets.only(right: TransitSpacing.space6),
                      child: _ModeChip(
                        label: _modeLabels[m] ?? m,
                        selected: _mode == m,
                        onTap: () => setState(() => _mode = m),
                        colors: colors,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: TransitSpacing.space12),
              if (_mode == 'fixed')
                TransitButton(
                  label: 'Añadir salida',
                  icon: Icons.add,
                  isPrimary: false,
                  onPressed: _showAddScheduleModal,
                )
              else if (_mode == 'frequency')
                TransitButton(
                  label: 'Generar frecuencia',
                  icon: Icons.repeat,
                  isPrimary: false,
                  onPressed: _showFrequencyModal,
                )
              else if (_mode == 'relative')
                ..._buildRelativeMode(colors)
              else if (_mode == 'on_demand')
                ..._buildOnDemandMode(colors),
            ],
          ),
        ),
        if (widget.schedules.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule, size: 48, color: colors.textLo),
                  const SizedBox(height: TransitSpacing.space12),
                  Text(
                    'Sin horarios',
                    style: TransitTypography.bodyPrimary(colors.textLo),
                  ),
                  const SizedBox(height: TransitSpacing.space4),
                  Text(
                    'Los horarios son opcionales',
                    style: TransitTypography.bodySmall(colors.textLo),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: TransitSpacing.space16,
              ),
              children: [
                for (final entry in grouped.entries) ...[
                  _DayTypeHeader(
                    dayType: entry.key,
                    label: _dayTypeLabels[entry.key] ?? entry.key,
                    iconData: _dayTypeIcons[entry.key] ?? Icons.schedule,
                    count: entry.value.length,
                    colors: colors,
                  ),
                  for (var i = 0; i < entry.value.length; i++)
                    _ScheduleTile(
                      schedule: entry.value[i],
                      dayLabel: _dayTypeLabels[entry.value[i].dayType] ??
                          entry.value[i].dayType,
                      onDelete: () {
                        final globalIndex =
                            widget.schedules.indexOf(entry.value[i]);
                        if (globalIndex >= 0) _removeSchedule(globalIndex);
                      },
                      colors: colors,
                    ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _DayTypeHeader extends StatelessWidget {
  const _DayTypeHeader({
    required this.dayType,
    required this.label,
    required this.iconData,
    required this.count,
    required this.colors,
  });

  final String dayType;
  final String label;
  final IconData iconData;
  final int count;
  final TransitColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: TransitSpacing.space16,
        bottom: TransitSpacing.space8,
      ),
      child: Row(
        children: [
          Icon(iconData, size: 16, color: colors.accent),
          const SizedBox(width: TransitSpacing.space8),
          Text(
            '$label ($count)',
            style: TransitTypography.bodyPrimary(colors.accent),
          ),
        ],
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({
    required this.schedule,
    required this.dayLabel,
    required this.onDelete,
    required this.colors,
  });

  final WizardSchedule schedule;
  final String dayLabel;
  final VoidCallback onDelete;
  final TransitColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TransitSpacing.space8),
      child: GlassCard(
        borderRadius: 8,
        padding: const EdgeInsets.symmetric(
          horizontal: TransitSpacing.space12,
          vertical: TransitSpacing.space8,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.departure_board,
                  size: 16, color: colors.accent),
            ),
            const SizedBox(width: TransitSpacing.space10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.departureTime,
                    style: TransitTypography.displayNumber(colors.textHi),
                  ),
                  if (schedule.notes != null &&
                      schedule.notes!.isNotEmpty)
                    Text(
                      schedule.notes!,
                      style: TransitTypography.bodySmall(colors.textLo),
                    ),
                ],
              ),
            ),
            Pressable(
              onTap: onDelete,
              child: Icon(Icons.close,
                  size: 18, color: colors.stateCancelled),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddScheduleSheet extends StatefulWidget {
  const _AddScheduleSheet({required this.onScheduleCreated});

  final ValueChanged<WizardSchedule> onScheduleCreated;

  @override
  State<_AddScheduleSheet> createState() => _AddScheduleSheetState();
}

class _AddScheduleSheetState extends State<_AddScheduleSheet> {
  final _timeCtrl = TextEditingController();
  final Set<String> _selectedDays = {};
  final _notesCtrl = TextEditingController();

  static const _dayOptions = [
    'weekday',
    'saturday',
    'sunday',
    'holiday',
    'summer',
    'winter',
    'every_day',
  ];

  static const _dayLabels = {
    'weekday': 'L-V',
    'saturday': 'Sábado',
    'sunday': 'Domingo',
    'holiday': 'Festivo',
    'summer': 'Verano',
    'winter': 'Invierno',
    'every_day': 'Todos los días',
  };

  @override
  void dispose() {
    _timeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _add() {
    final time = _timeCtrl.text.trim();
    if (!_isValidTime(time)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Formato de hora inválido (HH:mm)')),
      );
      return;
    }
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un tipo de día')),
      );
      return;
    }

    for (final day in _selectedDays) {
      widget.onScheduleCreated(WizardSchedule(
        dayType: day,
        departureTime: time,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      ));
    }
  }

  bool _isValidTime(String t) {
    final parts = t.split(':');
    if (parts.length != 2) return false;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    return h != null &&
        m != null &&
        h >= 0 &&
        h <= 23 &&
        m >= 0 &&
        m <= 59;
  }

  void _toggleDay(String day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = TransitColorScheme.of(isDark);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(TransitSpacing.space16),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: TransitSpacing.space16),
                Text(
                  'Añadir salida',
                  style: TransitTypography.heading(colors.textHi),
                ),
                const SizedBox(height: TransitSpacing.space20),

                Text(
                  'Hora de salida',
                  style: TransitTypography.bodyPrimary(colors.textHi),
                ),
                const SizedBox(height: TransitSpacing.space8),
                TransitInput(
                  hint: 'HH:mm (ej. 08:30)',
                  controller: _timeCtrl,
                  maxLines: 1,
                ),
                const SizedBox(height: TransitSpacing.space16),

                Text(
                  'Tipo de día',
                  style: TransitTypography.bodyPrimary(colors.textHi),
                ),
                const SizedBox(height: TransitSpacing.space8),
                Wrap(
                  spacing: TransitSpacing.space8,
                  runSpacing: TransitSpacing.space8,
                  children: _dayOptions.map((day) {
                    final selected = _selectedDays.contains(day);
                    return _DayChip(
                      label: _dayLabels[day] ?? day,
                      selected: selected,
                      onTap: () => _toggleDay(day),
                      colors: colors,
                    );
                  }).toList(),
                ),
                const SizedBox(height: TransitSpacing.space16),

                TransitInput(
                  hint: 'Notas (opcional)',
                  controller: _notesCtrl,
                  maxLines: 1,
                ),
                const SizedBox(height: TransitSpacing.space20),

                TransitButton(
                  label: 'Añadir',
                  onPressed: _add,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.colors,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final TransitColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TransitSpacing.space12,
          vertical: TransitSpacing.space6,
        ),
        decoration: BoxDecoration(
          color: selected
              ? colors.accent.withValues(alpha: 0.2)
              : colors.bgInput,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? colors.accent : colors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TransitTypography.bodySmall(
            selected ? colors.accent : colors.textMid,
          ),
        ),
      ),
    );
  }
}

class _FrequencySheet extends StatefulWidget {
  const _FrequencySheet({required this.onGenerated});

  final ValueChanged<List<WizardSchedule>> onGenerated;

  @override
  State<_FrequencySheet> createState() => _FrequencySheetState();
}

class _FrequencySheetState extends State<_FrequencySheet> {
  final _intervalCtrl = TextEditingController();
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final Set<String> _selectedDays = {};

  static const _dayOptions = [
    'weekday',
    'saturday',
    'sunday',
    'holiday',
    'summer',
    'winter',
    'every_day',
  ];

  static const _dayLabels = {
    'weekday': 'L-V',
    'saturday': 'Sábado',
    'sunday': 'Domingo',
    'holiday': 'Festivo',
    'summer': 'Verano',
    'winter': 'Invierno',
    'every_day': 'Todos los días',
  };

  @override
  void dispose() {
    _intervalCtrl.dispose();
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  void _generate() {
    final interval = int.tryParse(_intervalCtrl.text.trim());
    final from = _fromCtrl.text.trim();
    final to = _toCtrl.text.trim();

    if (interval == null || interval <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Intervalo inválido')),
      );
      return;
    }
    if (!_isValidTime(from) || !_isValidTime(to)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Formato de hora inválido (HH:mm)')),
      );
      return;
    }
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Selecciona al menos un tipo de día')),
      );
      return;
    }

    final fromMin = _toMinutes(from);
    final toMin = _toMinutes(to);
    final end = toMin <= fromMin ? toMin + 24 * 60 : toMin;

    final schedules = <WizardSchedule>[];
    for (var m = fromMin; m <= end; m += interval) {
      final h = (m ~/ 60) % 24;
      final min = m % 60;
      final time =
          '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
      for (final day in _selectedDays) {
        schedules.add(WizardSchedule(
          dayType: day,
          departureTime: time,
        ));
      }
    }

    widget.onGenerated(schedules);
  }

  bool _isValidTime(String t) {
    final parts = t.split(':');
    if (parts.length != 2) return false;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    return h != null &&
        m != null &&
        h >= 0 &&
        h <= 23 &&
        m >= 0 &&
        m <= 59;
  }

  int _toMinutes(String t) {
    final parts = t.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  void _toggleDay(String day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = TransitColorScheme.of(isDark);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.8,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(TransitSpacing.space16),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: TransitSpacing.space16),
                Text(
                  'Generar frecuencia',
                  style: TransitTypography.heading(colors.textHi),
                ),
                const SizedBox(height: TransitSpacing.space4),
                Text(
                  'Crea múltiples salidas con un intervalo fijo.',
                  style: TransitTypography.bodySecondary(colors.textMid),
                ),
                const SizedBox(height: TransitSpacing.space20),

                Text(
                  'Cada X minutos',
                  style: TransitTypography.bodyPrimary(colors.textHi),
                ),
                const SizedBox(height: TransitSpacing.space8),
                TransitInput(
                  hint: 'Ej. 15',
                  controller: _intervalCtrl,
                  maxLines: 1,
                ),
                const SizedBox(height: TransitSpacing.space16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Desde',
                            style: TransitTypography.bodyPrimary(
                                colors.textHi),
                          ),
                          const SizedBox(
                              height: TransitSpacing.space8),
                          TransitInput(
                            hint: 'HH:mm',
                            controller: _fromCtrl,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: TransitSpacing.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hasta',
                            style: TransitTypography.bodyPrimary(
                                colors.textHi),
                          ),
                          const SizedBox(
                              height: TransitSpacing.space8),
                          TransitInput(
                            hint: 'HH:mm',
                            controller: _toCtrl,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TransitSpacing.space16),

                Text(
                  'Tipo de día',
                  style: TransitTypography.bodyPrimary(colors.textHi),
                ),
                const SizedBox(height: TransitSpacing.space8),
                Wrap(
                  spacing: TransitSpacing.space8,
                  runSpacing: TransitSpacing.space8,
                  children: _dayOptions.map((day) {
                    final selected = _selectedDays.contains(day);
                    return _DayChip(
                      label: _dayLabels[day] ?? day,
                      selected: selected,
                      onTap: () => _toggleDay(day),
                      colors: colors,
                    );
                  }).toList(),
                ),
                const SizedBox(height: TransitSpacing.space20),

                TransitButton(
                  label: 'Generar salidas',
                  onPressed: _generate,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.colors,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final TransitColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TransitSpacing.space10,
          vertical: TransitSpacing.space6,
        ),
        decoration: BoxDecoration(
          color: selected ? colors.accent.withValues(alpha: 0.2) : colors.bgInput,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? colors.accent : colors.border,
          ),
        ),
        child: Text(label,
            style: TransitTypography.bodySmall(
                selected ? colors.accent : colors.textMid)),
      ),
    );
  }
}

class _PerStopSheet extends StatefulWidget {
  const _PerStopSheet({required this.stops, required this.onGenerated});
  final List<WizardStop> stops;
  final void Function(Map<String, String> perStop, Set<String> dayTypes)
      onGenerated;

  @override
  State<_PerStopSheet> createState() => _PerStopSheetState();
}

class _PerStopSheetState extends State<_PerStopSheet> {
  final Map<String, TextEditingController> _ctrls = {};
  final Set<String> _selectedDays = {};

  static const _dayOptions = [
    'weekday',
    'saturday',
    'sunday',
    'holiday',
    'summer',
    'winter',
    'every_day',
  ];

  static const _dayLabels = {
    'weekday': 'L-V',
    'saturday': 'Sábado',
    'sunday': 'Domingo',
    'holiday': 'Festivo',
    'summer': 'Verano',
    'winter': 'Invierno',
    'every_day': 'Todos los días',
  };

  @override
  void initState() {
    super.initState();
    for (final s in widget.stops) {
      _ctrls[s.stopId] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool _isValidTime(String t) {
    final parts = t.split(':');
    if (parts.length != 2) return false;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    return h != null && m != null && h >= 0 && h <= 23 && m >= 0 && m <= 59;
  }

  void _save() {
    final perStop = <String, String>{};
    for (final s in widget.stops) {
      final time = _ctrls[s.stopId]?.text.trim() ?? '';
      if (time.isEmpty) continue;
      if (!_isValidTime(time)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hora inválida en "${s.name}"')),
        );
        return;
      }
      perStop[s.stopId] = time;
    }
    if (perStop.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introduce al menos una hora')),
      );
      return;
    }
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un tipo de día')),
      );
      return;
    }
    widget.onGenerated(perStop, _selectedDays);
  }

  void _toggleDay(String day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = TransitColorScheme.of(isDark);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16,
              16 + MediaQuery.of(context).viewInsets.bottom),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Horarios por parada',
                  style: TransitTypography.heading(colors.textHi)),
              const SizedBox(height: 4),
              Text(
                'Hora a la que el bus pasa por cada parada. Deja en blanco las paradas sin servicio.',
                style: TransitTypography.bodySecondary(colors.textMid),
              ),
              const SizedBox(height: 16),
              Text('Tipo de día',
                  style: TransitTypography.bodyPrimary(colors.textHi)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _dayOptions.map((day) {
                  final selected = _selectedDays.contains(day);
                  return _DayChip(
                    label: _dayLabels[day] ?? day,
                    selected: selected,
                    onTap: () => _toggleDay(day),
                    colors: colors,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text('Hora por parada',
                  style: TransitTypography.bodyPrimary(colors.textHi)),
              const SizedBox(height: 8),
              for (var i = 0; i < widget.stops.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: i == 0
                              ? Colors.green
                              : i == widget.stops.length - 1
                                  ? Colors.red
                                  : colors.accent,
                          shape: BoxShape.circle,
                        ),
                        child: Text('${i + 1}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.stops[i].name,
                          style:
                              TransitTypography.bodyPrimary(colors.textHi),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: TransitInput(
                          hint: 'HH:mm',
                          controller: _ctrls[widget.stops[i].stopId]!,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              TransitButton(
                label: 'Guardar',
                onPressed: _save,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RelativeStopRow extends StatefulWidget {
  const _RelativeStopRow({
    required this.stop,
    required this.colors,
    required this.stops,
  });

  final WizardStop stop;
  final TransitColorScheme colors;
  final List<WizardStop> stops;

  @override
  State<_RelativeStopRow> createState() => _RelativeStopRowState();
}

class _RelativeStopRowState extends State<_RelativeStopRow> {
  final _minCtrl = TextEditingController();

  @override
  void dispose() {
    _minCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final index = widget.stops.indexOf(widget.stop);
    return Padding(
      padding: const EdgeInsets.only(bottom: TransitSpacing.space6),
      child: Row(
        children: [
          Icon(Icons.place, size: 16, color: widget.colors.accent),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              widget.stop.name,
              style: TransitTypography.bodyPrimary(widget.colors.textHi),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 60,
            child: TransitInput(
              hint: index == 0 ? '0' : 'min',
              controller: _minCtrl,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
