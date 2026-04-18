import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/mock/mock_data_service.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/smoke_background.dart';

class ManagerInboxScreen extends ConsumerWidget {
  const ManagerInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final mockData = ref.watch(mockDataServiceProvider);
    final feedbacks = mockData.feedbacks;
    final suggestions = mockData.routeSuggestions;

    return Scaffold(
      backgroundColor: c.bgRoot,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textMid),
          onPressed: () => context.pop(),
        ),
        title: Text('BANDEJA DE GESTIÓN',
            style: TransitTypography.sectionTitle(c.textHi)),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          Positioned.fill(child: SmokeBackground(color: c.accent, isDark: isDark)),
          Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${feedbacks.length + suggestions.length} pendientes',
              style: GoogleFonts.ibmPlexMono(fontSize: 12, color: c.textMid),
            ),
          ),
          const SizedBox(height: 8),
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
                      Tab(text: 'FEEDBACK'),
                      Tab(text: 'SUGERENCIAS'),
                      Tab(text: 'RESUELTOS'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Feedback tab
                        ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: feedbacks.length.clamp(0, 2),
                          itemBuilder: (context, index) {
                            final fb = feedbacks[index];
                            final priorityColor = switch (fb.autoPriority) {
                              _ when fb.autoPriority.name == 'high' ||
                                      fb.autoPriority.name == 'urgent' =>
                                c.stateCancelled,
                              _ when fb.autoPriority.name == 'medium' =>
                                c.stateDelay,
                              _ => c.textMid,
                            };
                            return GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Detalle: próximamente')),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: c.bgSurface,
                                  border: Border(
                                    left: BorderSide(
                                        color: priorityColor, width: 2),
                                    top: BorderSide(
                                        color: c.border, width: 0.5),
                                    right: BorderSide(
                                        color: c.border, width: 0.5),
                                    bottom: BorderSide(
                                        color: c.border, width: 0.5),
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          fb.feedbackType.label.toUpperCase(),
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
                                      style: TransitTypography.bodySecondary(
                                          c.textHi),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        // Suggestions tab
                        ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: suggestions.length.clamp(0, 1),
                          itemBuilder: (context, index) {
                            final sug = suggestions[index];
                            return GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Detalle: próximamente')),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: c.bgSurface,
                                  border: Border(
                                    left: BorderSide(
                                        color: c.accent, width: 2),
                                    top: BorderSide(
                                        color: c.border, width: 0.5),
                                    right: BorderSide(
                                        color: c.border, width: 0.5),
                                    bottom: BorderSide(
                                        color: c.border, width: 0.5),
                                  ),
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
                                      style: TransitTypography.bodySecondary(
                                          c.textHi),
                                    ),
                                    if (sug.notes != null)
                                      Text(
                                        sug.notes!,
                                        style:
                                            TransitTypography.bodySmall(
                                                c.textMid),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        // Resolved tab
                        const Center(
                          child: EmptyState(
                            'SIN ELEMENTOS RESUELTOS',
                            'Los items resueltos aparecerán aquí',
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
      ),
        ],
      ),
    );
  }
}
