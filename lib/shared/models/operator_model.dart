import 'package:freezed_annotation/freezed_annotation.dart';

part 'operator_model.freezed.dart';

@freezed
class OperatorModel with _$OperatorModel {
  const OperatorModel._();

  const factory OperatorModel({
    required String id,
    required String name,
    required String shortName,
    required String region,
    @Default('') String website,
    @Default('') String phone,
  }) = _OperatorModel;

  static OperatorModel fromJson(Map<String, dynamic> j) => OperatorModel(
        id: j['id'] as String,
        name: j['name'] as String,
        shortName: j['shortName'] as String,
        region: j['region'] as String,
        website: j['website'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'shortName': shortName,
        'region': region,
        if (website.isNotEmpty) 'website': website,
        if (phone.isNotEmpty) 'phone': phone,
      };
}
