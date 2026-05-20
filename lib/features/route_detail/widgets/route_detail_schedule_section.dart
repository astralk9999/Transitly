import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../data/mock/mock_data_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/schedule_model.dart';

/// HORARIOS section: day-type tabs + upcoming list + expand-all toggle.
class RouteDetailScheduleSection extends StatefulWidget {
  const RouteDetailScheduleSection({
    super.key,
    required this.mockData,
    required this.routeId,
  });

  final MockDataService mockData;
  final String routeId;

  @override
  State<RouteDetailScheduleSection> createState() =>
      _RouteDetailScheduleSectionState();
}

class _RouteDetailScheduleSectionState
    extends State<RouteDetailScheduleSection> {
  DayType _selectedDayType = DayType.weekday;
  bool _showAllSchedules = false;

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    final schedules = widget.mockData
        .getSchedulesForRoute(widget.routeId, dayType: _selectedDayType);
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;

    final sorted = [...schedules]
      ..sort((a, b) => a.departureTime.compareTo(b.departureTime));

    int nextIndex = -1;
    for (int i = 0; i < sorted.length; i++) {
      final m = _timeToMinutes(sorted[i].departureTime);
      if (m >= nowMinutes) {
        nextIndex = i;
        break;
      }
    }

    final upcoming = <_Entry>[];
    if (nextIndex >= 0) {
      for (int i = nextIndex;
          i < sorted.length && upcoming.length < 5;
          i++) {
        final m = _timeToMinutes(sorted[i].departureTime);
        upcoming.add(_Entry(sorted[i].departureTime, m - nowMinutes,
            i == nextIndex));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Semantics(
              header: true,
              child: Text('HORARIOS',
                  style: TransitTypography.sectionTitle(c.textMid)),
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _dayTypeButton(c, 'LABORABLE', DayType.weekday),
            const SizedBox(width: 12),
            _dayTypeButton(c, 'SÁBADO', DayType.saturday),
            const SizedBox(width: 12),
            _dayTypeButton(c, 'FESTIVO', DayType.sundayHoliday),
          ],
        ),
        const SizedBox(height: 12),
        if (upcoming.isNotEmpty) ...[
          for (final entry in upcoming) _upcomingRow(c, entry),
          const SizedBox(height: 8),
        ] else ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(AppLocalizations.of(context).routeNoUpcomingSchedules,
                style: TransitTypography.bodySecondary(c.textMid)),
          ),
        ],
        GestureDetector(
          onTap: () =>
              setState(() => _showAllSchedules = !_showAllSchedules),
          child: Text(
            _showAllSchedules ? 'Ocultar ▴' : 'Ver todos ▾',
            style: TransitTypography.bodySecondary(c.accent),
          ),
        ),
        if (_showAllSchedules) ...[
          const SizedBox(height: 12),
          _allScheduleWrap(c, sorted, nowMinutes, nextIndex),
        ],
      ],
    );
  }

  Widget _upcomingRow(TransitColorScheme c, _Entry entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              entry.time,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: entry.isNext ? c.accent : c.textHi,
              ),
            ),
          ),
          const SizedBox(width: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              'en ${entry.diffMinutes} min',
              key: ValueKey(entry.diffMinutes),
              style: TransitTypography.bodySecondary(
                  entry.isNext ? c.accent : c.textMid),
            ),
          ),
        ],
      ),
    );
  }

  Widget _allScheduleWrap(TransitColorScheme c, List<ScheduleModel> sorted,
      int nowMinutes, int nextIndex) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: sorted.map((s) {
        final m = _timeToMinutes(s.departureTime);
        final isPast = m < nowMinutes;
        final isNext = sorted.indexOf(s) == nextIndex;
        return Text(
          s.departureTime,
          style: GoogleFonts.ibmPlexMono(
            fontSize: 14,
            color: isNext
                ? c.accent
                : isPast
                    ? c.textLo
                    : c.textHi,
          ),
        );
      }).toList(),
    );
  }

  Widget _dayTypeButton(TransitColorScheme c, String label, DayType type) {
    final isActive = _selectedDayType == type;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedDayType = type;
        _showAllSchedules = false;
      }),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isActive ? c.accent : c.textMid,
              letterSpacing: 0.5,
            ),
          ),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 2,
              width: label.length * 6.5,
              color: c.accent,
            ),
        ],
      ),
    );
  }
}

class _Entry {
  const _Entry(this.time, this.diffMinutes, this.isNext);
  final String time;
  final int diffMinutes;
  final bool isNext;
}
