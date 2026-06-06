import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'editor_controller.dart';
import 'steps/step_info.dart';
import 'steps/step_return.dart';
import 'steps/step_review.dart';
import 'steps/step_schedules.dart';
import 'steps/step_stops.dart';
import 'steps/step_trace.dart';

class ManualRouteEditor extends StatefulWidget {
  const ManualRouteEditor({super.key});

  @override
  State<ManualRouteEditor> createState() => _ManualRouteEditorState();
}

class _ManualRouteEditorState extends State<ManualRouteEditor> {
  final _controller = RouteEditorController();
  final _pageController = PageController();
  int _step = 0;

  List<String> _titles(BuildContext context) => [
    AppLocalizations.of(context).editorStepInfo.toUpperCase(),
    AppLocalizations.of(context).editorStepTrace.toUpperCase(),
    AppLocalizations.of(context).editorStepStops.toUpperCase(),
    AppLocalizations.of(context).editorStepReturn.toUpperCase(),
    AppLocalizations.of(context).sectionSchedules,
    AppLocalizations.of(context).editorStepReview.toUpperCase(),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textMid),
          tooltip: 'Volver',
          onPressed: () {
            if (_step > 0) {
              _goToStep(_step - 1);
            } else {
              context.pop();
            }
          },
        ),
        title: Text(_titles(context)[_step],
            style: TransitTypography.sectionTitle(c.textHi)),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _StepIndicator(step: _step, c: c),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    StepInfo(
                        controller: _controller,
                        onNext: () => _goToStep(1)),
                    StepTrace(
                        controller: _controller,
                        isDark: isDark,
                        onNext: () => _goToStep(2)),
                    StepStops(
                        controller: _controller,
                        isDark: isDark,
                        onNext: () => _goToStep(3)),
                    StepReturn(
                        controller: _controller,
                        onNext: () => _goToStep(4)),
                    StepSchedules(
                        controller: _controller,
                        onNext: () => _goToStep(5)),
                    StepReview(controller: _controller, isDark: isDark),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step, required this.c});

  final int step;
  final TransitColorScheme c;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(6, (i) {
          final isCompleted = i < step;
          final isCurrent = i == step;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrent ? c.accent : Colors.transparent,
                border: Border.all(
                  color: isCurrent || isCompleted ? c.accent : c.textLo,
                  width: 1.5,
                ),
              ),
              child: isCompleted
                  ? Icon(Icons.check, size: 12, color: c.accent)
                  : Center(
                      child: Text(
                        '${i + 1}',
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 10,
                          fontWeight:
                              isCurrent ? FontWeight.w700 : FontWeight.w400,
                          color: isCurrent ? c.bgRoot : c.textLo,
                        ),
                      ),
                    ),
            ),
          );
        }),
      ),
    );
  }
}
