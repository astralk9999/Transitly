import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/operator_model.dart';
import '../domain/operator_repository.dart';
import '../operator_helpers.dart';

/// Implementación remota de [OperatorRepository] sobre Supabase.
/// Lee de la tabla `operators` y de la función SQL `nearby_operators`
/// (F2.5).
class OperatorRemoteRepository implements OperatorRepository {
  OperatorRemoteRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<OperatorModel>> list({int? limit, int? offset}) async {
    try {
      dynamic query = _client.from('operators').select().order('name');
      if (offset != null) {
        final end = offset + (limit ?? 100) - 1;
        query = query.range(offset, end);
      } else if (limit != null) {
        query = query.limit(limit);
      }
      final rows = await query;
      return (rows as List<dynamic>).map((e) => operatorFromRow(e as Map<String, dynamic>)).toList();
    } catch (e, st) {
      throw mapOperatorError(e, st, 'list');
    }
  }

  @override
  Future<OperatorModel?> byId(String id) async {
    try {
      final row = await _client
          .from('operators')
          .select()
          .eq('id', id)
          .maybeSingle();
      return row == null ? null : operatorFromRow(row);
    } catch (e, st) {
      throw mapOperatorError(e, st, 'byId($id)');
    }
  }

  @override
  Future<List<OperatorModel>> nearby(
    LatLng center, {
    double radiusM = 50000,
  }) async {
    try {
      final result = await _client.rpc(
        'nearby_operators',
        params: <String, dynamic>{
          'p_lat': center.latitude,
          'p_lng': center.longitude,
          'p_radius_m': radiusM.toInt(),
        },
      );
      return (result as List<dynamic>)
          .map((e) => operatorFromRow(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      throw mapOperatorError(e, st, 'nearby');
    }
  }

  @override
  Future<OperatorModel> create(OperatorModel operator) async {
    try {
      final row = await _client
          .from('operators')
          .insert(<String, dynamic>{
            'slug': operator.slug,
            'name': operator.name,
            'region': operator.region,
            'website': operator.website,
            'contact_email': operator.contactEmail,
            if (operator.color.isNotEmpty) 'color': operator.color,
            'is_active': operator.isActive,
          })
          .select()
          .single();
      return operatorFromRow(row);
    } catch (e, st) {
      throw mapOperatorError(e, st, 'create');
    }
  }

  @override
  Future<OperatorModel> update(OperatorModel operator) async {
    try {
      final row = await _client
          .from('operators')
          .update(<String, dynamic>{
            'slug': operator.slug,
            'name': operator.name,
            'region': operator.region,
            'website': operator.website,
            'contact_email': operator.contactEmail,
            'color': operator.color.isEmpty ? null : operator.color,
            'is_active': operator.isActive,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', operator.id)
          .select()
          .single();
      return operatorFromRow(row);
    } catch (e, st) {
      throw mapOperatorError(e, st, 'update(${operator.id})');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _client.from('operators').delete().eq('id', id);
    } catch (e, st) {
      throw mapOperatorError(e, st, 'delete($id)');
    }
  }

  /// Mapeo delegado a [operatorFromRow] y [mapOperatorError] en
  /// `operator_helpers.dart`.
}
