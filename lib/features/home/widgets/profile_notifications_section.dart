import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_text.dart';

class ProfileNotificationsSection extends StatefulWidget {
  const ProfileNotificationsSection({super.key});

  @override
  State<ProfileNotificationsSection> createState() =>
      _ProfileNotificationsSectionState();
}

class _ProfileNotificationsSectionState
    extends State<ProfileNotificationsSection> {
  bool _alertsOn = true;
  bool _busWarningOn = true;
  bool _remindersOn = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientText(
            'NOTIFICACIONES',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            gradient: c.gradientAccent,
          ),
          const SizedBox(height: 12),
          _NotifRow(
              c: c,
              label: 'Alertas de servicio',
              value: _alertsOn,
              onChanged: (v) => setState(() => _alertsOn = v)),
          _NotifRow(
              c: c,
              label: 'Aviso de bus',
              value: _busWarningOn,
              onChanged: (v) => setState(() => _busWarningOn = v)),
          _NotifRow(
              c: c,
              label: 'Recordatorios',
              value: _remindersOn,
              onChanged: (v) => setState(() => _remindersOn = v)),
        ],
      ),
    );
  }
}

class _NotifRow extends StatelessWidget {
  const _NotifRow({
    required this.c,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final TransitColorScheme c;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: TransitTypography.bodyPrimary(c.textHi)),
        ),
        Switch.adaptive(
          value: value,
          activeTrackColor: c.accent,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
