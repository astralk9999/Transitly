import 'package:flutter/material.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_spacing.dart';

Future<T?> showTransitBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double maxHeightFraction = 0.85,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final c = TransitColorScheme.of(isDark);

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.bgSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(TransitSpacing.space16),
      ),
    ),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * maxHeightFraction,
    ),
    builder: (ctx) => _TransitSheetWrapper(builder: builder),
  );
}

class _TransitSheetWrapper extends StatelessWidget {
  const _TransitSheetWrapper({required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: TransitSpacing.space12),
        // Handle bar
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: c.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: TransitSpacing.space8),
        // Close button row
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: TransitSpacing.space8),
            child: Tooltip(
              message: 'Cerrar',
              child: IconButton(
                icon: Icon(Icons.close, size: 20, color: c.textMid),
                onPressed: () => Navigator.of(context).pop(),
                constraints: const BoxConstraints(
                  minWidth: TransitSpacing.minTapTarget,
                  minHeight: TransitSpacing.minTapTarget,
                ),
              ),
            ),
          ),
        ),
        // Content
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TransitSpacing.space24,
            ),
            child: builder(context),
          ),
        ),
        const SizedBox(height: TransitSpacing.space16),
      ],
    );
  }
}
