import 'package:freezed_annotation/freezed_annotation.dart';

part 'operator_model.freezed.dart';

@freezed
abstract class OperatorModel with _$OperatorModel {
  const OperatorModel._();

  const factory OperatorModel({
    required String id,
    required String name,
    required String shortName,
    required String slug,
    required String region,
    @Default('') String website,
    @Default('') String contactEmail,
    @Default('') String phone,
  }) = _OperatorModel;

  static OperatorModel fromJson(Map<String, dynamic> j) => OperatorModel(
        id: j['id'] as String,
        name: j['name'] as String,
        shortName: j['shortName'] as String,
        slug: j['slug'] as String? ?? '',
        region: j['region'] as String,
        website: j['website'] as String? ?? '',
        contactEmail: j['contactEmail'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'shortName': shortName,
        'slug': slug,
        'region': region,
        if (website.isNotEmpty) 'website': website,
        if (contactEmail.isNotEmpty) 'contactEmail': contactEmail,
        if (phone.isNotEmpty) 'phone': phone,
      };
}
