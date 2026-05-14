import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/theme/backgrounds/app_background.dart';
import '../../core/theme/backgrounds/prefab_backgrounds.dart';
import '../../core/theme/palettes/app_palette.dart';
import '../../core/theme/palettes/prefab_palettes.dart';
import '../../core/theme/transit_theme.dart';
import '../../core/utils/app_logger.dart';
import '../../data/user_preferences/domain/user_preferences_repository.dart';
import '../../data/user_preferences/user_preferences_repository_provider.dart';
import '../models/user_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeNotifier({required UserPreferencesRepository prefsRepo})
      : _prefsRepo = prefsRepo;

  final UserPreferencesRepository _prefsRepo;

  static const _logTag = 'ThemeNotifier';
  static const _guestBoxName = 'guest_theme_prefs';

  String _paletteId = 'default';
  Brightness _brightness = Brightness.dark;
  String _backgroundId = 'smoke';
  bool _backgroundEnabled = true;
  double _backgroundOpacity = 1.0;
  double _fontScale = 1.0;
  ColorBlindMode _colorBlindMode = ColorBlindMode.none;
  bool _dyslexiaFontEnabled = false;
  bool _reduceMotion = false;

  Box<Map<dynamic, dynamic>>? _guestBox;
  bool _initialized = false;

  // ── Getters ──────────────────────────────────────────────

  String get paletteId => _paletteId;
  Brightness get brightness => _brightness;
  String get backgroundId => _backgroundId;
  bool get backgroundEnabled => _backgroundEnabled;
  double get backgroundOpacity => _backgroundOpacity;
  double get fontScale => _fontScale;
  ColorBlindMode get colorBlindMode => _colorBlindMode;
  bool get dyslexiaFontEnabled => _dyslexiaFontEnabled;
  bool get reduceMotion => _reduceMotion;

  AppPalette get palette => paletteFromId(_paletteId);

  AppBackground get background => backgroundFromId(_backgroundId);

  // ── Setters ──────────────────────────────────────────────

  set paletteId(String value) {
    if (_paletteId == value) return;
    _paletteId = value;
    _brightness = paletteFromId(value).brightness;
    notifyListeners();
    unawaited(_persist());
  }

  set brightness(Brightness value) {
    if (_brightness == value) return;
    _brightness = value;
    notifyListeners();
    unawaited(_persist());
  }

  set backgroundId(String value) {
    if (_backgroundId == value) return;
    _backgroundId = value;
    notifyListeners();
    unawaited(_persist());
  }

  set backgroundEnabled(bool value) {
    if (_backgroundEnabled == value) return;
    _backgroundEnabled = value;
    notifyListeners();
    unawaited(_persist());
  }

  set backgroundOpacity(double value) {
    if (_backgroundOpacity == value) return;
    _backgroundOpacity = value;
    notifyListeners();
    unawaited(_persist());
  }

  set fontScale(double value) {
    if (_fontScale == value) return;
    _fontScale = value;
    notifyListeners();
    unawaited(_persist());
  }

  set colorBlindMode(ColorBlindMode value) {
    if (_colorBlindMode == value) return;
    _colorBlindMode = value;
    notifyListeners();
    unawaited(_persist());
  }

  set dyslexiaFontEnabled(bool value) {
    if (_dyslexiaFontEnabled == value) return;
    _dyslexiaFontEnabled = value;
    notifyListeners();
    unawaited(_persist());
  }

  set reduceMotion(bool value) {
    if (_reduceMotion == value) return;
    _reduceMotion = value;
    notifyListeners();
    unawaited(_persist());
  }

  // ── Theme building ───────────────────────────────────────

  ThemeData buildTheme(Brightness brightness) =>
      buildTransitTheme(palette.scheme, fontScale: _fontScale);

  // ── Preferences I/O ─────────────────────────────────────

  void loadFromPreferences(UserPreferences prefs) {
    _paletteId = prefs.themePaletteId;
    _backgroundId = prefs.backgroundId;
    _backgroundEnabled = prefs.backgroundEnabled;
    _backgroundOpacity = prefs.backgroundOpacity;
    _fontScale = prefs.fontScale;
    _colorBlindMode = prefs.colorBlindMode;
    _dyslexiaFontEnabled = prefs.dyslexiaFontEnabled;
    _reduceMotion = prefs.reduceMotion;
    _initialized = true;
    notifyListeners();
  }

  UserPreferences toPreferences(String userId) => UserPreferences(
        userId: userId,
        themePaletteId: _paletteId,
        backgroundId: _backgroundId,
        backgroundEnabled: _backgroundEnabled,
        backgroundOpacity: _backgroundOpacity,
        fontScale: _fontScale,
        colorBlindMode: _colorBlindMode,
        dyslexiaFontEnabled: _dyslexiaFontEnabled,
        reduceMotion: _reduceMotion,
      );

  /// Load saved preferences. Called once at startup.
  Future<void> init({required String userId}) async {
    if (_initialized) return;

    try {
      final prefs = await _prefsRepo.getMine();
      loadFromPreferences(prefs);
      AppLogger.info(_logTag, 'loaded auth user prefs (userId=$userId, palette=$_paletteId)');
    } on UserPreferencesRepositoryException {
      await _loadGuestPrefs();
      AppLogger.info(_logTag, 'auth prefs unavailable; loaded guest fallback (palette=$_paletteId)');
    }
  }

  /// Reload after auth state change.
  Future<void> reloadFromAuth({required String userId}) async {
    _initialized = false;
    await init(userId: userId);
  }

  /// Load prefs for guest mode.
  Future<void> loadGuest() async {
    _initialized = false;
    await _loadGuestPrefs();
  }

  Future<void> _loadGuestPrefs() async {
    try {
      _guestBox ??= await _openGuestBox();
      final data = _guestBox!.get('prefs');
      if (data != null) {
        _paletteId = data['paletteId'] as String? ?? 'default';
        _backgroundId = data['backgroundId'] as String? ?? 'smoke';
        _backgroundEnabled = data['backgroundEnabled'] as bool? ?? true;
        _backgroundOpacity = (data['backgroundOpacity'] as num?)?.toDouble() ?? 1.0;
        _fontScale = (data['fontScale'] as num?)?.toDouble() ?? 1.0;
        _colorBlindMode = _parseColorBlindMode(data['colorBlindMode'] as String?);
        _dyslexiaFontEnabled = data['dyslexiaFontEnabled'] as bool? ?? false;
        _reduceMotion = data['reduceMotion'] as bool? ?? false;
      }
    } catch (e) {
      AppLogger.warn(_logTag, 'guest prefs load failed; using defaults', e);
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    if (!_initialized) return;

    try {
      await _prefsRepo.update(toPreferences('_current_'));
      return;
    } on UserPreferencesRepositoryException {
      // Fall through to guest persistence
    }

    try {
      _guestBox ??= await _openGuestBox();
      await _guestBox!.put('prefs', <String, dynamic>{
        'paletteId': _paletteId,
        'backgroundId': _backgroundId,
        'backgroundEnabled': _backgroundEnabled,
        'backgroundOpacity': _backgroundOpacity,
        'fontScale': _fontScale,
        'colorBlindMode': _colorBlindMode.name,
        'dyslexiaFontEnabled': _dyslexiaFontEnabled,
        'reduceMotion': _reduceMotion,
      });
    } catch (e) {
      AppLogger.warn(_logTag, 'guest prefs persist failed', e);
    }
  }

  ColorBlindMode _parseColorBlindMode(String? value) {
    if (value == null) return ColorBlindMode.none;
    return ColorBlindMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ColorBlindMode.none,
    );
  }

  static Future<Box<Map<dynamic, dynamic>>> _openGuestBox() async {
    if (Hive.isBoxOpen(_guestBoxName)) {
      return Hive.box<Map<dynamic, dynamic>>(_guestBoxName);
    }
    return Hive.openBox<Map<dynamic, dynamic>>(_guestBoxName);
  }

  @override
  void dispose() {
    _guestBox = null;
    super.dispose();
  }
}

final themeNotifierProvider = ChangeNotifierProvider<ThemeNotifier>((ref) {
  final repo = ref.watch(userPreferencesRepositoryProvider);
  final notifier = ThemeNotifier(prefsRepo: repo);

  ref.onDispose(() => notifier.dispose());

  return notifier;
});
