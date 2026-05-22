import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/incident/incident_repository_provider.dart';
import '../../data/mock/mock_data_service.dart';
import '../../data/route_feedback/route_feedback_repository_provider.dart';
import '../../data/route_suggestion/route_suggestion_repository_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/models/incident_model.dart';
import '../../shared/models/route_feedback_model.dart';
import '../../shared/models/route_suggestion_model.dart';
import '../../shared/providers/local_feedback_provider.dart';
import '../../shared/providers/user_provider.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/reputation_badge.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/smoke_background.dart';
import 'widgets/suggestions_tab_content.dart';

class MyContributionsScreen extends ConsumerStatefulWidget {
  const MyContributionsScreen({super.key});

  @override
  ConsumerState<MyContributionsScreen> createState() =>
      _MyContributionsScreenState();
}

class _MyContributionsScreenState
    extends ConsumerState<MyContributionsScreen> {
  List<RouteSuggestionModel> _suggestions = [];
  List<RouteFeedbackModel> _feedbacks = [];
  List<IncidentModel> _incidents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final user = ref.read(currentUserProvider);
    final uid = user.id;

    final suggestionRepo = ref.read(routeSuggestionRepositoryProvider);
    final feedbackRepo = ref.read(routeFeedbackRepositoryProvider);
    final incidentRepo = ref.read(incidentRepositoryProvider);

    final results = await Future.wait([
      suggestionRepo.list().then(
            (list) => list.where((s) => s.suggestedBy == uid).toList(),
            onError: (_) => <RouteSuggestionModel>[],
          ),
      feedbackRepo.byAuthor(uid),
      incidentRepo.byAuthor(uid),
    ]);

    if (mounted) {
      setState(() {
        _suggestions = results[0] as List<RouteSuggestionModel>;
        _feedbacks = results[1] as List<RouteFeedbackModel>;
        _incidents = results[2] as List<IncidentModel>;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final mockData = ref.watch(mockDataServiceProvider);
    final localFeedbacks = ref.watch(localFeedbackProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: c.bgRoot,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textMid),
          tooltip: l10n.actionBack,
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.myContributionsTitle.toUpperCase(),
            style: TransitTypography.sectionTitle(c.textHi)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: c.textMid, size: 20),
            onPressed: _load,
            tooltip: l10n.myContributionsReload,
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
              child: SmokeBackground(color: c.accent, isDark: isDark)),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            ContentConstraints(
              child: Builder(builder: (context) {
                final padding = ResponsiveScaffold.screenPadding(context);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: padding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ReputationBadge(
                                  ref.watch(currentUserProvider).reputationLevel),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  l10n.myContributionsSummary(_suggestions.length,
                                      _feedbacks.length + localFeedbacks.length,
                                      _incidents.length),
                                  style: GoogleFonts.dmSans(
                                      fontSize: 12, color: c.textMid),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 2.5,
                            children: [
                              _statCell(c, _suggestions.length.toString(),
                                  l10n.myContributionsLabelSuggestions),
                              _statCell(
                                  c,
                                  (_feedbacks.length + localFeedbacks.length)
                                      .toString(),
                                  l10n.myContributionsLabelCorrections),
                              _statCell(c, _incidents.length.toString(),
                                  l10n.myContributionsLabelReports),
                              _statCell(c, '—', l10n.myContributionsLabelPhotos),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    Expanded(
                      child: DefaultTabController(
                        length: 3,
                        child: Column(
                          children: [
                            TabBar(
                              indicatorColor: c.accent,
                              labelColor: c.accent,
                              unselectedLabelColor: c.textMid,
                              labelStyle: GoogleFonts.ibmPlexMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                              tabs: [
                                Tab(text: l10n.myContributionsTabSuggestions.toUpperCase()),
                                Tab(text: l10n.myContributionsTabFeedback.toUpperCase()),
                                Tab(text: l10n.myContributionsTabReports.toUpperCase()),
                              ],
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  SuggestionsTabContent(
                                    suggestions: _suggestions,
                                    colorScheme: c,
                                    padding: padding,
                                  ),
                                  _buildFeedbackTab(
                                      c, localFeedbacks, mockData, padding),
                                  _buildReportsTab(c, padding),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildFeedbackTab(TransitColorScheme c,
      List<LocalFeedbackEntry> localFeedbacks, MockDataService mockData,
      double padding) {
    final allFeedbacks = _feedbacks;
    final hasLocal = localFeedbacks.isNotEmpty;

    if (allFeedbacks.isEmpty && !hasLocal) {
      final l10n = AppLocalizations.of(context);
      return Center(
        child: EmptyState(
          l10n.myContributionsEmptyFeedback.toUpperCase(),
          l10n.myContributionsEmptyFeedbackSubtitle,
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(padding),
      itemCount: localFeedbacks.length + allFeedbacks.length,
      itemBuilder: (context, index) {
        if (index < localFeedbacks.length) {
          final fb = localFeedbacks[index];
          final code =
              mockData.getRouteById(fb.routeId)?.code ?? fb.routeId;
          return _buildLocalFeedbackTile(c, code, fb);
        }
        final fb = allFeedbacks[index - localFeedbacks.length];
        final code =
            mockData.getRouteById(fb.routeId)?.code ?? fb.routeId;
        return _buildRemoteFeedbackTile(c, code, fb);
      },
    );
  }

  Widget _buildLocalFeedbackTile(
      TransitColorScheme c, String code, LocalFeedbackEntry fb) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.accentBg.withValues(alpha: 0.15),
        border: Border.all(color: c.accent, width: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$code · ${fb.category.label.toUpperCase()}',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: c.textMid,
                ),
              ),
              const Spacer(),
              Text(
                AppLocalizations.of(context).myContributionsLocalDraft.toUpperCase(),
                style: TransitTypography.bodySmall(c.accent),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            fb.description,
            style: TransitTypography.bodySecondary(c.textHi),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRemoteFeedbackTile(
      TransitColorScheme c, String code, RouteFeedbackModel fb) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.bgSurface,
        border: Border.all(color: c.border, width: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$code · ${fb.feedbackType.label.toUpperCase()}',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: c.textMid,
                ),
              ),
              const Spacer(),
              Text(
                fb.status.label,
                style: TransitTypography.bodySmall(c.accent),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            fb.description,
            style: TransitTypography.bodySecondary(c.textHi),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab(TransitColorScheme c, double padding) {
    if (_incidents.isEmpty) {
      final l10n = AppLocalizations.of(context);
      return Center(
        child: EmptyState(
          l10n.myContributionsEmptyReports.toUpperCase(),
          l10n.myContributionsEmptyReportsSubtitle,
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(padding),
      itemCount: _incidents.length,
      itemBuilder: (context, index) {
        final inc = _incidents[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.bgSurface,
            border: Border.all(color: c.border, width: 0.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    inc.incidentType.name.toUpperCase(),
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: c.textMid,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    inc.category.label,
                    style: TransitTypography.bodySmall(c.accent),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                inc.comment ?? AppLocalizations.of(context).myContributionsNoDescription,
                style: TransitTypography.bodySecondary(c.textHi),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _statCell(
      TransitColorScheme c, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.bgSurface,
        border: Border.all(color: c.border, width: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Text(
            value,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: c.accent,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.dmSans(fontSize: 13, color: c.textMid),
          ),
        ],
      ),
    );
  }
}
