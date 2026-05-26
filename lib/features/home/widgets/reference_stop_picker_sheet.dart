import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../data/mock/mock_data_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/stop_model.dart';
import '../../../shared/providers/home_reference_stop_provider.dart';
import '../../../shared/widgets/glass_card.dart';

void showReferenceStopPickerSheet(BuildContext context, WidgetRef ref) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final c = TransitColorScheme.of(isDark);
  final mockData = ref.read(mockDataServiceProvider);
  final l10n = AppLocalizations.of(context);
  final allStops = mockData.stops;

  final queryController = TextEditingController();
  var query = '';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.bgSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          final filtered = query.isEmpty
              ? allStops.take(50).toList()
              : allStops
                  .where((s) => s.name.toLowerCase().contains(query))
                  .take(50)
                  .toList();

          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              24 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: c.textLo,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  l10n.homeReferenceStopTitle,
                  style: TransitTypography.heading(c.textHi),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: queryController,
                  style: TransitTypography.bodyPrimary(c.textHi),
                  cursorColor: c.accent,
                  decoration: InputDecoration(
                    hintText: l10n.homeReferenceStopSearchHint,
                    hintStyle: TransitTypography.bodySecondary(c.textMid),
                    prefixIcon:
                        Icon(Icons.search, size: 20, color: c.textMid),
                    filled: true,
                    fillColor: c.bgInput,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: c.border, width: 0.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: c.accent, width: 1),
                    ),
                  ),
                  onChanged: (v) {
                    setSheetState(() {
                      query = v.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        l10n.mapSearchNoResults,
                        style:
                            TransitTypography.bodySecondary(c.textMid),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final stop = filtered[i];
                        return _StopTile(
                          c: c,
                          stop: stop,
                          onTap: () {
                            ref
                                .read(homeReferenceStopProvider.notifier)
                                .setStop(stop.id);
                            Navigator.of(ctx).pop();
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _StopTile extends StatelessWidget {
  const _StopTile({
    required this.c,
    required this.stop,
    required this.onTap,
  });

  final TransitColorScheme c;
  final StopModel stop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 10,
      margin: const EdgeInsets.only(bottom: 6),
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stop.name,
                    style: TransitTypography.bodyPrimary(c.textHi),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    stop.municipality,
                    style: TransitTypography.bodySmall(c.textMid),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: c.textMid),
          ],
        ),
      ),
    );
  }
}
