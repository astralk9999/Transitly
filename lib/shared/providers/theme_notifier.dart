import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/utils/boot_canary.dart';

import '../../core/theme/backgrounds/app_background.dart';
import '../../core/theme/backgrounds/prefab_backgrounds.dart';
import '../../core/theme/palettes/app_palette.dart';
import '../../core/theme/palettes/custom_colors.dart';
import '../../core/theme/palettes/prefab_palettes.dart';
import '../../core/theme/high_contrast_theme.dart';
import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_theme.dart';
import '../../core/utils/app_logger.dart';
import '../../data/user_preferences/domain/user_preferences_repository.dart';
import '../../data/user_preferences/user_preferences_repository_provider.dart';
import '../models/named_custom_palette.dart';
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
  String _backgroundId = 'shaders/smoke.frag';
  bool _backgroundEnabled = true;
  double _backgroundOpacity = 1.0;
  double _fontScale = 1.0;
  ColorBlindMode _colorBlindMode = ColorBlindMode.none;
  bool _dyslexiaFontEnabled = false;
  bool _reduceMotion = false;
  bool _highContrast = false;
  bool _hcPreserveAccent = false;
  String _mapStyle = 'streets';
  ThemeMode _themeMode = ThemeMode.system;
  bool _notifIncidentResolved = true;
  bool _notifRoutePromoted = true;
  bool _notifBusApproaching = true;
  bool _notifFeatureRequestReplied = true;
  bool _quietHoursEnabled = false;
  String? _quietHoursStart;
  String? _quietHoursEnd;
  bool _notifZoneAlerts = true;

  // Sub P2-#54: configuración de aviso "bus llegando".
  int _busApproachingMinutesAhead = 10;
  String _busApproachingActiveStart = '07:00';
  String _busApproachingActiveEnd = '22:00';

  Map<String, Color> _customColors = <String, Color>{};
  static const _customPaletteId = 'custom';

  List<NamedCustomPalette> _customPalettes = [];
  static const _customPalettesBoxName = 'custom_palettes';

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
  bool get hcPreserveAccent => _hcPreserveAccent;
  String get mapStyle => _mapStyle;
  ThemeMode get themeMode => _themeMode;

  bool get notifIncidentResolved => _notifIncidentResolved;
  bool get notifRoutePromoted => _notifRoutePromoted;
  bool get notifBusApproaching => _notifBusApproaching;
  bool get notifFeatureRequestReplied => _notifFeatureRequestReplied;
  bool get quietHoursEnabled => _quietHoursEnabled;
  String? get quietHoursStart => _quietHoursStart;
  String? get quietHoursEnd => _quietHoursEnd;
  bool get notifZoneAlerts => _notifZoneAlerts;

  int get busApproachingMinutesAhead => _busApproachingMinutesAhead;
  String get busApproachingActiveStart => _busApproachingActiveStart;
  String get busApproachingActiveEnd => _busApproachingActiveEnd;

  Map<String, Color> get customColors => Map.unmodifiable(_customColors);

  bool get isCustomPalette => _paletteId == _customPaletteId;

  List<NamedCustomPalette> get customPalettes =>
      List.unmodifiable(_customPalettes);

  AppPalette get palette {
    if (_paletteId == _customPaletteId && _customColors.isNotEmpty) {
      final scheme = TransitCustomColors(
        primary: _customColors['primary'] ?? const Color(0xFF977DDF),
        secondary: _customColors['secondary'] ?? const Color(0xFF6C63FF),
        bgRoot: _customColors['bgRoot'] ?? const Color(0xFF08081A),
        bgSurface: _customColors['bgSurface'] ?? const Color(0xFF10102A),
        textHi: _customColors['textHi'] ?? const Color(0xFFF0F0FA),
      );
      return AppPalette(
        id: _customPaletteId,
        name: 'Custom',
        isDark: true,
        scheme: scheme,
        darkScheme: scheme,
      );
    }
    if (_paletteId.startsWith('custom-')) {
      final idx = _customPalettes.indexWhere((p) => p.id == _paletteId);
      if (idx >= 0) {
        final cp = _customPalettes[idx];
        final scheme = TransitCustomColors(
          primary: cp.colors['primary'] ?? const Color(0xFF977DDF),
          secondary: cp.colors['secondary'] ?? const Color(0xFF6C63FF),
          bgRoot: cp.colors['bgRoot'] ?? const Color(0xFF08081A),
          bgSurface: cp.colors['bgSurface'] ?? const Color(0xFF10102A),
          textHi: cp.colors['textHi'] ?? const Color(0xFFF0F0FA),
        );
        return AppPalette(
          id: cp.id,
          name: cp.name,
          isDark: true,
          scheme: scheme,
          darkScheme: scheme,
        );
      }
    }
    return paletteFromId(_paletteId);
  }

  AppBackground get background => backgroundFromId(_backgroundId);

  String get visualKey {
    final custom = _customColors.entries
        .map((e) => '${e.key}:${_colorToHex(e.value)}')
        .toList()
      ..sort();
    final cpKeys = _customPalettes.map((p) => 'cp:${p.id}:${p.name}').toList()
      ..sort();
    return [
      _paletteId,
      _backgroundId,
      _backgroundEnabled,
      _backgroundOpacity.toStringAsFixed(2),
      _fontScale.toStringAsFixed(2),
      _colorBlindMode.name,
      _dyslexiaFontEnabled,
      _reduceMotion,
      _highContrast,
      _hcPreserveAccent,
      _mapStyle,
      ...cpKeys,
      ...custom,
    ].join('|');
  }

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
    BootCanary.markPendingSensitive('backgroundId');
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
    final clamped = value.clamp(0.85, 1.4);
    if (_fontScale == clamped) return;
    BootCanary.markPendingSensitive('fontScale');
    _fontScale = clamped;
    notifyListeners();
    unawaited(_persist());
  }

  set colorBlindMode(ColorBlindMode value) {
    if (_colorBlindMode == value) return;
    BootCanary.markPendingSensitive('colorBlindMode');
    _colorBlindMode = value;
    notifyListeners();
    unawaited(_persist());
  }

  set dyslexiaFontEnabled(bool value) {
    if (_dyslexiaFontEnabled == value) return;
    BootCanary.markPendingSensitive('dyslexiaFontEnabled');
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
    BootCanary.markPendingSensitive('highContrast');
    _highContrast = value;
    notifyListeners();
    unawaited(_persist());
  }

  set hcPreserveAccent(bool value) {
    if (_hcPreserveAccent == value) return;
    BootCanary.markPendingSensitive('hcPreserveAccent');
    _hcPreserveAccent = value;
    notifyListeners();
    unawaited(_persist());
  }

  set mapStyle(String value) {
    if (_mapStyle == value) return;
    _mapStyle = value;
    notifyListeners();
    unawaited(_persist());
  }

  set themeMode(ThemeMode value) {
    if (_themeMode == value) return;
    _themeMode = value;
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

  set notifZoneAlerts(bool value) {
    if (_notifZoneAlerts == value) return;
    _notifZoneAlerts = value;
    notifyListeners();
    unawaited(_persist());
  }

  set busApproachingMinutesAhead(int value) {
    final v = value.clamp(1, 60);
    if (_busApproachingMinutesAhead == v) return;
    _busApproachingMinutesAhead = v;
    notifyListeners();
    unawaited(_persist());
  }

  set busApproachingActiveStart(String value) {
    if (_busApproachingActiveStart == value) return;
    _busApproachingActiveStart = value;
    notifyListeners();
    unawaited(_persist());
  }

  set busApproachingActiveEnd(String value) {
    if (_busApproachingActiveEnd == value) return;
    _busApproachingActiveEnd = value;
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

  Future<void> saveCustomPalette(NamedCustomPalette p) async {
    final idx = _customPalettes.indexWhere((x) => x.id == p.id);
    if (idx >= 0) {
      _customPalettes[idx] = p;
    } else {
      _customPalettes.add(p);
    }
    notifyListeners();
    await _persistCustomPalettes();
  }

  Future<void> removeCustomPalette(String id) async {
    _customPalettes.removeWhere((x) => x.id == id);
    if (_paletteId == id) {
      _paletteId = 'default';
      _brightness = palette.brightness;
    }
    notifyListeners();
    await _persistCustomPalettes();
  }

  Future<void> _loadCustomPalettes() async {
    try {
      final box = await Hive.openBox(_customPalettesBoxName);
      final raw = box.get('list', defaultValue: <dynamic>[]) as List;
      _customPalettes = raw
          .map((e) => NamedCustomPalette.fromHive(e as Map<dynamic, dynamic>))
          .toList();

      if (_customColors.isNotEmpty) {
        _migrateLegacyCustomColors();
        _customColors = <String, Color>{};
      }
    } catch (e) {
      AppLogger.warn(_logTag, 'loadCustomPalettes failed', e);
    }
  }

  void _migrateLegacyCustomColors() {
    final legacyId = 'custom-legacy';
    if (_customPalettes.any((p) => p.id == legacyId)) return;
    _customPalettes.add(NamedCustomPalette(
      id: legacyId,
      name: 'Mi paleta',
      colors: Map.of(_customColors),
    ));
    if (_paletteId == _customPaletteId) {
      _paletteId = legacyId;
    }
    AppLogger.info(_logTag, 'migrated legacy customColors to named palette');
    unawaited(_persistCustomPalettes());
  }

  Future<void> _persistCustomPalettes() async {
    try {
      final box = await Hive.openBox(_customPalettesBoxName);
      await box.put('list',
          _customPalettes.map((p) => p.toHive()).toList());
    } catch (e) {
      AppLogger.warn(_logTag, 'persistCustomPalettes failed', e);
    }
  }

  // ── Theme building ───────────────────────────────────────

  ThemeData buildTheme(Brightness brightness) {
    final p = palette;
    final scheme = brightness == Brightness.dark
        ? (p.darkScheme ?? const TransitDarkColors())
        : (p.lightScheme ?? const TransitLightColors());
    final base = buildTransitTheme(
      scheme,
      fontScale: _fontScale,
      dyslexiaFontEnabled: _dyslexiaFontEnabled,
    );
    if (_highContrast) {
      try {
        return HighContrastTheme.apply(
          base,
          scheme,
          preserveAccent: _hcPreserveAccent,
          originalAccent: scheme.accent,
        );
      } catch (e, st) {
        AppLogger.error(_logTag, 'HighContrastTheme.apply failed, using base theme', e, st);
        return base;
      }
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
    _hcPreserveAccent = false;
    _mapStyle = prefs.mapStyle;
    _notifIncidentResolved = prefs.notifIncidentResolved;
    _notifRoutePromoted = prefs.notifRoutePromoted;
    _notifBusApproaching = prefs.notifBusApproaching;
    _notifFeatureRequestReplied = prefs.notifFeatureRequestReplied;
    _quietHoursEnabled = prefs.quietHoursEnabled;
    _quietHoursStart = prefs.quietHoursStart;
    _quietHoursEnd = prefs.quietHoursEnd;
    _notifZoneAlerts = true;
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
    await _loadCustomPalettes();

    try {
      final prefs = await _prefsRepo.getMine();
      loadFromPreferences(prefs);
      AppLogger.info(_logTag, 'loaded auth user prefs (userId=$userId, palette=$_paletteId)');
    } on UserPreferencesRepositoryException {
      await _loadGuestPrefs();
      AppLogger.info(_logTag, 'auth prefs unavailable; loaded guest fallback (palette=$_paletteId)');
    } catch (e, st) {
      AppLogger.error(_logTag, 'auth prefs corrupted, resetting to defaults', e, st);
      _resetToDefaults();
      _initialized = true;
      notifyListeners();
    }
  }

  /// Reload after auth state change.
  Future<void> reloadFromAuth({required String userId}) async {
    _initialized = false;
    await init(userId: userId);
  }

  /// Load prefs for guest mode.
  Future<void> loadGuest() async {
    if (_initialized && _paletteId != 'default') {
      AppLogger.info(_logTag, 'loadGuest: ya hidratado (palette=$_paletteId), skip');
      return;
    }
    _initialized = false;
    await _loadCustomPalettes();
    await _loadGuestPrefs();
  }

  Future<void> _loadGuestPrefs() async {
    try {
      _guestBox ??= await _openGuestBox();
      final data = _guestBox!.get('prefs');
      AppLogger.info(_logTag, 'guestBox hydrate: paletteId=${data?['paletteId']} bgId=${data?['backgroundId']} fontScale=${data?['fontScale']}');
      if (data != null) {
        _paletteId = _safeString(data['paletteId'], 'default');
        _backgroundId = _safeString(data['backgroundId'], 'shaders/smoke.frag');
        _backgroundEnabled = data['backgroundEnabled'] as bool? ?? true;
        _backgroundOpacity = _safeDouble(data['backgroundOpacity'], 1.0);
        _fontScale = _safeDouble(data['fontScale'], 1.0).clamp(0.8, 2.5);
        _colorBlindMode = _parseColorBlindMode(data['colorBlindMode'] as String?);
        _dyslexiaFontEnabled = _safeBool(data['dyslexiaFontEnabled'], false);
        _reduceMotion = _safeBool(data['reduceMotion'], false);
        _highContrast = _safeBool(data['highContrast'], false);
        _hcPreserveAccent = _safeBool(data['hcPreserveAccent'], false);
        _mapStyle = _safeString(data['mapStyle'], 'streets');
        _themeMode = _parseThemeMode(data['themeMode'] as String?);
        _notifIncidentResolved = _safeBool(data['notifIncidentResolved'], true);
        _notifRoutePromoted = _safeBool(data['notifRoutePromoted'], true);
        _notifBusApproaching = _safeBool(data['notifBusApproaching'], true);
        _notifFeatureRequestReplied = _safeBool(data['notifFeatureRequestReplied'], true);
        _quietHoursEnabled = _safeBool(data['quietHoursEnabled'], false);
        _quietHoursStart = data['quietHoursStart'] as String?;
        _quietHoursEnd = data['quietHoursEnd'] as String?;
        _notifZoneAlerts = _safeBool(data['notifZoneAlerts'], true);
        _busApproachingMinutesAhead =
            (data['busApproachingMinutesAhead'] as int?)?.clamp(1, 60) ?? 10;
        _busApproachingActiveStart =
            _safeString(data['busApproachingActiveStart'], '07:00');
        _busApproachingActiveEnd =
            _safeString(data['busApproachingActiveEnd'], '22:00');
        final rawCustom = data['customColors'] as Map<dynamic, dynamic>?;
        if (rawCustom != null) {
          _customColors = <String, Color>{};
          for (final entry in rawCustom.entries) {
            final c = _parseHexColor(entry.value.toString());
            if (c != null) _customColors[entry.key.toString()] = c;
          }
        }
      }
    } catch (e, st) {
      AppLogger.error(_logTag, 'guest prefs corrupted, resetting to defaults', e, st);
      _resetToDefaults();
      try {
        _guestBox ??= await _openGuestBox();
        await _guestBox!.delete('prefs');
      } catch (_) {}
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    if (!_initialized) {
      await _loadGuestPrefs();
    }

    try {
      final uid = _authUserId;
      if (uid != null) {
        await _prefsRepo.update(toPreferences(uid));
        return;
      }
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
        'hcPreserveAccent': _hcPreserveAccent,
        'mapStyle': _mapStyle,
        'themeMode': _themeMode.name,
        'notifIncidentResolved': _notifIncidentResolved,
        'notifRoutePromoted': _notifRoutePromoted,
        'notifBusApproaching': _notifBusApproaching,
        'notifFeatureRequestReplied': _notifFeatureRequestReplied,
        'quietHoursEnabled': _quietHoursEnabled,
        'quietHoursStart': _quietHoursStart,
        'quietHoursEnd': _quietHoursEnd,
        'notifZoneAlerts': _notifZoneAlerts,
        'busApproachingMinutesAhead': _busApproachingMinutesAhead,
        'busApproachingActiveStart': _busApproachingActiveStart,
        'busApproachingActiveEnd': _busApproachingActiveEnd,
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

  ThemeMode _parseThemeMode(String? value) {
    if (value == null) return ThemeMode.system;
    return ThemeMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ThemeMode.system,
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

  double _safeDouble(dynamic v, double fallback) {
    if (v is num && v.isFinite) return v.toDouble().clamp(-1000, 1000);
    return fallback;
  }

  String _safeString(dynamic v, String fallback) {
    return v is String && v.isNotEmpty ? v : fallback;
  }

  bool _safeBool(dynamic v, bool fallback) {
    return v is bool ? v : fallback;
  }

  void _resetToDefaults() {
    _paletteId = 'default';
    _backgroundId = 'shaders/smoke.frag';
    _backgroundEnabled = true;
    _backgroundOpacity = 1.0;
    _fontScale = 1.0;
    _colorBlindMode = ColorBlindMode.none;
    _dyslexiaFontEnabled = false;
    _highContrast = false;
    _hcPreserveAccent = false;
    _reduceMotion = false;
    _mapStyle = 'streets';
    _themeMode = ThemeMode.system;
    _notifZoneAlerts = true;
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
  // ChangeNotifierProvider llama a dispose() automáticamente al cerrarse
  // el scope; no añadimos ref.onDispose(notifier.dispose) porque eso
  // disparaba doble-dispose y rompía tests del router.
  return ThemeNotifier(prefsRepo: repo);
});
