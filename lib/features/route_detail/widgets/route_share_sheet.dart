import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/transit_colors.dart';
import '../../../../core/theme/transit_typography.dart';
import '../../../../data/supabase/supabase_client_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/transit_button.dart';

/// Bottom sheet para compartir una ruta comunitaria con otro usuario
/// o mediante enlace público.
void showRouteShareSheet(
  BuildContext context,
  WidgetRef ref, {
  required String routeId,
  required String routeName,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final c = TransitColorScheme.of(isDark);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(ctx).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: c.bgRoot,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: _ShareSheetContent(
        c: c,
        ref: ref,
        routeId: routeId,
        routeName: routeName,
      ),
    ),
  );
}

class _ShareSheetContent extends ConsumerStatefulWidget {
  const _ShareSheetContent({
    required this.c,
    required this.ref,
    required this.routeId,
    required this.routeName,
  });

  final TransitColorScheme c;
  final WidgetRef ref;
  final String routeId;
  final String routeName;

  @override
  ConsumerState<_ShareSheetContent> createState() => _ShareSheetContentState();
}

class _ShareSheetContentState extends ConsumerState<_ShareSheetContent> {
  final _emailController = TextEditingController();
  String? _feedback;
  String? _generatedLink;

  Future<void> _shareWithUser(String email, String permission) async {
    setState(() => _feedback = null);

    try {
      final client = ref.read(supabaseClientProvider);
      final session = client.auth.currentSession;
      if (session == null) {
        setState(() => _feedback = 'Inicia sesión para compartir rutas');
        return;
      }

      final response = await client
          .from('profiles')
          .select('id')
          .eq('email', email.trim())
          .limit(1);

      if ((response as List).isEmpty) {
        setState(() => _feedback = AppLocalizations.of(context).routeShareUserNotFound);
        return;
      }

      final sharedWithId = ((response as List).first as Map<String, dynamic>)['id'] as String;

      await client.from('route_shares').upsert({
        'route_id': widget.routeId,
        'shared_with_id': sharedWithId,
        'shared_by_id': session.user.id,
        'permission': permission,
      });

      setState(() => _feedback = AppLocalizations.of(context).routeShareSuccess(email));
    } catch (e) {
      setState(() => _feedback = AppLocalizations.of(context).routeShareError);
    }
  }

  Future<void> _generateLink() async {
    setState(() => _feedback = null);

    try {
      final client = ref.read(supabaseClientProvider);
      final session = client.auth.currentSession;
      if (session == null) return;

      final slug =
          '${widget.routeId.substring(0, 8)}-${DateTime.now().millisecondsSinceEpoch % 100000}';

      await client.from('route_public_links').insert({
        'slug': slug,
        'route_id': widget.routeId,
        'created_by': session.user.id,
      });

      setState(() {
        _generatedLink = slug;
        _feedback = 'Enlace generado';
      });
    } catch (e) {
      setState(() => _feedback = AppLocalizations.of(context).routeShareErrorGeneratingLink);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: c.textLo.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Compartir ruta',
              style: TransitTypography.heading(c.textHi)),
          const SizedBox(height: 4),
          Text(widget.routeName,
              style: TransitTypography.bodySecondary(c.textMid)),
          const SizedBox(height: 16),

          // Compartir con usuario
          Text('Compartir con usuario',
              style: TransitTypography.sectionTitle(c.textMid)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _emailController,
                  style: TextStyle(color: c.textHi, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'email@ejemplo.com',
                    hintStyle: TextStyle(color: c.textLo),
                    filled: true,
                    fillColor: c.bgSurface,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: c.border),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TransitButton(
                label: 'COMPARTIR',
                isSmall: true,
                onPressed: () => _shareWithUser(
                    _emailController.text.trim(), 'view'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Enlace público
          Text('Enlace público',
              style: TransitTypography.sectionTitle(c.textMid)),
          const SizedBox(height: 8),
          if (_feedback != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_feedback!,
                  style: TextStyle(color: c.accent, fontSize: 13)),
            ),
          if (_generatedLink != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: c.bgSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_generatedLink!,
                  style: TextStyle(
                      color: c.accent,
                      fontFamily: 'monospace',
                      fontSize: 13)),
            ),
          ],
          TransitButton(
            label: _generatedLink != null ? 'REGENERAR ENLACE' : 'GENERAR ENLACE',
            isPrimary: false,
            isSmall: true,
            onPressed: () => _generateLink(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
