import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/mock/mock_data_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/models/user_achievement_model.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/smoke_background.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  static IconData _iconFor(String code) => switch (code) {
        'bus' => Icons.directions_bus,
        'route' => Icons.route,
        'star' => Icons.star,
        'map' => Icons.map,
        'explore' => Icons.explore,
        'feedback' => Icons.feedback,
        'report' => Icons.flag,
        'photo' => Icons.camera_alt,
        'streak' => Icons.local_fire_department,
        'night' => Icons.nightlight_round,
        'eco' => Icons.eco,
        'trophy' => Icons.emoji_events,
        _ => Icons.workspace_premium,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final l10n = AppLocalizations.of(context);
    final mockData = ref.watch(mockDataServiceProvider);
    final achievements = mockData.achievements;
    final userAchievements = mockData.userAchievements;

    final progressMap = <String, UserAchievementModel>{};
    for (final ua in userAchievements) {
      progressMap[ua.achievementId] = ua;
    }

    return Scaffold(
      backgroundColor: c.bgRoot,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textMid),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.achievementsTitle,
            style: TransitTypography.sectionTitle(c.textHi)),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          Positioned.fill(child: SmokeBackground(color: c.accent, isDark: isDark)),
          ContentConstraints(
        child: Builder(builder: (context) {
        final padding = ResponsiveScaffold.screenPadding(context);
        final columns = ResponsiveScaffold.gridColumns(context) + 1;
        return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: Text(
              l10n.achievementsLevel('VIAJERO', 450),
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: c.accent,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.symmetric(horizontal: padding),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.0,
              ),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final ach = achievements[index];
                final ua = progressMap[ach.id];
                final unlocked = ua?.unlocked ?? false;
                final progress = ua?.progress ?? 0;

                return Opacity(
                  opacity: unlocked ? 1.0 : 0.4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: c.bgSurface,
                      border: Border.all(color: c.border, width: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _iconFor(ach.icon),
                          size: 32,
                          color: unlocked ? c.accent : c.textLo,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ach.name,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: unlocked ? c.textHi : c.textLo,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        unlocked
                            ? Text(
                                '✓',
                                style: GoogleFonts.ibmPlexMono(
                                  fontSize: 11,
                                  color: c.accent,
                                ),
                              )
                            : Text(
                                '$progress/${ach.threshold}',
                                style: GoogleFonts.ibmPlexMono(
                                  fontSize: 11,
                                  color: c.textMid,
                                ),
                              ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
        }),
      ),
        ],
      ),
    );
  }
}
