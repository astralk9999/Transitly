import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/theme/backgrounds/app_background.dart';
import '../../core/theme/backgrounds/prefab_backgrounds.dart';
import '../../core/theme/palettes/app_palette.dart';
import '../../core/theme/palettes/custom_colors.dart';
import '../../core/theme/palettes/prefab_palettes.dart';
import '../../core/theme/high_contrast_theme.dart';
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

  String? _authUserId;
  String _paletteId = 'default';
  Brightness _brightness = Brightness.dark;
  String _backgroundId = 'smoke';
  bool _backgroundEnabled = true;
  double _backgroundOpacity = 1.0;
  double _fontScale = 1.0;
  ColorBlindMode _colorBlindMode = ColorBlindMode.none;
  bool _dyslexiaFontEnabled = false;
  bool _reduceMotion = false;
  bool _highContrast = false;
  String _mapStyle = 'streets';
  bool _notifIncidentResolved = true;
  bool _notifRoutePromoted = true;
  bool _notifBusApproaching = true;
  bool _notifFeatureRequestReplied = true;
  bool _quietHoursEnabled = false;
  String? _quietHoursStart;
  String? _quietHoursEnd;

  Map<String, Color> _customColors = <String, Color>{};
  static const _customPaletteId = 'custom';

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
  bool get highContrast => _highContrast;
  String get mapStyle => _mapStyle;

  bool get notifIncidentResolved => _notifIncidentResolved;
  bool get notifRoutePromoted => _notifRoutePromoted;
  bool get notifBusApproaching => _notifBusApproaching;
  bool get notifFeatureRequestReplied => _notifFeatureRequestReplied;
  bool get quietHoursEnabled => _quietHoursEnabled;
  String? get quietHoursStart => _quietHoursStart;
  String? get quietHoursEnd => _quietHoursEnd;

  Map<String, Color> get customColors => Map.unmodifiable(_customColors);

  bool get isCustomPalette => _paletteId == _customPaletteId;

  AppPalette get palette {
    if (_paletteId == _customPaletteId && _customColors.isNotEmpty) {
      return AppPalette(
        id: _customPaletteId,
        name: 'Custom',
        isDark: true,
        scheme: TransitCustomColors(
          primary: _customColors['primary'] ?? const Color(0xFF977DDF),
          secondary: _customColors['secondary'] ?? const Color(0xFF6C63FF),
          bgRoot: _customColors['bgRoot'] ?? const Color(0xFF08081A),
          bgSurface: _customColors['bgSurface'] ?? const Color(0xFF10102A),
          textHi: _customColors['textHi'] ?? const Color(0xFFF0F0FA),
        ),
      );
    }
    return paletteFromId(_paletteId);
  }

  AppBackground get background => backgroundFromId(_backgroundId);

  // ── Setters ──────────────────────────────────────────────

  set paletteId(String value) {
    if (_paletteId == value) return;
    _paletteId = value;
    _brightness = palette.brightness;
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

  set highContrast(bool value) {
    if (_highContrast == value) return;
    _highContrast = value;
    notifyListeners();
    unawaited(_persist());
  }

  set mapStyle(String value) {
    if (_mapStyle == value) return;
    _mapStyle = value;
    notifyListeners();
    unawaited(_persist());
  }

  set notifIncidentResolved(bool value) {
    if (_notifIncidentResolved == value) return;
    _notifIncidentResolved = value;
    notifyListeners();
    unawaited(_persist());
  }

  set notifRoutePromoted(bool value) {
    if (_notifRoutePromoted == value) return;
    _notifRoutePromoted = value;
    notifyListeners();
    unawaited(_persist());
  }

  set notifBusApproaching(bool value) {
    if (_notifBusApproaching == value) return;
    _notifBusApproaching = value;
    notifyListeners();
    unawaited(_persist());
  }

  set notifFeatureRequestReplied(bool value) {
    if (_notifFeatureRequestReplied == value) return;
    _notifFeatureRequestReplied = value;
    notifyListeners();
    unawaited(_persist());
  }

  set quietHoursEnabled(bool value) {
    if (_quietHoursEnabled == value) return;
    _quietHoursEnabled = value;
    notifyListeners();
    unawaited(_persist());
  }

  set quietHoursStart(String? value) {
    if (_quietHoursStart == value) return;
    _quietHoursStart = value;
    notifyListeners();
    unawaited(_persist());
  }

  set quietHoursEnd(String? value) {
    if (_quietHoursEnd == value) return;
    _quietHoursEnd = value;
    notifyListeners();
    unawaited(_persist());
  }

  void setCustomPalette(Map<String, Color> colors) {
    _customColors = Map.of(colors);
    _paletteId = _customPaletteId;
    _brightness = Brightness.dark;
    notifyListeners();
    unawaited(_persist());
  }

  // ── Theme building ───────────────────────────────────────

  ThemeData buildTheme(Brightness brightness) {
    final base = buildTransitTheme(
      palette.scheme,
      fontScale: _fontScale,
      dyslexiaFontEnabled: _dyslexiaFontEnabled,
    );
    if (_highContrast) {
      return HighContrastTheme.apply(base, palette.scheme);
    }
    return base;
  }

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
    _highContrast = prefs.highContrast;
    _mapStyle = prefs.mapStyle;
    _notifIncidentResolved = prefs.notifIncidentResolved;
    _notifRoutePromoted = prefs.notifRoutePromoted;
    _notifBusApproaching = prefs.notifBusApproaching;
    _notifFeatureRequestReplied = prefs.notifFeatureRequestReplied;
    _quietHoursEnabled = prefs.quietHoursEnabled;
    _quietHoursStart = prefs.quietHoursStart;
    _quietHoursEnd = prefs.quietHoursEnd;
    _customColors = _parseCustomColors(prefs.customColors);
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
        highContrast: _highContrast,
        mapStyle: _mapStyle,
        notifIncidentResolved: _notifIncidentResolved,
        notifRoutePromoted: _notifRoutePromoted,
        notifBusApproaching: _notifBusApproaching,
        notifFeatureRequestReplied: _notifFeatureRequestReplied,
        quietHoursEnabled: _quietHoursEnabled,
        quietHoursStart: _quietHoursStart,
        quietHoursEnd: _quietHoursEnd,
        customColors: _customColors.isEmpty
            ? null
            : _customColors.map((k, v) => MapEntry(k, _colorToHex(v))),
      );

  /// Load saved preferences. Called once at startup.
  Future<void> init({required String userId}) async {
    if (_initialized) return;

    _authUserId = userId;

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
        _highContrast = data['highContrast'] as bool? ?? false;
        _mapStyle = data['mapStyle'] as String? ?? 'streets';
        _notifIncidentResolved = data['notifIncidentResolved'] as bool? ?? true;
        _notifRoutePromoted = data['notifRoutePromoted'] as bool? ?? true;
        _notifBusApproaching = data['notifBusApproaching'] as bool? ?? true;
        _notifFeatureRequestReplied = data['notifFeatureRequestReplied'] as bool? ?? true;
        _quietHoursEnabled = data['quietHoursEnabled'] as bool? ?? false;
        _quietHoursStart = data['quietHoursStart'] as String?;
        _quietHoursEnd = data['quietHoursEnd'] as String?;
        final rawCustom = data['customColors'] as Map<dynamic, dynamic>?;
        if (rawCustom != null) {
          _customColors = <String, Color>{};
          for (final entry in rawCustom.entries) {
            final c = _parseHexColor(entry.value.toString());
            if (c != null) _customColors[entry.key.toString()] = c;
          }
        }
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
      final uid = _authUserId;
      if (uid == null) return;
      await _prefsRepo.update(toPreferences(uid));
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
        'highContrast': _highContrast,
        'mapStyle': _mapStyle,
        'notifIncidentResolved': _notifIncidentResolved,
        'notifRoutePromoted': _notifRoutePromoted,
        'notifBusApproaching': _notifBusApproaching,
        'notifFeatureRequestReplied': _notifFeatureRequestReplied,
        'quietHoursEnabled': _quietHoursEnabled,
        'quietHoursStart': _quietHoursStart,
        'quietHoursEnd': _quietHoursEnd,
        'customColors': _customColors.map((k, v) => MapEntry(k, _colorToHex(v))),
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

  Map<String, Color> _parseCustomColors(Map<String, String>? raw) {
    if (raw == null) return <String, Color>{};
    final result = <String, Color>{};
    for (final entry in raw.entries) {
      final c = _parseHexColor(entry.value);
      if (c != null) result[entry.key] = c;
    }
    return result;
  }

  Color? _parseHexColor(String hex) {
    try {
      final s = hex.replaceFirst('#', '');
      if (s.length == 6) {
        return Color(int.parse('FF$s', radix: 16));
      }
      if (s.length == 8) {
        return Color(int.parse(s, radix: 16));
      }
      return null;
    } catch (e) {
      AppLogger.warn(_logTag, 'parseHexColor failed', e);
      return null;
    }
  }

  String _colorToHex(Color c) {
    final r = ((c.r * 255).round() & 0xff).toRadixString(16).padLeft(2, '0');
    final g = ((c.g * 255).round() & 0xff).toRadixString(16).padLeft(2, '0');
    final b = ((c.b * 255).round() & 0xff).toRadixString(16).padLeft(2, '0');
    final a = ((c.a * 255).round() & 0xff).toRadixString(16).padLeft(2, '0');
    return '$a$r$g$b';
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

  ref.onDispose(notifier.dispose);

  return notifier;
});
