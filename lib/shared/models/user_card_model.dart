class UserCardModel {
  const UserCardModel({
    required this.id,
    required this.userId,
    required this.cardNumber,
    required this.operatorId,
    required this.balance,
    required this.cardType,
  });

  final String id;
  final String userId;
  final String cardNumber;
  final String operatorId;
  final double balance;
  final String cardType;

  factory UserCardModel.fromJson(Map<String, dynamic> j) => UserCardModel(
        id: j['id'] as String,
        userId: j['userId'] as String,
        cardNumber: j['cardNumber'] as String,
        operatorId: 'comujesa',
        balance: (j['balance'] as num).toDouble(),
        cardType: j['type'] as String? ?? 'multiviaje',
      );
}
