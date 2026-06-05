import 'package:flutter/material.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_spacing.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/transit_button.dart';
import '../../../shared/widgets/transit_input.dart';

class StepBasicInfo extends StatefulWidget {
  const StepBasicInfo({
    super.key,
    required this.nameCtrl,
    required this.descCtrl,
    required this.routeColor,
    required this.serviceType,
    required this.onColorChanged,
    required this.onServiceTypeChanged,
  });

  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final String routeColor;
  final String serviceType;
  final ValueChanged<String> onColorChanged;
  final ValueChanged<String> onServiceTypeChanged;

  @override
  State<StepBasicInfo> createState() => _StepBasicInfoState();
}

class _StepBasicInfoState extends State<StepBasicInfo> {
  static const _presetColors = [
    '0xFF977DDF',
    '0xFF4CAF50',
    '0xFF2196F3',
    '0xFFFF9800',
    '0xFFF44336',
    '0xFF00BCD4',
    '0xFF8BC34A',
    '0xFFFF5722',
  ];

  static const _serviceTypes = [
    'urban',
    'interurban',
    'long_distance',
    'school',
    'on_demand',
    'custom',
  ];

  static const _serviceTypeIcons = {
    'urban': Icons.bus_alert,
    'interurban': Icons.route,
    'long_distance': Icons.flight,
    'school': Icons.school,
    'on_demand': Icons.smart_button,
    'custom': Icons.tune,
  };

  static const _serviceTypeLabels = {
    'urban': 'Urbano',
    'interurban': 'Interurbano',
    'long_distance': 'Larga distancia',
    'school': 'Escolar',
    'on_demand': 'A demanda',
    'custom': 'Personalizado',
  };

  final _hexCtrl = TextEditingController();

  @override
  void dispose() {
    _hexCtrl.dispose();
    super.dispose();
  }

  String _colorToHex(Color c) =>
      '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  Color _parseHexColor(String text) {
    final clean = text.replaceFirst('#', '');
    if (clean.length == 6) {
      return Color(int.parse('FF$clean', radix: 16));
    }
    return Colors.grey;
  }

  void _showCustomColorPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = TransitColorScheme.of(isDark);
    _hexCtrl.text = widget.routeColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.bgRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20,
                20 + MediaQuery.of(ctx).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Color personalizado',
                    style: TransitTypography.heading(colors.textHi)),
                const SizedBox(height: 16),
                TextField(
                  controller: _hexCtrl,
                  style: TransitTypography.bodyPrimary(colors.textHi),
                  decoration: InputDecoration(
                    hintText: '#RRGGBB',
                    hintStyle: TransitTypography.bodySecondary(colors.textMid),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: colors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: colors.accent),
                    ),
                    prefixIcon: Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _parseHexColor(_hexCtrl.text),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colors.border),
                      ),
                    ),
                  ),
                  onChanged: (_) => setSheetState(() {}),
                ),
                const SizedBox(height: 8),
                Text('Ej. #FF5722, #4CAF50, #2196F3',
                    style: TransitTypography.bodySmall(colors.textMid)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TransitButton(
                    label: 'Aplicar',
                    onPressed: () {
                      final text = _hexCtrl.text.trim();
                      if (RegExp(r'^#?[0-9a-fA-F]{6}$').hasMatch(text)) {
                        final hex =
                            text.startsWith('#') ? text : '#$text';
                        widget.onColorChanged(hex.toUpperCase());
                        Navigator.pop(ctx);
                      } else {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Formato inválido. Usa #RRGGBB')),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = TransitColorScheme.of(isDark);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(TransitSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información básica',
            style: TransitTypography.heading(colors.textHi),
          ),
          const SizedBox(height: TransitSpacing.space4),
          Text(
            'Define el nombre, descripción y aspecto visual de tu ruta.',
            style: TransitTypography.bodySecondary(colors.textMid),
          ),
          const SizedBox(height: TransitSpacing.space24),

          Text(
            'Nombre',
            style: TransitTypography.bodyPrimary(colors.textHi),
          ),
          const SizedBox(height: TransitSpacing.space8),
          TransitInput(
            hint: 'Ej. Ruta Centro - Estación',
            controller: widget.nameCtrl,
            maxLines: 1,
          ),
          const SizedBox(height: TransitSpacing.space4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${widget.nameCtrl.text.length}/80',
              style: TransitTypography.bodySmall(
                widget.nameCtrl.text.length < 3 ||
                        widget.nameCtrl.text.length > 80
                    ? colors.stateCancelled
                    : colors.textLo,
              ),
            ),
          ),
          const SizedBox(height: TransitSpacing.space20),

          Text(
            'Descripción',
            style: TransitTypography.bodyPrimary(colors.textHi),
          ),
          const SizedBox(height: TransitSpacing.space8),
          TransitInput(
            hint: 'Describe el recorrido, puntos de interés... (opcional)',
            controller: widget.descCtrl,
            maxLines: 4,
          ),
          const SizedBox(height: TransitSpacing.space4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${widget.descCtrl.text.length}/500',
              style: TransitTypography.bodySmall(
                widget.descCtrl.text.length > 500
                    ? colors.stateCancelled
                    : colors.textLo,
              ),
            ),
          ),
          const SizedBox(height: TransitSpacing.space24),

          Text(
            'Color de ruta',
            style: TransitTypography.bodyPrimary(colors.textHi),
          ),
          const SizedBox(height: TransitSpacing.space12),
          Wrap(
            spacing: TransitSpacing.space8,
            runSpacing: TransitSpacing.space8,
            children: [
              _ColorOption(
                color: colors.accent,
                label: 'Acento',
                isSelected: _colorToHex(colors.accent) == widget.routeColor,
                onTap: () =>
                    widget.onColorChanged(_colorToHex(colors.accent)),
              ),
              for (final hex in _presetColors)
                _ColorOption(
                  color: Color(int.parse(hex)),
                  isSelected: '#${hex.substring(4)}' ==
                      widget.routeColor.toUpperCase(),
                  onTap: () =>
                      widget.onColorChanged('#${hex.substring(4)}'),
                ),
              _ColorOption(
                color: colors.bgRaised,
                label: '+',
                isSelected: false,
                onTap: _showCustomColorPicker,
              ),
            ],
          ),
          const SizedBox(height: TransitSpacing.space24),

          Text(
            'Tipo de servicio',
            style: TransitTypography.bodyPrimary(colors.textHi),
          ),
          const SizedBox(height: TransitSpacing.space12),
          // P2-02: ChoiceChips horizontales scrollables con icono + label.
          // Más visible y usable que el DropdownButton anterior.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _serviceTypes.map((t) {
                final selected = widget.serviceType == t;
                return Padding(
                  padding: const EdgeInsets.only(right: TransitSpacing.space8),
                  child: ChoiceChip(
                    selected: selected,
                    onSelected: (_) => widget.onServiceTypeChanged(t),
                    avatar: Icon(
                      _serviceTypeIcons[t],
                      size: 18,
                      color: selected ? Colors.white : colors.accent,
                    ),
                    label: Text(_serviceTypeLabels[t] ?? t),
                    labelStyle: TransitTypography.bodyPrimary(
                      selected ? Colors.white : colors.textHi,
                    ),
                    selectedColor: colors.accent,
                    backgroundColor: colors.bgRaised,
                    side: BorderSide(
                      color: selected ? colors.accent : colors.border,
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorOption extends StatelessWidget {
  const _ColorOption({
    required this.color,
    this.label,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final String? label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Tooltip(
        message: label ?? '',
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: isSelected
                ? Border.all(color: Colors.white, width: 3)
                : Border.all(
                    color: color.withValues(alpha: 0.3),
                    width: 1,
                  ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: isSelected
              ? const Icon(Icons.check, color: Colors.white, size: 18)
              : label != null
                  ? const Icon(Icons.colorize, color: Colors.white, size: 18)
                  : null,
        ),
      ),
    );
  }
}
