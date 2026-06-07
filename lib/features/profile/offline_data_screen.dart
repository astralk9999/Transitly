import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/mock/mock_data_service.dart';
import '../../data/snapshot/snapshot_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/providers/is_dark_provider.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_text.dart';
import '../../shared/widgets/transit_app_bar.dart';
import '../../shared/widgets/transit_button.dart';

class OfflineDataScreen extends ConsumerStatefulWidget {
  const OfflineDataScreen({super.key});

  @override
  ConsumerState<OfflineDataScreen> createState() => _OfflineDataScreenState();
}

class _OfflineDataScreenState extends ConsumerState<OfflineDataScreen> {
  bool _reloading = false;
  bool _syncing = false;
  bool _exporting = false;
  DateTime? _lastSync;

  @override
  void initState() {
    super.initState();
    _refreshLastSync();
  }

  Future<void> _refreshLastSync() async {
    final ts = await ref.read(snapshotServiceProvider).lastSync();
    if (mounted) setState(() => _lastSync = ts);
  }

  Future<void> _reload() async {
    setState(() => _reloading = true);
    try {
      await ref.read(mockDataServiceProvider).reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).offlineDataReloaded)),
      );
    } finally {
      if (mounted) setState(() => _reloading = false);
    }
  }

  /// Descarga las líneas frescas de Supabase, guarda el snapshot local y lo
  /// aplica en caliente para ver los datos al día.
  Future<void> _sync() async {
    setState(() => _syncing = true);
    try {
      final raw = await ref.read(snapshotServiceProvider).syncAndSave();
      await ref
          .read(mockDataServiceProvider)
          .loadFromSnapshotString(raw, label: 'snapshot');
      await _refreshLastSync();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos actualizados desde el servidor')),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sin conexión o error: $e')),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  /// Exporta el snapshot (o lo genera) y abre el diálogo de compartir para
  /// guardar/descargar el JSON funcional.
  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final svc = ref.read(snapshotServiceProvider);
      var raw = await svc.readLocal();
      raw ??= await svc.syncAndSave();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/transitly_rutas.json');
      await file.writeAsString(raw);
      await Share.shareXFiles([XFile(file.path)],
          subject: 'Rutas COMUJESA (Transitly)');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo exportar: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _fmt(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode(ref, context);
    final c = TransitColorScheme.of(isDark);
    final data = ref.watch(mockDataServiceProvider);

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: TransitAppBar(title: l10n.offlineDataTitle, transparent: true),
      body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _syncCard(c, data),
                const SizedBox(height: 16),
                _StatsCard(data: data, c: c),
                const SizedBox(height: 16),
                _MetadataCard(data: data, c: c),
                const SizedBox(height: 24),
                TransitButton(
                  label: AppLocalizations.of(context).offlineDataReloadButton,
                  icon: Icons.refresh,
                  isLoading: _reloading,
                  isPrimary: false,
                  onPressed: _reload,
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context).offlineDataExplanation,
                  style: TransitTypography.bodySmall(c.textLo),
                ),
              ],
            ),
    );
  }

  Widget _syncCard(TransitColorScheme c, MockDataService data) {
    final fromSnapshot = data.dataSource == 'snapshot';
    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(fromSnapshot ? Icons.cloud_done : Icons.inventory_2_outlined,
                  size: 18, color: c.accent),
              const SizedBox(width: 8),
              Text(fromSnapshot ? 'Datos sincronizados' : 'Datos de fábrica',
                  style: TransitTypography.bodyPrimary(c.textHi)
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _lastSync != null
                ? 'Última sincronización: ${_fmt(_lastSync!)}'
                : 'Nunca sincronizado. Pulsa "Actualizar" con conexión para '
                    'descargar las líneas más recientes.',
            style: TransitTypography.bodySmall(c.textMid),
          ),
          const SizedBox(height: 14),
          TransitButton(
            label: _syncing ? 'Actualizando...' : 'Actualizar desde el servidor',
            icon: Icons.cloud_download_outlined,
            isLoading: _syncing,
            onPressed: _syncing ? null : _sync,
          ),
          const SizedBox(height: 10),
          TransitButton(
            label: _exporting ? 'Exportando...' : 'Descargar / compartir JSON',
            icon: Icons.ios_share,
            isPrimary: false,
            isLoading: _exporting,
            onPressed: _exporting ? null : _export,
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.data, required this.c});

  final MockDataService data;
  final TransitColorScheme c;

  @override
  Widget build(BuildContext context) {
    final scheduleCount =
        data.schedules.values.fold<int>(0, (s, l) => s + l.length);

    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientText(
            AppLocalizations.of(context).offlineDataContent,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            gradient: c.gradientAccent,
          ),
          const SizedBox(height: 12),
          _Stat(label: 'Operador', value: data.operator_.name, c: c),
          _Stat(label: 'Rutas', value: '${data.routes.length}', c: c),
          _Stat(label: 'Paradas', value: '${data.stops.length}', c: c),
          _Stat(label: 'Horarios', value: '$scheduleCount', c: c),
          _Stat(label: 'Alertas', value: '${data.alerts.length}', c: c),
          _Stat(label: 'Incidencias', value: '${data.incidents.length}', c: c),
          _Stat(
            label: 'Sugerencias',
            value: '${data.routeSuggestions.length}',
            c: c,
          ),
          _Stat(label: 'Usuarios demo', value: '${data.users.length}', c: c),
        ],
      ),
    );
  }
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.data, required this.c});

  final MockDataService data;
  final TransitColorScheme c;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientText(
            AppLocalizations.of(context).offlineDataArchive,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            gradient: c.gradientAccent,
          ),
          const SizedBox(height: 12),
          _Stat(
            label: 'Tamaño',
            value: _formatBytes(data.assetBytes),
            c: c,
          ),
          _Stat(
            label: 'Cargado',
            value: _formatTimestamp(data.loadedAt),
            c: c,
          ),
          _Stat(
            label: 'Origen',
            value: 'assets/mock/comujesa_data.json',
            c: c,
          ),
        ],
      ),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  static String _formatTimestamp(DateTime t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    final ss = t.second.toString().padLeft(2, '0');
    final yyyy = t.year.toString().padLeft(4, '0');
    final mo = t.month.toString().padLeft(2, '0');
    final d = t.day.toString().padLeft(2, '0');
    return '$yyyy-$mo-$d $hh:$mm:$ss';
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.c});

  final String label;
  final String value;
  final TransitColorScheme c;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TransitTypography.bodyPrimary(c.textMid)),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: c.textHi,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
