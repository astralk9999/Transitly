import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../shared/models/achievement_model.dart';
import '../../../shared/models/user_achievement_model.dart';

IconData _iconFor(String code) => switch (code) {
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

class AchievementGridItem extends StatelessWidget {
  const AchievementGridItem({
    super.key,
    required this.c,
    required this.achievement,
    required this.userAchievement,
  });

  final TransitColorScheme c;
  final AchievementModel achievement;
  final UserAchievementModel? userAchievement;

  bool get _unlocked => userAchievement?.unlocked ?? false;

  int get _progress => userAchievement?.progress ?? 0;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _unlocked ? 1.0 : 0.4,
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
              _iconFor(achievement.icon),
              size: 32,
              color: _unlocked ? c.accent : c.textLo,
            ),
            const SizedBox(height: 8),
            Text(
              achievement.name,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _unlocked ? c.textHi : c.textLo,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            _unlocked
                ? Text(
                    '\u2713',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 11,
                      color: c.accent,
                    ),
                  )
                : Text(
                    '$_progress/${achievement.threshold}',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 11,
                      color: c.textMid,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
