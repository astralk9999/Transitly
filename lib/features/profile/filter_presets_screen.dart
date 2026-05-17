import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_spacing.dart';
import '../../core/theme/transit_typography.dart';
import '../../core/utils/app_logger.dart';
import '../../features/map/map_filter_controller.dart';
import '../../features/map/map_filter_state.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/single_field_dialog.dart';
import '../../shared/widgets/transit_app_bar.dart';
import '../../shared/widgets/transit_button.dart';

const _logTag = 'FilterPresets';
const _prefsKey = 'map_filter_presets';

/// Presets con nombre de los filtros del mapa. Se persisten en
/// shared_preferences y se aplican sobre [mapFilterControllerProvider].
class FilterPresetsScreen extends ConsumerStatefulWidget {
  const FilterPresetsScreen({super.key});

  @override
  ConsumerState<FilterPresetsScreen> createState() =>
      _FilterPresetsScreenState();
}

class _FilterPresetsScreenState extends ConsumerState<FilterPresetsScreen> {
  Map<String, MapFilterState> _presets = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      final map = <String, MapFilterState>{};
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        decoded.forEach((name, json) {
          map[name] =
              MapFilterState.fromJson(json as Map<String, dynamic>);
        });
      }
      if (mounted) {
        setState(() {
          _presets = map;
          _loaded = true;
        });
      }
    } catch (e) {
      AppLogger.warn(_logTag, 'failed to load presets', e);
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = <String, dynamic>{
        for (final e in _presets.entries) e.key: e.value.toJson(),
      };
      await prefs.setString(_prefsKey, jsonEncode(encoded));
    } catch (e) {
      AppLogger.error(_logTag, 'failed to persist presets', e);
    }
  }

  Future<void> _saveCurrent() async {
    final name = await showSingleFieldDialog(
      context,
      title: 'Guardar filtros',
      hint: 'Nombre del preset',
      confirmLabel: 'GUARDAR',
    );
    if (name == null || name.isEmpty) return;
    final current = ref.read(mapFilterControllerProvider);
    setState(() => _presets = {..._presets, name: current});
    await _persist();
  }

  void _apply(String name) {
    final preset = _presets[name];
    if (preset == null) return;
    ref.read(mapFilterControllerProvider.notifier).applyState(preset);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Filtros «$name» aplicados')),
    );
  }

  Future<void> _delete(String name) async {
    final next = {..._presets}..remove(name);
    setState(() => _presets = next);
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final names = _presets.keys.toList();

    return Scaffold(
      backgroundColor: c.bgRoot,
      body: Column(
        children: [
          const TransitAppBar(title: 'Filtros predefinidos'),
          Expanded(
            child: !_loaded
                ? const Center(child: CircularProgressIndicator())
                : names.isEmpty
                    ? EmptyState(
                        'Sin presets guardados',
                        'Guarda la combinación de filtros del mapa que más uses '
                        'para aplicarla con un toque.',
                        icon: Icons.tune,
                        actionLabel: 'GUARDAR FILTROS ACTUALES',
                        onAction: _saveCurrent,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(TransitSpacing.space16),
                        itemCount: names.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: TransitSpacing.space8),
                        itemBuilder: (context, i) {
                          final name = names[i];
                          return _PresetTile(
                            c: c,
                            name: name,
                            onApply: () => _apply(name),
                            onDelete: () => _delete(name),
                          );
                        },
                      ),
          ),
          if (_loaded && names.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(TransitSpacing.space16),
              child: TransitButton(
                label: 'GUARDAR FILTROS ACTUALES',
                isPrimary: false,
                onPressed: _saveCurrent,
              ),
            ),
        ],
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.c,
    required this.name,
    required this.onApply,
    required this.onDelete,
  });

  final TransitColorScheme c;
  final String name;
  final VoidCallback onApply;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: c.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border, width: 0.5),
      ),
      child: ListTile(
        onTap: onApply,
        leading: Icon(Icons.tune, color: c.accent),
        title: Text(name, style: TransitTypography.bodyPrimary(c.textHi)),
        subtitle: Text('Tocar para aplicar',
            style: TransitTypography.bodySecondary(c.textMid)),
        trailing: IconButton(
          tooltip: 'Eliminar',
          icon: Icon(Icons.delete_outline, color: c.textMid),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
