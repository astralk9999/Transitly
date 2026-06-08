import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../data/notification/local_push_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/providers/is_dark_provider.dart';
import '../../../shared/providers/theme_notifier.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_text.dart';

class ProfileNotificationsSection extends ConsumerWidget {
  const ProfileNotificationsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = isDarkMode(ref, context);
    final c = TransitColorScheme.of(isDark);
    final l10n = AppLocalizations.of(context);
    final notifier = ref.watch(themeNotifierProvider);

    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientText(
            l10n.notifPrefSectionTitle,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            gradient: c.gradientAccent,
          ),
          const SizedBox(height: 12),
          // Permiso del sistema: sin él, los toggles de abajo no pueden
          // entregar notificaciones. Solo en móvil (en web no aplica).
          if (!kIsWeb) ...[
            const _NotifPermissionBanner(),
            const SizedBox(height: 12),
          ],
          _NotifToggle(
            c: c,
            icon: Icons.check_circle_outline,
            label: l10n.notifPrefIncidentResolved,
            value: notifier.notifIncidentResolved,
            onChanged: (v) => notifier.notifIncidentResolved = v,
          ),
          _NotifToggle(
            c: c,
            icon: Icons.route_outlined,
            label: l10n.notifPrefRoutePromoted,
            value: notifier.notifRoutePromoted,
            onChanged: (v) => notifier.notifRoutePromoted = v,
          ),
          _NotifToggle(
            c: c,
            icon: Icons.directions_bus_outlined,
            label: l10n.notifPrefBusApproaching,
            value: notifier.notifBusApproaching,
            onChanged: (v) => notifier.notifBusApproaching = v,
          ),
          // Sub-config #54: solo aparece si "bus llegando" está ON.
          if (notifier.notifBusApproaching) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Avisar cuando el bus esté a '
                    '${notifier.busApproachingMinutesAhead} min de la parada',
                    style: TransitTypography.bodySmall(c.textMid),
                  ),
                  const SizedBox(height: 6),
                  // Chips en Wrap en lugar de SegmentedButton: con 5 opciones
                  // el SegmentedButton quedaba estrecho y el texto se
                  // descolocaba en pantallas normales.
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final m in const [3, 5, 10, 15, 20])
                        () {
                          final sel =
                              notifier.busApproachingMinutesAhead == m;
                          return GestureDetector(
                            onTap: () =>
                                notifier.busApproachingMinutesAhead = m,
                            child: Container(
                              width: 48,
                              height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: sel
                                    ? c.accent.withValues(alpha: 0.2)
                                    : c.bgRaised,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: sel ? c.accent : c.border,
                                    width: sel ? 1.4 : 0.5),
                              ),
                              child: Text('$m',
                                  style: TransitTypography.bodyPrimary(
                                          sel ? c.accent : c.textMid)
                                      .copyWith(
                                          fontWeight: FontWeight.w700)),
                            ),
                          );
                        }(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Solo durante estas horas',
                    style: TransitTypography.bodySmall(c.textMid),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: _ActiveTimePicker(
                          c: c,
                          label: 'Desde',
                          value: notifier.busApproachingActiveStart,
                          onChanged: (v) =>
                              notifier.busApproachingActiveStart = v,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActiveTimePicker(
                          c: c,
                          label: 'Hasta',
                          value: notifier.busApproachingActiveEnd,
                          onChanged: (v) =>
                              notifier.busApproachingActiveEnd = v,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          _NotifToggle(
            c: c,
            icon: Icons.lightbulb_outline,
            label: l10n.notifPrefFeatureRequestReplied,
            value: notifier.notifFeatureRequestReplied,
            onChanged: (v) => notifier.notifFeatureRequestReplied = v,
          ),
          _NotifToggle(
            c: c,
            icon: Icons.location_on_outlined,
            label: l10n.notifPrefZoneAlerts,
            value: notifier.notifZoneAlerts,
            onChanged: (v) => notifier.notifZoneAlerts = v,
          ),
          const SizedBox(height: 16),
          Divider(
            height: 1,
            thickness: 0.5,
            color: c.border,
          ),
          const SizedBox(height: 16),
          GradientText(
            l10n.notifPrefQuietHoursSection,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            gradient: c.gradientAccent,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.notifPrefQuietHoursDescription,
            style: TransitTypography.bodySmall(c.textMid),
          ),
          const SizedBox(height: 12),
          _NotifToggle(
            c: c,
            icon: Icons.nightlight_round,
            label: l10n.notifPrefQuietHoursEnabled,
            value: notifier.quietHoursEnabled,
            onChanged: (v) => notifier.quietHoursEnabled = v,
          ),
          if (notifier.quietHoursEnabled) ...[
            const SizedBox(height: 12),
            _TimePickerRow(
              c: c,
              l10n: l10n,
              label: l10n.notifPrefQuietHoursStart,
              time: notifier.quietHoursStart,
              onTimeSelected: (t) => notifier.quietHoursStart = t,
            ),
            const SizedBox(height: 8),
            _TimePickerRow(
              c: c,
              l10n: l10n,
              label: l10n.notifPrefQuietHoursEnd,
              time: notifier.quietHoursEnd,
              onTimeSelected: (t) => notifier.quietHoursEnd = t,
            ),
          ],
        ],
      ),
    );
  }
}

class _NotifToggle extends StatelessWidget {
  const _NotifToggle({
    required this.c,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final TransitColorScheme c;
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: value ? c.accent : c.textLo),
        const SizedBox(width: 10),
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

class _ActiveTimePicker extends StatelessWidget {
  const _ActiveTimePicker({
    required this.c,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final TransitColorScheme c;
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final parts = value.split(':');
        final initial = TimeOfDay(
          hour: int.tryParse(parts.firstOrNull ?? '7') ?? 7,
          minute: int.tryParse(parts.elementAtOrNull(1) ?? '0') ?? 0,
        );
        final picked = await showTimePicker(
          context: context,
          initialTime: initial,
        );
        if (picked != null) {
          final hh = picked.hour.toString().padLeft(2, '0');
          final mm = picked.minute.toString().padLeft(2, '0');
          onChanged('$hh:$mm');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: c.bgInput,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Text(label, style: TransitTypography.bodySmall(c.textLo)),
            const Spacer(),
            Text(
              value,
              style: TransitTypography.bodyPrimary(c.accent),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePickerRow extends StatelessWidget {
  const _TimePickerRow({
    required this.c,
    required this.l10n,
    required this.label,
    required this.time,
    required this.onTimeSelected,
  });

  final TransitColorScheme c;
  final AppLocalizations l10n;
  final String label;
  final String? time;
  final ValueChanged<String> onTimeSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Icon(Icons.access_time, size: 18, color: c.textLo),
        ),
        const SizedBox(width: 10),
        Text(label, style: TransitTypography.bodyPrimary(c.textHi)),
        const Spacer(),
        GestureDetector(
          onTap: () => _pickTime(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: c.bgInput,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: c.border),
            ),
            child: Text(
              time ?? l10n.notifPrefQuietHoursNotSet,
              style: TransitTypography.bodySecondary(
                time != null ? c.accent : c.textLo,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickTime(BuildContext context) async {
    TimeOfDay initial;
    if (time != null) {
      final parts = time!.split(':');
      initial = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 0,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    } else {
      initial = const TimeOfDay(hour: 22, minute: 0);
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      cancelText: l10n.actionCancel,
      confirmText: l10n.notifPrefSelectTime,
    );

    if (picked != null) {
      final hh = picked.hour.toString().padLeft(2, '0');
      final mm = picked.minute.toString().padLeft(2, '0');
      onTimeSelected('$hh:$mm');
    }
  }
}

/// Banner que muestra si las notificaciones del sistema están activas y
/// permite pedir el permiso (Android 13+). Sin este permiso, ningún toggle
/// entrega notificaciones.
class _NotifPermissionBanner extends StatefulWidget {
  const _NotifPermissionBanner();

  @override
  State<_NotifPermissionBanner> createState() => _NotifPermissionBannerState();
}

class _NotifPermissionBannerState extends State<_NotifPermissionBanner> {
  bool? _enabled;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final e = await LocalPushService.instance.areEnabled();
    if (mounted) setState(() => _enabled = e);
  }

  Future<void> _request() async {
    setState(() => _busy = true);
    final granted = await LocalPushService.instance.requestPermission();
    if (mounted) setState(() { _enabled = granted; _busy = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final enabled = _enabled;

    final color = enabled == true ? const Color(0xFF22C55E) : c.accent;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            enabled == true
                ? Icons.notifications_active
                : Icons.notifications_off_outlined,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  enabled == true
                      ? 'Notificaciones activadas'
                      : 'Notificaciones desactivadas',
                  style: TransitTypography.bodyPrimary(c.textHi),
                ),
                const SizedBox(height: 2),
                Text(
                  enabled == true
                      ? 'Recibirás avisos según tus preferencias.'
                      : 'Actívalas para recibir avisos del sistema.',
                  style: TransitTypography.bodySmall(c.textMid),
                ),
              ],
            ),
          ),
          if (enabled != true)
            FilledButton(
              onPressed: _busy ? null : _request,
              style: FilledButton.styleFrom(
                backgroundColor: c.accent,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: Text(_busy ? '…' : 'Activar'),
            ),
        ],
      ),
    );
  }
}
