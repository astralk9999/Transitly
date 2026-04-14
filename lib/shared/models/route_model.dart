import 'dart:ui';
import 'enums.dart';

class RouteModel {
  const RouteModel({
    required this.id,
    required this.operatorId,
    required this.code,
    required this.name,
    required this.serviceType,
    required this.routeColor,
    this.hasReturn = true,
    this.isCircular = false,
    this.status = RouteStatus.official,
    this.active = true,
  });

  final String id;
  final String operatorId;
  final String code;
  final String name;
  final ServiceType serviceType;
  final Color routeColor;
  final bool hasReturn;
  final bool isCircular;
  final RouteStatus status;
  final bool active;

  factory RouteModel.fromJson(Map<String, dynamic> j,
          {String operatorId = 'comujesa'}) =>
      RouteModel(
        id: j['code'] as String,
        operatorId: operatorId,
        code: j['code'] as String,
        name: j['name'] as String,
        serviceType: ServiceType.fromString(j['serviceType'] as String),
        routeColor: _parseColor(j['color'] as String),
        isCircular: (j['name'] as String).toLowerCase().contains('circular') ||
            (j['name'] as String).toLowerCase().contains('circunvalación'),
        status: RouteStatus.official,
        active: true,
      );

  static Color _parseColor(String hex) {
    final buffer = StringBuffer();
    if (hex.startsWith('#')) hex = hex.substring(1);
    if (hex.length == 6) buffer.write('FF');
    buffer.write(hex);
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
