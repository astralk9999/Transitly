import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:transitly/data/operator/domain/operator_repository.dart';
import 'package:transitly/data/operator/operator_repository_provider.dart';
import 'package:transitly/features/admin/admin_operators_screen.dart';
import 'package:transitly/shared/models/operator_model.dart';
import 'package:transitly/shared/models/user_model.dart';
import 'package:transitly/shared/models/user_role.dart';
import 'package:transitly/shared/providers/user_provider.dart';

import '../../helpers/pump_app.dart';

class MockOperatorRepository extends Mock implements OperatorRepository {}

OperatorModel _testOp(String id) => OperatorModel(
      id: id,
      name: 'Operator $id',
      shortName: 'OP$id',
      slug: 'op$id',
      region: 'Region $id',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockOperatorRepository mockRepo;

  setUp(() {
    mockRepo = MockOperatorRepository();

    registerFallbackValue(_testOp('fallback'));
    registerFallbackValue('');
  });

  Override adminUserOverride() {
    const adminUser = UserModel(
      id: 'admin',
      name: 'Admin',
      email: 'admin@test.com',
      role: UserRole.admin,
    );
    return currentUserProvider.overrideWithValue(adminUser);
  }

  List<Override> allOverrides() => [
        operatorRepositoryProvider.overrideWithValue(mockRepo),
        adminUserOverride(),
      ];

  group('AdminOperatorsScreen', () {
    testWidgets('muestra ShimmerSkeleton durante loading', (tester) async {
      final completer = Completer<List<OperatorModel>>();
      when(() => mockRepo.list()).thenAnswer((_) => completer.future);

      await pumpApp(
        tester,
        child: const AdminOperatorsScreen(),
        overrides: allOverrides(),
        locale: const Locale('es'),
      );

      final shimmerFinder = find.byWidgetPredicate(
        (w) => w.runtimeType.toString().contains('Shimmer'),
      );
      expect(shimmerFinder, findsWidgets);

      completer.complete([]);
      addTearDown(() => unmount(tester));
    });

    testWidgets('muestra EmptyState cuando lista vacia', (tester) async {
      when(() => mockRepo.list()).thenAnswer((_) async => []);

      await pumpApp(
        tester,
        child: const AdminOperatorsScreen(),
        overrides: allOverrides(),
        locale: const Locale('es'),
      );

      await tester.pump();
      await tester.pump();

      expect(find.text('No hay operadores registrados'), findsWidgets);

      addTearDown(() => unmount(tester));
    });

    testWidgets('muestra ErrorCard y boton retry cuando hay error', (tester) async {
      when(() => mockRepo.list()).thenThrow(
        const OperatorRepositoryException(
          error: OperatorRepositoryError.network,
          message: 'No connection',
        ),
      );

      await pumpApp(
        tester,
        child: const AdminOperatorsScreen(),
        overrides: allOverrides(),
        locale: const Locale('es'),
      );

      await tester.pump();
      await tester.pump();

      expect(
        find.textContaining('Error de red al cargar operadores'),
        findsOneWidget,
      );
      expect(find.text('REINTENTAR'), findsOneWidget);

      addTearDown(() => unmount(tester));
    });

    testWidgets('RoleGate protege la pantalla para no-admin', (tester) async {
      const nonAdminUser = UserModel(
        id: 'u1',
        name: 'Passenger',
        email: 'p@test.com',
        role: UserRole.passenger,
      );

      when(() => mockRepo.list()).thenAnswer((_) async => []);

      await pumpApp(
        tester,
        child: const AdminOperatorsScreen(),
        overrides: [
          ...allOverrides(),
          currentUserProvider.overrideWithValue(nonAdminUser),
        ],
        locale: const Locale('es'),
      );

      await tester.pump();

      expect(find.text('Gesti\u00f3n de operadores'), findsNothing);

      addTearDown(() => unmount(tester));
    });
  });
}
