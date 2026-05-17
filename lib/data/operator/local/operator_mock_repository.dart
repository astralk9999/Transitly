import 'package:latlong2/latlong.dart';

import '../../../core/utils/app_logger.dart';
import '../../../shared/models/operator_model.dart';
import '../../mock/mock_data_service.dart';
import '../domain/operator_repository.dart';

/// Implementación de [OperatorRepository] que delega en el JSON mock
/// cargado por [MockDataService]. **Solo se usa en modo invitado**
/// (sin sesión Supabase) o en tests que no quieren tocar red.
///
/// El JSON mock contiene un único operador (COMUJESA) y no se va a
/// expandir, así que las búsquedas espaciales son triviales.
class OperatorMockRepository implements OperatorRepository {
  OperatorMockRepository(this._mockData) : _cached = [_mockData.operator_];

  // ignore: unused_field
  final MockDataService _mockData;
  final List<OperatorModel> _cached;

  @override
  Future<List<OperatorModel>> list() async => List.unmodifiable(_cached);

  @override
  Future<OperatorModel?> byId(String id) async {
    try {
      return _cached.firstWhere((o) => o.id == id);
    } catch (e) {
      AppLogger.warn('OperatorMockRepo', 'byId failed', e);
      return null;
    }
  }

  @override
  Future<List<OperatorModel>> nearby(
    LatLng center, {
    double radiusM = 50000,
  }) async {
    return List.unmodifiable(_cached);
  }

  @override
  Future<OperatorModel> create(OperatorModel operator) async {
    _cached.add(operator);
    return operator;
  }

  @override
  Future<OperatorModel> update(OperatorModel operator) async {
    final idx = _cached.indexWhere((o) => o.id == operator.id);
    if (idx == -1) {
      throw const OperatorRepositoryException(
        error: OperatorRepositoryError.notFound,
        message: 'Operator not found for update',
      );
    }
    _cached[idx] = operator;
    return operator;
  }

  @override
  Future<void> delete(String id) async {
    _cached.removeWhere((o) => o.id == id);
  }
}
