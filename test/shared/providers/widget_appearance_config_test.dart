import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:transitly/shared/providers/widget_appearance_config_provider.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('hive_widget_cfg_test_');
    Hive.init(dir.path);
  });

  setUp(() async {
    if (await Hive.boxExists('widget_appearance_config')) {
      await Hive.deleteBoxFromDisk('widget_appearance_config');
    }
  });

  test('default config: medium / auto / 60 min', () async {
    final n = WidgetAppearanceConfigNotifier();
    await n.ready;
    expect(n.state.size, WidgetSize.medium);
    expect(n.state.theme, WidgetTheme.auto);
    expect(n.state.refreshMinutes, 60);
  });

  test('setSize updates state and persists', () async {
    final n = WidgetAppearanceConfigNotifier();
    await n.ready;
    await n.setSize(WidgetSize.large);
    expect(n.state.size, WidgetSize.large);

    final n2 = WidgetAppearanceConfigNotifier();
    await n2.ready;
    expect(n2.state.size, WidgetSize.large);
  });

  test('setTheme + setRefreshMinutes both persist independently', () async {
    final n = WidgetAppearanceConfigNotifier();
    await n.ready;
    await n.setTheme(WidgetTheme.dark);
    await n.setRefreshMinutes(15);
    expect(n.state.theme, WidgetTheme.dark);
    expect(n.state.refreshMinutes, 15);

    final n2 = WidgetAppearanceConfigNotifier();
    await n2.ready;
    expect(n2.state.theme, WidgetTheme.dark);
    expect(n2.state.refreshMinutes, 15);
  });

  test('setRefreshMinutes only accepts 15/30/60 (otherwise noop)', () async {
    final n = WidgetAppearanceConfigNotifier();
    await n.ready;
    await n.setRefreshMinutes(60);
    await n.setRefreshMinutes(45);
    expect(n.state.refreshMinutes, 60);
  });
}
