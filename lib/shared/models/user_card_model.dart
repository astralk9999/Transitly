import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_card_model.freezed.dart';

@freezed
class UserCardModel with _$UserCardModel {
  const UserCardModel._();

  const factory UserCardModel({
    required String id,
    required String userId,
    required String cardNumber,
    required String operatorId,
    required double balance,
    required String cardType,
  }) = _UserCardModel;

  static UserCardModel fromJson(Map<String, dynamic> j) => UserCardModel(
        id: j['id'] as String,
        userId: j['userId'] as String,
        cardNumber: j['cardNumber'] as String,
        operatorId: 'comujesa',
        balance: (j['balance'] as num).toDouble(),
        cardType: j['type'] as String? ?? 'multiviaje',
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'userId': userId,
        'cardNumber': cardNumber,
        'balance': balance,
        'type': cardType,
      };
}
