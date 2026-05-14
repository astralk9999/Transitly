import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:transitly/data/supabase/supabase_client_provider.dart';
import 'package:transitly/features/admin/admin_users_screen.dart';
import 'package:transitly/shared/models/user_model.dart';
import 'package:transitly/shared/models/user_role.dart';
import 'package:transitly/shared/providers/user_provider.dart';

import '../../helpers/pump_app.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockSession extends Mock implements Session {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockPostgrestFilterBuilder
    extends Mock
    implements PostgrestFilterBuilder<PostgrestList> {}

class FakeTransform extends Mock
    implements PostgrestTransformBuilder<PostgrestList> {
  final Future<PostgrestList> _future;

  FakeTransform(Future<PostgrestList> future) : _future = future;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(PostgrestList) onValue, {
    Function? onError,
  }) {
    return _future.then(onValue, onError: onError);
  }

  @override
  Future<PostgrestList> catchError(
    Function onError, {
    bool Function(Object)? test,
  }) {
    return _future.catchError(onError, test: test);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockSession mockSession;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockSession = MockSession();

    registerFallbackValue(MockSupabaseQueryBuilder());
    registerFallbackValue(MockPostgrestFilterBuilder());
    registerFallbackValue(
        FakeTransform(Future.value(PostgrestList.from([]))));
  });

  List<Override> supabaseOverride() =>
      [supabaseClientProvider.overrideWithValue(mockClient)];

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
        ...supabaseOverride(),
        adminUserOverride(),
      ];

  void stubQuery(List<Map<String, dynamic>> data) {
    final queryBuilder = MockSupabaseQueryBuilder();
    final filterBuilder = MockPostgrestFilterBuilder();
    final transform = FakeTransform(
        Future.value(PostgrestList.from(data)));

    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentSession).thenReturn(mockSession);
    when(() => mockClient.from('profiles')).thenAnswer((_) => queryBuilder);
    when(() => queryBuilder.select(any())).thenAnswer((_) => filterBuilder);
    when(() => filterBuilder.order('display_name'))
        .thenAnswer((_) => transform);
  }

  void stubQueryHanging() {
    final queryBuilder = MockSupabaseQueryBuilder();
    final filterBuilder = MockPostgrestFilterBuilder();
    final completer = Completer<PostgrestList>();
    final transform = FakeTransform(completer.future);

    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentSession).thenReturn(mockSession);
    when(() => mockClient.from('profiles')).thenAnswer((_) => queryBuilder);
    when(() => queryBuilder.select(any())).thenAnswer((_) => filterBuilder);
    when(() => filterBuilder.order('display_name'))
        .thenAnswer((_) => transform);
  }

  group('AdminUsersScreen', () {
    testWidgets('muestra ShimmerSkeleton durante loading', (tester) async {
      stubQueryHanging();

      await pumpApp(
        tester,
        child: const AdminUsersScreen(),
        overrides: allOverrides(),
        locale: const Locale('es'),
      );

      final shimmerFinder = find.byWidgetPredicate(
        (w) => w.runtimeType.toString().contains('Shimmer'),
      );
      expect(shimmerFinder, findsWidgets);

      addTearDown(() => unmount(tester));
    });

    testWidgets('muestra EmptyState cuando no hay usuarios', (tester) async {
      stubQuery([]);

      await pumpApp(
        tester,
        child: const AdminUsersScreen(),
        overrides: allOverrides(),
        locale: const Locale('es'),
      );

      await tester.pump();
      await tester.pump();

      expect(find.text('Sin conexión'), findsOneWidget);
      expect(find.text('No se encontraron usuarios'), findsOneWidget);

      addTearDown(() => unmount(tester));
    });

    testWidgets('muestra ErrorCard con botón retry cuando hay error',
        (tester) async {
      when(() => mockClient.auth).thenThrow(
          const AuthException('auth error'));

      await pumpApp(
        tester,
        child: const AdminUsersScreen(),
        overrides: allOverrides(),
        locale: const Locale('es'),
      );

      await tester.pump();
      await tester.pump();

      expect(find.textContaining('Error al cargar usuarios'), findsOneWidget);
      expect(find.text('REINTENTAR'), findsOneWidget);

      addTearDown(() => unmount(tester));
    });

    testWidgets('chip de filtro "Todos" aparece', (tester) async {
      stubQuery([
        {
          'id': '1',
          'display_name': 'Admin User',
          'email': 'admin@test.com',
          'role': 'admin',
          'reputation_score': 100,
          'reputation_level': 'trusted',
        },
      ]);

      await pumpApp(
        tester,
        child: const AdminUsersScreen(),
        overrides: allOverrides(),
        locale: const Locale('es'),
      );

      await tester.pump();
      await tester.pump();

      expect(find.text('Todos'), findsOneWidget);

      addTearDown(() => unmount(tester));
    });

    testWidgets('RoleGate protege la pantalla para usuario no-admin',
        (tester) async {
      const nonAdminUser = UserModel(
        id: 'u1',
        name: 'Passenger',
        email: 'p@test.com',
        role: UserRole.passenger,
      );

      stubQuery([]);

      await pumpApp(
        tester,
        child: const AdminUsersScreen(),
        overrides: [
          ...allOverrides(),
          currentUserProvider.overrideWithValue(nonAdminUser),
        ],
        locale: const Locale('es'),
      );

      await tester.pump();

      expect(find.text('Gestión de usuarios'), findsNothing);
      expect(find.byType(TextFormField), findsNothing);

      addTearDown(() => unmount(tester));
    });
  });
}
