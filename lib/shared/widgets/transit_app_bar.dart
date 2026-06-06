import 'package:flutter/material.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_spacing.dart';
import '../../core/theme/transit_typography.dart';

class TransitAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TransitAppBar({
    super.key,
    this.title,
    this.showBack = true,
    this.actions,
    this.transparent = false,
    this.breadcrumbs,
    this.contextualHelp,
  });

  final String? title;
  final bool showBack;
  final List<Widget>? actions;
  final bool transparent;
  final List<({String label, VoidCallback onTap})>? breadcrumbs;
  final ({String title, String message})? contextualHelp;

  // PreferredSizeWidget: permite usar el TransitAppBar directamente
  // en Scaffold.appBar para que Material aplique el padding del
  // status bar exactamente igual en TODAS las pantallas. Antes había
  // disparidad porque cada pantalla envolvía el TransitAppBar de
  // forma distinta (con/sin SafeArea explícito).
  @override
  Size get preferredSize =>
      const Size.fromHeight(TransitSpacing.heightNavBar);

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
                child: breadcrumbs != null && breadcrumbs!.isNotEmpty
                    ? _Breadcrumbs(
                        crumbs: breadcrumbs!,
                        c: c,
                        currentTitle: title!,
                      )
                    : Text(
                        title!,
                        style: TransitTypography.subheading(c.textHi),
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
            ] else
              const Spacer(),
            if (contextualHelp != null)
              Tooltip(
                message: contextualHelp!.title,
                child: IconButton(
                  icon: Icon(Icons.help_outline, size: 20, color: c.textMid),
                  constraints: const BoxConstraints(
                    minWidth: TransitSpacing.minTapTarget,
                    minHeight: TransitSpacing.minTapTarget,
                  ),
                  onPressed: () => _showHelp(context, c),
                ),
              ),
            if (actions != null) ...actions!,
          ],
        ),
      ),
    );
  }

  void _showHelp(BuildContext context, TransitColorScheme c) {
    final help = contextualHelp;
    if (help == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.bgSurface,
        title: Text(help.title, style: TransitTypography.subheading(c.textHi)),
        content: Text(help.message,
            style: TransitTypography.bodyPrimary(c.textMid)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text('OK', style: TransitTypography.bodyPrimary(c.accent)),
          ),
        ],
      ),
    );
  }
}

class _Breadcrumbs extends StatelessWidget {
  const _Breadcrumbs({
    required this.crumbs,
    required this.c,
    required this.currentTitle,
  });

  final List<({String label, VoidCallback onTap})> crumbs;
  final TransitColorScheme c;
  final String currentTitle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Breadcrumb: ${crumbs.map((c) => c.label).join(' > ')} > $currentTitle',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < crumbs.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.chevron_right, size: 16, color: c.textLo),
                ),
              InkWell(
                onTap: crumbs[i].onTap,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    crumbs[i].label,
                    style: TransitTypography.bodySmall(c.accent),
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.chevron_right, size: 16, color: c.textLo),
            ),
            Flexible(
              child: Text(
                currentTitle,
                style: TransitTypography.subheading(c.textHi),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
