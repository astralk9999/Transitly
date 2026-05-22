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

  void addScheduleTime(String key, String hhmm) {
    final list = schedules[key];
    if (list == null) return;
    list
      ..add(hhmm)
      ..sort();
    notifyListeners();
  }

  int get totalScheduleCount =>
      schedules.values.fold<int>(0, (sum, l) => sum + l.length);

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
