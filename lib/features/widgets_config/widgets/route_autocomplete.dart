import 'package:flutter/material.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../shared/models/models.dart';

class RouteAutocomplete extends StatelessWidget {
  const RouteAutocomplete({
    super.key,
    required this.routes,
    required this.onSelected,
    required this.label,
    this.initialValue,
  });

  final List<RouteModel> routes;
  final ValueChanged<RouteModel> onSelected;
  final String label;
  final RouteModel? initialValue;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Autocomplete<RouteModel>(
      displayStringForOption: (r) => '${r.code} · ${r.name}',
      optionsBuilder: (textEditingValue) {
        final q = textEditingValue.text.trim().toLowerCase();
        if (q.isEmpty) return routes;
        return routes.where((r) =>
            r.code.toLowerCase().contains(q) ||
            r.name.toLowerCase().contains(q));
      },
      onSelected: onSelected,
      fieldViewBuilder: (ctx, controller, focusNode, onSubmitted) {
        if (initialValue != null && controller.text.isEmpty) {
          controller.text = '${initialValue!.code} · ${initialValue!.name}';
        }
        return TextField(
          controller: controller,
          focusNode: focusNode,
          style: TransitTypography.bodyPrimary(c.textHi),
          cursorColor: c.accent,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TransitTypography.bodySecondary(c.textMid),
            filled: true,
            fillColor: c.bgInput,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.border),
            ),
            suffixIcon: Icon(Icons.search, color: c.textMid),
          ),
        );
      },
      optionsViewBuilder: (ctx, onSelect, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: c.bgRaised,
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (_, i) {
                  final r = options.elementAt(i);
                  return ListTile(
                    dense: true,
                    title: Text(
                      '${r.code} · ${r.name}',
                      style: TransitTypography.bodyPrimary(c.textHi),
                    ),
                    onTap: () => onSelect(r),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
