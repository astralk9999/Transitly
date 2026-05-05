import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Único punto de acceso a la instancia global de Supabase para el resto
/// de la app.
///
/// **Regla:** ningún archivo fuera de `main.dart` debe usar
/// `Supabase.instance.client` directamente; todo consumidor pasa por
/// este provider. La razón es testabilidad — un `overrideWithValue`
/// permite a los tests sustituir el cliente por un mock sin tocar la
/// red, y deja el wiring de inicialización aislado en `main.dart`.
///
/// Lanza `Supabase` (no inicializado) si se accede antes de
/// `Supabase.initialize` en main. La pantalla de error de Env evita
/// que ese caso llegue al árbol de widgets.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
