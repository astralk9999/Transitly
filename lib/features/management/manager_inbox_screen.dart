import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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

  void _showFeedbackSheet(RouteFeedbackModel fb) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final isOpen = fb.status == FeedbackStatus.submitted ||
        fb.status == FeedbackStatus.inReview;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: c.textLo,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  fb.feedbackType.label.toUpperCase(),
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: c.textMid,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  fb.description,
                  style: TransitTypography.bodyPrimary(c.textHi),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${l10n.managerInboxStatus}: ',
                      style: TransitTypography.bodySmall(c.textMid),
                    ),
                    Text(
                      fb.status.label,
                      style: TransitTypography.bodySmall(c.accent),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('dd/MM/yy HH:mm').format(fb.createdAt),
                      style: TransitTypography.bodySmall(c.textLo),
                    ),
                  ],
                ),
                if (isOpen) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: l10n.managerInboxMarkInReview,
                          color: c.accent,
                          onTap: () {
                            Navigator.pop(ctx);
                            _updateFeedbackStatus(fb, 'in_review');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionButton(
                          label: l10n.managerInboxResolve,
                          color: c.stateOnTime,
                          onTap: () {
                            Navigator.pop(ctx);
                            _updateFeedbackStatus(fb, 'resolved');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionButton(
                          label: l10n.managerInboxReject,
                          color: c.stateCancelled,
                          onTap: () {
                            Navigator.pop(ctx);
                            _updateFeedbackStatus(fb, 'rejected');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showIncidentSheet(IncidentModel incident) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final isOpen = incident.status == 'open' ||
        incident.status == 'in_review';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: c.textLo,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  incident.incidentType.label.toUpperCase(),
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: c.textMid,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  incident.comment ?? incident.category.label,
                  style: TransitTypography.bodyPrimary(c.textHi),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${l10n.managerInboxStatus}: ',
                      style: TransitTypography.bodySmall(c.textMid),
                    ),
                    Text(
                      incident.status,
                      style: TransitTypography.bodySmall(c.accent),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('dd/MM/yy HH:mm').format(incident.createdAt),
                      style: TransitTypography.bodySmall(c.textLo),
                    ),
                  ],
                ),
                if (isOpen) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: l10n.managerInboxMarkInReview,
                          color: c.accent,
                          onTap: () {
                            Navigator.pop(ctx);
                            _updateIncidentStatus(incident, 'in_review');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionButton(
                          label: l10n.managerInboxResolve,
                          color: c.stateOnTime,
                          onTap: () {
                            Navigator.pop(ctx);
                            _updateIncidentStatus(incident, 'resolved');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionButton(
                          label: l10n.managerInboxReject,
                          color: c.stateCancelled,
                          onTap: () {
                            Navigator.pop(ctx);
                            _updateIncidentStatus(incident, 'rejected');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSuggestionSheet(RouteSuggestionModel sug) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: c.textLo,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.managerInboxSuggestions.toUpperCase(),
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: c.textMid,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${sug.originText} → ${sug.destinationText}',
                  style: TransitTypography.bodyPrimary(c.textHi),
                ),
                if (sug.notes != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    sug.notes!,
                    style: TransitTypography.bodySecondary(c.textMid),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${l10n.managerInboxStatus}: ',
                      style: TransitTypography.bodySmall(c.textMid),
                    ),
                    Text(
                      sug.status.label,
                      style: TransitTypography.bodySmall(c.accent),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('dd/MM/yy HH:mm').format(sug.createdAt),
                      style: TransitTypography.bodySmall(c.textLo),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: _ActionButton(
                    label: l10n.managerInboxOpen,
                    color: c.accent,
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push('/suggestions/${sug.id}');
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
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
        final priorityColor = switch (fb.autoPriority) {
          Priority.high || Priority.urgent => c.stateCancelled,
          Priority.medium => c.stateDelay,
          _ => c.textMid,
        };
        return GestureDetector(
          onTap: () => _showFeedbackSheet(fb),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.bgSurface,
                border: Border(
                  left: BorderSide(color: priorityColor, width: 2),
                  top: BorderSide(color: c.border, width: 0.5),
                  right: BorderSide(color: c.border, width: 0.5),
                  bottom: BorderSide(color: c.border, width: 0.5),
                ),
              ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      fb.feedbackType.label.toUpperCase(),
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestionsTab(
      TransitColorScheme c, AppLocalizations l10n) {
    if (_suggestions.isEmpty) {
      return _emptyTab(l10n.managerInboxEmptySuggestions);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final sug = _suggestions[index];
        return GestureDetector(
          onTap: () => _showSuggestionSheet(sug),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.bgSurface,
                border: Border(
                  left: BorderSide(color: c.accent, width: 2),
                  top: BorderSide(color: c.border, width: 0.5),
                  right: BorderSide(color: c.border, width: 0.5),
                  bottom: BorderSide(color: c.border, width: 0.5),
                ),
              ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      l10n.managerInboxSuggestions.toUpperCase(),
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: c.textMid,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      sug.status.label,
                      style: TransitTypography.bodySmall(c.accent),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${sug.originText} → ${sug.destinationText}',
                  style: TransitTypography.bodySecondary(c.textHi),
                ),
                if (sug.notes != null)
                  Text(
                    sug.notes!,
                    style: TransitTypography.bodySmall(c.textMid),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResolvedTab(
      TransitColorScheme c, AppLocalizations l10n) {
    final items = <Widget>[];

    for (final fb in _resolvedFeedbacks) {
      items.add(_buildResolvedFeedbackItem(c, fb));
    }
    for (final inc in _resolvedIncidents) {
      items.add(_buildResolvedIncidentItem(c, inc));
    }

    if (items.isEmpty) {
      return _emptyTab(l10n.managerInboxEmptyResolved);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: items,
    );
  }

  Widget _buildResolvedFeedbackItem(
      TransitColorScheme c, RouteFeedbackModel fb) {
    return GestureDetector(
      onTap: () => _showFeedbackSheet(fb),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.bgSurface.mix(c.stateCancelled, 0.08),
          border: Border.all(color: c.border, width: 0.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  fb.feedbackType.label.toUpperCase(),
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: c.textMid,
                  ),
                ),
                const Spacer(),
                Text(
                  fb.status.label,
                  style: TransitTypography.bodySmall(
                      fb.status == FeedbackStatus.applied
                          ? c.stateOnTime
                          : c.stateCancelled),
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
      ),
    );
  }

  Widget _buildResolvedIncidentItem(
      TransitColorScheme c, IncidentModel incident) {
    return GestureDetector(
      onTap: () => _showIncidentSheet(incident),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.bgSurface.mix(c.stateCancelled, 0.08),
          border: Border.all(color: c.border, width: 0.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  incident.incidentType.label.toUpperCase(),
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: c.textMid,
                  ),
                ),
                const Spacer(),
                Text(
                  incident.status,
                  style: TransitTypography.bodySmall(
                      incident.status == 'resolved'
                          ? c.stateOnTime
                          : c.stateCancelled),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              incident.comment ?? incident.category.label,
              style: TransitTypography.bodySecondary(c.textHi),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyTab(String message) {
    return Center(child: EmptyState(message, ''));
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

extension on Color {
  Color mix(Color other, double amount) {
    return Color.lerp(this, other, amount) ?? this;
  }
}
