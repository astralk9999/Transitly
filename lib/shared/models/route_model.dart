import 'dart:ui';

import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'route_model.freezed.dart';

@freezed
abstract class RouteModel with _$RouteModel {
  const RouteModel._();

  const factory RouteModel({
    required String id,
    required String operatorId,
    required String code,
    required String name,
    required ServiceType serviceType,
    required Color routeColor,
    @Default(true) bool hasReturn,
    @Default(false) bool isCircular,
    @Default(RouteStatus.official) RouteStatus status,
    @Default(true) bool active,
    DateTime? lastUpdatedAt,
  }) = _RouteModel;

  static RouteModel fromJson(Map<String, dynamic> j,
          {String operatorId = 'comujesa'}) =>
      RouteModel(
        id: j['code'] as String,
        operatorId: operatorId,
        code: j['code'] as String,
        name: j['name'] as String,
        serviceType: ServiceType.fromString(j['serviceType'] as String),
        routeColor: _parseColor(j['color'] as String),
        isCircular:
            (j['name'] as String).toLowerCase().contains('circular') ||
                (j['name'] as String).toLowerCase().contains('circunvalación'),
        status: RouteStatus.official,
        active: true,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'code': code,
        'name': name,
        'serviceType': serviceType.name,
        'color': '#${routeColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
        'hasReturn': hasReturn,
        'isCircular': isCircular,
        'status': status.name,
        'active': active,
      };

  static Color _parseColor(String hex) {
    final buffer = StringBuffer();
    if (hex.startsWith('#')) hex = hex.substring(1);
    if (hex.length == 6) buffer.write('FF');
    buffer.write(hex);
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
