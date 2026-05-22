import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../data/supabase/supabase_client_provider.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/smoke_background.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/transit_button.dart';

class DriversScreen extends ConsumerStatefulWidget {
  const DriversScreen({super.key});

  @override
  ConsumerState<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends ConsumerState<DriversScreen> {
  List<Map<String, dynamic>>? _drivers;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = ref.read(supabaseClientProvider);
      final session = client.auth.currentSession;
      if (session == null) {
        setState(() {
          _loading = false;
          _drivers = [];
        });
        return;
      }

      final rows = await client
          .from('driver_assignments')
          .select('driver_id, granted_at, profiles(display_name, email)')
          .filter('revoked_at', 'is', null)
          .order('granted_at', ascending: false);

      setState(() {
        _drivers = rows.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context).driversErrorLoading;
      });
    }
  }

  Future<void> _revokeDriver(String driverId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final c = TransitColorScheme.of(isDark);
        return AlertDialog(
          backgroundColor: c.bgSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text('¿Revocar conductor?',
              style: TransitTypography.heading(c.textHi)),
          content: Text(
              'El conductor perderá el acceso al modo conductor.',
              style: TransitTypography.bodySecondary(c.textMid)),
          actions: [
            TransitButton(
              label: AppLocalizations.of(ctx).actionCancel.toUpperCase(),
              isPrimary: false,
              isSmall: true,
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            TransitButton(
              label: 'REVOCAR',
              isDanger: true,
              isSmall: true,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final client = ref.read(supabaseClientProvider);
      await client.rpc('revoke_driver', params: {
        'p_driver_id': driverId,
        'p_operator_id': '00000000-0000-0000-0000-000000000000',
      });
      await _loadDrivers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).driversErrorRevoking)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Scaffold(
      backgroundColor: c.bgRoot,
      body: Stack(
        children: [
          Positioned.fill(
              child: SmokeBackground(color: c.accent, isDark: isDark)),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        color: c.textHi,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Text('Conductores',
                          style: TransitTypography.heading(c.textHi)),
                    ],
                  ),
                ),
                Expanded(child: _buildContent(c)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(TransitColorScheme c) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 16),
            TransitButton(
              label: 'REINTENTAR',
              isSmall: true,
              onPressed: _loadDrivers,
            ),
          ],
        ),
      );
    }

    if (_drivers == null || _drivers!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: c.textLo),
            const SizedBox(height: 16),
            Text('No hay conductores asignados',
                style: TransitTypography.bodyPrimary(c.textMid)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _drivers!.length,
      itemBuilder: (context, index) {
        final driver = _drivers![index];
        final profile = driver['profiles'] as Map<String, dynamic>? ??
            <String, dynamic>{};

        return GlassCard(
          blur: 12,
          fillOpacity: 0.05,
          borderRadius: 12,
          padding: const EdgeInsets.all(12),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: c.accent.withValues(alpha: 0.12),
              child: Text(
                (profile['display_name'] as String? ?? '?')[0].toUpperCase(),
                style: TextStyle(color: c.accent, fontWeight: FontWeight.w600),
              ),
            ),
            title: Text(
              profile['display_name'] as String? ?? 'Sin nombre',
              style: TransitTypography.bodyPrimary(c.textHi),
            ),
            subtitle: Text(
              profile['email'] as String? ?? '',
              style: TransitTypography.bodySmall(c.textMid),
            ),
            trailing: TransitButton(
              label: 'REVOCAR',
              isDanger: true,
              isSmall: true,
              onPressed: () =>
                  _revokeDriver(driver['driver_id'] as String),
            ),
          ),
        );
      },
    );
  }
}
