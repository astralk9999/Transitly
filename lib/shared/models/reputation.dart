import 'package:flutter/material.dart';

enum ReputationRank {
  none(0, 'reputationRankNone', Icons.radio_button_unchecked, Color(0xFF888888)),
  novice(10, 'reputationRankNovice', Icons.star_border, Color(0xFF4CAF50)),
  contributor(50, 'reputationRankContributor', Icons.star_half, Color(0xFF2196F3)),
  advocate(200, 'reputationRankAdvocate', Icons.star, Color(0xFF9C27B0)),
  cartographer(500, 'reputationRankCartographer', Icons.map, Color(0xFFFF9800)),
  guardian(1500, 'reputationRankGuardian', Icons.shield, Color(0xFFE91E63)),
  legend(5000, 'reputationRankLegend', Icons.auto_awesome, Color(0xFFFFD700));

  final int minScore;
  final String nameKey;
  final IconData icon;
  final Color color;
  const ReputationRank(this.minScore, this.nameKey, this.icon, this.color);

  static ReputationRank forScore(int score) {
    return ReputationRank.values.reversed.firstWhere(
      (r) => score >= r.minScore,
    );
  }

  int scoreToNext(int score) {
    final idx = ReputationRank.values.indexOf(this);
    if (idx >= ReputationRank.values.length - 1) return 0;
    return ReputationRank.values[idx + 1].minScore - score;
  }
}
