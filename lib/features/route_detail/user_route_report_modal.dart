import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/user_routes/user_routes_repository.dart';
import '../../shared/widgets/transit_button.dart';

// TODO(l10n):
class UserRouteReportModal extends ConsumerStatefulWidget {
  const UserRouteReportModal({super.key, required this.routeId});

  final String routeId;

  static void show(BuildContext context, String routeId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => UserRouteReportModal(routeId: routeId),
    );
  }

  @override
  ConsumerState<UserRouteReportModal> createState() =>
      _UserRouteReportModalState();
}

class _UserRouteReportModalState extends ConsumerState<UserRouteReportModal> {
  String? _selectedReason;
  final _descriptionController = TextEditingController();
  bool _submitting = false;

  final _reasons = const [
    ('spam', 'Spam'),
    ('inappropriate', 'Contenido inapropiado'),
    ('wrong_data', 'Datos incorrectos'),
    ('duplicated', 'Ruta duplicada'),
    ('other', 'Otro'),
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedReason == null) return;
    setState(() => _submitting = true);

    final repo = ref.read(userRoutesRepositoryProvider);
    if (repo == null) {
      if (mounted) setState(() => _submitting = false);
      return;
    }

    try {
      await repo.report(
        widget.routeId,
        _selectedReason!,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reporte enviado'),
          // TODO(l10n):
          duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al enviar reporte'),
          // TODO(l10n):
          duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
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
          const SizedBox(height: 20),
          Text(
            'Reportar ruta',
            // TODO: l10n
            style: TransitTypography.heading(c.textHi),
          ),
          const SizedBox(height: 4),
          Text(
            'Selecciona el motivo del reporte',
            // TODO: l10n
            style: TransitTypography.bodySecondary(c.textMid),
          ),
          const SizedBox(height: 16),

          // Reason radio buttons
          RadioGroup<String>(
            groupValue: _selectedReason ?? '',
            onChanged: (v) => setState(() => _selectedReason = v),
            child: Column(
              children: _reasons.map((r) {
                final (value, label) = r;
                return RadioListTile<String>(
                  value: value,
                  title: Text(
                    label,
                    style: TransitTypography.bodyPrimary(c.textHi),
                  ),
                  activeColor: c.stateCancelled,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Description
          TextField(
            controller: _descriptionController,
            style: TransitTypography.bodyPrimary(c.textHi),
            cursorColor: c.accent,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Descripción (opcional)',
              // TODO(l10n):
              hintStyle: TransitTypography.bodyPrimary(c.textLo),
              filled: true,
              fillColor: c.bgRaised,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: c.border, width: 0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: c.border, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: c.borderFocus, width: 1),
              ),
            ),
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: TransitButton(
              label: _submitting ? 'Enviando...' : 'Enviar reporte',
              // TODO(l10n):
              isPrimary: true,
              isLoading: _submitting,
              onPressed: _selectedReason == null ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }
}
