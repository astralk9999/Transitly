import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:transitly/data/incident/domain/incident_repository.dart';
import 'package:transitly/data/incident/incident_repository_provider.dart';
import 'package:transitly/data/route_feedback/domain/route_feedback_repository.dart';
import 'package:transitly/data/route_feedback/route_feedback_repository_provider.dart';
import 'package:transitly/data/route_suggestion/domain/route_suggestion_repository.dart';
import 'package:transitly/data/route_suggestion/route_suggestion_repository_provider.dart';
import 'package:transitly/features/management/manager_inbox_screen.dart';
import 'package:transitly/shared/models/enums.dart';
import 'package:transitly/shared/models/incident_model.dart';
import 'package:transitly/shared/models/route_feedback_model.dart';
import 'package:transitly/shared/models/route_suggestion_model.dart';

import '../../helpers/pump_app.dart';

class MockRouteFeedbackRepo extends Mock
    implements RouteFeedbackRepository {}

class MockIncidentRepo extends Mock implements IncidentRepository {}

class MockRouteSuggestionRepo extends Mock
    implements RouteSuggestionRepository {}

RouteFeedbackModel _openFeedback(String id) => RouteFeedbackModel(
      id: id,
      userId: 'user-1',
      routeId: 'L1',
      feedbackType: FeedbackType.scheduleOutdated,
      description: 'Feedback $id',
      status: FeedbackStatus.submitted,
      createdAt: DateTime(2026, 1, 1),
    );

RouteSuggestionModel _suggestion(String id) => RouteSuggestionModel(
      id: id,
      suggestedBy: 'user-1',
      originText: 'A',
      destinationText: 'B',
      status: SuggestionStatus.idea,
      createdAt: DateTime(2026, 1, 1),
    );

List<Override> _emptyOverrides({
  required MockRouteFeedbackRepo feedbackRepo,
  required MockRouteSuggestionRepo suggestionRepo,
  required MockIncidentRepo incidentRepo,
}) =>
    [
      routeFeedbackRepositoryProvider.overrideWithValue(feedbackRepo),
      routeSuggestionRepositoryProvider.overrideWithValue(suggestionRepo),
      incidentRepositoryProvider.overrideWithValue(incidentRepo),
    ];

List<Override> _dataOverrides({
  required MockRouteFeedbackRepo feedbackRepo,
  required MockRouteSuggestionRepo suggestionRepo,
  required MockIncidentRepo incidentRepo,
}) =>
    [
      routeFeedbackRepositoryProvider.overrideWithValue(feedbackRepo),
      routeSuggestionRepositoryProvider.overrideWithValue(suggestionRepo),
      incidentRepositoryProvider.overrideWithValue(incidentRepo),
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockRouteFeedbackRepo feedbackRepo;
  late MockRouteSuggestionRepo suggestionRepo;
  late MockIncidentRepo incidentRepo;

  setUp(() {
    feedbackRepo = MockRouteFeedbackRepo();
    suggestionRepo = MockRouteSuggestionRepo();
    incidentRepo = MockIncidentRepo();
  });

  group('ManagerInboxScreen', () {
    testWidgets('pantalla renderiza 3 tabs (Feedback, Sugerencias, Resueltos)',
        (tester) async {
      when(() => feedbackRepo.listAll()).thenAnswer(
        (_) async => [_openFeedback('fb-1')],
      );
      when(() => suggestionRepo.list()).thenAnswer(
        (_) async => [_suggestion('sug-1')],
      );
      when(() => incidentRepo.listAll()).thenAnswer((_) async => []);

      await pumpApp(
        tester,
        child: const ManagerInboxScreen(),
        overrides: _dataOverrides(
          feedbackRepo: feedbackRepo,
          suggestionRepo: suggestionRepo,
          incidentRepo: incidentRepo,
        ),
        locale: const Locale('es'),
      );

      await tester.pump();
      await tester.pump();

      expect(find.text('Feedback'), findsOneWidget);
      expect(find.text('Sugerencias'), findsOneWidget);
      expect(find.text('Resueltos'), findsOneWidget);

      addTearDown(() => unmount(tester));
    });

    testWidgets('muestra EmptyState cuando no hay datos', (tester) async {
      when(() => feedbackRepo.listAll()).thenAnswer((_) async => []);
      when(() => suggestionRepo.list()).thenAnswer((_) async => []);
      when(() => incidentRepo.listAll()).thenAnswer((_) async => []);

      await pumpApp(
        tester,
        child: const ManagerInboxScreen(),
        overrides: _emptyOverrides(
          feedbackRepo: feedbackRepo,
          suggestionRepo: suggestionRepo,
          incidentRepo: incidentRepo,
        ),
        locale: const Locale('es'),
      );

      await tester.pump();
      await tester.pump();

      expect(find.text('Feedback'), findsOneWidget);
      expect(find.text('Sugerencias'), findsOneWidget);
      expect(find.text('Resueltos'), findsOneWidget);

      expect(find.text('No hay feedback pendiente'), findsOneWidget);

      addTearDown(() => unmount(tester));
    });

    testWidgets('loading state (CircularProgressIndicator)', (tester) async {
      final feedbackCompleter = Completer<List<RouteFeedbackModel>>();
      final suggestionCompleter = Completer<List<RouteSuggestionModel>>();
      final incidentCompleter = Completer<List<IncidentModel>>();

      when(() => feedbackRepo.listAll())
          .thenAnswer((_) => feedbackCompleter.future);
      when(() => suggestionRepo.list())
          .thenAnswer((_) => suggestionCompleter.future);
      when(() => incidentRepo.listAll())
          .thenAnswer((_) => incidentCompleter.future);

      await pumpApp(
        tester,
        child: const ManagerInboxScreen(),
        overrides: _emptyOverrides(
          feedbackRepo: feedbackRepo,
          suggestionRepo: suggestionRepo,
          incidentRepo: incidentRepo,
        ),
        locale: const Locale('es'),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      feedbackCompleter.complete([]);
      suggestionCompleter.complete([]);
      incidentCompleter.complete([]);

      addTearDown(() => unmount(tester));
    });
  });
}
