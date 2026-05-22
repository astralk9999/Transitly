import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../shared/models/active_trip_model.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/route_model.dart';
import '../../shared/models/stop_model.dart';
import '../../shared/providers/is_dark_provider.dart';
import '../../shared/providers/theme_provider.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/capacity_indicator.dart';
import '../../shared/widgets/data_freshness_indicator.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_card.dart';
import '../../shared/widgets/reputation_badge.dart';
import '../../shared/widgets/route_card.dart';
import '../../shared/widgets/shimmer_skeleton.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/stop_list_item.dart';
import '../../shared/widgets/transit_button.dart';
import '../../shared/widgets/transit_chip.dart';
import '../../shared/widgets/transit_input.dart';

class ComponentShowcaseScreen extends ConsumerWidget {
  const ComponentShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = isDarkMode(ref, context);
    final c = TransitColorScheme.of(isDark);

    return Scaffold(
      backgroundColor: c.bgRoot,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textMid),
          tooltip: 'Volver',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('COMPONENT SHOWCASE',
            style: TransitTypography.sectionTitle(c.textHi)),
        centerTitle: false,
        actions: [
          Row(
            children: [
              Icon(isDark ? Icons.dark_mode : Icons.light_mode,
                  size: 16, color: c.textMid),
              const SizedBox(width: 4),
              Switch.adaptive(
                value: isDark,
                activeTrackColor: c.accent,
                onChanged: (v) {
                  ref.read(themeModeProvider.notifier).state =
                      v ? ThemeMode.dark : ThemeMode.light;
                },
              ),
            ],
          ),
        ],
      ),
      body: ContentConstraints(
        child: Builder(builder: (context) {
        final padding = ResponsiveScaffold.screenPadding(context);
        return ListView(
        padding: EdgeInsets.fromLTRB(padding, 0, padding, 32),
        children: [
          // ── COLORES ──
          _sectionTitle(c, 'COLORES'),
          _colorGrid(c),
          const SizedBox(height: 24),

          // ── TIPOGRAFÍA ──
          _sectionTitle(c, 'TIPOGRAFÍA'),
          _typographySection(c),
          const SizedBox(height: 24),

          // ── ROUTE CARDS ──
          _sectionTitle(c, 'ROUTE CARDS'),
          ..._routeCards(),
          const SizedBox(height: 24),

          // ── BADGES ──
          _sectionTitle(c, 'BADGES'),
          _badgesSection(c),
          const SizedBox(height: 24),

          // ── BUTTONS ──
          _sectionTitle(c, 'BUTTONS'),
          _buttonsSection(),
          const SizedBox(height: 24),

          // ── CHIPS ──
          _sectionTitle(c, 'CHIPS'),
          _chipsSection(),
          const SizedBox(height: 24),

          // ── STOP ITEMS ──
          _sectionTitle(c, 'STOP ITEMS'),
          _stopItemsSection(),
          const SizedBox(height: 24),

          // ── INPUTS ──
          _sectionTitle(c, 'INPUTS'),
          _inputsSection(c),
          const SizedBox(height: 24),

          // ── STATES ──
          _sectionTitle(c, 'STATES'),
          _statesSection(context),
          const SizedBox(height: 24),

          // ── INDICATORS ──
          _sectionTitle(c, 'INDICATORS'),
          _indicatorsSection(c),
        ],
      );
        }),
      ),
    );
  }

  // ── SECTION TITLE ──
  Widget _sectionTitle(TransitColorScheme c, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.ibmPlexMono(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: c.textMid,
          ),
        ),
        Divider(height: 16, thickness: 0.5, color: c.border),
      ],
    );
  }

  // ── COLORES ──
  Widget _colorGrid(TransitColorScheme c) {
    final colors = <String, Color>{
      'bgRoot': c.bgRoot,
      'bgSidebar': c.bgSidebar,
      'bgSurface': c.bgSurface,
      'bgRaised': c.bgRaised,
      'bgInput': c.bgInput,
      'border': c.border,
      'borderFocus': c.borderFocus,
      'accent': c.accent,
      'accentBg': c.accentBg,
      'stateOnRoute': c.stateOnRoute,
      'stateOnTime': c.stateOnTime,
      'stateDelay': c.stateDelay,
      'stateCancelled': c.stateCancelled,
      'stateIdle': c.stateIdle,
      'textHi': c.textHi,
      'textMid': c.textMid,
      'textLo': c.textLo,
    };

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.65,
      ),
      itemCount: colors.length,
      itemBuilder: (context, index) {
        final entry = colors.entries.elementAt(index);
        final hex =
            '#${entry.value.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
        return Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: entry.value,
                border: Border.all(color: c.border, width: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              entry.key,
              style: GoogleFonts.ibmPlexMono(fontSize: 8, color: c.textLo),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              hex,
              style: GoogleFonts.ibmPlexMono(fontSize: 8, color: c.textLo),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }

  // ── TIPOGRAFÍA ──
  Widget _typographySection(TransitColorScheme c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _typoRow('displayTime', TransitTypography.displayTime(c.textHi), '12:45', c.textMid),
        _typoRow('displayNumber', TransitTypography.displayNumber(c.textHi), '2,450', c.textMid),
        _typoRow('routeCode', TransitTypography.routeCode(c.accent), 'L1', c.textMid),
        _typoRow('routeCodeSmall', TransitTypography.routeCodeSmall(c.accent), 'M-011', c.textMid),
        _typoRow('statusBadge', TransitTypography.statusBadge(c.stateOnTime), 'A TIEMPO', c.textMid),
        _typoRow('stopTime', TransitTypography.stopTime(c.textHi), '08:30', c.textMid),
        _typoRow('sectionTitle', TransitTypography.sectionTitle(c.textMid), 'SECCIÓN', c.textMid),
        _typoRow('navLabel', TransitTypography.navLabel(c.textMid), 'INICIO', c.textMid),
        _typoRow('heading', TransitTypography.heading(c.textHi), 'Título principal', c.textMid),
        _typoRow('subheading', TransitTypography.subheading(c.textHi), 'Subtítulo', c.textMid),
        _typoRow('bodyPrimary', TransitTypography.bodyPrimary(c.textHi), 'Texto principal de la app', c.textMid),
        _typoRow('bodySecondary', TransitTypography.bodySecondary(c.textMid), 'Texto secundario', c.textMid),
        _typoRow('bodySmall', TransitTypography.bodySmall(c.textLo), 'Texto pequeño', c.textMid),
      ],
    );
  }

  Widget _typoRow(
      String name, TextStyle style, String example, Color labelColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              name,
              style: GoogleFonts.ibmPlexMono(fontSize: 9, color: labelColor),
            ),
          ),
          Expanded(child: Text(example, style: style)),
        ],
      ),
    );
  }

  // ── ROUTE CARDS ──
  List<Widget> _routeCards() {
    final routes = [
      const RouteModel(
        id: 'L1', operatorId: 'comujesa', code: 'L1',
        name: 'Estella – Guadalcacín', serviceType: ServiceType.urban,
        routeColor: Color(0xFF00A0FF),
      ),
      const RouteModel(
        id: 'L3', operatorId: 'comujesa', code: 'L3',
        name: 'Centro – La Granja', serviceType: ServiceType.urban,
        routeColor: Color(0xFFFF8C00),
      ),
      const RouteModel(
        id: 'L8', operatorId: 'comujesa', code: 'L8',
        name: 'Circular Norte', serviceType: ServiceType.urban,
        routeColor: Color(0xFFFF3B3B), isCircular: true,
      ),
      const RouteModel(
        id: 'L10', operatorId: 'comujesa', code: 'L10',
        name: 'Poligono – Centro', serviceType: ServiceType.urban,
        routeColor: Color(0xFF7A7A7A),
      ),
    ];

    final trips = [
      ActiveTripModel(
        id: 't1', routeId: 'L1',
        startedAt: DateTime.now().subtract(const Duration(minutes: 20)),
        status: TripStatus.onTime, capacity: BusCapacity.seatsAvailable,
        currentStopIndex: 5,
      ),
      ActiveTripModel(
        id: 't2', routeId: 'L3',
        startedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        status: TripStatus.delay, capacity: BusCapacity.halfFull,
        delayMinutes: 8, currentStopIndex: 3,
      ),
      const ActiveTripModel(
        id: 't3', routeId: 'L8',
        status: TripStatus.cancelled, capacity: BusCapacity.empty,
      ),
      null,
    ];

    return List.generate(routes.length, (i) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: RouteCard(
          route: routes[i],
          activeTrip: trips[i],
          remainingStops: 12 - (i * 3),
          estimatedMinutes: trips[i] != null ? '${25 - i * 5}m' : null,
        ),
      );
    });
  }

  // ── BADGES ──
  Widget _badgesSection(TransitColorScheme c) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        StatusBadge('En ruta', c.stateOnRoute),
        StatusBadge('A tiempo', c.stateOnTime),
        StatusBadge('Demora', c.stateDelay),
        StatusBadge('Cancelado', c.stateCancelled),
        StatusBadge('Oficial', c.accent),
        StatusBadge('Verificada', c.accent),
        StatusBadge('Comunitaria', c.textMid),
      ],
    );
  }

  // ── BUTTONS ──
  Widget _buttonsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: TransitButton(label: 'PRIMARY', onPressed: () {}),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TransitButton(
              label: 'SECONDARY', isPrimary: false, onPressed: () {}),
        ),
        const SizedBox(height: 8),
        TransitButton(label: 'SMALL', isSmall: true, onPressed: () {}),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TransitButton(
              label: 'DANGER', isDanger: true, onPressed: () {}),
        ),
        const SizedBox(height: 8),
        const SizedBox(
          width: double.infinity,
          child: TransitButton(label: 'DISABLED'),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TransitButton(
              label: 'LOADING', isLoading: true, onPressed: () {}),
        ),
      ],
    );
  }

  // ── CHIPS ──
  Widget _chipsSection() {
    return const Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        TransitChip('L1', color: Color(0xFF00A0FF)),
        TransitChip('L3', color: Color(0xFFFF8C00)),
        TransitChip('L8', color: Color(0xFFFF3B3B)),
        TransitChip('M-011', color: Color(0xFF00C896)),
      ],
    );
  }

  // ── STOP ITEMS ──
  Widget _stopItemsSection() {
    final stops = [
      const StopModel(id: 's1', name: 'Estación de Autobuses', officialCode: 'EA-001', lat: 36.685, lng: -6.126, municipality: 'Jerez'),
      const StopModel(id: 's2', name: 'Plaza del Arenal', officialCode: 'PA-002', lat: 36.683, lng: -6.128, municipality: 'Jerez'),
      const StopModel(id: 's3', name: 'Calle Larga', officialCode: 'CL-003', lat: 36.681, lng: -6.130, municipality: 'Jerez'),
      const StopModel(id: 's4', name: 'Hospital de Jerez', officialCode: 'HJ-004', lat: 36.679, lng: -6.132, municipality: 'Jerez'),
      const StopModel(id: 's5', name: 'Guadalcacín', officialCode: 'GD-005', lat: 36.677, lng: -6.134, municipality: 'Jerez'),
    ];

    return Column(
      children: List.generate(stops.length, (i) {
        return StopListItem(
          stop: stops[i],
          scheduledTime: '${8 + i}:${(i * 7).toString().padLeft(2, '0')}',
          isCurrent: i == 2,
          isPassed: i < 2,
          isFirst: i == 0,
          isLast: i == stops.length - 1,
          transferLines: i == 1 ? ['L3', 'L5'] : null,
        );
      }),
    );
  }

  // ── INPUTS ──
  Widget _inputsSection(TransitColorScheme c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TransitInput(hint: 'Campo vacío'),
        const SizedBox(height: 8),
        TransitInput(
          hint: 'Con texto',
          controller: TextEditingController(text: 'Plaza del Arenal'),
        ),
        const SizedBox(height: 8),
        TransitInput(
          hint: 'Con sufijo',
          suffix: Icon(Icons.search, size: 20, color: c.textMid),
        ),
      ],
    );
  }

  // ── STATES ──
  Widget _statesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerSkeleton.routeCard(context),
        const SizedBox(height: 12),
        const ErrorCard('Sin conexión'),
        const SizedBox(height: 12),
        const SizedBox(
          height: 120,
          child: EmptyState('SIN RESULTADOS', 'No hay datos disponibles'),
        ),
      ],
    );
  }

  // ── INDICATORS ──
  Widget _indicatorsSection(TransitColorScheme c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Capacity
        Text('CapacityIndicator',
            style: GoogleFonts.ibmPlexMono(fontSize: 10, color: c.textMid)),
        const SizedBox(height: 6),
        const Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            CapacityIndicator(BusCapacity.empty, showLabel: true),
            CapacityIndicator(BusCapacity.seatsAvailable, showLabel: true),
            CapacityIndicator(BusCapacity.halfFull, showLabel: true),
            CapacityIndicator(BusCapacity.full, showLabel: true),
            CapacityIndicator(BusCapacity.overcrowded, showLabel: true),
          ],
        ),
        const SizedBox(height: 16),

        // DataFreshness
        Text('DataFreshnessIndicator',
            style: GoogleFonts.ibmPlexMono(fontSize: 10, color: c.textMid)),
        const SizedBox(height: 6),
        DataFreshnessIndicator(DateTime.now()),
        const SizedBox(height: 4),
        DataFreshnessIndicator(
            DateTime.now().subtract(const Duration(days: 15))),
        const SizedBox(height: 4),
        DataFreshnessIndicator(
            DateTime.now().subtract(const Duration(days: 45))),
        const SizedBox(height: 16),

        // ReputationBadge
        Text('ReputationBadge',
            style: GoogleFonts.ibmPlexMono(fontSize: 10, color: c.textMid)),
        const SizedBox(height: 6),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ReputationBadge(ReputationLevel.new_),
            ReputationBadge(ReputationLevel.contributor),
            ReputationBadge(ReputationLevel.trusted),
            ReputationBadge(ReputationLevel.expert),
          ],
        ),
      ],
    );
  }
}
