import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';
import '../supabase/supabase_client_provider.dart';

const _logTag = 'Snapshot';
const _operatorId = '00000000-0000-0000-0000-000000000001';
const _assetPath = 'assets/mock/comujesa_data.json';
const _snapshotName = 'comujesa_snapshot.json';

/// Genera, guarda y exporta un snapshot JSON de las líneas desde Supabase.
///
/// El snapshot reusa el asset empaquetado como plantilla (operador, badges,
/// etc.) y reemplaza únicamente `lines` con datos frescos de Supabase, de modo
/// que siempre es 100% compatible con [MockDataService] (mismo esquema). Se
/// guarda en el directorio de documentos de la app para uso offline.
class SnapshotService {
  SnapshotService(this._client);
  final SupabaseClient _client;

  Future<File> _snapshotFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_snapshotName');
  }

  /// Ruta del snapshot local si existe, o null.
  Future<File?> existing() async {
    final f = await _snapshotFile();
    return await f.exists() ? f : null;
  }

  /// Fecha de la última sincronización (mtime del snapshot), o null.
  Future<DateTime?> lastSync() async {
    final f = await existing();
    if (f == null) return null;
    return f.lastModified();
  }

  /// Consulta Supabase (RPC snapshot_lines) y construye el JSON del snapshot
  /// (string). Reusa el asset como plantilla y reemplaza `lines`. Lanza si la
  /// red falla.
  Future<String> buildJson() async {
    final baseRaw = await rootBundle.loadString(_assetPath);
    final base = json.decode(baseRaw) as Map<String, dynamic>;

    final res = await _client.rpc('snapshot_lines', params: {
      'p_operator_id': _operatorId,
    });
    final lines = (res as List).cast<Map<String, dynamic>>();

    base['lines'] = lines;
    base['_metadata'] = {
      ...(base['_metadata'] as Map<String, dynamic>? ?? const {}),
      'snapshotGeneratedAt': DateTime.now().toIso8601String(),
      'source': 'supabase',
      'lineCount': lines.length,
    };
    return json.encode(base);
  }

  /// Genera el snapshot y lo guarda localmente. Devuelve el JSON crudo.
  Future<String> syncAndSave() async {
    final raw = await buildJson();
    final f = await _snapshotFile();
    await f.writeAsString(raw);
    AppLogger.info(_logTag, 'snapshot saved (${raw.length} B) -> ${f.path}');
    return raw;
  }

  /// Lee el snapshot local (string) si existe.
  Future<String?> readLocal() async {
    final f = await existing();
    return f?.readAsString();
  }
}

final snapshotServiceProvider = Provider<SnapshotService>((ref) {
  return SnapshotService(ref.watch(supabaseClientProvider));
});
