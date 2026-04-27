import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:transitly/core/theme/transit_theme.dart';
import 'package:transitly/data/mock/mock_data_service.dart';
import 'package:transitly/l10n/generated/app_localizations.dart';

/// Pump a bare Material shell around [child] with a ProviderScope.
///
/// Optional [overrides] lets a test stub providers (mockData, NFC, etc.).
/// Optional [themeDark] switches between light and dark theme.
Future<void> pumpApp(
  WidgetTester tester, {
  required Widget child,
  List<Override> overrides = const [],
  bool themeDark = true,
  bool disableAnimations = true,
  Locale locale = const Locale('es'),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MediaQuery(
        // disableAnimations=true stops StaggerList et al. from scheduling
        // uncancelable `Future.delayed(...)` work that would trip the test
        // binding's pending-timer assertion.
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildTransitTheme(themeDark),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      ),
    ),
  );
}

/// Unmount the widget tree so tickers / open streams finalize before the
/// binding asserts no pending work.
Future<void> unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

/// Initialize [MockDataService] by loading the real asset bundle.
/// Requires `TestWidgetsFlutterBinding.ensureInitialized()` to have been
/// called and the host package to have `assets/mock/` declared.
Future<MockDataService> loadMockData() => MockDataService.init();

/// Convenience override that provides an already-initialized [MockDataService].
Override mockDataOverride(MockDataService svc) =>
    mockDataServiceProvider.overrideWithValue(svc);
