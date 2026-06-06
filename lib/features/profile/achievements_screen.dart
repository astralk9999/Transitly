import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../core/utils/app_logger.dart';
import '../../data/mock/mock_data_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/models/achievement_model.dart';
import '../../shared/models/user_achievement_model.dart';
import '../../shared/widgets/responsive_scaffold.dart';

const String _logTag = 'AchievementsScreen';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  static IconData _iconFor(String code) => switch (code) {
        'report' => Icons.report,
        'flag' => Icons.flag,
        'edit_road' => Icons.edit_road,
        'verified' => Icons.verified,
        'assured_workload' => Icons.assured_workload,
        'how_to_vote' => Icons.how_to_vote,
        'checklist' => Icons.checklist,
        'map' => Icons.map,
        'directions_bus' => Icons.directions_bus,
        'bus' => Icons.directions_bus,
        'rocket_launch' => Icons.rocket_launch,
        'route' => Icons.route,
        'star' => Icons.star,
        'explore' => Icons.explore,
        'feedback' => Icons.feedback,
        'photo' => Icons.camera_alt,
        'streak' => Icons.local_fire_department,
        'night' => Icons.nightlight_round,
        'eco' => Icons.eco,
        'trophy' => Icons.emoji_events,
        _ => Icons.workspace_premium,
      };

  Future<List<AchievementModel>> _loadFromAsset() async {
    try {
      final raw = await rootBundle.loadString('assets/achievements.json');
      final list = json.decode(raw) as List<dynamic>;
      return list
          .map((e) =>
              AchievementModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.warn(_logTag, 'failed to load achievements.json, using mock fallback', e);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final l10n = AppLocalizations.of(context);
    final mockData = ref.watch(mockDataServiceProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textMid),
          tooltip: l10n.actionBack,
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.achievementsTitle,
            style: TransitTypography.subheading(c.textHi)),
        centerTitle: false,
      ),
      body: Stack(
        children: [
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
              l10n.achievementsLevel('Nuevo', 0),
              style: TextStyle(fontFamily: 'DM Sans', 
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: c.accent,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<AchievementModel>>(
              future: _loadFromAsset().catchError((_) => mockData.achievements),
              builder: (context, snapshot) {
                final achievements = snapshot.data ?? mockData.achievements;
                final userAchievements = mockData.userAchievements;

                final progressMap = <String, UserAchievementModel>{};
                for (final ua in userAchievements) {
                  progressMap[ua.achievementId] = ua;
                }

                return GridView.builder(
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
                    final ua = progressMap[ach.code] ?? progressMap[ach.id];
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
                              style: TextStyle(fontFamily: 'DM Sans', 
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
