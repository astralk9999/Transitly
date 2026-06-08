import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../data/admin/admin_routes_repository.dart';
import '../../../data/supabase/supabase_client_provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/primary_zone_provider.dart';
import '../../../data/auth/auth_repository.dart';

/// Sheet para elegir la ZONA PRINCIPAL del perfil (profiles.primary_zone_id).
/// La zona principal se usa como destino por defecto del mapa cuando no hay
/// ubicación. Solo lista zonas con perímetro (centro+radio).
Future<void> showPrimaryZonePicker(BuildContext context, WidgetRef ref) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final c = TransitColorScheme.of(isDark);
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: c.bgSurface,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const _PrimaryZoneSheet(),
  );
}

class _PrimaryZoneSheet extends ConsumerStatefulWidget {
  const _PrimaryZoneSheet();

  @override
  ConsumerState<_PrimaryZoneSheet> createState() => _PrimaryZoneSheetState();
}

class _PrimaryZoneSheetState extends ConsumerState<_PrimaryZoneSheet> {
  List<ZoneRow> _zones = const [];
  String? _currentId;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final client = ref.read(supabaseClientProvider);
      final authState = ref.read(authStateProvider).valueOrNull;
      final uid = authState is AuthAuthenticated ? authState.user.id : null;
      final zones = await AdminRoutesRepository(client).listZones();
      String? current;
      if (uid != null) {
        final prof = await client
            .from('profiles')
            .select('primary_zone_id')
            .eq('id', uid)
            .maybeSingle();
        current = prof?['primary_zone_id'] as String?;
      }
      if (!mounted) return;
      setState(() {
        // Solo zonas con perímetro sirven como destino por defecto.
        _zones = zones.where((z) => z.hasGeometry).toList();
        _currentId = current;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _select(String? zoneId) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final authState = ref.read(authStateProvider).valueOrNull;
      final uid = authState is AuthAuthenticated ? authState.user.id : null;
      if (uid != null) {
        await client
            .from('profiles')
            .update({'primary_zone_id': zoneId}).eq('id', uid);
      }
      ref.invalidate(primaryZoneProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Zona principal', style: TransitTypography.heading(c.textHi)),
          const SizedBox(height: 4),
          Text(
            'Se usará como destino por defecto del mapa cuando no haya '
            'ubicación disponible.',
            style: TransitTypography.bodySecondary(c.textMid),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_zones.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No hay zonas con perímetro disponibles.',
                      style: TransitTypography.bodyPrimary(c.textMid)),
                  const SizedBox(height: 4),
                  Text(
                      'Un administrador debe crearlas en Gestión de zonas.',
                      style: TransitTypography.bodySmall(c.textLo)),
                ],
              ),
            )
          else
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  // Opción "ninguna" → vuelve al destino por defecto (Jerez).
                  _tile(c, null, 'Ninguna (Jerez por defecto)',
                      Icons.location_off_outlined),
                  for (final z in _zones)
                    _tile(c, z.id,
                        '${z.name} · ${(z.radiusM! / 1000).toStringAsFixed(1)} km',
                        Icons.location_city),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _tile(
      TransitColorScheme c, String? id, String label, IconData icon) {
    final selected = _currentId == id;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: selected ? c.accent : c.textMid),
      title: Text(label, style: TransitTypography.bodyPrimary(c.textHi)),
      trailing: selected
          ? Icon(Icons.check_circle, color: c.accent)
          : (_saving
              ? null
              : Icon(Icons.radio_button_unchecked, color: c.textLo)),
      onTap: _saving ? null : () => _select(id),
    );
  }
}
