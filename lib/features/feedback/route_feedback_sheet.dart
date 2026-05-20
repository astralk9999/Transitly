import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../core/utils/uuid.dart';
import '../../data/route_feedback/route_feedback_repository_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/route_feedback_model.dart';
import '../../shared/models/route_model.dart';
import '../../shared/models/stop_model.dart';
import '../../shared/providers/user_provider.dart';
import '../../shared/widgets/transit_button.dart';
import '../../shared/widgets/transit_input.dart';

void showRouteFeedbackSheet(
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
      return _RouteFeedbackContent(
        c: c,
        ref: ref,
        route: route,
        stop: stop,
      );
    },
  );
}

class _RouteFeedbackContent extends ConsumerStatefulWidget {
  const _RouteFeedbackContent({
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
  ConsumerState<_RouteFeedbackContent> createState() =>
      _RouteFeedbackContentState();
}

class _RouteFeedbackContentState extends ConsumerState<_RouteFeedbackContent> {
  final _descCtrl = TextEditingController();
  FeedbackType _selectedType = FeedbackType.generalInfo;
  bool _submitting = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final route = widget.route;
    final stop = widget.stop;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit, size: 20, color: c.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'MEJORAR INFORMACIÓN',
                    style: TransitTypography.sectionTitle(c.textHi),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(Icons.close, size: 20, color: c.textLo),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (route != null)
              Text(
                'Línea: ${route.code} · ${route.name}',
                style: TransitTypography.bodySecondary(c.textMid),
              ),
            if (stop != null)
              Text(
                'Parada: ${stop.name}',
                style: TransitTypography.bodySecondary(c.textMid),
              ),
            const SizedBox(height: 16),

            Text('Tipo de mejora',
                style: TransitTypography.bodySecondary(c.textMid)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: FeedbackType.values.map((ft) {
                final selected = _selectedType == ft;
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = ft),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? c.accentBg : c.bgRaised,
                      border: Border.all(
                        color: selected ? c.accent : c.border,
                        width: selected ? 1 : 0.5,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      ft.label,
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: selected ? c.accent : c.textMid,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            TransitInput(
              hint: 'Describe la mejora...',
              controller: _descCtrl,
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: TransitButton(
                label: _submitting ? 'ENVIANDO...' : 'ENVIAR MEJORA',
                onPressed:
                    _descCtrl.text.trim().isNotEmpty && !_submitting
                        ? _submit
                        : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);

    final user = widget.ref.read(currentUserProvider);
    final repo = widget.ref.read(routeFeedbackRepositoryProvider);

    final feedback = RouteFeedbackModel(
      id: generateUuidV4(),
      userId: user.id,
      routeId: widget.route?.id ?? '',
      stopId: widget.stop?.id,
      feedbackType: _selectedType,
      description: _descCtrl.text.trim(),
      status: FeedbackStatus.submitted,
      createdAt: DateTime.now(),
    );

    try {
      await repo.create(feedback);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).routeFeedbackImprovementSent)),
        );
        Navigator.of(context).pop();
      }
    } catch (_) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).feedbackErrorSending)),
        );
      }
    }
  }
}
