import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/route_suggestion/route_suggestion_repository_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/models/route_suggestion_model.dart';
import '../../shared/widgets/smoke_background.dart';
import '../../shared/widgets/transit_button.dart';

class SuggestionDetailScreen extends ConsumerStatefulWidget {
  const SuggestionDetailScreen({super.key, required this.suggestionId});

  final String suggestionId;

  @override
  ConsumerState<SuggestionDetailScreen> createState() =>
      _SuggestionDetailScreenState();
}

class _SuggestionDetailScreenState
    extends ConsumerState<SuggestionDetailScreen> {
  late Future<RouteSuggestionModel?> _loader;

  @override
  void initState() {
    super.initState();
    _loader = ref
        .read(routeSuggestionRepositoryProvider)
        .byId(widget.suggestionId);
  }

  void _reload() {
    setState(() {
      _loader = ref
          .read(routeSuggestionRepositoryProvider)
          .byId(widget.suggestionId);
    });
  }

  Future<void> _vote() async {
    final repo = ref.read(routeSuggestionRepositoryProvider);
    await repo.castVote(widget.suggestionId);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Scaffold(
      backgroundColor: c.bgRoot,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textMid),
          tooltip: 'Volver',
          onPressed: () => context.pop(),
        ),
        title: Text('DETALLE SUGERENCIA',
            style: TransitTypography.sectionTitle(c.textHi)),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          Positioned.fill(
              child: SmokeBackground(color: c.accent, isDark: isDark)),
          FutureBuilder<RouteSuggestionModel?>(
            future: _loader,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final suggestion = snap.data;
              if (suggestion == null || snap.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('No se encontró la sugerencia',
                          style: TransitTypography.bodyPrimary(c.textMid)),
                      const SizedBox(height: 12),
                      TransitButton(
                        label: 'REINTENTAR',
                        onPressed: _reload,
                      ),
                    ],
                  ),
                );
              }
              return _buildContent(suggestion, c);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent(RouteSuggestionModel s, TransitColorScheme c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route, size: 24, color: c.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${s.originText} → ${s.destinationText}',
                  style: TransitTypography.sectionTitle(c.textHi),
                ),
              ),
            ],
          ),
          if (s.routeCode != null) ...[
            const SizedBox(height: 8),
            Text('Código: ${s.routeCode}',
                style: TransitTypography.bodySecondary(c.textMid)),
          ],
          if (s.operatorName != null) ...[
            const SizedBox(height: 4),
            Text(AppLocalizations.of(context).driverCurrentOperator(s.operatorName!),
                style: TransitTypography.bodySecondary(c.textMid)),
          ],
          const SizedBox(height: 16),

          _infoRow(c, 'Estado', s.status.label),
          const SizedBox(height: 4),
          _infoRow(c, 'Prioridad', s.priority.label),
          const SizedBox(height: 4),
          _infoRow(c, 'Votos', s.voteCount.toString()),
          const SizedBox(height: 4),
          if (s.contributionCount > 0)
            _infoRow(c, 'Contribuciones', s.contributionCount.toString()),
          const SizedBox(height: 4),
          _infoRow(c, 'Creada', _formatDate(s.createdAt)),
          const SizedBox(height: 16),

          if (s.notes != null && s.notes!.isNotEmpty) ...[
            Text('Descripción',
                style: TransitTypography.bodySecondary(c.textMid)),
            const SizedBox(height: 6),
            Text(s.notes!,
                style: TransitTypography.bodyPrimary(c.textHi)),
            const SizedBox(height: 16),
          ],

          if (s.source != null && s.source!.isNotEmpty) ...[
            Text('Fuente: ${s.source}',
                style: TransitTypography.bodySecondary(c.textMid)),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TransitButton(
              label: 'VOTAR (${s.voteCount + 1})',
              onPressed: _vote,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(TransitColorScheme c, String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label,
              style: TransitTypography.bodySecondary(c.textMid)),
        ),
        Expanded(
          child: Text(value,
              style: GoogleFonts.ibmPlexMono(
                  fontSize: 14, color: c.textHi)),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
