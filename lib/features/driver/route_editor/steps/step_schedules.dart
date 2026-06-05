import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/transit_colors.dart';
import '../../../../core/theme/transit_typography.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/transit_button.dart';
import '../../../../shared/widgets/transit_input.dart';
import '../editor_controller.dart';

/// Sub P2-06: paso de horarios con 3 modos (Fijas / Frecuencia / Híbrido)
/// por cada día (weekday / saturday / sunday).
class StepSchedules extends StatelessWidget {
  const StepSchedules({
    super.key,
    required this.controller,
    required this.onNext,
  });

  final RouteEditorController controller;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => DefaultTabController(
        length: 3,
        child: Column(
          children: [
            TabBar(
              indicatorColor: c.accent,
              labelColor: c.accent,
              unselectedLabelColor: c.textMid,
              labelStyle: GoogleFonts.ibmPlexMono(
                  fontSize: 11, fontWeight: FontWeight.w600),
              tabs: [
                Tab(
                    text: AppLocalizations.of(context)
                        .routeDayWeekday
                        .toUpperCase()),
                Tab(
                    text: AppLocalizations.of(context)
                        .routeDaySaturday
                        .toUpperCase()),
                Tab(
                    text: AppLocalizations.of(context)
                        .routeDayHoliday
                        .toUpperCase()),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _ScheduleTab(controller: controller, keyName: 'weekday'),
                  _ScheduleTab(controller: controller, keyName: 'saturday'),
                  _ScheduleTab(controller: controller, keyName: 'sunday'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tiempo total (min)',
                      style: TransitTypography.bodySecondary(c.textMid)),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 120,
                    child: TransitInput(
                      hint: '45',
                      controller: controller.totalTimeCtrl,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TransitButton(
                      label: AppLocalizations.of(context)
                          .actionNext
                          .toUpperCase(),
                      onPressed: onNext,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleTab extends StatelessWidget {
  const _ScheduleTab({required this.controller, required this.keyName});

  final RouteEditorController controller;
  final String keyName;

  Future<String?> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked == null) return null;
    return '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final mode = controller.scheduleMode[keyName] ?? 'fixed';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'fixed',
                label: Text('Fijas'),
                icon: Icon(Icons.schedule, size: 16),
              ),
              ButtonSegment(
                value: 'frequency',
                label: Text('Frecuencia'),
                icon: Icon(Icons.update, size: 16),
              ),
              ButtonSegment(
                value: 'hybrid',
                label: Text('Híbrido'),
                icon: Icon(Icons.merge_type, size: 16),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (s) {
              if (s.isNotEmpty) {
                controller.setScheduleMode(keyName, s.first);
              }
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return c.accent;
                return c.bgRaised;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return Colors.white;
                return c.textMid;
              }),
              side: WidgetStateProperty.all(
                BorderSide(color: c.border, width: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (mode == 'fixed') _FixedModeEditor(controller: controller, keyName: keyName, c: c, pickTime: _pickTime),
          if (mode == 'frequency') _FrequencyModeEditor(controller: controller, keyName: keyName, c: c),
          if (mode == 'hybrid') _HybridModeEditor(controller: controller, keyName: keyName, c: c, pickTime: _pickTime),
          const SizedBox(height: 16),
          _PreviewSection(controller: controller, keyName: keyName, c: c),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Modo Fijas
// ---------------------------------------------------------------------------
class _FixedModeEditor extends StatelessWidget {
  const _FixedModeEditor({
    required this.controller,
    required this.keyName,
    required this.c,
    required this.pickTime,
  });
  final RouteEditorController controller;
  final String keyName;
  final TransitColorScheme c;
  final Future<String?> Function(BuildContext) pickTime;

  @override
  Widget build(BuildContext context) {
    final times = controller.schedules[keyName] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Horas (${times.length})',
            style: TransitTypography.sectionTitle(c.textMid)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...times.asMap().entries.map((e) => _TimeChip(
                  text: e.value,
                  c: c,
                  onDelete: () =>
                      controller.removeScheduleTime(keyName, e.key),
                )),
            GestureDetector(
              onTap: () async {
                final t = await pickTime(context);
                if (t != null) controller.addScheduleTime(keyName, t);
              },
              child: Container(
                width: 64,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.bgSurface,
                  border: Border.all(color: c.accent, width: 1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.add, size: 18, color: c.accent),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Modo Frecuencia
// ---------------------------------------------------------------------------
class _FrequencyModeEditor extends StatelessWidget {
  const _FrequencyModeEditor({
    required this.controller,
    required this.keyName,
    required this.c,
  });
  final RouteEditorController controller;
  final String keyName;
  final TransitColorScheme c;

  @override
  Widget build(BuildContext context) {
    final start = controller.scheduleFreqStart[keyName] ?? '07:00';
    final end = controller.scheduleFreqEnd[keyName] ?? '22:00';
    final interval = controller.scheduleFreqInterval[keyName] ?? 15;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _TimeField(
                label: 'Inicio',
                value: start,
                c: c,
                onChanged: (v) =>
                    controller.setScheduleFreq(keyName, start: v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TimeField(
                label: 'Fin',
                value: end,
                c: c,
                onChanged: (v) =>
                    controller.setScheduleFreq(keyName, end: v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Intervalo: $interval min',
            style: TransitTypography.bodySecondary(c.textMid)),
        const SizedBox(height: 4),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 5, label: Text('5')),
            ButtonSegment(value: 10, label: Text('10')),
            ButtonSegment(value: 15, label: Text('15')),
            ButtonSegment(value: 20, label: Text('20')),
            ButtonSegment(value: 30, label: Text('30')),
            ButtonSegment(value: 60, label: Text('60')),
          ],
          selected: {interval},
          onSelectionChanged: (s) {
            if (s.isNotEmpty) {
              controller.setScheduleFreq(keyName, interval: s.first);
            }
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return c.accent;
              return c.bgRaised;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return Colors.white;
              return c.textMid;
            }),
            side: WidgetStateProperty.all(
              BorderSide(color: c.border, width: 0.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Modo Híbrido
// ---------------------------------------------------------------------------
class _HybridModeEditor extends StatelessWidget {
  const _HybridModeEditor({
    required this.controller,
    required this.keyName,
    required this.c,
    required this.pickTime,
  });
  final RouteEditorController controller;
  final String keyName;
  final TransitColorScheme c;
  final Future<String?> Function(BuildContext) pickTime;

  @override
  Widget build(BuildContext context) {
    final extras = controller.scheduleExtras[keyName] ?? [];
    final excludes = controller.scheduleExcludes[keyName] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FrequencyModeEditor(controller: controller, keyName: keyName, c: c),
        const SizedBox(height: 16),
        Text('Horas extra (${extras.length})',
            style: TransitTypography.sectionTitle(c.textMid)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ...extras.asMap().entries.map((e) => _TimeChip(
                  text: e.value,
                  c: c,
                  color: c.stateOnRoute,
                  onDelete: () =>
                      controller.removeScheduleExtraAt(keyName, e.key),
                )),
            GestureDetector(
              onTap: () async {
                final t = await pickTime(context);
                if (t != null) controller.addScheduleExtra(keyName, t);
              },
              child: Container(
                width: 56,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.bgSurface,
                  border: Border.all(color: c.stateOnRoute, width: 1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.add, size: 16, color: c.stateOnRoute),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Horas excluidas (${excludes.length})',
            style: TransitTypography.sectionTitle(c.textMid)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ...excludes.asMap().entries.map((e) => _TimeChip(
                  text: e.value,
                  c: c,
                  color: c.stateCancelled,
                  onDelete: () =>
                      controller.removeScheduleExcludeAt(keyName, e.key),
                )),
            GestureDetector(
              onTap: () async {
                final t = await pickTime(context);
                if (t != null) controller.addScheduleExclude(keyName, t);
              },
              child: Container(
                width: 56,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.bgSurface,
                  border: Border.all(color: c.stateCancelled, width: 1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.add, size: 16, color: c.stateCancelled),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Preview compartido (lista efectiva + paradas si hay)
// ---------------------------------------------------------------------------
class _PreviewSection extends StatelessWidget {
  const _PreviewSection({
    required this.controller,
    required this.keyName,
    required this.c,
  });
  final RouteEditorController controller;
  final String keyName;
  final TransitColorScheme c;

  @override
  Widget build(BuildContext context) {
    final times = controller.generateScheduleTimes(keyName);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.bgRaised,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility_outlined, size: 16, color: c.accent),
              const SizedBox(width: 6),
              Text('Vista previa: ${times.length} salidas',
                  style: TransitTypography.sectionTitle(c.accent)),
            ],
          ),
          const SizedBox(height: 6),
          if (times.isEmpty)
            Text('Sin salidas (configura los parámetros)',
                style: TransitTypography.bodySmall(c.textLo))
          else
            Text(
              times.length > 10
                  ? '${times.take(10).join(', ')}, …'
                  : times.join(', '),
              style: GoogleFonts.ibmPlexMono(fontSize: 12, color: c.textMid),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets auxiliares
// ---------------------------------------------------------------------------
class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.text,
    required this.c,
    required this.onDelete,
    this.color,
  });
  final String text;
  final TransitColorScheme c;
  final VoidCallback onDelete;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accentColor = color ?? c.accent;
    return InputChip(
      label: Text(text,
          style: GoogleFonts.ibmPlexMono(fontSize: 12, color: c.textHi)),
      backgroundColor: c.bgSurface,
      side: BorderSide(color: accentColor, width: 0.5),
      deleteIcon: const Icon(Icons.close, size: 14),
      deleteIconColor: c.textLo,
      onDeleted: onDelete,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    );
  }
}

class _TimeField extends StatefulWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.c,
    required this.onChanged,
  });
  final String label;
  final String value;
  final TransitColorScheme c;
  final ValueChanged<String> onChanged;

  @override
  State<_TimeField> createState() => _TimeFieldState();
}

class _TimeFieldState extends State<_TimeField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_TimeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _ctrl.text) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: TransitTypography.bodySecondary(widget.c.textMid)),
        const SizedBox(height: 4),
        SizedBox(
          height: 40,
          child: TextField(
            controller: _ctrl,
            onChanged: widget.onChanged,
            style: GoogleFonts.ibmPlexMono(fontSize: 14, color: widget.c.textHi),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: widget.c.bgRaised,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: widget.c.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: widget.c.border),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
