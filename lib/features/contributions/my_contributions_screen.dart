import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/mock/mock_data_service.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/models/enums.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/reputation_badge.dart';

class MyContributionsScreen extends ConsumerWidget {
  const MyContributionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final mockData = ref.watch(mockDataServiceProvider);
    final suggestions = mockData.routeSuggestions;
    final feedbacks = mockData.feedbacks;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textMid),
          onPressed: () => context.pop(),
        ),
        title: Text('MIS CONTRIBUCIONES',
            style: TransitTypography.sectionTitle(c.textHi)),
        centerTitle: false,
      ),
      body: ContentConstraints(
        child: Builder(builder: (context) {
        final padding = ResponsiveScaffold.screenPadding(context);
        return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with reputation
          Padding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const ReputationBadge(ReputationLevel.contributor),
                    const SizedBox(width: 12),
                    Text(
                      'Puntuación: 85 / 100 para Confiable',
                      style: GoogleFonts.dmSans(
                          fontSize: 13, color: c.textMid),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: 85 / 100,
                    backgroundColor: c.bgRaised,
                    valueColor: AlwaysStoppedAnimation(c.accent),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 16),

                // Stats grid 2x2
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.5,
                  children: [
                    _statCell(c, '2', 'sugerencias'),
                    _statCell(c, '4', 'correcciones'),
                    _statCell(c, '12', 'reportes'),
                    _statCell(c, '3', 'fotos'),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Tabs
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  TabBar(
                    indicatorColor: c.accent,
                    labelColor: c.accent,
                    unselectedLabelColor: c.textMid,
                    labelStyle: GoogleFonts.ibmPlexMono(
                        fontSize: 11, fontWeight: FontWeight.w600),
                    tabs: const [
                      Tab(text: 'SUGERENCIAS'),
                      Tab(text: 'FEEDBACK'),
                      Tab(text: 'REPORTES'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Suggestions tab
                        suggestions.isEmpty
                            ? const Center(
                                child: EmptyState(
                                  'SIN SUGERENCIAS',
                                  'Tus sugerencias de ruta aparecerán aquí',
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.all(padding),
                                itemCount: suggestions.length,
                                itemBuilder: (context, index) {
                                  final sug = suggestions[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: c.bgSurface,
                                      border: Border.all(
                                          color: c.border, width: 0.5),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'SUGERENCIA',
                                              style: GoogleFonts.ibmPlexMono(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: c.textMid,
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              sug.status.label,
                                              style:
                                                  TransitTypography.bodySmall(
                                                      c.accent),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${sug.originText} → ${sug.destinationText}',
                                          style:
                                              TransitTypography.bodySecondary(
                                                  c.textHi),
                                        ),
                                        if (sug.routeCode != null)
                                          Text(
                                            sug.routeCode!,
                                            style:
                                                TransitTypography.bodySmall(
                                                    c.textMid),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),

                        // Feedback tab
                        feedbacks.isEmpty
                            ? const Center(
                                child: EmptyState(
                                  'SIN FEEDBACK',
                                  'Tu feedback enviado aparecerá aquí',
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.all(padding),
                                itemCount: feedbacks.length,
                                itemBuilder: (context, index) {
                                  final fb = feedbacks[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: c.bgSurface,
                                      border: Border.all(
                                          color: c.border, width: 0.5),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              fb.feedbackType.label
                                                  .toUpperCase(),
                                              style: GoogleFonts.ibmPlexMono(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: c.textMid,
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              fb.status.label,
                                              style:
                                                  TransitTypography.bodySmall(
                                                      c.accent),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          fb.description,
                                          style:
                                              TransitTypography.bodySecondary(
                                                  c.textHi),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),

                        // Reports tab
                        const Center(
                          child: EmptyState(
                            'SIN REPORTES',
                            'Tus reportes de incidencias aparecerán aquí',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
        }),
      ),
    );
  }

  static Widget _statCell(TransitColorScheme c, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.bgSurface,
        border: Border.all(color: c.border, width: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Text(
            value,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: c.accent,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.dmSans(fontSize: 13, color: c.textMid),
          ),
        ],
      ),
    );
  }
}
