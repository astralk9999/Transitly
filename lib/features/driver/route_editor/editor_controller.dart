import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class EditorStop {
  EditorStop(this.name, this.position)
      : id = '${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

  static int _seq = 0;

  final String id;
  final String name;
  final LatLng position;
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

  @override
  void dispose() {
    codeCtrl.dispose();
    nameCtrl.dispose();
    totalTimeCtrl.dispose();
    super.dispose();
  }
}
