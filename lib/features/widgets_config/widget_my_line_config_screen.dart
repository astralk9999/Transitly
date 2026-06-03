import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/mock/mock_data_service.dart';
import '../../data/widgets_native/widget_data_writer.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/user_favorites_provider.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/transit_button.dart';

class WidgetMyLineConfigScreen extends ConsumerWidget {
  const WidgetMyLineConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final mockData = ref.watch(mockDataServiceProvider);
    final favs = ref.watch(userFavoritesProvider);
    final routes = favs
        .map((id) => mockData.getRouteById(id))
        .whereType<RouteModel>()
        .toList();

    return Scaffold(
      backgroundColor: c.bgRoot,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textHi),
          onPressed: () => context.pop(),
        ),
        title: Text('Mi línea', style: TransitTypography.heading(c.textHi)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Selecciona tu línea favorita desde la lista.',
                style: TransitTypography.bodySecondary(c.textMid)),
            const SizedBox(height: 16),
            if (routes.isEmpty)
              GlassCard(
                blur: 12,
                fillOpacity: 0.05,
                borderRadius: 12,
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text('No tienes líneas favoritas.\nMarca una línea como favorita primero.',
                      textAlign: TextAlign.center,
                      style: TransitTypography.bodySecondary(c.textMid)),
                ),
              )
            else
              ...routes.map((route) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
                    blur: 12,
                    fillOpacity: 0.05,
                    borderRadius: 12,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: route.routeColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(route.code,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(route.name,
                              style: TransitTypography.bodyPrimary(c.textHi)),
                        ),
                        TransitButton(
                          label: 'PROBAR',
                          isSmall: true,
                          onPressed: () async {
                            final stopId = mockData
                                .getStopsForRoute(route.id)
                                .firstOrNull
                                ?.id ?? '';
                            final deps = mockData.getNextDepartures(
                                route.id, stopId, 4);
                            await HomeWidget.setAppGroupId(
                                'group.com.transitly.transitly');
                            await WidgetDataWriter.writeMyLineStatus(
                              routeCode: route.code,
                              upcoming:
                                  deps.map((d) => {'time': d.departureTime}).toList(),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Widget actualizado')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
