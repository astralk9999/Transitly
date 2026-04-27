import 'package:flutter/material.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import 'transit_input.dart';

/// Dialog with a single text input, a cancel action and a confirm action.
///
/// Owns its [TextEditingController] so the controller is disposed reliably
/// when the dialog is closed. Prefer this over creating a controller inline
/// in a `showDialog` builder (which leaks on every open).
class SingleFieldDialog extends StatefulWidget {
  const SingleFieldDialog({
    super.key,
    required this.title,
    required this.hint,
    required this.confirmLabel,
    this.cancelLabel = 'CANCELAR',
    this.initialValue,
  });

  final String title;
  final String hint;
  final String confirmLabel;
  final String cancelLabel;
  final String? initialValue;

  @override
  State<SingleFieldDialog> createState() => _SingleFieldDialogState();
}

class _SingleFieldDialogState extends State<SingleFieldDialog> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.initialValue ?? '');

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    return AlertDialog(
      backgroundColor: c.bgSurface,
      title: Text(widget.title, style: TransitTypography.heading(c.textHi)),
      content: TransitInput(hint: widget.hint, controller: _ctrl),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancelLabel,
              style: TransitTypography.bodySecondary(c.textMid)),
        ),
        TextButton(
          onPressed: () {
            final value = _ctrl.text.trim();
            if (value.isEmpty) {
              Navigator.of(context).pop();
              return;
            }
            Navigator.of(context).pop(value);
          },
          child: Text(widget.confirmLabel,
              style: TransitTypography.bodySecondary(c.accent)),
        ),
      ],
    );
  }
}

/// Show [SingleFieldDialog] and await the confirmed value (null on cancel).
Future<String?> showSingleFieldDialog(
  BuildContext context, {
  required String title,
  required String hint,
  required String confirmLabel,
  String cancelLabel = 'CANCELAR',
  String? initialValue,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => SingleFieldDialog(
      title: title,
      hint: hint,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      initialValue: initialValue,
    ),
  );
}
