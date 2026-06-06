import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../core/utils/app_logger.dart';
import '../../data/incident/domain/incident_repository.dart';
import '../../data/incident/incident_repository_provider.dart';
import '../../data/route_feedback/domain/route_feedback_repository.dart';
import '../../data/route_feedback/route_feedback_helpers.dart';
import '../../data/route_feedback/route_feedback_repository_provider.dart';
import '../../data/route_suggestion/domain/route_suggestion_repository.dart';
import '../../data/route_suggestion/route_suggestion_repository_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/incident_model.dart';
import '../../shared/models/route_feedback_model.dart';
import '../../shared/models/route_suggestion_model.dart';
import '../../shared/widgets/empty_state.dart';
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
  bool _statusLoading = false;
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
      AppLogger.warn('ManagerInbox', '_loadData failed', e);
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _updateFeedbackStatus(
      RouteFeedbackModel fb, String newStatus) async {
    final fbStatus = feedbackStatusFromString(newStatus);
    final updated = fb.copyWith(status: fbStatus);

    setState(() {
      _statusLoading = true;
      _feedbacks = _feedbacks.where((f) => f.id != fb.id).toList();
      _resolvedFeedbacks = [updated, ..._resolvedFeedbacks];
    });

    try {
      await ref.read(routeFeedbackRepositoryProvider).updateStatus(fb.id, newStatus);
    } on RouteFeedbackRepositoryException {
      if (!mounted) return;
      setState(() {
        _feedbacks = [fb, ..._feedbacks];
        _resolvedFeedbacks = _resolvedFeedbacks.where((f) => f.id != fb.id).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).adminOperatorsErrorUnknown)),
      );
    } finally {
      if (mounted) setState(() => _statusLoading = false);
    }
  }

  Future<void> _updateIncidentStatus(
      IncidentModel incident, String newStatus) async {
    final updated = incident.copyWith(status: newStatus);

    setState(() {
      _statusLoading = true;
      _resolvedIncidents = [updated, ..._resolvedIncidents];
    });

    try {
      await ref.read(incidentRepositoryProvider).updateStatus(incident.id, newStatus);
    } on IncidentRepositoryException {
      if (!mounted) return;
      setState(() {
        _resolvedIncidents = _resolvedIncidents.where((i) => i.id != incident.id).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).adminOperatorsErrorUnknown)),
      );
    } finally {
      if (mounted) setState(() => _statusLoading = false);
    }
  }

  Future<void> _updateSuggestionStatus(
      RouteSuggestionModel sug, String newStatus) async {
    setState(() {
      _statusLoading = true;
      _suggestions = _suggestions.where((s) => s.id != sug.id).toList();
    });

    try {
      await ref.read(routeSuggestionRepositoryProvider).updateStatus(sug.id, newStatus);
    } on RouteSuggestionRepositoryException {
      if (!mounted) return;
      setState(() {
        _suggestions = [sug, ..._suggestions];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).adminOperatorsErrorUnknown)),
      );
    } finally {
      if (mounted) setState(() => _statusLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final l10n = AppLocalizations.of(context);
    final pendingCount = _feedbacks.length + _suggestions.length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textMid),
          tooltip: 'Volver',
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.managerInboxTitle,
            style: TransitTypography.subheading(c.textHi)),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          if (_statusLoading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(),
            ),
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
                        TransitTypography.errorText(c.textMid),
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
                          labelStyle: TransitTypography.tabLabel(Colors.white),
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
            onResolve: sug.status != SuggestionStatus.accepted &&
                    sug.status != SuggestionStatus.rejected
                ? () => _updateSuggestionStatus(sug, 'accepted')
                : null,
            onReject: sug.status != SuggestionStatus.accepted &&
                    sug.status != SuggestionStatus.rejected
                ? () => _updateSuggestionStatus(sug, 'rejected')
                : null,
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
