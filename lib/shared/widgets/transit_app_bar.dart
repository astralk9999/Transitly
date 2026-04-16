import 'package:flutter/material.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_spacing.dart';
import '../../core/theme/transit_typography.dart';

class TransitAppBar extends StatelessWidget {
  const TransitAppBar({
    super.key,
    this.title,
    this.showBack = true,
    this.actions,
    this.transparent = false,
  });

  final String? title;
  final bool showBack;
  final List<Widget>? actions;
  final bool transparent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return SafeArea(
      bottom: false,
      child: Container(
        height: TransitSpacing.heightNavBar,
        padding: const EdgeInsets.symmetric(horizontal: TransitSpacing.space8),
        color: transparent ? Colors.transparent : c.bgRoot,
        child: Row(
          children: [
            if (showBack)
              Tooltip(
                message: 'Volver',
                child: IconButton(
                  icon: Icon(Icons.arrow_back, size: 24, color: c.textMid),
                  onPressed: () => Navigator.of(context).maybePop(),
                  constraints: const BoxConstraints(
                    minWidth: TransitSpacing.minTapTarget,
                    minHeight: TransitSpacing.minTapTarget,
                  ),
                ),
              ),
            if (title != null) ...[
              const SizedBox(width: TransitSpacing.space8),
              Expanded(
                child: Text(
                  title!,
                  style: TransitTypography.subheading(c.textHi),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ] else
              const Spacer(),
            if (actions != null) ...actions!,
          ],
        ),
      ),
    );
  }
}
