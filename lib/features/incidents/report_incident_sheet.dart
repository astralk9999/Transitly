import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../core/utils/uuid.dart';
import '../../data/incident/incident_repository_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/incident_model.dart';
import '../../shared/models/route_model.dart';
import '../../shared/models/stop_model.dart';
import '../../shared/providers/user_provider.dart';
import '../../shared/widgets/transit_button.dart';
import '../../shared/widgets/transit_input.dart';

void showReportIncidentSheet(
  BuildContext context, {
  required WidgetRef ref,
  RouteModel? route,
  StopModel? stop,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final c = TransitColorScheme.of(isDark);

  showModalBottomSheet(
    context: context,
    backgroundColor: c.bgSurface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
    ),
    builder: (ctx) {
      return _ReportIncidentContent(
        c: c,
        ref: ref,
        route: route,
        stop: stop,
      );
    },
  );
}

class _ReportIncidentContent extends ConsumerStatefulWidget {
  const _ReportIncidentContent({
    required this.c,
    required this.ref,
    this.route,
    this.stop,
  });

  final TransitColorScheme c;
  final WidgetRef ref;
  final RouteModel? route;
  final StopModel? stop;

  @override
  ConsumerState<_ReportIncidentContent> createState() =>
      _ReportIncidentContentState();
}

class _ReportIncidentContentState
    extends ConsumerState<_ReportIncidentContent> {
  String? _selected;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selected == null) return;

    setState(() => _submitting = true);

    try {
      final user = ref.read(currentUserProvider);
      final repo = ref.read(incidentRepositoryProvider);

      IncidentType type;
      IncidentCategory category;
      switch (_selected) {
        case 'delay':
          type = IncidentType.delay;
          category = IncidentCategory.service;
        case 'no_show':
          type = IncidentType.busNoShow;
          category = IncidentCategory.service;
        case 'full':
          type = IncidentType.busFull;
          category = IncidentCategory.service;
        case 'detour':
          type = IncidentType.detour;
          category = IncidentCategory.service;
        case 'breakdown':
          type = IncidentType.dangerousDriving;
          category = IncidentCategory.service;
        case 'punctual':
          type = IncidentType.punctual;
          category = IncidentCategory.positive;
        case 'kind':
          type = IncidentType.driverKind;
          category = IncidentCategory.positive;
        case 'clean':
          type = IncidentType.stopClean;
          category = IncidentCategory.positive;
        default:
          type = IncidentType.delay;
          category = IncidentCategory.service;
      }

      final incident = IncidentModel(
        id: generateUuidV4(),
        reporterId: user.id,
        routeId: widget.route?.id ?? '',
        stopId: widget.stop?.id,
        incidentType: type,
        category: category,
        comment: _commentCtrl.text.trim().isEmpty
            ? null
            : _commentCtrl.text.trim(),
        status: 'open',
        createdAt: DateTime.now().toUtc(),
      );

      await repo.create(incident);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context).incidentReportSent)),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).incidentErrorSending)),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
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
            '¿QUÉ HA PASADO?',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: c.textHi,
            ),
          ),
          const SizedBox(height: 4),
          if (widget.route != null)
            Text(
              '${widget.route!.code} · ${widget.route!.name}',
              style: TransitTypography.bodySecondary(c.textMid),
            ),
          if (widget.stop != null)
            Text(
              widget.stop!.name,
              style: TransitTypography.bodySecondary(c.textMid),
            ),
          const SizedBox(height: 16),

          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.2,
            children: [
              _optionCell(c, 'no_show', Icons.bus_alert, 'No pasó'),
              _optionCell(c, 'delay', Icons.access_time, 'Retraso'),
              _optionCell(c, 'full', Icons.people, 'Lleno'),
              _optionCell(c, 'detour', Icons.alt_route, 'Desvío'),
              _optionCell(c, 'breakdown', Icons.build, 'Avería'),
              _optionCell(c, 'other', Icons.more_horiz, 'Otro'),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, thickness: 0.5, color: c.border),
          const SizedBox(height: 12),

          Text(
            'POSITIVO:',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.0,
              color: c.textMid,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child:
                      _optionCell(c, 'punctual', Icons.check, 'Puntual')),
              const SizedBox(width: 8),
              Expanded(
                  child: _optionCell(
                      c, 'kind', Icons.favorite_border, 'Amable')),
              const SizedBox(width: 8),
              Expanded(
                  child: _optionCell(
                      c, 'clean', Icons.cleaning_services, 'Limpio')),
            ],
          ),
          const SizedBox(height: 16),
          TransitInput(
            hint: 'Comentario (opcional)',
            controller: _commentCtrl,
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: TransitButton(
              label: _submitting ? AppLocalizations.of(context).actionSending : AppLocalizations.of(context).actionSend.toUpperCase(),
              onPressed: _selected != null && !_submitting
                  ? _submit
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionCell(
      TransitColorScheme c, String value, IconData icon, String label) {
    final isSelected = _selected == value;
    return GestureDetector(
      onTap: () => setState(() => _selected = value),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: c.bgRaised,
          border: Border.all(
            color: isSelected ? c.accent : c.border,
            width: isSelected ? 1 : 0.5,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 28,
                color: isSelected ? c.accent : c.textMid),
            const SizedBox(height: 2),
            Text(
              label,
              style: TransitTypography.bodySmall(
                  isSelected ? c.accent : c.textMid),
            ),
          ],
        ),
      ),
    );
  }
}
