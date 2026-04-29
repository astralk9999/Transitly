import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stream of the current network reachability.
///
/// Emits the latest list of active connection types reported by
/// `connectivity_plus`. The map tab uses this to show an "offline" hint
/// when basemap tiles cannot be fetched.
final connectivityStreamProvider =
    StreamProvider<List<ConnectivityResult>>((ref) {
  final conn = Connectivity();
  return conn.onConnectivityChanged;
});

/// True when the device has no usable network interface.
final isOfflineProvider = Provider<bool>((ref) {
  final result = ref.watch(connectivityStreamProvider);
  return result.maybeWhen(
    data: (list) =>
        list.isEmpty || list.every((r) => r == ConnectivityResult.none),
    orElse: () => false,
  );
});
