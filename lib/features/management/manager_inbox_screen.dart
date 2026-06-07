import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../core/utils/app_logger.dart';
import '../../data/incident/domain/incident_repository.dart';
import '../../data/incident/incident_repository_provider.dart';
import '../../data/route_feedback/domain/route_feedback_repository.dart';
import '../../data/route_feedback/route_feedback_repository_provider.dart';
import '../../data/route_suggestion/domain/route_suggestion_repository.dart';
import '../../data/route_suggestion/route_suggestion_repository_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/incident_model.dart';
import '../../shared/models/route_feedback_model.dart';
import '../../shared/models/route_suggestion_model.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/transit_app_bar.dart';

class ManagerInboxScreen extends ConsumerStatefulWidget {
  const ManagerInboxScreen({super.key});

  @override
  ConsumerState<ManagerInboxScreen> createState() =>
      _ManagerInboxScreenState();
}

class _ManagerInboxScreenState extends ConsumerState<ManagerInboxScreen> {
  List<RouteFeedbackModel> _pendingFeedbacks = [];
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
        _pendingFeedbacks = allFeedbacks.where((f) {
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
    setState(() => _statusLoading = true);
    try {
      await ref
          .read(routeFeedbackRepositoryProvider)
          .updateStatus(fb.id, newStatus);
      await _loadData();
      _toast('Feedback → $newStatus');
    } on RouteFeedbackRepositoryException catch (e) {
      _toast('Error: $e');
    } finally {
      if (mounted) setState(() => _statusLoading = false);
    }
  }

  Future<void> _updateIncidentStatus(
      IncidentModel inc, String newStatus) async {
    setState(() => _statusLoading = true);
    try {
      await ref
          .read(incidentRepositoryProvider)
          .updateStatus(inc.id, newStatus);
      await _loadData();
      _toast('Incidencia → $newStatus');
    } on IncidentRepositoryException catch (e) {
      _toast('Error: $e');
    } finally {
      if (mounted) setState(() => _statusLoading = false);
    }
  }

  Future<void> _updateSuggestionStatus(
      RouteSuggestionModel sug, String newStatus) async {
    setState(() => _statusLoading = true);
    try {
      await ref
          .read(routeSuggestionRepositoryProvider)
          .updateStatus(sug.id, newStatus);
      await _loadData();
      _toast('Sugerencia → $newStatus');
    } on RouteSuggestionRepositoryException catch (e) {
      _toast('Error: $e');
    } finally {
      if (mounted) setState(() => _statusLoading = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final l10n = AppLocalizations.of(context);
    final pendingFb = _pendingFeedbacks.length;
    final pendingSug = _suggestions
        .where((s) =>
            s.status != SuggestionStatus.accepted &&
            s.status != SuggestionStatus.rejected)
        .length;
    final resolvedCount =
        _resolvedFeedbacks.length + _resolvedIncidents.length;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: TransitAppBar(
            title: l10n.managerInboxTitle, transparent: true),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _errorView(c)
                : Stack(
                    children: [
                      if (_statusLoading)
                        const Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: LinearProgressIndicator(),
                        ),
                      Column(
                        children: [
                          _statsHeader(c, pendingFb, pendingSug, resolvedCount),
                          Container(
                            margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                            decoration: BoxDecoration(
                              color: c.bgRaised,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: c.border, width: 0.5),
                            ),
                            child: TabBar(
                              isScrollable: false,
                              dividerColor: Colors.transparent,
                              indicator: BoxDecoration(
                                color: c.accent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              indicatorSize: TabBarIndicatorSize.tab,
                              indicatorPadding: const EdgeInsets.all(4),
                              labelPadding: EdgeInsets.zero,
                              padding: EdgeInsets.zero,
                              labelColor: c.accent,
                              unselectedLabelColor: c.textMid,
                              labelStyle: GoogleFonts.ibmPlexMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1),
                              tabs: [
                                _tabLabel('FEEDBACK', pendingFb,
                                    Icons.feedback_outlined,
                                    const Color(0xFFFF9800)),
                                _tabLabel('SUGER.', pendingSug,
                                    Icons.lightbulb_outline,
                                    const Color(0xFF2196F3)),
                                _tabLabel('RESUELTOS', resolvedCount,
                                    Icons.check_circle_outline,
                                    const Color(0xFF4CAF50)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                _FeedbackTab(
                                  items: _pendingFeedbacks,
                                  resolved: false,
                                  onAction: _updateFeedbackStatus,
                                  onRefresh: _loadData,
                                  c: c,
                                ),
                                _SuggestionsTab(
                                  items: _suggestions,
                                  onAction: _updateSuggestionStatus,
                                  onRefresh: _loadData,
                                  c: c,
                                  l10n: l10n,
                                ),
                                _ResolvedTab(
                                  feedbacks: _resolvedFeedbacks,
                                  incidents: _resolvedIncidents,
                                  onFeedbackAction: _updateFeedbackStatus,
                                  onIncidentAction: _updateIncidentStatus,
                                  onRefresh: _loadData,
                                  c: c,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _errorView(TransitColorScheme c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: c.stateCancelled),
            const SizedBox(height: 12),
            Text('No se pudo cargar la bandeja',
                style: TransitTypography.bodyPrimary(c.textHi)),
            const SizedBox(height: 4),
            Text(_error!,
                style: TransitTypography.bodySmall(c.textLo),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsHeader(
      TransitColorScheme c, int pendingFb, int pendingSug, int resolved) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
              child: _statPill(c, Icons.feedback_outlined, '$pendingFb',
                  'Feedback', const Color(0xFFFF9800))),
          const SizedBox(width: 8),
          Expanded(
              child: _statPill(c, Icons.lightbulb_outline, '$pendingSug',
                  'Sugerencias', const Color(0xFF2196F3))),
          const SizedBox(width: 8),
          Expanded(
              child: _statPill(c, Icons.check_circle_outline, '$resolved',
                  'Resueltos', const Color(0xFF4CAF50))),
        ],
      ),
    );
  }

  Widget _statPill(TransitColorScheme c, IconData icon, String value,
      String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(value,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.textHi,
                  )),
            ],
          ),
          const SizedBox(height: 2),
          Text(label,
              style: TransitTypography.bodySmall(c.textLo),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _tabLabel(String text, int count, IconData icon, Color color) {
    return Tab(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Flexible(
                child: Text(text,
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$count',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: color,
                    )),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// HELPERS COMPARTIDOS
// ─────────────────────────────────────────────────────────────────────
class _UuidRegex {
  static final regex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
}

Widget _searchBar(BuildContext context, TransitColorScheme c,
    TextEditingController ctrl, String value, ValueChanged<String> onChanged) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
    child: Container(
      decoration: BoxDecoration(
        color: c.bgRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(Icons.search, size: 18, color: c.textMid),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: ctrl,
              onChanged: onChanged,
              style: TransitTypography.bodyPrimary(c.textHi),
              decoration: InputDecoration(
                hintText: 'Buscar…',
                hintStyle: TransitTypography.bodySecondary(c.textMid),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (value.isNotEmpty)
            IconButton(
              icon: Icon(Icons.close, size: 16, color: c.textMid),
              onPressed: () {
                ctrl.clear();
                onChanged('');
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    ),
  );
}

/// Fila de chips de filtro: se centra si cabe, hace scroll horizontal
/// si no. Soluciona el "padding extra a la izquierda" y el desborde
/// cuando hay 4+ chips anchos.
Widget _filterRow(BuildContext context, List<Widget> chips) {
  return SizedBox(
    height: 36,
    child: LayoutBuilder(
      builder: (ctx, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
                minWidth: constraints.maxWidth - 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                for (var i = 0; i < chips.length; i++) ...[
                  chips[i],
                  if (i < chips.length - 1) const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        );
      },
    ),
  );
}

Widget _filterChip(TransitColorScheme c,
    {required IconData icon,
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap}) {
  return InkWell(
    borderRadius: BorderRadius.circular(20),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: 0.18) : c.bgRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: selected ? color : c.border,
            width: selected ? 1.2 : 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: selected ? color : c.textMid),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                fontSize: 12,
                color: selected ? color : c.textHi,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              )),
        ],
      ),
    ),
  );
}

Widget _cardHeader(TransitColorScheme c, IconData icon, String label,
    Color color, DateTime? createdAt) {
  return Row(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border:
              Border.all(color: color.withValues(alpha: 0.5), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label.toUpperCase(),
                style: GoogleFonts.ibmPlexMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 1)),
          ],
        ),
      ),
      const Spacer(),
      if (createdAt != null)
        Text(_formatDate(createdAt),
            style: TransitTypography.bodySmall(c.textLo)),
    ],
  );
}

Widget _miniBadge(TransitColorScheme c,
    {required IconData icon,
    required String label,
    required Color color}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 3),
        Flexible(
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              )),
        ),
      ],
    ),
  );
}

Widget _userLink(BuildContext context, TransitColorScheme c, String userId,
    {String prefix = 'Autor'}) {
  // Solo enlace si parece UUID válido (algunos mocks usan códigos).
  final isUuid = _UuidRegex.regex.hasMatch(userId);
  return InkWell(
    onTap: isUuid ? () => context.push('/admin/users/$userId') : null,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.person_outline,
              size: 12, color: isUuid ? c.accent : c.textMid),
          const SizedBox(width: 4),
          Text('$prefix: ${userId.substring(0, userId.length.clamp(0, 8))}…',
              style: GoogleFonts.ibmPlexMono(
                fontSize: 11,
                color: isUuid ? c.accent : c.textMid,
                fontWeight: FontWeight.w600,
              )),
          if (isUuid) ...[
            const SizedBox(width: 4),
            Icon(Icons.open_in_new, size: 11, color: c.accent),
          ],
        ],
      ),
    ),
  );
}

Widget _routeLink(BuildContext context, TransitColorScheme c, String routeId) {
  final isUuid = _UuidRegex.regex.hasMatch(routeId);
  return InkWell(
    onTap: () => context.push('/route/$routeId'),
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.route_outlined, size: 12, color: c.accent),
          const SizedBox(width: 4),
          Text(
              'Ruta: ${isUuid ? "${routeId.substring(0, 8)}…" : routeId}',
              style: GoogleFonts.ibmPlexMono(
                fontSize: 11,
                color: c.accent,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(width: 4),
          Icon(Icons.open_in_new, size: 11, color: c.accent),
        ],
      ),
    ),
  );
}

Widget _actionRow(TransitColorScheme c, List<_InboxAction> actions) {
  return Row(
    children: [
      for (var i = 0; i < actions.length; i++) ...[
        Expanded(
          child: actions[i].primary
              ? FilledButton.icon(
                  onPressed: actions[i].onPressed,
                  icon: Icon(actions[i].icon, size: 16),
                  label: Text(actions[i].label),
                  style: FilledButton.styleFrom(
                    backgroundColor: actions[i].color ?? c.accent,
                  ),
                )
              : OutlinedButton.icon(
                  onPressed: actions[i].onPressed,
                  icon: Icon(actions[i].icon, size: 16),
                  label: Text(actions[i].label),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: actions[i].color ?? c.textMid,
                    side: BorderSide(
                        color: (actions[i].color ?? c.border)
                            .withValues(alpha: 0.5)),
                  ),
                ),
        ),
        if (i < actions.length - 1) const SizedBox(width: 8),
      ],
    ],
  );
}

class _InboxAction {
  const _InboxAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
    this.color,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool primary;
  final Color? color;
}

String _formatDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

Widget _emptyState(TransitColorScheme c, IconData icon, String message,
    VoidCallback onRefresh) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: c.textLo),
          const SizedBox(height: 12),
          Text(message,
              style: TransitTypography.bodyPrimary(c.textMid),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Refrescar'),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────
// TAB 1 — FEEDBACK
// ─────────────────────────────────────────────────────────────────────
class _FeedbackTab extends StatefulWidget {
  const _FeedbackTab({
    required this.items,
    required this.resolved,
    required this.onAction,
    required this.onRefresh,
    required this.c,
  });
  final List<RouteFeedbackModel> items;
  final bool resolved;
  final void Function(RouteFeedbackModel, String) onAction;
  final Future<void> Function() onRefresh;
  final TransitColorScheme c;

  @override
  State<_FeedbackTab> createState() => _FeedbackTabState();
}

class _FeedbackTabState extends State<_FeedbackTab> {
  String _search = '';
  String _status = 'all'; // all / submitted / inReview
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final filtered = widget.items.where((f) {
      if (_status == 'submitted' &&
          f.status != FeedbackStatus.submitted) return false;
      if (_status == 'inReview' &&
          f.status != FeedbackStatus.inReview) return false;
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return f.description.toLowerCase().contains(q) ||
          f.userId.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        _searchBar(context, c, _ctrl, _search,
            (v) => setState(() => _search = v)),
        _filterRow(context, [
          _filterChip(c,
              icon: Icons.list,
              label: 'Todos',
              selected: _status == 'all',
              color: c.accent,
              onTap: () => setState(() => _status = 'all')),
          _filterChip(c,
              icon: Icons.inbox_outlined,
              label: 'Nuevos',
              selected: _status == 'submitted',
              color: const Color(0xFFFF9800),
              onTap: () => setState(() => _status = 'submitted')),
          _filterChip(c,
              icon: Icons.visibility_outlined,
              label: 'En revisión',
              selected: _status == 'inReview',
              color: const Color(0xFF2196F3),
              onTap: () => setState(() => _status = 'inReview')),
        ]),
        const SizedBox(height: 4),
        Expanded(
          child: filtered.isEmpty
              ? _emptyState(c, Icons.feedback_outlined,
                  'Sin feedback pendiente', widget.onRefresh)
              : RefreshIndicator(
                  onRefresh: widget.onRefresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _feedbackCard(context, c, filtered[i],
                          isResolved: widget.resolved),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _feedbackCard(
      BuildContext context, TransitColorScheme c, RouteFeedbackModel fb,
      {required bool isResolved}) {
    final isInReview = fb.status == FeedbackStatus.inReview;
    final (label, color) = switch (fb.status) {
      FeedbackStatus.inReview => ('En revisión', const Color(0xFF2196F3)),
      FeedbackStatus.applied => ('Aplicado', const Color(0xFF4CAF50)),
      FeedbackStatus.accepted => ('Aceptado', const Color(0xFF4CAF50)),
      FeedbackStatus.rejected => ('Rechazado', const Color(0xFFB71C1C)),
      FeedbackStatus.duplicate => ('Duplicado', Color(0xFF888888)),
      _ => ('Nuevo', const Color(0xFFFF9800)),
    };

    return GlassCard(
      blur: 12,
      fillOpacity: 0.05,
      borderRadius: 12,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(c, Icons.feedback_outlined, label, color, fb.createdAt),
          const SizedBox(height: 10),
          Text(fb.description,
              style: TransitTypography.bodyPrimary(c.textHi),
              maxLines: 5,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _miniBadge(c,
                  icon: Icons.category_outlined,
                  label: fb.feedbackType.name,
                  color: c.textMid),
            ],
          ),
          if (fb.userId.isNotEmpty) ...[
            const SizedBox(height: 4),
            _userLink(context, c, fb.userId),
          ],
          if (fb.routeId.isNotEmpty) ...[
            _routeLink(context, c, fb.routeId),
          ],
          if (!isResolved) ...[
            const SizedBox(height: 12),
            _actionRow(c, [
              _InboxAction(
                label: 'Rechazar',
                icon: Icons.close,
                color: c.stateCancelled,
                onPressed: () => widget.onAction(fb, 'rejected'),
              ),
              if (!isInReview)
                _InboxAction(
                  label: 'Revisar',
                  icon: Icons.visibility,
                  color: const Color(0xFF2196F3),
                  onPressed: () => widget.onAction(fb, 'in_review'),
                ),
              _InboxAction(
                label: 'Aplicar',
                icon: Icons.check,
                primary: true,
                color: const Color(0xFF4CAF50),
                onPressed: () => widget.onAction(fb, 'applied'),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// TAB 2 — SUGERENCIAS
// ─────────────────────────────────────────────────────────────────────
class _SuggestionsTab extends StatefulWidget {
  const _SuggestionsTab({
    required this.items,
    required this.onAction,
    required this.onRefresh,
    required this.c,
    required this.l10n,
  });
  final List<RouteSuggestionModel> items;
  final void Function(RouteSuggestionModel, String) onAction;
  final Future<void> Function() onRefresh;
  final TransitColorScheme c;
  final AppLocalizations l10n;

  @override
  State<_SuggestionsTab> createState() => _SuggestionsTabState();
}

class _SuggestionsTabState extends State<_SuggestionsTab> {
  String _search = '';
  String _status = 'pending';
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final filtered = widget.items.where((s) {
      switch (_status) {
        case 'pending':
          if (s.status == SuggestionStatus.accepted ||
              s.status == SuggestionStatus.rejected) return false;
        case 'accepted':
          if (s.status != SuggestionStatus.accepted) return false;
        case 'rejected':
          if (s.status != SuggestionStatus.rejected) return false;
      }
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      final title = '${s.originText} - ${s.destinationText}'.toLowerCase();
      return title.contains(q) ||
          (s.notes ?? '').toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        _searchBar(context, c, _ctrl, _search,
            (v) => setState(() => _search = v)),
        _filterRow(context, [
          _filterChip(c,
              icon: Icons.pending_outlined,
              label: 'Pendientes',
              selected: _status == 'pending',
              color: const Color(0xFFFF9800),
              onTap: () => setState(() => _status = 'pending')),
          _filterChip(c,
              icon: Icons.check_circle_outline,
              label: 'Aceptadas',
              selected: _status == 'accepted',
              color: const Color(0xFF4CAF50),
              onTap: () => setState(() => _status = 'accepted')),
          _filterChip(c,
              icon: Icons.close,
              label: 'Rechazadas',
              selected: _status == 'rejected',
              color: const Color(0xFFB71C1C),
              onTap: () => setState(() => _status = 'rejected')),
          _filterChip(c,
              icon: Icons.list,
              label: 'Todas',
              selected: _status == 'all',
              color: c.accent,
              onTap: () => setState(() => _status = 'all')),
        ]),
        const SizedBox(height: 4),
        Expanded(
          child: filtered.isEmpty
              ? _emptyState(c, Icons.lightbulb_outline,
                  'Sin sugerencias', widget.onRefresh)
              : RefreshIndicator(
                  onRefresh: widget.onRefresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child:
                          _suggestionCard(context, c, filtered[i]),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _suggestionCard(BuildContext context, TransitColorScheme c,
      RouteSuggestionModel sug) {
    final (label, color) = switch (sug.status) {
      SuggestionStatus.accepted => ('Aceptada', const Color(0xFF4CAF50)),
      SuggestionStatus.rejected => ('Rechazada', const Color(0xFFB71C1C)),
      SuggestionStatus.inReview => ('En revisión', const Color(0xFF2196F3)),
      SuggestionStatus.enriched => ('Enriquecida', const Color(0xFF9C27B0)),
      SuggestionStatus.converted => ('Convertida', const Color(0xFF4CAF50)),
      SuggestionStatus.duplicate => ('Duplicada', Color(0xFF888888)),
      _ => ('Nueva', const Color(0xFF2196F3)),
    };
    final isPending = sug.status != SuggestionStatus.accepted &&
        sug.status != SuggestionStatus.rejected;

    return GlassCard(
      blur: 12,
      fillOpacity: 0.05,
      borderRadius: 12,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
              c, Icons.lightbulb_outline, label, color, sug.createdAt),
          const SizedBox(height: 10),
          Text('${sug.originText} → ${sug.destinationText}',
              style: TransitTypography.bodyPrimary(c.textHi),
              maxLines: 3,
              overflow: TextOverflow.ellipsis),
          if (sug.notes != null && sug.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(sug.notes!,
                style: TransitTypography.bodySecondary(c.textMid),
                maxLines: 4,
                overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _miniBadge(c,
                  icon: Icons.thumb_up_outlined,
                  label: '${sug.voteCount} votos',
                  color: c.accent),
              if (sug.routeCode != null)
                _miniBadge(c,
                    icon: Icons.tag,
                    label: sug.routeCode!,
                    color: c.textMid),
            ],
          ),
          const SizedBox(height: 4),
          _userLink(context, c, sug.suggestedBy),
          const SizedBox(height: 8),
          if (isPending)
            _actionRow(c, [
              _InboxAction(
                label: 'Rechazar',
                icon: Icons.close,
                color: c.stateCancelled,
                onPressed: () => widget.onAction(sug, 'rejected'),
              ),
              _InboxAction(
                label: 'Aceptar',
                icon: Icons.check,
                primary: true,
                color: const Color(0xFF4CAF50),
                onPressed: () => widget.onAction(sug, 'accepted'),
              ),
            ])
          else
            OutlinedButton.icon(
              onPressed: () => context.push('/suggestions/${sug.id}'),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Abrir detalle'),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// TAB 3 — RESUELTOS (feedback + incidencias mezclados)
// ─────────────────────────────────────────────────────────────────────
class _ResolvedTab extends StatefulWidget {
  const _ResolvedTab({
    required this.feedbacks,
    required this.incidents,
    required this.onFeedbackAction,
    required this.onIncidentAction,
    required this.onRefresh,
    required this.c,
  });
  final List<RouteFeedbackModel> feedbacks;
  final List<IncidentModel> incidents;
  final void Function(RouteFeedbackModel, String) onFeedbackAction;
  final void Function(IncidentModel, String) onIncidentAction;
  final Future<void> Function() onRefresh;
  final TransitColorScheme c;

  @override
  State<_ResolvedTab> createState() => _ResolvedTabState();
}

class _ResolvedTabState extends State<_ResolvedTab> {
  String _search = '';
  String _kind = 'all'; // all / feedback / incident
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final items = <_ResolvedEntry>[];
    if (_kind != 'incident') {
      for (final f in widget.feedbacks) {
        if (_search.isEmpty ||
            f.description.toLowerCase().contains(_search.toLowerCase())) {
          items.add(_ResolvedEntry.feedback(f));
        }
      }
    }
    if (_kind != 'feedback') {
      for (final i in widget.incidents) {
        if (_search.isEmpty ||
            (i.comment ?? '').toLowerCase().contains(_search.toLowerCase())) {
          items.add(_ResolvedEntry.incident(i));
        }
      }
    }
    items.sort((a, b) => b.date.compareTo(a.date));

    return Column(
      children: [
        _searchBar(context, c, _ctrl, _search,
            (v) => setState(() => _search = v)),
        _filterRow(context, [
          _filterChip(c,
              icon: Icons.list,
              label: 'Todos',
              selected: _kind == 'all',
              color: c.accent,
              onTap: () => setState(() => _kind = 'all')),
          _filterChip(c,
              icon: Icons.feedback_outlined,
              label: 'Feedback',
              selected: _kind == 'feedback',
              color: const Color(0xFF2196F3),
              onTap: () => setState(() => _kind = 'feedback')),
          _filterChip(c,
              icon: Icons.warning_amber,
              label: 'Incidencias',
              selected: _kind == 'incident',
              color: const Color(0xFFFF9800),
              onTap: () => setState(() => _kind = 'incident')),
        ]),
        const SizedBox(height: 4),
        Expanded(
          child: items.isEmpty
              ? _emptyState(c, Icons.check_circle_outline,
                  'Sin elementos resueltos', widget.onRefresh)
              : RefreshIndicator(
                  onRefresh: widget.onRefresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: items.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: items[i].build(context, c, this),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _ResolvedEntry {
  _ResolvedEntry.feedback(RouteFeedbackModel this.feedback)
      : incident = null,
        date = feedback.createdAt;
  _ResolvedEntry.incident(IncidentModel this.incident)
      : feedback = null,
        date = incident.createdAt;

  final RouteFeedbackModel? feedback;
  final IncidentModel? incident;
  final DateTime date;

  Widget build(
      BuildContext context, TransitColorScheme c, _ResolvedTabState parent) {
    if (feedback != null) {
      final fb = feedback!;
      final (label, color) = switch (fb.status) {
        FeedbackStatus.applied => ('Aplicado', const Color(0xFF4CAF50)),
        FeedbackStatus.accepted => ('Aceptado', const Color(0xFF4CAF50)),
        FeedbackStatus.rejected => ('Rechazado', const Color(0xFFB71C1C)),
        FeedbackStatus.duplicate => ('Duplicado', Color(0xFF888888)),
        _ => (fb.status.name, c.textMid),
      };
      return GlassCard(
        blur: 12,
        fillOpacity: 0.05,
        borderRadius: 12,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(
                c, Icons.feedback_outlined, label, color, fb.createdAt),
            const SizedBox(height: 8),
            Text(fb.description,
                style: TransitTypography.bodyPrimary(c.textHi),
                maxLines: 4,
                overflow: TextOverflow.ellipsis),
            if (fb.userId.isNotEmpty) ...[
              const SizedBox(height: 4),
              _userLink(context, c, fb.userId),
            ],
            if (fb.routeId.isNotEmpty) _routeLink(context, c, fb.routeId),
          ],
        ),
      );
    }
    final inc = incident!;
    final (label, color) = switch (inc.status) {
      'resolved' => ('Resuelta', const Color(0xFF4CAF50)),
      'rejected' => ('Rechazada', const Color(0xFFB71C1C)),
      _ => (inc.status, c.textMid),
    };
    return GlassCard(
      blur: 12,
      fillOpacity: 0.05,
      borderRadius: 12,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(c, Icons.warning_amber, label, color, inc.createdAt),
          const SizedBox(height: 8),
          Text(inc.comment ?? '(sin descripción)',
              style: TransitTypography.bodyPrimary(c.textHi),
              maxLines: 4,
              overflow: TextOverflow.ellipsis),
          if (inc.reporterId.isNotEmpty) ...[
            const SizedBox(height: 4),
            _userLink(context, c, inc.reporterId, prefix: 'Reportada por'),
          ],
          if (inc.routeId.isNotEmpty) _routeLink(context, c, inc.routeId),
        ],
      ),
    );
  }
}
