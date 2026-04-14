class OperatorModel {
  const OperatorModel({
    required this.id,
    required this.name,
    required this.shortName,
    required this.region,
    required this.website,
    required this.phone,
  });

  final String id;
  final String name;
  final String shortName;
  final String region;
  final String website;
  final String phone;

  factory OperatorModel.fromJson(Map<String, dynamic> j) => OperatorModel(
        id: j['id'] as String,
        name: j['name'] as String,
        shortName: j['shortName'] as String,
        region: j['region'] as String,
        website: j['website'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
      );
}
