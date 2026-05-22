import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_animations.dart';
import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/mock/mock_data_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/schedule_model.dart';
import '../../shared/providers/derived/schedule_providers.dart';
import '../../shared/widgets/smoke_background.dart';
import '../../shared/widgets/transit_button.dart';

class StartRouteScreen extends ConsumerStatefulWidget {
  const StartRouteScreen({super.key});

  @override
  ConsumerState<StartRouteScreen> createState() => _StartRouteScreenState();
}

class _StartRouteScreenState extends ConsumerState<StartRouteScreen> {
  String? _selectedRouteId;
  String? _selectedTime;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _routeListKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToRouteList() {
    final ctx = _routeListKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: TransitAnimations.normal,
      curve: TransitAnimations.transitEaseOut,
      alignment: 0.05,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final l10n = AppLocalizations.of(context);
    final mockData = ref.watch(mockDataServiceProvider);

    // Driver routes (mock: L1, L3, L5, L8)
    final driverRouteIds = {'L1', 'L3', 'L5', 'L8'};
    final driverRoutes =
        mockData.routes.where((r) => driverRouteIds.contains(r.id)).toList();

    // Suggestion: first route with next departure
    final suggestedRoute = driverRoutes.isNotEmpty ? driverRoutes.first : null;
    final suggestedNext = suggestedRoute != null
        ? mockData.getNextDepartures(suggestedRoute.id, '', 1)
        : <ScheduleModel>[];
    final suggestedTime =
        suggestedNext.isNotEmpty ? suggestedNext.first.departureTime : '--:--';

    // Schedules for selected route — pre-sorted por el provider derivado.
    final sortedSchedules = _selectedRouteId == null
        ? const <ScheduleModel>[]
        : ref.watch(upcomingDeparturesForRouteProvider((
            routeId: _selectedRouteId!,
            count: null,
            dayType: DayType.weekday,
          )));

    // Selected route info
    final selectedRoute =
        _selectedRouteId != null ? mockData.getRouteById(_selectedRouteId!) : null;
    final selectedStops = _selectedRouteId != null
        ? mockData.getStopsForRoute(_selectedRouteId!)
        : [];

    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;

    return Scaffold(
      backgroundColor: c.bgRoot,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textMid),
          tooltip: l10n.actionBack,
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.driverStartTitle,
            style: TransitTypography.sectionTitle(c.textHi)),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          Positioned.fill(child: SmokeBackground(color: c.accent, isDark: isDark)),
          SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── a) SUGERENCIA ──
            if (suggestedRoute != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: c.accent, width: 1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                       l10n.driverStartSuggestionFmt(suggestedRoute.code, suggestedTime, l10n.routeDayWeekday),
                      style: TransitTypography.bodyPrimary(c.textHi),
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.driverStartIsThisYourRoute,
                        style: TransitTypography.bodySecondary(c.textMid)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        TransitButton(
                          label: l10n.driverStartYesStart,
                          isSmall: true,
                          onPressed: () => context.push('/driver/active'),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _scrollToRouteList,
                          child: Text(AppLocalizations.of(context).driverChooseAnother,
                              style:
                                  TransitTypography.bodySecondary(c.accent)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // ── b) SELECCIONAR LÍNEA ──
            Text(l10n.driverStartSelectLine,
                key: _routeListKey,
                style: TransitTypography.sectionTitle(c.textMid)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.0,
              children: driverRoutes.map((route) {
                final isSelected = _selectedRouteId == route.id;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedRouteId = route.id;
                    _selectedTime = null;
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: c.bgSurface,
                      border: Border.all(
                        color: isSelected ? c.accent : c.border,
                        width: isSelected ? 1 : 0.5,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          route.code,
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: c.accent,
                          ),
                        ),
                        Text(
                          route.name,
                          style: TransitTypography.bodySmall(c.textMid),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            // ── c) SELECCIONAR HORARIO ──
            if (_selectedRouteId != null) ...[
              const SizedBox(height: 24),
              Text(l10n.driverStartSelectSchedule,
                  style: TransitTypography.sectionTitle(c.textMid)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sortedSchedules.map((s) {
                  final time = s.departureTime;
                  final parts = time.split(':');
                  final m = int.parse(parts[0]) * 60 + int.parse(parts[1]);
                  final isPast = m < nowMinutes;
                  final isNext = !isPast &&
                      (sortedSchedules.indexOf(s) ==
                          sortedSchedules.indexWhere((x) {
                            final p = x.departureTime.split(':');
                            return int.parse(p[0]) * 60 + int.parse(p[1]) >=
                                nowMinutes;
                          }));
                  final isSelected = _selectedTime == time;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedTime = time),
                    child: Container(
                      width: 60,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? c.accentBg : c.bgSurface,
                        border: Border.all(
                          color: isSelected || isNext ? c.accent : c.border,
                          width: isSelected ? 1 : 0.5,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        time,
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 14,
                          color: isPast
                              ? c.textLo
                              : isNext || isSelected
                                  ? c.accent
                                  : c.textHi,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            // ── d) RESUMEN + CONFIRMAR ──
            if (_selectedRouteId != null && _selectedTime != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.bgSurface,
                  border: Border.all(color: c.accent, width: 1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${selectedRoute?.code} · ${selectedRoute?.name}',
                      style: TransitTypography.bodyPrimary(c.textHi),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.driverStartDepartureFmt(_selectedTime!),
                      style: TransitTypography.stopTime(c.accent),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.driverStartStopsAndTime(selectedStops.length, selectedStops.length * 3),
                      style: TransitTypography.bodySecondary(c.textMid),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: TransitButton(
                  label: l10n.driverStartStartButton,
                  onPressed: () => context.push('/driver/active'),
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
        ],
      ),
    );
  }
}
