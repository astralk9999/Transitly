class ForceUpdateChecker {
  ForceUpdateChecker._();

  static int? get minVersion {
    final raw = const String.fromEnvironment('TRANSITLY_MIN_VERSION');
    if (raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  static bool updateRequired(int currentVersion) {
    final min = minVersion;
    if (min == null) return false;
    return currentVersion < min;
  }
}
