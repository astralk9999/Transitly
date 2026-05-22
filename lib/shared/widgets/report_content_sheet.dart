import 'package:flutter/material.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../shared/widgets/transit_button.dart';

class ReportContentSheet extends StatelessWidget {
  const ReportContentSheet({super.key, this.contentType, this.contentId});

  final String? contentType;
  final String? contentId;

  static void show(
    BuildContext context, {
    String? contentType,
    String? contentId,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    showModalBottomSheet(
      context: context,
      backgroundColor: c.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ReportContentSheet(
        contentType: contentType,
        contentId: contentId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Padding(
      padding: const EdgeInsets.all(24),
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
            'Report content',
            style: TransitTypography.subheading(c.textHi),
          ),
          const SizedBox(height: 8),
          Text(
            'If this content violates our community guidelines, '
            'please let us know.',
            style: TransitTypography.bodySecondary(c.textMid),
          ),
          const SizedBox(height: 20),
          _ReportReason(
            icon: Icons.gpp_bad,
            label: 'Spam or misleading',
            c: c,
            onTap: () => _submit(context, 'spam'),
          ),
          const SizedBox(height: 8),
          _ReportReason(
            icon: Icons.block,
            label: 'Harassment or hate speech',
            c: c,
            onTap: () => _submit(context, 'harassment'),
          ),
          const SizedBox(height: 8),
          _ReportReason(
            icon: Icons.info_outline,
            label: 'False or inaccurate information',
            c: c,
            onTap: () => _submit(context, 'misinformation'),
          ),
          const SizedBox(height: 8),
          _ReportReason(
            icon: Icons.warning_amber,
            label: 'Inappropriate or offensive content',
            c: c,
            onTap: () => _submit(context, 'inappropriate'),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: TransitButton(
              label: 'Cancel',
              isPrimary: false,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  void _submit(BuildContext context, String reason) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Report sent: $reason'),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class _ReportReason extends StatelessWidget {
  const _ReportReason({
    required this.icon,
    required this.label,
    required this.c,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final TransitColorScheme c;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: c.stateCancelled, size: 20),
            const SizedBox(width: 12),
            Text(label, style: TransitTypography.bodyPrimary(c.textHi)),
          ],
        ),
      ),
    );
  }
}
