import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/transit_colors.dart';
import '../../../../core/theme/transit_typography.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/single_field_dialog.dart';
import '../../../../shared/widgets/transit_button.dart';
import '../../../../shared/widgets/transit_input.dart';
import '../editor_controller.dart';

class StepSchedules extends StatelessWidget {
  const StepSchedules({
    super.key,
    required this.controller,
    required this.onNext,
  });

  final RouteEditorController controller;
  final VoidCallback onNext;

  Future<void> _addTime(BuildContext context, String key) async {
    final time = await showSingleFieldDialog(
      context,
      title: 'Añadir hora',
      hint: 'HH:MM',
      confirmLabel: 'AÑADIR',
    );
    if (time != null) controller.addScheduleTime(key, time);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return DefaultTabController(
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
              Tab(text: AppLocalizations.of(context).routeDayWeekday.toUpperCase()),
              Tab(text: AppLocalizations.of(context).routeDaySaturday.toUpperCase()),
              Tab(text: AppLocalizations.of(context).routeDayHoliday.toUpperCase()),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ScheduleTab(
                  controller: controller,
                  keyName: 'weekday',
                  onAddTime: () => _addTime(context, 'weekday'),
                ),
                _ScheduleTab(
                  controller: controller,
                  keyName: 'saturday',
                  onAddTime: () => _addTime(context, 'saturday'),
                ),
                _ScheduleTab(
                  controller: controller,
                  keyName: 'sunday',
                  onAddTime: () => _addTime(context, 'sunday'),
                ),
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
                    label: 'SIGUIENTE',
                    onPressed: onNext,
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

class _ScheduleTab extends StatelessWidget {
  const _ScheduleTab({
    required this.controller,
    required this.keyName,
    required this.onAddTime,
  });

  final RouteEditorController controller;
  final String keyName;
  final VoidCallback onAddTime;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final times = controller.schedules[keyName]!;
    final stops = controller.stops;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...times.map((t) => Container(
                    width: 60,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.bgSurface,
                      border: Border.all(color: c.border, width: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(t,
                        style: GoogleFonts.ibmPlexMono(
                            fontSize: 14, color: c.textHi)),
                  )),
              GestureDetector(
                onTap: onAddTime,
                child: Container(
                  width: 60,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.bgSurface,
                    border: Border.all(color: c.accent, width: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(Icons.add, size: 18, color: c.accent),
                ),
              ),
            ],
          ),
          if (times.isNotEmpty && stops.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Preview',
                style: TransitTypography.sectionTitle(c.textMid)),
            const SizedBox(height: 8),
            ...List.generate(stops.length, (i) {
              final totalMin =
                  int.tryParse(controller.totalTimeCtrl.text) ?? 45;
              final interval =
                  stops.length > 1 ? totalMin / (stops.length - 1) : 0;
              final offsetMin = (interval * i).round();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '${stops[i].name}  +${offsetMin}m',
                  style: TransitTypography.bodySecondary(c.textHi),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
