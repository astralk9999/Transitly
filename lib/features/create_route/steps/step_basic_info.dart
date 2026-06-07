import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_spacing.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../shared/widgets/pressable.dart';
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
    this.codeCtrl,
    this.zoneNames = const [],
    this.selectedZone,
    this.onZoneChanged,
    this.onRecommendZone,
  });

  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final String routeColor;
  final String serviceType;
  final ValueChanged<String> onColorChanged;
  final ValueChanged<String> onServiceTypeChanged;
  final TextEditingController? codeCtrl;
  final List<String> zoneNames;
  final String? selectedZone;
  final ValueChanged<String?>? onZoneChanged;
  final ValueChanged<String>? onRecommendZone;

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

  @override
  void initState() {
    super.initState();
    // Sin estos listeners los contadores "x/80" y "x/500" no se
    // refrescan al escribir — TextEditingController no notifica al
    // StatefulWidget padre por sí solo.
    widget.nameCtrl.addListener(_onTextChanged);
    widget.descCtrl.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.nameCtrl.removeListener(_onTextChanged);
    widget.descCtrl.removeListener(_onTextChanged);
    super.dispose();
  }

  String _colorToHex(Color c) =>
      '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  Color _parseRouteColor(String text) {
    final clean = text.replaceFirst('#', '');
    if (clean.length == 6) {
      return Color(int.parse('FF$clean', radix: 16));
    }
    if (clean.length == 8) {
      return Color(int.parse(clean, radix: 16));
    }
    return const Color(0xFF977DDF);
  }

  /// Mismo color wheel + paletas que la pantalla de "Apariencia →
  /// Paleta personalizada" (flex_color_picker). Antes el sheet
  /// solo tenía un campo de hex, lo cual era pobre comparado con
  /// el resto de la app.
  Future<void> _showCustomColorPicker() async {
    final picked = await showColorPickerDialog(
      context,
      _parseRouteColor(widget.routeColor),
      title: const Text('Color de la ruta'),
      pickersEnabled: const {
        ColorPickerType.wheel: true,
        ColorPickerType.primary: true,
        ColorPickerType.accent: true,
        ColorPickerType.custom: true,
      },
      showRecentColors: true,
      showMaterialName: false,
      showColorName: false,
      showColorCode: true,
      copyPasteBehavior: const ColorPickerCopyPasteBehavior(
        copyFormat: ColorPickerCopyFormat.hexRRGGBB,
      ),
      enableOpacity: false,
      width: 36,
      height: 36,
      spacing: 4,
      runSpacing: 4,
    );
    if (!mounted) return;
    widget.onColorChanged(_colorToHex(picked));
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

          if (widget.codeCtrl != null) ...[
            Text('Código de línea (opcional)',
                style: TransitTypography.bodyPrimary(colors.textHi)),
            const SizedBox(height: TransitSpacing.space8),
            TransitInput(
              hint: 'Ej. L1, C2, M-340',
              controller: widget.codeCtrl!,
              maxLines: 1,
            ),
            const SizedBox(height: TransitSpacing.space20),
          ],

          if (widget.onZoneChanged != null) ...[
            Text('Zona', style: TransitTypography.bodyPrimary(colors.textHi)),
            const SizedBox(height: TransitSpacing.space8),
            _ZoneField(
              colors: colors,
              zoneNames: widget.zoneNames,
              selected: widget.selectedZone,
              onChanged: widget.onZoneChanged!,
              onRecommend: widget.onRecommendZone,
            ),
            const SizedBox(height: TransitSpacing.space20),
          ],

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
              // Color "Acento" del esquema. Si coincide con uno de los
              // presets (por defecto el acento ES 0xFF977DDF y el primer
              // preset también), saltamos el preset duplicado más abajo.
              _ColorOption(
                color: colors.accent,
                label: 'Acento',
                isSelected: _colorToHex(colors.accent) == widget.routeColor,
                onTap: () =>
                    widget.onColorChanged(_colorToHex(colors.accent)),
              ),
              for (final hex in _presetColors)
                if ('#${hex.substring(4)}' !=
                    _colorToHex(colors.accent).toUpperCase())
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

class _ZoneField extends StatelessWidget {
  const _ZoneField({
    required this.colors,
    required this.zoneNames,
    required this.selected,
    required this.onChanged,
    this.onRecommend,
  });

  final TransitColorScheme colors;
  final List<String> zoneNames;
  final String? selected;
  final ValueChanged<String?> onChanged;
  final ValueChanged<String>? onRecommend;

  @override
  Widget build(BuildContext context) {
    final value = zoneNames.contains(selected) ? selected : null;
    return Container(
      decoration: BoxDecoration(
        color: colors.bgRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: colors.bgElevated,
                hint: Text('Selecciona zona',
                    style: TransitTypography.bodySecondary(colors.textLo)),
                icon: Icon(Icons.expand_more, color: colors.textMid),
                style: TransitTypography.bodyPrimary(colors.textHi),
                items: zoneNames
                    .map((z) => DropdownMenuItem(value: z, child: Text(z)))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
          if (onRecommend != null)
            IconButton(
              tooltip: 'Proponer zona nueva',
              icon: Icon(Icons.add_location_alt_outlined, color: colors.accent),
              onPressed: () async {
                final ctrl = TextEditingController();
                final name = await showDialog<String>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Proponer zona'),
                    content: TextField(
                      controller: ctrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                          labelText: 'Nombre de la zona'),
                    ),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancelar')),
                      TextButton(
                          onPressed: () =>
                              Navigator.pop(ctx, ctrl.text.trim()),
                          child: const Text('Proponer')),
                    ],
                  ),
                );
                if (name != null && name.isNotEmpty) onRecommend!(name);
              },
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
