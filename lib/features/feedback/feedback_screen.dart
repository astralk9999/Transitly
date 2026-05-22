import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../core/utils/uuid.dart';
import '../../data/mock/mock_data_service.dart';
import '../../data/route_feedback/route_feedback_repository_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/route_feedback_model.dart';
import '../../shared/providers/local_feedback_provider.dart';
import '../../shared/providers/user_provider.dart';
import '../../shared/widgets/smoke_background.dart';
import '../../shared/widgets/transit_button.dart';
import '../../shared/widgets/transit_input.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key, required this.routeId});

  final String routeId;

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _descCtrl = TextEditingController();
  FeedbackCategory? _selected;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  bool _submitting = false;

  FeedbackType _categoryToFeedbackType(FeedbackCategory cat) => switch (cat) {
        FeedbackCategory.route => FeedbackType.routePath,
        FeedbackCategory.stops => FeedbackType.stopMissing,
        FeedbackCategory.schedules => FeedbackType.scheduleOutdated,
        FeedbackCategory.info => FeedbackType.generalInfo,
        FeedbackCategory.suggestion => FeedbackType.suggestion,
      };

  Future<void> _submit() async {
    final cat = _selected;
    if (cat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).feedbackSelectCategoryFirst)),
      );
      return;
    }
    final desc = _descCtrl.text.trim();
    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).feedbackEnterDescription)),
      );
      return;
    }

    setState(() => _submitting = true);

    final localNotifier = ref.read(localFeedbackProvider.notifier);
    final entry = LocalFeedbackEntry(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      routeId: widget.routeId,
      category: cat,
      description: desc,
      createdAt: DateTime.now(),
    );
    await localNotifier.add(entry);

    final user = ref.read(currentUserProvider);
    final repo = ref.read(routeFeedbackRepositoryProvider);
    final feedback = RouteFeedbackModel(
      id: generateUuidV4(),
      userId: user.id,
      routeId: widget.routeId,
      feedbackType: _categoryToFeedbackType(cat),
      description: desc,
      status: FeedbackStatus.submitted,
      createdAt: DateTime.now(),
    );
    try {
      await repo.create(feedback);
    } on Exception {
      // Feedback already persisted locally; remote will sync via offline queue
    }

    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).feedbackSent)),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final mockData = ref.watch(mockDataServiceProvider);
    final route = mockData.getRouteById(widget.routeId);
    final code = route?.code ?? widget.routeId;

    return Scaffold(
      backgroundColor: c.bgRoot,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textMid),
          onPressed: () => context.pop(),
        ),
        title: Text('FEEDBACK · $code',
            style: TransitTypography.sectionTitle(c.textHi)),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          Positioned.fill(
              child: SmokeBackground(color: c.accent, isDark: isDark)),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _option(c, Icons.route, FeedbackCategory.route),
                _option(c, Icons.location_on, FeedbackCategory.stops),
                _option(c, Icons.schedule, FeedbackCategory.schedules),
                _option(c, Icons.info_outline, FeedbackCategory.info),
                _option(c, Icons.lightbulb_outline,
                    FeedbackCategory.suggestion),

                const SizedBox(height: 24),

                Text('Descripción',
                    style: TransitTypography.bodySecondary(c.textMid)),
                const SizedBox(height: 6),
                TransitInput(
                  hint: 'Descripción de lo que has encontrado',
                  controller: _descCtrl,
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TransitButton(
                    label: _submitting ? AppLocalizations.of(context).actionSending : AppLocalizations.of(context).actionSendFeedback.toUpperCase(),
                    onPressed: _submitting ? null : _submit,
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

  Widget _option(TransitColorScheme c, IconData icon, FeedbackCategory cat) {
    final isSelected = _selected == cat;
    return GestureDetector(
      onTap: () => setState(() => _selected = cat),
      child: Container(
        height: 56,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? c.accentBg : c.bgSurface,
          border: Border.all(
              color: isSelected ? c.accent : c.border,
              width: isSelected ? 1 : 0.5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: c.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(cat.label,
                  style: TransitTypography.bodyPrimary(c.textHi)),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.chevron_right,
              size: 20,
              color: isSelected ? c.accent : c.textLo,
            ),
          ],
        ),
      ),
    );
  }
}
