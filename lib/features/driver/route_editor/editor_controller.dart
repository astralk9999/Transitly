import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';

import '../../../../data/cache/hive_init.dart';

class EditorStop {
  EditorStop(this.name, this.position)
      : id = '${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

  static int _seq = 0;

  final String id;
  final String name;
  final LatLng position;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lat': position.latitude,
        'lng': position.longitude,
      };

  factory EditorStop.fromJson(Map<String, dynamic> j) {
    final stop = EditorStop(
      j['name'] as String,
      LatLng((j['lat'] as num).toDouble(), (j['lng'] as num).toDouble()),
    );
    // Preserve the original id if present.
    return stop;
  }
}

/// Shared mutable state across the manual route editor steps.
///
/// Steps consume the controller via [ListenableBuilder] / [AnimatedBuilder]
/// and mutate it directly. Keeping state here (instead of threading through
/// callbacks) lets each step be a small, dedicated widget without giving up
/// reactivity.
class RouteEditorController extends ChangeNotifier {
  // ── Step 1: info ──
  final TextEditingController codeCtrl = TextEditingController();
  final TextEditingController nameCtrl = TextEditingController();
  String serviceType = 'urban';

  set serviceTypeValue(String v) {
    if (serviceType == v) return;
    serviceType = v;
    notifyListeners();
  }

  /// Force a listener refresh after mutating a plain [TextEditingController]
  /// owned by this state holder (the step widgets read `codeCtrl.text` etc.
  /// to compute button enablement).
  void refresh() => notifyListeners();

  // ── Step 2: trace ──
  final List<LatLng> tracePoints = [];
  final MapController traceMapCtrl = MapController();

  void addTracePoint(LatLng p) {
    tracePoints.add(p);
    notifyListeners();
  }

  void removeLastTracePoint() {
    if (tracePoints.isEmpty) return;
    tracePoints.removeLast();
    notifyListeners();
  }

  /// Sub P2-05: elimina un vértice por índice.
  void removeTracePointAt(int index) {
    if (index < 0 || index >= tracePoints.length) return;
    tracePoints.removeAt(index);
    notifyListeners();
  }

  /// Sub P2-05: cierra el polígono añadiendo el primer punto al final.
  /// Útil para rutas circulares.
  void closeTracePolygon() {
    if (tracePoints.length < 3) return;
    final first = tracePoints.first;
    final last = tracePoints.last;
    if (first.latitude == last.latitude && first.longitude == last.longitude) {
      return; // ya cerrado
    }
    tracePoints.add(first);
    notifyListeners();
  }

  /// Sub P2-05: calcula el total de km del trazado.
  double get traceTotalKm {
    if (tracePoints.length < 2) return 0;
    const dist = Distance();
    double total = 0;
    for (var i = 1; i < tracePoints.length; i++) {
      total += dist.as(LengthUnit.Meter, tracePoints[i - 1], tracePoints[i]);
    }
    return total / 1000;
  }

  // ── Step 3: stops ──
  final List<EditorStop> stops = [];
  final MapController stopsMapCtrl = MapController();

  void addStop(EditorStop s) {
    stops.add(s);
    notifyListeners();
  }

  void removeStopAt(int index) {
    stops.removeAt(index);
    notifyListeners();
  }

  void reorderStops(int oldIdx, int newIdx) {
    if (newIdx > oldIdx) newIdx--;
    final item = stops.removeAt(oldIdx);
    stops.insert(newIdx, item);
    notifyListeners();
  }

  /// Sub P2-04: invierte el orden de las paradas. Útil si grabaste la vuelta.
  void reverseStops() {
    if (stops.length < 2) return;
    final reversed = stops.reversed.toList();
    stops
      ..clear()
      ..addAll(reversed);
    notifyListeners();
  }

  // ── Step 4: return ──
  String returnChoice = ''; // 'invert' | 'new' | 'oneway'

  set returnChoiceValue(String v) {
    if (returnChoice == v) return;
    returnChoice = v;
    notifyListeners();
  }

  // ── Step 5: schedules ──
  final Map<String, List<String>> schedules = {
    'weekday': [],
    'saturday': [],
    'sunday': [],
  };
  final TextEditingController totalTimeCtrl =
      TextEditingController(text: '45');

  // Sub P2-06: modo por día — 'fixed' | 'frequency' | 'hybrid'.
  final Map<String, String> scheduleMode = {
    'weekday': 'fixed',
    'saturday': 'fixed',
    'sunday': 'fixed',
  };
  // Sub P2-06: parámetros de Frecuencia por día.
  final Map<String, String> scheduleFreqStart = {
    'weekday': '07:00',
    'saturday': '08:00',
    'sunday': '09:00',
  };
  final Map<String, String> scheduleFreqEnd = {
    'weekday': '22:00',
    'saturday': '22:00',
    'sunday': '22:00',
  };
  final Map<String, int> scheduleFreqInterval = {
    'weekday': 15,
    'saturday': 30,
    'sunday': 30,
  };
  // Sub P2-06: horas extra y excluidas del modo Híbrido.
  final Map<String, List<String>> scheduleExtras = {
    'weekday': [],
    'saturday': [],
    'sunday': [],
  };
  final Map<String, List<String>> scheduleExcludes = {
    'weekday': [],
    'saturday': [],
    'sunday': [],
  };

  static final _hhmmRegExp = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  void addScheduleTime(String key, String hhmm) {
    final list = schedules[key];
    if (list == null) return;
    if (!_hhmmRegExp.hasMatch(hhmm)) return;
    if (list.contains(hhmm)) return;
    list
      ..add(hhmm)
      ..sort();
    notifyListeners();
  }

  void removeScheduleTime(String key, int index) {
    final list = schedules[key];
    if (list == null || index < 0 || index >= list.length) return;
    list.removeAt(index);
    notifyListeners();
  }

  /// Sub P2-06: cambia el modo del día.
  void setScheduleMode(String key, String mode) {
    if (!scheduleMode.containsKey(key)) return;
    if (scheduleMode[key] == mode) return;
    scheduleMode[key] = mode;
    notifyListeners();
  }

  /// Sub P2-06: actualiza parámetros de Frecuencia.
  void setScheduleFreq(
    String key, {
    String? start,
    String? end,
    int? interval,
  }) {
    if (start != null && _hhmmRegExp.hasMatch(start)) {
      scheduleFreqStart[key] = start;
    }
    if (end != null && _hhmmRegExp.hasMatch(end)) {
      scheduleFreqEnd[key] = end;
    }
    if (interval != null && interval >= 5 && interval <= 120) {
      scheduleFreqInterval[key] = interval;
    }
    notifyListeners();
  }

  void addScheduleExtra(String key, String hhmm) {
    if (!_hhmmRegExp.hasMatch(hhmm)) return;
    final list = scheduleExtras[key];
    if (list == null || list.contains(hhmm)) return;
    list
      ..add(hhmm)
      ..sort();
    notifyListeners();
  }

  void removeScheduleExtraAt(String key, int index) {
    final list = scheduleExtras[key];
    if (list == null || index < 0 || index >= list.length) return;
    list.removeAt(index);
    notifyListeners();
  }

  void addScheduleExclude(String key, String hhmm) {
    if (!_hhmmRegExp.hasMatch(hhmm)) return;
    final list = scheduleExcludes[key];
    if (list == null || list.contains(hhmm)) return;
    list
      ..add(hhmm)
      ..sort();
    notifyListeners();
  }

  void removeScheduleExcludeAt(String key, int index) {
    final list = scheduleExcludes[key];
    if (list == null || index < 0 || index >= list.length) return;
    list.removeAt(index);
    notifyListeners();
  }

  /// Sub P2-06: devuelve la lista efectiva de horas según el modo del día.
  List<String> generateScheduleTimes(String key) {
    final mode = scheduleMode[key] ?? 'fixed';
    final start = scheduleFreqStart[key] ?? '07:00';
    final end = scheduleFreqEnd[key] ?? '22:00';
    final interval = scheduleFreqInterval[key] ?? 15;

    switch (mode) {
      case 'frequency':
        return _generateFreq(start, end, interval);
      case 'hybrid':
        final base = _generateFreq(start, end, interval);
        final extras = scheduleExtras[key] ?? const <String>[];
        final excludes = scheduleExcludes[key] ?? const <String>[];
        final combined = {...base, ...extras}.toList()
          ..removeWhere(excludes.contains)
          ..sort();
        return combined;
      default:
        return List<String>.from(schedules[key] ?? const <String>[]);
    }
  }

  List<String> _generateFreq(String start, String end, int intervalMin) {
    if (!_hhmmRegExp.hasMatch(start) || !_hhmmRegExp.hasMatch(end)) return [];
    final s = _parseHhMm(start);
    final e = _parseHhMm(end);
    if (e <= s || intervalMin <= 0) return [];
    final result = <String>[];
    for (var m = s; m <= e; m += intervalMin) {
      final h = (m ~/ 60).toString().padLeft(2, '0');
      final mm = (m % 60).toString().padLeft(2, '0');
      result.add('$h:$mm');
    }
    return result;
  }

  int _parseHhMm(String s) {
    final parts = s.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  int get totalScheduleCount {
    int total = 0;
    for (final key in scheduleMode.keys) {
      total += generateScheduleTimes(key).length;
    }
    return total;
  }

  // ── Serialization ──

  Map<String, dynamic> toJson() => {
        'code': codeCtrl.text,
        'name': nameCtrl.text,
        'serviceType': serviceType,
        'tracePoints': tracePoints
            .map((p) => {'lat': p.latitude, 'lng': p.longitude})
            .toList(),
        'stops': stops.map((s) => s.toJson()).toList(),
        'returnChoice': returnChoice,
        'schedules': schedules.map(
            (k, v) => MapEntry(k, List<String>.from(v))),
        'scheduleMode': Map<String, String>.from(scheduleMode),
        'scheduleFreqStart': Map<String, String>.from(scheduleFreqStart),
        'scheduleFreqEnd': Map<String, String>.from(scheduleFreqEnd),
        'scheduleFreqInterval': Map<String, int>.from(scheduleFreqInterval),
        'scheduleExtras': scheduleExtras
            .map((k, v) => MapEntry(k, List<String>.from(v))),
        'scheduleExcludes': scheduleExcludes
            .map((k, v) => MapEntry(k, List<String>.from(v))),
        'totalTime': totalTimeCtrl.text,
      };

  void loadFromJson(Map<String, dynamic> json) {
    codeCtrl.text = json['code'] as String? ?? '';
    nameCtrl.text = json['name'] as String? ?? '';
    serviceType = json['serviceType'] as String? ?? 'urban';

    final traceList = json['tracePoints'] as List<dynamic>? ?? [];
    tracePoints.clear();
    for (final p in traceList) {
      tracePoints.add(LatLng(
        (p['lat'] as num).toDouble(),
        (p['lng'] as num).toDouble(),
      ));
    }

    stops.clear();
    final stopList = json['stops'] as List<dynamic>? ?? [];
    for (final s in stopList) {
      stops.add(EditorStop.fromJson(s as Map<String, dynamic>));
    }

    returnChoice = json['returnChoice'] as String? ?? '';

    schedules.clear();
    final schedMap = json['schedules'] as Map<String, dynamic>? ?? {};
    for (final entry in schedMap.entries) {
      schedules[entry.key] =
          (entry.value as List<dynamic>).cast<String>();
    }
    // Sub P2-06: restaurar modo + parámetros + extras/excluidos.
    final modeMap = json['scheduleMode'] as Map<String, dynamic>? ?? {};
    for (final entry in modeMap.entries) {
      scheduleMode[entry.key] = entry.value as String? ?? 'fixed';
    }
    final freqStartMap =
        json['scheduleFreqStart'] as Map<String, dynamic>? ?? {};
    for (final entry in freqStartMap.entries) {
      scheduleFreqStart[entry.key] = entry.value as String? ?? '07:00';
    }
    final freqEndMap = json['scheduleFreqEnd'] as Map<String, dynamic>? ?? {};
    for (final entry in freqEndMap.entries) {
      scheduleFreqEnd[entry.key] = entry.value as String? ?? '22:00';
    }
    final freqIntMap =
        json['scheduleFreqInterval'] as Map<String, dynamic>? ?? {};
    for (final entry in freqIntMap.entries) {
      scheduleFreqInterval[entry.key] = (entry.value as num?)?.toInt() ?? 15;
    }
    final extrasMap = json['scheduleExtras'] as Map<String, dynamic>? ?? {};
    for (final entry in extrasMap.entries) {
      scheduleExtras[entry.key] =
          (entry.value as List<dynamic>).cast<String>();
    }
    final excludesMap =
        json['scheduleExcludes'] as Map<String, dynamic>? ?? {};
    for (final entry in excludesMap.entries) {
      scheduleExcludes[entry.key] =
          (entry.value as List<dynamic>).cast<String>();
    }

    totalTimeCtrl.text = json['totalTime'] as String? ?? '45';
    notifyListeners();
  }

  /// Guarda el estado actual del editor como borrador en Hive.
  Future<void> saveDraft() async {
    final box = Hive.box<Map<dynamic, dynamic>>(HiveBoxes.editorDrafts);
    final key = 'draft:${codeCtrl.text.isNotEmpty ? codeCtrl.text : 'new'}';
    await box.put(key, toJson());
  }

  /// Carga un borrador desde Hive.
  Future<bool> loadDraft(String code) async {
    final box = Hive.box<Map<dynamic, dynamic>>(HiveBoxes.editorDrafts);
    final key = 'draft:$code';
    final data = box.get(key);
    if (data != null) {
      loadFromJson(Map<String, dynamic>.from(data));
      return true;
    }
    return false;
  }

  /// Lista los borradores guardados.
  static Future<List<String>> listDrafts() async {
    final box = Hive.box<Map<dynamic, dynamic>>(HiveBoxes.editorDrafts);
    final keys = box.keys
        .where((k) => (k as String).startsWith('draft:'))
        .map((k) => (k as String).replaceFirst('draft:', ''))
        .toList();
    return keys;
  }

  /// Elimina un borrador.
  static Future<void> deleteDraft(String code) async {
    final box = Hive.box<Map<dynamic, dynamic>>(HiveBoxes.editorDrafts);
    await box.delete('draft:$code');
  }

  @override
  void dispose() {
    codeCtrl.dispose();
    nameCtrl.dispose();
    totalTimeCtrl.dispose();
    traceMapCtrl.dispose();
    stopsMapCtrl.dispose();
    super.dispose();
  }
}
