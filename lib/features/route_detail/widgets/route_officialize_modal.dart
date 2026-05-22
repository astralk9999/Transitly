import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/transit_colors.dart';
import '../../../../core/theme/transit_typography.dart';
import '../../../../data/supabase/supabase_client_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/transit_button.dart';

/// Modal para solicitar la oficialización de una ruta comunitaria.
/// Llama a la RPC `submit_official_request` creada en F2.5.
void showRouteOfficializeModal(
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
    builder: (ctx) => _OfficializeModal(
      c: c,
      ref: ref,
      routeId: routeId,
      routeName: routeName,
    ),
  );
}

class _OfficializeModal extends ConsumerStatefulWidget {
  const _OfficializeModal({
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
  ConsumerState<_OfficializeModal> createState() => _OfficializeModalState();
}

class _OfficializeModalState extends ConsumerState<_OfficializeModal> {
  final _justificationCtrl = TextEditingController();
  String? _error;
  String? _success;

  Future<void> _submit() async {
    final justification = _justificationCtrl.text.trim();
    if (justification.length < 100) {
      setState(() =>
          _error = 'La justificación debe tener al menos 100 caracteres');
      return;
    }

    setState(() => _error = null);

    try {
      final client = ref.read(supabaseClientProvider);
      await client.rpc('submit_official_request', params: {
        'p_route_id': widget.routeId,
        'p_justification': justification,
      });

      if (!mounted) return;
      setState(() => _success =
          'Solicitud enviada. Recibirás una notificación cuando se resuelva.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = AppLocalizations.of(context).routeOfficializeError);
    }
  }

  @override
  void dispose() {
    _justificationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: c.bgRoot,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
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
            Text('Solicitar oficialización',
                style: TransitTypography.heading(c.textHi)),
            const SizedBox(height: 4),
            Text(widget.routeName,
                style: TransitTypography.bodySecondary(c.textMid)),
            const SizedBox(height: 16),

            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.redAccent)),
              ),
              const SizedBox(height: 16),
            ],

            if (_success != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_success!,
                    style: TextStyle(color: c.accent)),
              ),
              const SizedBox(height: 16),
            ],

            Text('Justificación',
                style: TransitTypography.sectionTitle(c.textMid)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _justificationCtrl,
              maxLines: 4,
              maxLength: 500,
              style: TextStyle(color: c.textHi, fontSize: 14),
              decoration: InputDecoration(
                hintText:
                    'Explica por qué esta ruta debería ser oficial (mín. 100 caracteres)',
                hintStyle: TextStyle(color: c.textLo),
                filled: true,
                fillColor: c.bgSurface,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: c.border),
                ),
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.orangeAccent, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Solo el equipo de moderación puede aprobar la conversión a oficial. Recibirás una notificación cuando se resuelva.',
                      style: TextStyle(
                          color: Colors.orangeAccent, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_success == null)
              TransitButton(
                label: AppLocalizations.of(context).actionSendRequest.toUpperCase(),
                onPressed: _submit,
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
