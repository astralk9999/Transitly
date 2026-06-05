import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

enum WidgetSize { small, medium, large }

enum WidgetTheme { auto, light, dark, brand }

class WidgetAppearanceConfig {
  const WidgetAppearanceConfig({
    this.size = WidgetSize.medium,
    this.theme = WidgetTheme.auto,
    this.refreshMinutes = 60,
  });

  final WidgetSize size;
  final WidgetTheme theme;
  final int refreshMinutes;

  WidgetAppearanceConfig copyWith({
    WidgetSize? size,
    WidgetTheme? theme,
    int? refreshMinutes,
  }) {
    return WidgetAppearanceConfig(
      size: size ?? this.size,
      theme: theme ?? this.theme,
      refreshMinutes: refreshMinutes ?? this.refreshMinutes,
    );
  }
}

class WidgetAppearanceConfigNotifier
    extends StateNotifier<WidgetAppearanceConfig> {
  WidgetAppearanceConfigNotifier() : super(const WidgetAppearanceConfig()) {
    _loadFuture = _load();
  }

  static const _boxName = 'widget_appearance_config';
  static const _kSize = 'size';
  static const _kTheme = 'theme';
  static const _kRefresh = 'refreshMinutes';
  static const _allowedRefresh = <int>[15, 30, 60];

  late final Future<void> _loadFuture;
  Future<void> get ready => _loadFuture;

  Future<void> _load() async {
    final box = await Hive.openBox<dynamic>(_boxName);
    final size = _parseSize(box.get(_kSize) as String?);
    final theme = _parseTheme(box.get(_kTheme) as String?);
    final refresh = box.get(_kRefresh) as int?;
    state = WidgetAppearanceConfig(
      size: size,
      theme: theme,
      refreshMinutes:
          (refresh != null && _allowedRefresh.contains(refresh))
              ? refresh
              : 60,
    );
  }

  Future<void> setSize(WidgetSize value) async {
    state = state.copyWith(size: value);
    final box = await Hive.openBox<dynamic>(_boxName);
    await box.put(_kSize, value.name);
  }

  Future<void> setTheme(WidgetTheme value) async {
    state = state.copyWith(theme: value);
    final box = await Hive.openBox<dynamic>(_boxName);
    await box.put(_kTheme, value.name);
  }

  Future<void> setRefreshMinutes(int value) async {
    if (!_allowedRefresh.contains(value)) return;
    state = state.copyWith(refreshMinutes: value);
    final box = await Hive.openBox<dynamic>(_boxName);
    await box.put(_kRefresh, value);
  }

  WidgetSize _parseSize(String? raw) {
    if (raw == null) return WidgetSize.medium;
    return WidgetSize.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => WidgetSize.medium,
    );
  }

  WidgetTheme _parseTheme(String? raw) {
    if (raw == null) return WidgetTheme.auto;
    return WidgetTheme.values.firstWhere(
      (t) => t.name == raw,
      orElse: () => WidgetTheme.auto,
    );
  }
}

final widgetAppearanceConfigProvider = StateNotifierProvider<
    WidgetAppearanceConfigNotifier, WidgetAppearanceConfig>(
  (ref) => WidgetAppearanceConfigNotifier(),
);
