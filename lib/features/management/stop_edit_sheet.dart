import 'package:flutter/material.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/admin/admin_routes_repository.dart';

/// Hoja sólida para crear/editar los datos de una parada.
/// Devuelve un [AdminStopRow] con los cambios o null si se cancela.
/// Conserva id, operatorId, lat y lng del [initial].
Future<AdminStopRow?> showStopEditSheet({
  required BuildContext context,
  required AdminStopRow initial,
}) {
  return showModalBottomSheet<AdminStopRow>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _StopEditSheet(initial: initial),
  );
}

class _StopEditSheet extends StatefulWidget {
  const _StopEditSheet({required this.initial});
  final AdminStopRow initial;

  @override
  State<_StopEditSheet> createState() => _StopEditSheetState();
}

class _StopEditSheetState extends State<_StopEditSheet> {
  late final TextEditingController _code;
  late final TextEditingController _name;
  late bool _accessible;
  late bool _shelter;
  late bool _bench;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.initial.code);
    _name = TextEditingController(text: widget.initial.name);
    _accessible = widget.initial.accessible;
    _shelter = widget.initial.hasShelter;
    _bench = widget.initial.hasBench;
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El nombre es obligatorio')));
      return;
    }
    Navigator.pop(
      context,
      AdminStopRow(
        id: widget.initial.id,
        operatorId: widget.initial.operatorId,
        code: _code.text.trim(),
        name: _name.text.trim(),
        lat: widget.initial.lat,
        lng: widget.initial.lng,
        accessible: _accessible,
        hasShelter: _shelter,
        hasBench: _bench,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final isNew = widget.initial.id.isEmpty;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: c.bgElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: c.border, width: 0.5),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isNew ? 'Nueva parada' : 'Editar parada',
                    style: TransitTypography.heading(c.textHi)),
                const SizedBox(height: 4),
                Text(
                    'Lat ${widget.initial.lat.toStringAsFixed(5)}, '
                    'Lng ${widget.initial.lng.toStringAsFixed(5)}',
                    style: TransitTypography.bodySmall(c.textMid)),
                const SizedBox(height: 16),
                _field(c, 'Código', _code, hint: 'p.ej. 1042'),
                const SizedBox(height: 10),
                _field(c, 'Nombre', _name, hint: 'p.ej. Plaza del Arenal'),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: c.accent,
                  title: const Text('Accesible silla de ruedas'),
                  value: _accessible,
                  onChanged: (v) => setState(() => _accessible = v),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: c.accent,
                  title: const Text('Marquesina'),
                  value: _shelter,
                  onChanged: (v) => setState(() => _shelter = v),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: c.accent,
                  title: const Text('Banco'),
                  value: _bench,
                  onChanged: (v) => setState(() => _bench = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: c.accent),
                        onPressed: _save,
                        child: const Text('Guardar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TransitColorScheme c, String label, TextEditingController ctrl,
      {String? hint}) {
    return Container(
      decoration: BoxDecoration(
        color: c.bgRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: ctrl,
        style: TransitTypography.bodyPrimary(c.textHi),
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          labelStyle: TransitTypography.bodySmall(c.textMid),
          hintText: hint,
          hintStyle: TransitTypography.bodySmall(c.textLo),
        ),
      ),
    );
  }
}
