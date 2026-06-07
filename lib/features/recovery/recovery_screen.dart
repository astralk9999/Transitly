import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../shared/providers/boot_canary_provider.dart';
import '../../core/utils/boot_canary.dart';

class RecoveryScreen extends ConsumerWidget {
  const RecoveryScreen({super.key});

  static const _guestBoxName = 'guest_theme_prefs';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bootCanaryStateProvider)!;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.light(primary: Colors.blue),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87, fontSize: 16),
          bodyMedium: TextStyle(color: Colors.black54, fontSize: 14),
          titleLarge: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
                    const SizedBox(height: 16),
                    const Text('Transitly no pudo iniciar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
                    const SizedBox(height: 12),
                    const Text(
                      'La app no se inició correctamente las últimas veces.\n'
                      'Posiblemente debido a un cambio de accesibilidad o apariencia.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                    if (state.pendingChange != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Último cambio: ${state.pendingChange}',
                        style: const TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () => _restoreDefaultsAndContinue(context),
                        child: const Text('Restaurar configuración por defecto', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => _continueAnyway(context),
                      child: const Text('Continuar sin cambios', style: TextStyle(color: Colors.black54)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _restoreDefaultsAndContinue(BuildContext context) async {
    try {
      final box = await Hive.openBox<Map<dynamic, dynamic>>(_guestBoxName);
      await box.delete('prefs');
    } catch (_) {}
    await BootCanary.markStable();
    await _exitToRelaunch(context);
  }

  Future<void> _continueAnyway(BuildContext context) async {
    await BootCanary.markPendingSensitive('');
    await BootCanary.markStable();
    await _exitToRelaunch(context);
  }

  /// El árbol Flutter actual está dentro de un MaterialApp ya en vivo, por
  /// lo que no podemos "volver a llamar main()" para cargar TransitlyApp.
  /// Lo más fiable y portable es cerrar la app limpiamente; al reabrirla
  /// el canary ya está STABLE y arranca por el camino normal.
  Future<void> _exitToRelaunch(BuildContext context) async {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Configuración restaurada. Vuelve a abrir Transitly para continuar.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await SystemNavigator.pop();
  }
}
