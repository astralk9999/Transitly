import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/mock/mock_data_service.dart';
import 'package:transitly/shared/providers/user_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDataService data;

  setUpAll(() async {
    data = await MockDataService.init();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(overrides: [
      mockDataServiceProvider.overrideWithValue(data),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  test('currentUserProvider returns a non-driver by default', () {
    final container = makeContainer();
    expect(container.read(isDriverModeProvider), isFalse);
    final user = container.read(currentUserProvider);
    expect(user.isDriver, isFalse);
  });

  test('toggling isDriverModeProvider switches to a driver user', () {
    final container = makeContainer();
    container.read(isDriverModeProvider.notifier).state = true;
    final user = container.read(currentUserProvider);
    expect(user.isDriver, isTrue);
  });
}
