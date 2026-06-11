import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../core/utils/uuid.dart';
import '../../data/route_suggestion/route_suggestion_repository_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/route_suggestion_model.dart';
import '../../shared/providers/user_provider.dart';
import '../../shared/widgets/single_field_dialog.dart';
import '../../shared/widgets/transit_app_bar.dart';
import '../../shared/widgets/transit_button.dart';
import '../../shared/widgets/transit_input.dart';

class SuggestRouteScreen extends ConsumerStatefulWidget {
  const SuggestRouteScreen({super.key});

  @override
  ConsumerState<SuggestRouteScreen> createState() =>
      _SuggestRouteScreenState();
}

class _SuggestRouteScreenState extends ConsumerState<SuggestRouteScreen> {
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _operator = '';
  String _source = '';
  final List<TextEditingController> _stopCtrls = [];
  final List<String> _hours = [];

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _codeCtrl.dispose();
    _notesCtrl.dispose();
    for (final c in _stopCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      appBar: TransitAppBar(
          title: l10n.suggestRouteScreenTitle, transparent: true),
      body: Stack(
        children: [
          SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.suggestRouteHelpText,
              style: TransitTypography.bodySecondary(c.textMid),
            ),
            const SizedBox(height: 16),

            // From / To
            Text(l10n.suggestRouteFromLabel, style: TransitTypography.bodySecondary(c.textMid)),
            const SizedBox(height: 6),
            TransitInput(
              hint: l10n.suggestRouteFromHint,
              controller: _fromCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Text(l10n.suggestRouteToLabel, style: TransitTypography.bodySecondary(c.textMid)),
            const SizedBox(height: 6),
            TransitInput(
              hint: l10n.suggestRouteToHint,
              controller: _toCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),

            // Operator chips
            Text(l10n.suggestRouteOperatorLabel,
                style: TransitTypography.bodySecondary(c.textMid)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                (l10n.suggestRouteOperatorComujesa, 'COMUJESA'),
                (l10n.suggestRouteOperatorOther, 'Otra'),
                (l10n.suggestRouteOperatorDontKnow, 'No lo sé'),
              ].map((op) {
                final selected = _operator == op.$2;
                return GestureDetector(
                  onTap: () => setState(() => _operator = op.$2),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? c.accentBg : c.bgRaised,
                      border: Border.all(
                        color: selected ? c.accent : c.border,
                        width: selected ? 1 : 0.5,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      op.$1,
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? c.accent : c.textMid,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Code
            Text(l10n.suggestRouteCodeLabel,
                style: TransitTypography.bodySecondary(c.textMid)),
            const SizedBox(height: 6),
            TransitInput(hint: l10n.suggestRouteCodeHint, controller: _codeCtrl),
            const SizedBox(height: 20),

            // Source
            Text(l10n.suggestRouteHowKnow,
                style: TransitTypography.bodySecondary(c.textMid)),
            const SizedBox(height: 8),
            ...[(l10n.suggestRouteSourceUseIt, 'La uso'), (l10n.suggestRouteSourceSawIt, 'La he visto'), (l10n.suggestRouteSourceTold, 'Me lo dijeron'), (l10n.suggestRouteSourceWeb, 'Web oficial')]
                .map((opt) => GestureDetector(
                      onTap: () => setState(() => _source = opt.$2),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _source == opt.$2 ? c.accent : c.textLo,
                                  width: 1.5,
                                ),
                              ),
                              child: _source == opt.$2
                                  ? Center(
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: c.accent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Text(opt.$1,
                                style:
                                    TransitTypography.subheading(c.textHi)),
                          ],
                        ),
                      ),
                    )),
            const SizedBox(height: 16),

            // Expansion: more details
            Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(l10n.suggestRouteAddDetails,
                    style: TransitTypography.bodySecondary(c.accent)),
                iconColor: c.accent,
                collapsedIconColor: c.accent,
                children: [
                  // Stops
                  Text(l10n.suggestRouteStopsRemember,
                      style: TransitTypography.bodySecondary(c.textMid)),
                  const SizedBox(height: 8),
                  ..._stopCtrls.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: TransitInput(
                          hint: l10n.suggestRouteStopNumber(e.key + 1),
                          controller: e.value,
                        ),
                      )),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => setState(
                          () => _stopCtrls.add(TextEditingController())),
                      child: Text(l10n.suggestRouteAddStop,
                          style: TransitTypography.bodySecondary(c.accent)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Hours
                  Text(l10n.suggestRouteTimesKnown,
                      style: TransitTypography.bodySecondary(c.textMid)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._hours.map((h) => Container(
                            width: 60,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: c.bgSurface,
                              border:
                                  Border.all(color: c.border, width: 0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(h,
                                style: GoogleFonts.ibmPlexMono(
                                    fontSize: 14, color: c.textHi)),
                          )),
                      GestureDetector(
                        onTap: () => _addHourDialog(c),
                        child: Container(
                          width: 60,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: c.bgSurface,
                            border:
                                Border.all(color: c.accent, width: 0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(Icons.add, size: 18, color: c.accent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  Text(l10n.suggestRouteNotesLabel,
                      style: TransitTypography.bodySecondary(c.textMid)),
                  const SizedBox(height: 6),
                  TransitInput(
                    hint: l10n.suggestRouteNotesHint,
                    controller: _notesCtrl,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Submit
            SizedBox(
              width: double.infinity,
              child: TransitButton(
                label: AppLocalizations.of(context).actionSendSuggestion.toUpperCase(),
                onPressed:
                    _fromCtrl.text.isNotEmpty && _toCtrl.text.isNotEmpty
                        ? () => _submitSuggestion(context, c)
                        : null,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
        ],
      ),
    );
  }

  Future<void> _submitSuggestion(
      BuildContext context, TransitColorScheme c) async {
    final user = ref.read(currentUserProvider);
    final repo = ref.read(routeSuggestionRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final l10n = AppLocalizations.of(context);

    final suggestion = RouteSuggestionModel(
      id: generateUuidV4(),
      suggestedBy: user.id,
      originText: _fromCtrl.text.trim(),
      destinationText: _toCtrl.text.trim(),
      routeCode: _codeCtrl.text.trim().isEmpty
          ? null
          : _codeCtrl.text.trim(),
      operatorName: _operator.isNotEmpty ? _operator : null,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      source: _source.isNotEmpty ? _source : null,
      status: SuggestionStatus.idea,
      createdAt: DateTime.now(),
    );

    try {
      await repo.create(suggestion);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.suggestRouteSent)),
        );
        nav.pop();
      }
    } on Exception catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.suggestRouteSubmitError(e.toString()))),
        );
      }
    }
  }

  Future<void> _addHourDialog(TransitColorScheme c) async {
    final l10n = AppLocalizations.of(context);
    final hour = await showSingleFieldDialog(
      context,
      title: l10n.suggestRouteAddTimeTitle,
      hint: l10n.suggestRouteAddTimeHint,
      confirmLabel: l10n.suggestRouteAddTimeConfirm,
    );
    if (hour != null && mounted) {
      setState(() {
        _hours
          ..add(hour)
          ..sort();
      });
    }
  }
}
