import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_notifier.dart';

/// Lee el themeMode del ThemeNotifier (que persiste en Hive).
///
/// Para cambiarlo no uses `.notifier.state =` — usa
/// `ref.read(themeNotifierProvider).themeMode = value`.
final themeModeProvider = Provider<ThemeMode>((ref) {
  final notifier = ref.watch(themeNotifierProvider);
  return notifier.themeMode;
});
