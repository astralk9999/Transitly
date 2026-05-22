import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/models/driver_invitation_code.dart';

void main() {
  group('DriverInvitationCode', () {
    test('fromJson parses all fields correctly', () {
      final json = <String, dynamic>{
        'code': 'ABC-1234-XY',
        'operatorId': 'op-1',
        'createdBy': 'user-99',
        'maxUses': 5,
        'uses': 2,
        'expiresAt': '2026-06-01T00:00:00.000Z',
        'kind': 'operatorAdmin',
      };

      final code = DriverInvitationCode.fromJson(json);

      expect(code.code, 'ABC-1234-XY');
      expect(code.operatorId, 'op-1');
      expect(code.createdBy, 'user-99');
      expect(code.maxUses, 5);
      expect(code.uses, 2);
      expect(code.expiresAt, DateTime.parse('2026-06-01T00:00:00.000Z'));
      expect(code.kind, InvitationKind.operatorAdmin);
    });

    test('fromJson defaults missing fields', () {
      final json = <String, dynamic>{
        'code': 'XYZ-9999-AB',
        'operatorId': 'op-2',
        'createdBy': 'user-42',
        'expiresAt': '2026-12-31T23:59:59.000Z',
      };

      final code = DriverInvitationCode.fromJson(json);

      expect(code.maxUses, 1);
      expect(code.uses, 0);
      expect(code.kind, InvitationKind.driver);
    });

    test('toJson roundtrips correctly', () {
      final expires = DateTime.parse('2026-07-15T12:00:00.000Z');
      final original = DriverInvitationCode(
        code: 'DEF-5678-ZZ',
        operatorId: 'op-3',
        createdBy: 'user-7',
        maxUses: 10,
        uses: 3,
        expiresAt: expires,
        kind: InvitationKind.driver,
      );

      final json = original.toJson();
      final restored = DriverInvitationCode.fromJson(json);

      expect(restored.code, original.code);
      expect(restored.operatorId, original.operatorId);
      expect(restored.createdBy, original.createdBy);
      expect(restored.maxUses, original.maxUses);
      expect(restored.uses, original.uses);
      expect(restored.expiresAt, original.expiresAt);
      expect(restored.kind, original.kind);
    });
  });
}
