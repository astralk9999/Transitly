import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/incident/domain/incident_repository.dart';
import '../../data/incident/incident_repository_provider.dart';
import '../../data/route_feedback/domain/route_feedback_repository.dart';
import '../../data/route_feedback/route_feedback_repository_provider.dart';
import '../../data/route_suggestion/route_suggestion_repository_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/incident_model.dart';
import '../../shared/models/route_feedback_model.dart';
import '../../shared/models/route_suggestion_model.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/smoke_background.dart';
import 'widgets/feedback_list_item.dart';
import 'widgets/inbox_action_sheets.dart';
import 'widgets/resolved_feedback_item.dart';
import 'widgets/resolved_incident_item.dart';
import 'widgets/suggestion_list_item.dart';

class ManagerInboxScreen extends ConsumerStatefulWidget {
  const ManagerInboxScreen({super.key});

  @override
  ConsumerState<ManagerInboxScreen> createState() =>
      _ManagerInboxScreenState();
}

class _ManagerInboxScreenState extends ConsumerState<ManagerInboxScreen> {
  List<RouteFeedbackModel> _feedbacks = [];
  List<RouteSuggestionModel> _suggestions = [];
  List<RouteFeedbackModel> _resolvedFeedbacks = [];
  List<IncidentModel> _resolvedIncidents = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final feedbackRepo = ref.read(routeFeedbackRepositoryProvider);
      final suggestionRepo = ref.read(routeSuggestionRepositoryProvider);
      final incidentRepo = ref.read(incidentRepositoryProvider);

      final results = await Future.wait([
        feedbackRepo.listAll(),
        suggestionRepo.list(),
        incidentRepo.listAll(),
      ]);

      if (!mounted) return;

      final allFeedbacks = results[0] as List<RouteFeedbackModel>;
      final allSuggestions = results[1] as List<RouteSuggestionModel>;
      final allIncidents = results[2] as List<IncidentModel>;

      setState(() {
        _feedbacks = allFeedbacks.where((f) {
          return f.status == FeedbackStatus.submitted ||
              f.status == FeedbackStatus.inReview;
        }).toList();
        _suggestions = allSuggestions;
        _resolvedFeedbacks = allFeedbacks.where((f) {
          return f.status == FeedbackStatus.applied ||
              f.status == FeedbackStatus.rejected ||
              f.status == FeedbackStatus.accepted ||
              f.status == FeedbackStatus.duplicate;
        }).toList();
        _resolvedIncidents = allIncidents.where((i) {
          return i.status == 'resolved' || i.status == 'rejected';
        }).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _updateFeedbackStatus(
      RouteFeedbackModel fb, String newStatus) async {
    final repo = ref.read(routeFeedbackRepositoryProvider);
    try {
      await repo.updateStatus(fb.id, newStatus);
      await _loadData();
    } on RouteFeedbackRepositoryException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).adminOperatorsErrorUnknown)),
      );
    }
  }

  Future<void> _updateIncidentStatus(
      IncidentModel incident, String newStatus) async {
    final repo = ref.read(incidentRepositoryProvider);
    try {
      await repo.updateStatus(incident.id, newStatus);
      await _loadData();
    } on IncidentRepositoryException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).adminOperatorsErrorUnknown)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final l10n = AppLocalizations.of(context);
    final pendingCount = _feedbacks.length + _suggestions.length;

    return Scaffold(
      backgroundColor: c.bgRoot,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textMid),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.managerInboxTitle,
            style: TransitTypography.sectionTitle(c.textHi)),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          Positioned.fill(
              child: SmokeBackground(color: c.accent, isDark: isDark)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_loading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Expanded(
                  child: Center(
                    child: Text(
                      _error!,
                      style: TransitTypography.bodyPrimary(c.stateCancelled),
                    ),
                  ),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    l10n.managerInboxPending(pendingCount),
                    style:
                        GoogleFonts.ibmPlexMono(fontSize: 12, color: c.textMid),
                  ),
                ),
                const SizedBox(height: 8),
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
                              fontSize: 11, fontWeight: FontWeight.w600),
                          tabs: [
                            Tab(text: l10n.managerInboxFeedback),
                            Tab(text: l10n.managerInboxSuggestions),
                            Tab(text: l10n.managerInboxResolved),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildFeedbackTab(c),
                              _buildSuggestionsTab(c, l10n),
                              _buildResolvedTab(c, l10n),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackTab(TransitColorScheme c) {
    if (_feedbacks.isEmpty) {
      return _emptyTab(AppLocalizations.of(context).managerInboxEmptyFeedback);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _feedbacks.length,
      itemBuilder: (context, index) {
        final fb = _feedbacks[index];
        return FeedbackListItem(
          feedback: fb,
          c: c,
          onTap: () => InboxActionSheets.showFeedbackSheet(
            context,
            feedback: fb,
            onMarkInReview: () => _updateFeedbackStatus(fb, 'in_review'),
            onResolve: () => _updateFeedbackStatus(fb, 'resolved'),
            onReject: () => _updateFeedbackStatus(fb, 'rejected'),
          ),
        );
      },
    );
  }

  Widget _buildSuggestionsTab(TransitColorScheme c, AppLocalizations l10n) {
    if (_suggestions.isEmpty) {
      return _emptyTab(l10n.managerInboxEmptySuggestions);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final sug = _suggestions[index];
        return SuggestionListItem(
          suggestion: sug,
          c: c,
          l10n: l10n,
          onTap: () => InboxActionSheets.showSuggestionSheet(
            context,
            suggestion: sug,
            onOpen: () => context.push('/suggestions/${sug.id}'),
          ),
        );
      },
    );
  }

  Widget _buildResolvedTab(TransitColorScheme c, AppLocalizations l10n) {
    final items = <Widget>[];

    for (final fb in _resolvedFeedbacks) {
      items.add(ResolvedFeedbackItem(
        feedback: fb,
        c: c,
        onTap: () => InboxActionSheets.showFeedbackSheet(
          context,
          feedback: fb,
          onMarkInReview: () => _updateFeedbackStatus(fb, 'in_review'),
          onResolve: () => _updateFeedbackStatus(fb, 'resolved'),
          onReject: () => _updateFeedbackStatus(fb, 'rejected'),
        ),
      ));
    }
    for (final inc in _resolvedIncidents) {
      items.add(ResolvedIncidentItem(
        incident: inc,
        c: c,
        onTap: () => InboxActionSheets.showIncidentSheet(
          context,
          incident: inc,
          onMarkInReview: () => _updateIncidentStatus(inc, 'in_review'),
          onResolve: () => _updateIncidentStatus(inc, 'resolved'),
          onReject: () => _updateIncidentStatus(inc, 'rejected'),
        ),
      ));
    }

    if (items.isEmpty) {
      return _emptyTab(l10n.managerInboxEmptyResolved);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: items,
    );
  }

  Widget _emptyTab(String message) {
    return Center(child: EmptyState(message, ''));
  }
}
