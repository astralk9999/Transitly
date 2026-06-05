import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:transitly/features/driver/route_editor/editor_controller.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('hive_editor_ctrl_test_');
    Hive.init(dir.path);
  });

  test('addScheduleTime accepts valid HH:MM and keeps list sorted', () {
    final c = RouteEditorController();
    addTearDown(c.dispose);

    c.addScheduleTime('weekday', '08:00');
    c.addScheduleTime('weekday', '07:30');
    c.addScheduleTime('weekday', '12:15');

    expect(c.schedules['weekday'], equals(['07:30', '08:00', '12:15']));
  });

  test('addScheduleTime rejects malformed input without throwing', () {
    final c = RouteEditorController();
    addTearDown(c.dispose);

    c.addScheduleTime('weekday', 'abc');
    c.addScheduleTime('weekday', '25:00');
    c.addScheduleTime('weekday', '08:60');
    c.addScheduleTime('weekday', '');
    c.addScheduleTime('weekday', '8:5');

    expect(c.schedules['weekday'], isEmpty);
  });

  test('addScheduleTime ignores duplicates', () {
    final c = RouteEditorController();
    addTearDown(c.dispose);

    c.addScheduleTime('weekday', '09:00');
    c.addScheduleTime('weekday', '09:00');
    c.addScheduleTime('weekday', '09:00');

    expect(c.schedules['weekday'], equals(['09:00']));
  });

  test('addScheduleTime does NOT notify listeners on noop (invalid/duplicate)',
      () {
    final c = RouteEditorController();
    addTearDown(c.dispose);
    var notifications = 0;
    c.addListener(() => notifications++);

    c.addScheduleTime('weekday', '08:00');
    expect(notifications, 1);

    c.addScheduleTime('weekday', '08:00');
    expect(notifications, 1);

    c.addScheduleTime('weekday', 'xx');
    expect(notifications, 1);
  });
}
