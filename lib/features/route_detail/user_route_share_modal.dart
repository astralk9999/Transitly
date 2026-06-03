import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/user_routes/user_routes_repository.dart';
import '../../shared/widgets/transit_button.dart';

// TODO(l10n):
class UserRouteShareModal extends StatelessWidget {
  const UserRouteShareModal({super.key, required this.route});

  final UserRouteModel route;

  static void show(BuildContext context, UserRouteModel route) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => UserRouteShareModal(route: route),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    final shareLink =
        route.publicSlug != null ? 'transitly.app/r/${route.publicSlug}' : null;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.textLo,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            route.name,
            style: TransitTypography.heading(c.textHi),
          ),
          const SizedBox(height: 20),

          // Share code
          if (route.shareCode != null) ...[
            Text(
              'Código de ruta',
              // TODO(l10n):
              style: TransitTypography.bodySmall(c.textMid),
            ),
            const SizedBox(height: 8),
            _buildCopyRow(
              context,
              c,
              route.shareCode!,
              large: true,
              label: 'Copiar código',
            ),
            const SizedBox(height: 16),
          ],

          // Public link
          if (shareLink != null) ...[
            Text(
              'Enlace público',
              // TODO(l10n):
              style: TransitTypography.bodySmall(c.textMid),
            ),
            const SizedBox(height: 8),
            _buildCopyRow(context, c, shareLink, label: 'Copiar enlace'),
            const SizedBox(height: 24),
          ],

          // Share buttons
          Text(
            'Compartir vía',
            // TODO(l10n):
            style: TransitTypography.bodySmall(c.textMid),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TransitButton(
                  label: 'WhatsApp',
                  icon: Icons.chat,
                  isPrimary: false,
                  onPressed: () {
                    if (shareLink != null) {
                      _copyAndDismiss(context, shareLink, 'Enlace copiado');
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TransitButton(
                  label: 'Email',
                  icon: Icons.email_outlined,
                  isPrimary: false,
                  onPressed: () {
                    if (shareLink != null) {
                      _copyAndDismiss(context, shareLink, 'Enlace copiado');
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TransitButton(
                  label: 'Enlace',
                  icon: Icons.link,
                  isPrimary: false,
                  onPressed: () {
                    if (shareLink != null) {
                      _copyAndDismiss(context, shareLink, 'Enlace copiado');
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCopyRow(
    BuildContext context,
    TransitColorScheme c,
    String text, {
    bool large = false,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.bgRaised,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: large
                  ? TransitTypography.routeCode(c.textHi)
                  : TransitTypography.bodySecondary(c.textHi),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          TransitButton(
            label: label,
            isSmall: true,
            isPrimary: false,
            icon: Icons.copy,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Copiado al portapapeles'),
                  // TODO(l10n):
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _copyAndDismiss(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
