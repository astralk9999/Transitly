import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../shared/widgets/glass_card.dart';

class WidgetsConfigScreen extends ConsumerWidget {
  const WidgetsConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Scaffold(
      backgroundColor: c.bgRoot,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textHi),
          onPressed: () => context.pop(),
        ),
        title: Text('Widgets', style: TransitTypography.heading(c.textHi)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _WidgetListItem(
            c: c,
            icon: Icons.directions_bus,
            title: 'Próximo bus',
            subtitle: 'Muestra la próxima salida de tu parada habitual',
            onTap: () => context.push('/widgets-config/next-bus'),
          ),
          const SizedBox(height: 8),
          _WidgetListItem(
            c: c,
            icon: Icons.route_outlined,
            title: 'Mi línea',
            subtitle: 'Muestra el estado y próximas salidas de tu línea favorita',
            onTap: () => context.push('/widgets-config/my-line'),
          ),
          const SizedBox(height: 8),
          _WidgetListItem(
            c: c,
            icon: Icons.credit_card,
            title: 'Saldo bonobús',
            subtitle: 'Muestra el saldo de tu última lectura NFC',
            onTap: () => context.push('/widgets-config/nfc-balance'),
          ),
        ],
      ),
    );
  }
}

class _WidgetListItem extends StatelessWidget {
  const _WidgetListItem({
    required this.c,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final TransitColorScheme c;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        blur: 12,
        fillOpacity: 0.05,
        borderRadius: 12,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: c.accent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TransitTypography.bodyPrimary(c.textHi)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TransitTypography.bodySmall(c.textMid)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: c.textMid, size: 20),
          ],
        ),
      ),
    );
  }
}
