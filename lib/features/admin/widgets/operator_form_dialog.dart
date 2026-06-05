import 'package:flutter/material.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../core/utils/uuid.dart';
import '../../../data/operator/operator_helpers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/operator_model.dart';
import '../../../shared/widgets/transit_button.dart';
import '../../../shared/widgets/transit_input.dart';

class OperatorFormDialog extends StatefulWidget {
  const OperatorFormDialog({super.key, this.operator});

  final OperatorModel? operator;

  @override
  State<OperatorFormDialog> createState() => _OperatorFormDialogState();
}

class _OperatorFormDialogState extends State<OperatorFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _slugCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _regionCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _colorCtrl;
  late bool _isActive;
  bool _saving = false;

  bool get _isEdit => widget.operator != null;

  @override
  void initState() {
    super.initState();
    final op = widget.operator;
    _slugCtrl = TextEditingController(text: op?.slug ?? '');
    _nameCtrl = TextEditingController(text: op?.name ?? '');
    _regionCtrl = TextEditingController(text: op?.region ?? '');
    _websiteCtrl = TextEditingController(text: op?.website ?? '');
    _emailCtrl = TextEditingController(text: op?.contactEmail ?? '');
    _colorCtrl = TextEditingController(text: op?.color ?? '');
    _isActive = op?.isActive ?? true;
  }

  @override
  void dispose() {
    _slugCtrl.dispose();
    _nameCtrl.dispose();
    _regionCtrl.dispose();
    _websiteCtrl.dispose();
    _emailCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  OperatorModel _buildOperator() {
    final op = widget.operator;
    final slug = _slugCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    return OperatorModel(
      id: op?.id ?? generateUuidV4(),
      name: name,
      shortName: operatorShortNameFromSlug(slug, name),
      slug: slug,
      region: _regionCtrl.text.trim(),
      website: _websiteCtrl.text.trim(),
      contactEmail: _emailCtrl.text.trim(),
      color: _colorCtrl.text.trim().replaceFirst('#', '').toUpperCase(),
      isActive: _isActive,
    );
  }

  Color? get _colorPreview {
    final hex = _colorCtrl.text.trim().replaceFirst('#', '');
    if (hex.length != 6) return null;
    final v = int.tryParse(hex, radix: 16);
    return v == null ? null : Color(0xFF000000 | v);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return AlertDialog(
      title: Text(
        _isEdit ? l10n.adminOperatorsEdit : l10n.adminOperatorsCreate,
        style: TransitTypography.subheading(c.textHi),
      ),
      content: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TransitInput(
                hint: l10n.adminOperatorsSlug,
                controller: _slugCtrl,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (v.contains(' ')) return 'No spaces';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TransitInput(
                hint: l10n.adminOperatorsName,
                controller: _nameCtrl,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (v.trim().length < 2) return 'Min 2 chars';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TransitInput(
                hint: l10n.adminOperatorsRegion,
                controller: _regionCtrl,
              ),
              const SizedBox(height: 12),
              TransitInput(
                hint: l10n.adminOperatorsWebsite,
                controller: _websiteCtrl,
              ),
              const SizedBox(height: 12),
              TransitInput(
                hint: l10n.adminOperatorsEmail,
                controller: _emailCtrl,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
                    return 'Invalid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TransitInput(
                      hint: 'Color (hex, ej. FF6F00)',
                      controller: _colorCtrl,
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        final t = v?.trim().replaceFirst('#', '') ?? '';
                        if (t.isEmpty) return null;
                        if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(t)) {
                          return '6 chars hex';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _colorPreview ?? c.bgRaised,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: c.border, width: 1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Activo',
                    style: TransitTypography.bodyPrimary(c.textHi)),
                subtitle: Text(
                  _isActive
                      ? 'Visible en mapa y listados'
                      : 'Oculto pero preservado',
                  style: TransitTypography.bodySmall(c.textLo),
                ),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                activeThumbColor: c.accent,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(
            MaterialLocalizations.of(context).cancelButtonLabel,
            style: TransitTypography.bodyPrimary(c.textMid),
          ),
        ),
        TransitButton(
          label: l10n.actionSave,
          isLoading: _saving,
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            setState(() => _saving = true);
            try {
              Navigator.of(context).pop(_buildOperator());
            } finally {
              if (mounted) setState(() => _saving = false);
            }
          },
        ),
      ],
    );
  }
}
