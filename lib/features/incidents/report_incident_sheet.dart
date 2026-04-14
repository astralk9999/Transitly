import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../shared/models/route_model.dart';
import '../../shared/models/stop_model.dart';
import '../../shared/widgets/transit_button.dart';
import '../../shared/widgets/transit_input.dart';

void showReportIncidentSheet(
  BuildContext context, {
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
        route: route,
        stop: stop,
      );
    },
  );
}

class _ReportIncidentContent extends StatefulWidget {
  const _ReportIncidentContent({
    required this.c,
    this.route,
    this.stop,
  });

  final TransitColorScheme c;
  final RouteModel? route;
  final StopModel? stop;

  @override
  State<_ReportIncidentContent> createState() =>
      _ReportIncidentContentState();
}

class _ReportIncidentContentState extends State<_ReportIncidentContent> {
  String? _selected;
  final _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
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
          // Handle
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

          // Title
          Text(
            '¿QUÉ HA PASADO?',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: c.textHi,
            ),
          ),
          const SizedBox(height: 4),

          // Context
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

          // Negative options
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

          // Positive options
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

          // Comment
          TransitInput(
            hint: 'Comentario (opcional)',
            controller: _commentCtrl,
          ),
          const SizedBox(height: 16),

          // Submit
          SizedBox(
            width: double.infinity,
            child: TransitButton(
              label: 'ENVIAR',
              onPressed: _selected != null
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Reporte enviado · Gracias')),
                      );
                      Navigator.of(context).pop();
                    }
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
            Icon(icon, size: 28, color: isSelected ? c.accent : c.textMid),
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
