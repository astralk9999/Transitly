import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../data/mock/mock_data_service.dart';
import '../../../shared/widgets/shimmer_skeleton.dart';

class CardTab extends ConsumerStatefulWidget {
  const CardTab({super.key});

  @override
  ConsumerState<CardTab> createState() => _CardTabState();
}

class _CardTabState extends ConsumerState<CardTab> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final mockData = ref.watch(mockDataServiceProvider);
    final card = mockData.transitCard;
    final history = mockData.tripHistory;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _loading ? _buildShimmer(context) : CustomScrollView(
        key: const ValueKey('card-content'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── TARJETA VISUAL ──
                _buildCard(c, card),
                const SizedBox(height: 24),

                // ── ESTADÍSTICAS ──
                Text('ESTE MES',
                    style: TransitTypography.sectionTitle(c.textMid)),
                const SizedBox(height: 8),
                _buildStatsGrid(c),
                const SizedBox(height: 24),

                // ── HISTORIAL ──
                Text('ÚLTIMOS VIAJES',
                    style: TransitTypography.sectionTitle(c.textMid)),
                const SizedBox(height: 8),
                ...history.map((trip) {
                  final route = mockData.getRouteById(trip.routeId);
                  final date =
                      '${trip.startedAt.day.toString().padLeft(2, '0')}/${trip.startedAt.month.toString().padLeft(2, '0')}';
                  final time =
                      '${trip.startedAt.hour.toString().padLeft(2, '0')}:${trip.startedAt.minute.toString().padLeft(2, '0')}';
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Text(
                              '$date · $time',
                              style: TransitTypography.bodySecondary(c.textMid),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                route != null
                                    ? '${route.code} ${route.name}'
                                    : trip.routeId,
                                style:
                                    TransitTypography.subheading(c.textHi),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (trip.cost != null)
                              Text(
                                '-${trip.cost!.toStringAsFixed(2)} €',
                                style: TransitTypography.bodySecondary(
                                    c.stateCancelled),
                              ),
                          ],
                        ),
                      ),
                      Divider(height: 1, thickness: 0.5, color: c.border),
                    ],
                  );
                }),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return Padding(
      key: const ValueKey('card-shimmer'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerSkeleton.rect(context, height: 200),
          const SizedBox(height: 24),
          ShimmerSkeleton.text(context, width: 100),
          const SizedBox(height: 12),
          ShimmerSkeleton.list(
            context: context,
            count: 4,
            builder: () => ShimmerSkeleton.stopItem(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(TransitColorScheme c, dynamic card) {
    final balance = card?.balance ?? 0.0;
    final cardNumber = card?.cardNumber ?? '0000 0000 0000 0000';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: c.bgSurface,
        border: Border.all(color: c.border, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'TARJETA MULTIVIAJE',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.0,
                  color: c.textMid,
                ),
              ),
              const Spacer(),
              Text(
                'COMUJESA',
                style: GoogleFonts.dmSans(fontSize: 12, color: c.textLo),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '${balance.toStringAsFixed(2)} €',
              style: GoogleFonts.ibmPlexMono(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: c.accent,
              ),
            ),
          ),
          Center(
            child: Text(
              'saldo disponible',
              style: TransitTypography.bodySecondary(c.textMid),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            cardNumber,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 14,
              color: c.textLo,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Actualizado hace 2h',
            style: GoogleFonts.dmSans(fontSize: 11, color: c.textLo),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(TransitColorScheme c) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.6,
      children: [
        _statCell(c, '23', 'viajes', c.textHi),
        _statCell(c, '18h 30min', 'en bus', c.textHi),
        _statCell(c, '45,80 €', 'gastados', c.textHi),
        _statCell(c, '~89 kg', 'CO₂ evitado', c.accent),
      ],
    );
  }

  Widget _statCell(
      TransitColorScheme c, String value, String label, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.bgSurface,
        border: Border.all(color: c.border, width: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmSans(fontSize: 11, color: c.textMid),
          ),
        ],
      ),
    );
  }
}
