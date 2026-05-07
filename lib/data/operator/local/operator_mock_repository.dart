import 'package:latlong2/latlong.dart';

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
  OperatorMockRepository(this._mockData);

  final MockDataService _mockData;

  @override
  Future<List<OperatorModel>> list() async => [_mockData.operator_];

  @override
  Future<OperatorModel?> byId(String id) async {
    final op = _mockData.operator_;
    return op.id == id ? op : null;
  }

  @override
  Future<List<OperatorModel>> nearby(
    LatLng center, {
    double radiusM = 50000,
  }) async {
    // El mock no almacena bbox; devolvemos el operador único si su
    // región ("Jerez de la Frontera") cae cerca del centro
    // proporcionado. En la práctica de la app demo siempre lo es.
    return [_mockData.operator_];
  }
}
