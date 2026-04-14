import 'package:flutter/material.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';

class TransitInput extends StatelessWidget {
  const TransitInput({
    super.key,
    this.hint,
    this.controller,
    this.onChanged,
    this.prefix,
    this.suffix,
    this.maxLines = 1,
  });

  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final Widget? prefix;
  final Widget? suffix;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return SizedBox(
      height: maxLines == 1 ? 44 : null,
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        maxLines: maxLines,
        style: TransitTypography.bodyPrimary(c.textHi),
        cursorColor: c.accent,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TransitTypography.bodyPrimary(c.textLo),
          filled: true,
          fillColor: c.bgInput,
          prefixIcon: prefix,
          suffixIcon: suffix,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: c.border, width: 0.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: c.border, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: c.borderFocus, width: 1),
          ),
        ),
      ),
    );
  }
}
