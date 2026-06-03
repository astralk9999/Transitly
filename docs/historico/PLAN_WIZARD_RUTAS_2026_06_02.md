# Plan de acción — Wizard crear ruta + bugs persistentes

**Fecha:** 2026-06-02
**Autor:** Claude Code (Opus 4.7)
**Estado:** propuesto, decisiones del usuario confirmadas (ver §3)
**Continuación de:** `PLAN_WIDGETS_RUTAS_2026_06_02.md`
**Alcance:** 5 bugs + 5 mejoras del wizard de crear ruta. Tocará bastante código pero con coherencia visual del sistema de diseño existente.

---

## 1. Resumen de problemas

### Bugs activos
| # | Problema | Severidad |
|---|----------|-----------|
| **B1** | Sesión se sigue cerrando al cerrar/reabrir app | **Crítica** |
| **B2** | Tras login solo carga el nombre — saldo, favoritos, líneas vacíos | **Crítica** |
| **B3** | Wizard horarios: feo + apartados se solapan + poco intuitivo | Alta |
| **B4** | Crear ruta NO permite dibujar el camino del bus | Alta |
| **B5** | Publicar ruta da error PostgreSQL `22P02` (invalid text representation) | **Crítica** (bloqueante) |

### Mejoras del wizard
| # | Mejora | Esfuerzo |
|---|--------|----------|
| **M1** | Color picker: presets + custom hex (#RRGGBB) | Bajo |
| **M2** | Iconos en dropdowns de tipo (servicio, parada, día) | Bajo |
| **M3** | Horarios: 4 modos (lista / frecuencia / relativo por parada / a demanda) | **Alto** |
| **M4** | Trazado del bus: tap secuencial entre paradas | Medio |
| **M5** | Coherencia visual con la app (TransitColorScheme, TransitTypography, GlassCard, TransitButton) | Bajo (audit + reemplazos) |

Total estimado: **~10 h** (separable en 2-3 sesiones).

---

## 2. Auditoría rápida (causa raíz)

### B1 — Sesión se cierra
La sesión Supabase se persiste en `flutter_secure_storage` por defecto (verificado en pubspec: `flutter_secure_storage ^10.2.0`). El fix anterior añadió retry de 300 ms pero el usuario reporta que persiste el problema.

**Hipótesis nueva:** el `_widgetBackgroundCallback` en `main.dart:286+` corre en un **isolate separado** y ejecuta `HiveInit.bootstrap()`. Este reinit puede entrar en conflicto con la sesión activa del isolate principal si abre boxes con cifrado distinto o resetea la clave AES. La sesión Supabase NO se toca, pero su token guardado en SharedPreferences sí podría perderse si el callback re-inicializa storage.

**Necesito antes de fixear:** capturar `adb logcat -d | grep -iE "Auth|Supabase|Hive"` después de reproducir. Sin esto, fix preventivo a ciegas.

### B2 — Datos no cargan tras login
Auditoría confirmada:
- `lib/shared/providers/user_favorites_provider.dart:5-17` — usa Hive box `userFavorites` SIN scope por user_id.
- `lib/data/nfc/nfc_balance_repository.dart` — usa Hive box `nfc_scans` global.

Por tanto los datos NO se borran al hacer login: están ahí. Pero el usuario reporta que NO se ven.

**Hipótesis fuerte:** los datos SÍ existen en Hive, pero los providers `UserFavoritesNotifier` y `NfcScanNotifier` se crean ANTES de que la sesión esté establecida. Como Hive box `userFavorites` se abre con `_load()` async sin esperar a auth, los stops se cargan correctamente para el invitado pero al cambiar a auth no se invalida ni se recarga el provider.

**Más sutil:** cuando el usuario hace login, Supabase emite `signedIn`. Pero **NINGÚN provider escucha ese evento para recargar sus datos**. Los providers siguen mostrando el state cacheado del modo invitado anterior — o si nunca se cargaron antes, vacío.

### B3 — Wizard horarios feo y solapado
Lo audité en planes previos pero hay que rehacerlo casi entero. El `step_schedules.dart` tiene 2 modales (`_AddScheduleSheet` y `_AddFrequencyModal`) que solapan formularios, dropdowns y botones sin orden visual claro.

### B4 — Sin trazado del bus
`step_stops.dart` solo guarda lat/lng de paradas. El modelo `WizardStop` (wizard_models.dart:1-43) NO tiene campo para puntos intermedios. Y el wizard ni siquiera tiene un Step para "trazar el camino". Falta completar el modelo + UI + persistencia.

Verificado: existe `lib/features/driver/route_editor/steps/step_trace.dart` que SÍ permite trazar caminos pero es para el editor de conductor (otro flow), no para el usuario normal.

### B5 — Error PostgreSQL 22P02
`22P02` = "invalid text representation". Casos típicos:
- UUID malformado en columna `uuid` (ej. cadena vacía).
- `timestamp` en formato incorrecto.
- Enum con valor no permitido (ej. `serviceType='urban'` cuando el enum solo acepta `'urbano'`).

Sin ver el payload exacto que se envía, mi sospecha:
- `route_color` enviado como `"#977DDF"` cuando la columna espera `text` sin `#` o un formato HEX específico.
- `day_type` o `service_type` con valor no presente en el enum SQL.
- `notes` o `description` con caracteres especiales mal escapados.

**Hay que añadir log del payload completo justo antes del `insert` y mirar la respuesta de Supabase con el campo problemático.**

---

## 3. Decisiones del usuario confirmadas (2026-06-02)

| Decisión | Elegido |
|----------|---------|
| Trazado | **Tap secuencial intermedios** entre paradas |
| Horarios | **4 modos**: horas fijas + frecuencia por franja + relativo por parada + a demanda |
| Color picker | **Presets + custom hex** (#RRGGBB) |
| Datos usuario | **Local + sync Supabase** (Hive como fuente, Supabase respaldo) |

---

## 4. Plan dividido en 5 tareas

### Tarea A — Bug B1+B2: sesión + carga de datos tras login (1.5 h)

#### A.1 — Diagnóstico del cierre de sesión (B1)
- Añadir log MUY verboso en `main.dart` justo antes y después de `Supabase.initialize`:
  ```dart
  AppLogger.info('Startup', 'BEFORE init: stored session exists in SecureStorage?');
  // ... initialize
  AppLogger.info('Startup', 'AFTER init: currentSession=${session != null} expires=${session?.expiresAt}');
  ```
- Pedir al usuario `adb logcat -d | grep Startup` después de reproducir.
- Mientras tanto, **fix preventivo más fuerte**:
  - Llamar `Supabase.instance.client.auth.refreshSession()` después del initial check si hay session válida pero sin user.
  - Manejar excepciones de `refreshSession()` sin desautenticar.

#### A.2 — Listener de auth para recargar providers (B2)
Crear un nuevo listener en `main.dart` después de `runApp`:
```dart
container.read(supabaseClientProvider).auth.onAuthStateChange.listen((data) {
  final event = data.event;
  final user = data.session?.user;
  if (event == AuthChangeEvent.signedIn && user != null) {
    // Invalidar providers para que recarguen con el contexto del nuevo user
    container.invalidate(userFavoritesProvider);
    container.invalidate(userFavoriteStopsProvider);
    container.invalidate(nfcScanProvider);
    container.invalidate(homeHabitualConfigProvider);
    // Sync inicial: pull desde Supabase si tiene datos remotos
    container.read(userFavoritesSyncServiceProvider).pullFromRemote(user.id);
  }
});
```

Necesita:
- Nuevo `UserFavoritesSyncService` (`lib/data/user_favorites/user_favorites_sync_service.dart`) con `pullFromRemote(userId)` y `pushToRemote(userId)`. Estrategia: Supabase es respaldo, local es la fuente; al login pulla y mergea con el local (union de sets).
- Tabla Supabase `user_favorites` con columnas `user_id uuid`, `lines text[]`, `stops text[]`, `updated_at timestamp`.

#### A.3 — Hidrate del saldo NFC tras login
El `NfcScanNotifier._hydrateFromCache()` ya lee Hive global. Para sincronizar con Supabase también:
- Pull último escaneo desde `nfc_scans` ordenado por `scanned_at desc` al hacer login.
- Si Supabase tiene uno más reciente que el local, actualizar local + widget.

---

### Tarea B — Wizard: rediseño del paso de horarios (B3 + M3) (3 h)

#### B.1 — Nuevo modelo `WizardScheduleConfig`
Reemplazar el `List<WizardSchedule>` actual por un objeto más rico:
```dart
class WizardScheduleConfig {
  /// 'fixed' | 'frequency' | 'relative' | 'on_demand'
  final String mode;
  final List<FixedDeparture> fixed;      // mode == 'fixed'
  final List<FrequencyWindow> frequency; // mode == 'frequency'
  final List<StopTimingOffset> offsets;  // mode == 'relative'
  // mode == 'on_demand' → todo null
}

class FixedDeparture {
  final String dayType;  // weekday/saturday/sunday/holiday
  final String hhmm;     // "08:30"
}

class FrequencyWindow {
  final String dayType;
  final String startHhmm;  // "07:00"
  final String endHhmm;    // "22:00"
  final int everyMinutes;  // 15
}

class StopTimingOffset {
  /// Para mode 'relative': cuántos min tarda en llegar desde la parada origen.
  final String stopId;
  final int minutesFromOrigin;
}
```

#### B.2 — UI con tabs/segmented control
Sustituir los 2 modales actuales por un **stepper visual** dentro del paso 3:
```
┌─ ¿Cómo se rige el horario? ──────────────┐
│ [Horas fijas] [Frecuencia] [Por parada] [A demanda] │  ← TransitChip toggle
├──────────────────────────────────────────┤
│ ... formulario según modo seleccionado   │
└──────────────────────────────────────────┘
```

Cada modo tiene su sub-formulario:
- **Horas fijas**: ListView con [día] + [hora] + delete. Botón "+ Añadir salida". Hora con `TimePicker`.
- **Frecuencia**: cards de "ventana": día + desde + hasta + cada N min. Botón "+ Añadir ventana".
- **Por parada**: lista de paradas (de Step 2) con TextField para "min desde origen". Calcula horas automáticamente al elegir hora de salida del origen.
- **A demanda**: solo un texto explicativo + textarea opcional "¿Cómo lo solicito?" (teléfono, app, etc.).

#### B.3 — Visual coherente con la app
Componentes a usar (memoria [[feedback-design-tokens]]):
- `GlassCard` para cada bloque.
- `TransitButton` para acciones primarias.
- `TransitChip` para selector de modo.
- `TransitColorScheme.of(isDark)` para colores.
- `TransitTypography.heading/sectionTitle/bodyPrimary` para textos.
- Padding inferior con `mq.padding.bottom + 80 (HomeBottomNav.height)`.
- `showModalBottomSheet` con `useSafeArea: true`.

---

### Tarea C — Wizard: trazado del camino del bus (B4 + M4) (2 h)

#### C.1 — Nuevo paso "Trazar recorrido"
Insertar entre el paso 2 (Paradas) y 3 (Horarios) un paso nuevo `step_route_path.dart`:

```
┌─ Trazar el camino del bus ──────────────┐
│ Toca el mapa para añadir puntos del     │
│ recorrido entre las paradas             │
├──────────────────────────────────────────┤
│ [Mapa con paradas como pins + polyline] │
│                                          │
│ Paradas: A ─ pt ─ pt ─ B ─ pt ─ pt ─ C  │
├──────────────────────────────────────────┤
│ Editando: A → B                          │
│ [Eliminar último punto] [Confirmar]      │
└──────────────────────────────────────────┘
```

Lógica:
- Lista de segmentos `[A→B, B→C, C→D]` (uno por par consecutivo de paradas).
- Toca el mapa → añade punto al segmento activo.
- "Confirmar segmento" → pasa al siguiente.
- Si el usuario salta un segmento, queda vacío y se interpola con línea recta al renderizar la ruta.

#### C.2 — Nuevo modelo
```dart
class WizardRoutePath {
  final List<WizardSegment> segments;
}
class WizardSegment {
  final String fromStopId;
  final String toStopId;
  final List<({double lat, double lng})> intermediatePoints;
}
```

#### C.3 — Persistencia Supabase
Tabla `user_route_segments`:
```sql
create table user_route_segments (
  id uuid primary key default gen_random_uuid(),
  route_id uuid references user_routes(id) on delete cascade,
  from_stop_id uuid references user_stops(id),
  to_stop_id uuid references user_stops(id),
  geometry geography(LineString, 4326),
  order_index int not null,
  created_at timestamp default now()
);
```
Polyline encoded como GeoJSON LineString para PostGIS.

#### C.4 — Visualización
En el mapa principal y en detalles de ruta, el polyline se muestra con `RoutePolylines` (componente ya existente).

---

### Tarea D — Wizard: color picker + iconos (M1 + M2) (1 h)

#### D.1 — Color personalizado
En `step_basic_info.dart`:
- Mantener los 8 presets en una `Row` horizontal.
- Añadir botón "Personalizado" al final con icono `Icons.colorize`.
- Al pulsar abre un `BottomSheet` con:
  - `TextField` con label "Código hex" (`#RRGGBB`).
  - Preview: cuadro de color que se actualiza en vivo al escribir.
  - Validación: 6 hex chars + opcional `#` al inicio.
  - Botón "Aplicar".

#### D.2 — Iconos en dropdowns
Auditar todos los `DropdownButton` del wizard:
- Tipo de servicio (urban/interurban/long_distance/special/school/on_demand) → icons: bus, road, route, special, school, accessible.
- Tipo de parada (urban_custom/hotel/motel/...) → ya hay map en `step_stops.dart:29` pero no se usa en `DropdownMenuItem`. Migrar.
- Tipo de día (weekday/saturday/...) → ya hay map en `step_schedules.dart:37`. Aplicarlo.

Patrón:
```dart
DropdownMenuItem(
  value: 'hotel',
  child: Row(
    children: [
      Icon(Icons.hotel, color: c.accent),
      const SizedBox(width: 8),
      Text('Hotel'),
    ],
  ),
)
```

---

### Tarea E — Fix error 22P02 + publicación (B5) (1.5 h)

#### E.1 — Log del payload
En `create_route_wizard.dart` justo antes de `insert`:
```dart
AppLogger.info(_logTag, 'PUBLISH payload: ${jsonEncode(routeData)}');
AppLogger.info(_logTag, 'PUBLISH stops: ${jsonEncode(stopsData)}');
AppLogger.info(_logTag, 'PUBLISH schedules: ${jsonEncode(schedulesData)}');
```

#### E.2 — Validar tipos antes de enviar
Casos a verificar y normalizar:
- `route_color`: enviar SIEMPRE en formato `#RRGGBB` exacto (6 hex). Si el user mete `rrggbb` añadir `#`. Si la columna SQL espera `text`, sin `#` debería ser tolerable también.
- `service_type`: validar que es uno de los enums permitidos.
- `visibility`: `private | public | community`.
- `day_type`: `weekday | saturday | sunday | holiday | summer | winter | every_day`.
- Todos los UUIDs (route_id, stop_id, user_id) — verificar formato uuid v4 antes de enviar.
- `departure_time`: formato `HH:MM:SS` (PostgreSQL time) — si el wizard envía `HH:MM` añadir `:00`.

#### E.3 — Mostrar error legible
Si Supabase devuelve un error con código:
```dart
} on PostgrestException catch (e) {
  if (e.code == '22P02') {
    // mostrar dialog con e.message y campo problemático
  }
}
```
Y SnackBar floating con mensaje claro en lugar del trace.

---

## 5. Archivos afectados (resumen)

### Nuevos
- `lib/data/user_favorites/user_favorites_sync_service.dart`
- `lib/features/create_route/steps/step_route_path.dart`
- `lib/features/create_route/widgets/route_path_map_screen.dart`
- `lib/features/create_route/widgets/custom_color_picker_sheet.dart`
- `lib/features/create_route/widgets/schedule_mode_selector.dart`
- `lib/features/create_route/widgets/schedule_fixed_form.dart`
- `lib/features/create_route/widgets/schedule_frequency_form.dart`
- `lib/features/create_route/widgets/schedule_relative_form.dart`

### Modificados
- `lib/main.dart` (listener onAuthStateChange + logs + refreshSession)
- `lib/features/create_route/create_route_wizard.dart` (nuevo paso + log + validación payload)
- `lib/features/create_route/steps/step_basic_info.dart` (color custom + iconos en service type)
- `lib/features/create_route/steps/step_stops.dart` (iconos en dropdown tipo)
- `lib/features/create_route/steps/step_schedules.dart` (reescritura completa con 4 modos)
- `lib/features/create_route/steps/wizard_models.dart` (modelos nuevos schedule + path)
- `lib/data/nfc/nfc_balance_repository.dart` (pull desde Supabase si hay user)
- `lib/shared/providers/user_favorites_provider.dart` (suscripción a auth changes)
- `lib/shared/providers/nfc_provider.dart` (suscripción a auth changes)

### Supabase
- Migration nueva: tabla `user_favorites`, tabla `user_route_segments` con PostGIS LineString.
- Verificar enums de `service_type`, `day_type`, `visibility`.

### Sin tocar
- AndroidManifest, gradle, providers Kotlin de widget.
- Sistema de fuentes y theming.
- Layer del mapa principal.

---

## 6. Estimación de tiempo

| Tarea | Tiempo | Acumulado | Prioridad |
|-------|--------|-----------|-----------|
| A — Sesión + sync datos (B1, B2) | 1.5 h | 1.5 h | **Crítica** |
| B — Horarios 4 modos (B3, M3) | 3 h | 4.5 h | Alta |
| C — Trazado camino (B4, M4) | 2 h | 6.5 h | Alta |
| D — Color custom + iconos (M1, M2) | 1 h | 7.5 h | Media |
| E — Fix 22P02 + payload (B5) | 1.5 h | 9 h | **Crítica** |
| Build + smoke test | 30 min | 9.5 h | — |
| **Total** | **~10 h** | | 2-3 sesiones |

---

## 7. Orden de ejecución recomendado

1. **A primero** (1.5 h): sin sesión + datos cargados el resto es inservible.
2. **E** (1.5 h): sin publicar no se puede testear el wizard al final.
3. **D** (1 h): mejoras visuales rápidas, da motivación para el resto.
4. **B** (3 h): horarios — el más laborioso de UI.
5. **C** (2 h): trazado — depende de tener las paradas funcionales (paso 2).
6. Build + smoke + iterar.

---

## 8. Coherencia visual: reglas para todos los cambios

Aplicables a CADA archivo nuevo o modificado del wizard:

- ❌ **Nunca** `Color(0xFF...)` ni `TextStyle(...)` ni `Duration(milliseconds: N)` inline.
- ✅ **Siempre** `TransitColorScheme.of(isDark).accent/bgRoot/textHi/...`.
- ✅ **Siempre** `TransitTypography.heading/sectionTitle/bodyPrimary/...`.
- ✅ **Siempre** `TransitSpacing.space8/16/24/...`.
- ✅ **Siempre** `TransitAnimations.medium/...` para duraciones.
- ✅ Componentes compartidos:
  - Tarjetas → `GlassCard`.
  - Botones → `TransitButton` (con `isPrimary` para CTA).
  - Inputs → `TransitInput`.
  - Chips/Toggle → `TransitChip`.
  - Listas → `StaggerList` cuando hay >3 items.
- ✅ Iconos via `Icons.*` Material Design (no asset PNG salvo branding).
- ✅ SnackBars: SIEMPRE floating + margin + duration 2s.
- ✅ Sheets: `useSafeArea: true` + padding inferior con `mq.padding.bottom + HomeBottomNav.height`.

---

## 9. Riesgos

- **R1: Refresh session puede revocar sesión por error.** Mitigación: try/catch + log + mantener última sesión válida.
- **R2: `invalidate(provider)` en login resetea state — si el provider tiene cache local importante se pierde.** Mitigación: usar `pull-then-merge` para favoritos en lugar de invalidate.
- **R3: Tap secuencial para trazar puede ser tedioso para rutas largas.** Mitigación: añadir botón "Saltar segmento" que deja recta automática.
- **R4: 4 modos de horario inflan el step 3 y lo hacen difícil de comprender.** Mitigación: progressive disclosure — al elegir un modo, los otros 3 colapsan.
- **R5: Hex color validation puede aceptar invalidos.** Mitigación: regex `^#?[0-9a-fA-F]{6}$` + preview en vivo + fallback al preset por defecto.
- **R6: Migration Supabase nueva puede romper deploys actuales.** Mitigación: hacerla idempotente con `if not exists` + columnas nullable.

---

## 10. Criterios de aceptación (smoke test final)

1. Login con email → cerrar app → reabrir → sigo logueado.
2. Login → ver favoritos, líneas, paradas, saldo NFC correctos (no vacíos).
3. Logout → confirm dialog → confirmo → todo limpio + redirige a login.
4. Crear ruta → paso 1: elegir color "Personalizado" → introducir `#FF6B35` → preview correcto.
5. Crear ruta → paso 2: añadir 3 paradas con tap-en-mapa (ya funcional desde sesión anterior).
6. Crear ruta → **paso 3 nuevo: trazar camino**. Tap en mapa entre A→B añade puntos, polyline visible.
7. Crear ruta → paso 4: elegir modo "Frecuencia" → "Cada 15 min entre 7:00 y 22:00 L-V" — sin solapamientos visuales.
8. Crear ruta → paso 4: alternativa "Por parada" → poner 0 min para origen, 5 para parada 2, 8 para parada 3.
9. Crear ruta → publicar → SIN error 22P02 → ruta aparece en "Mis rutas".
10. Detalle de ruta creada → mapa muestra polyline real con puntos intermedios + paradas + horarios.

---

## 11. Próximos pasos

Cuando apruebes:
- **"arranca todo en orden"** → A → E → D → B → C en una sesión larga (~10 h).
- **"arranca A+E"** → solo los bloqueantes críticos (3 h) — wizard quedará feo pero publicable.
- **"arranca por orden inverso (UI primero)"** → D → B → C → A → E si prefieres ver mejoras visuales antes que arreglar backend.

Recomiendo **"arranca todo en orden"** porque A y E son críticos.

---

## Changelog

- **2026-06-02** — Plan creado tras auditoría:
  - Bugs B1-B5 con causas identificadas (excepto B1 que requiere logs del usuario).
  - Decisiones del usuario integradas: tap secuencial trazado, 4 modos horario, hex picker simple, local + sync Supabase.
  - 5 tareas A-E con 9.5 h total estimadas.
