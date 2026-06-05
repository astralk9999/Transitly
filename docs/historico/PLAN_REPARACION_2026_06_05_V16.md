# Plan de reparación V16 — 2026-06-05

> Plan de reparación derivado de la sesión de testeo manual del 2026-06-05.
> Sucede a `PLAN_REPARACION_2026_06_01_V15.md`. Cubre 33 issues agrupados en
> 6 fases independientes priorizadas P0 → P2.5. Cada ítem trae criterios de
> aceptación (CA), archivos afectados (Σ) y notas de testing manual.
>
> **Restricciones globales:**
> - Calidad sobre velocidad — sin plazo de defensa fijo.
> - Plataformas objetivo: Android + iOS + **Web** (responsive con breakpoints).
> - Persistencia de preferencias UI: **solo Hive local** (no sincronizar en Supabase).
> - Backend Supabase: la infraestructura GDPR e invitaciones ya existe en
>   migraciones 001–020 — el plan repara el **wiring Flutter**, no crea schema
>   redundante.
>
> **Convenciones:**
> - `Σ` = lista no exhaustiva de archivos previsiblemente afectados.
> - `CA` = criterios de aceptación verificables.
> - `🐛` = bug reproducido durante el testeo.
> - `✨` = funcionalidad nueva o rediseño UX.
> - `🧱` = refactor estructural sin cambio visible.

---

## Índice

- [Fase P0 — Blockers](#fase-p0--blockers-9-ítems)
- [Fase P1 — Funcionalidad rota](#fase-p1--funcionalidad-rota-8-ítems)
- [Fase P1.5 — Sistema admin/operator/conductor](#fase-p15--sistema-adminoperatorconductor-7-ítems)
- [Fase P2 — Crear ruta (rediseño UX)](#fase-p2--crear-ruta-rediseño-ux-6-ítems)
- [Fase P2.5 — Responsive multiplataforma](#fase-p25--responsive-multiplataforma-4-ítems)
- [Anexo A — Migraciones SQL necesarias](#anexo-a--migraciones-sql-necesarias)
- [Anexo B — Bootstrap admin (SQL manual)](#anexo-b--bootstrap-admin-sql-manual)
- [Anexo C — Matriz de testing manual](#anexo-c--matriz-de-testing-manual)
- [Anexo D — Eventos PostHog/Sentry nuevos](#anexo-d--eventos-posthogsentry-nuevos)

---

## Fase P0 — Blockers (9 ítems)

Errores que impiden usar funcionalidad básica. Sin estos arreglados la app
no es defendible.

### P0-01 🐛 Las líneas de buses no se ven en el mapa

**Síntoma.** Al abrir el mapa principal no se dibujan las polilíneas de las
líneas de COMUJESA, aunque los datos están cargados.

**Hipótesis.**
1. `route_polylines.dart` recibe lista vacía porque el provider de líneas
   visibles filtra por una flag desactivada por defecto.
2. El `MapFilterState` arranca con `showRoutes=false` tras un cambio reciente.
3. Las polilíneas se dibujan en una capa que queda debajo del tile-layer
   por orden de `children` en `FlutterMap`.

**Σ archivos.**
- `lib/features/map/layers/route_polylines.dart`
- `lib/features/map/map_filter_state.dart`
- `lib/features/map/map_filter_controller.dart`
- `lib/features/map/transit_map.dart`

**CA.**
- [ ] Al abrir el mapa con cualquier operador activo, todas las líneas con
      `is_active=true` se pintan con su color.
- [ ] El test golden `transit_map_with_lines.golden` se actualiza y pasa.
- [ ] El zoom out muestra todas las líneas; el zoom in las mantiene.
- [ ] El filtro "ocultar líneas" sigue funcionando (toggle).

---

### P0-02 🐛 El mapa deja de cargar tras minutos abierto / al cambiar pestañas

**Síntoma.** Tras dejar la app abierta unos minutos o al volver al mapa desde
otra pestaña del navbar, los tiles dejan de descargarse y el mapa queda
gris o solo muestra los marcadores sobre fondo blanco.

**Hipótesis.**
1. Leak de `MapController` — la instancia se reutiliza tras dispose y el
   provider FMTC queda apuntando a un controller muerto.
2. El bus de eventos de `flutter_map_tile_caching` no se libera y el
   pool de descargas se satura tras N entradas/salidas.
3. La pestaña no usa `AutomaticKeepAliveClientMixin` y al recrearse el
   `State` se pierde el `TileLayer.network` provider.

**Σ archivos.**
- `lib/features/map/transit_map.dart`
- `lib/features/map/map_data_cache.dart`
- `lib/features/home/screens/home_screen.dart` (la que aloja el navbar)
- `lib/features/map/map_config.dart`

**Plan de diagnóstico (antes de tocar nada).**
1. Añadir `Sentry.addBreadcrumb` en `initState`/`dispose` de `TransitMap`.
2. Añadir métrica PostHog `map.tiles.failed_after_resume` (ver Anexo D).
3. Reproducir el bug con timer + DevTools Memory para confirmar leak.

**CA.**
- [ ] Tras 10 min con la app abierta en background, al volver al mapa los
      tiles cargan en < 2 s.
- [ ] Tras navegar Mapa → Perfil → Mapa 10 veces seguidas no hay degradación.
- [ ] DevTools Memory: sin crecimiento monotónico del heap tras dispose.
- [ ] Breadcrumbs Sentry confirman único `dispose()` por navegación.

---

### P0-03 🐛 Crear ruta — la app se queda pillada al añadir un horario

**Síntoma.** En el editor de ruta del conductor, al pulsar "Añadir horario"
dentro de `StepSchedules`, la interfaz desaparece y solo queda el fondo
del shader, sin posibilidad de interacción.

**Hipótesis.**
1. `showModalBottomSheet`/`showDialog` se invoca con `barrierColor:
   Colors.transparent` y nunca se hace `Navigator.pop` por error en
   el botón de confirmar.
2. El sheet llama a `setState` sobre un widget ya unmounted y dispara
   excepción silenciada que rompe el render.
3. Stack overflow en validador de TimeOfDay si el campo HH:MM se parsea
   mal y entra en un loop de `addPostFrameCallback`.

**Σ archivos.**
- `lib/features/driver/route_editor/steps/step_schedules.dart`
- `lib/features/driver/route_editor/editor_controller.dart`

**CA.**
- [ ] Al pulsar "Añadir horario" se abre un sheet visible con el reloj.
- [ ] Cancelar el sheet devuelve al editor sin perder horarios previos.
- [ ] Aceptar el sheet añade la hora a la lista y cierra el sheet.
- [ ] No hay excepciones en logs tras 20 ciclos abrir/cancelar.

> **Nota.** Este bug solapa con P2 (rediseño completo del paso Horarios).
> P0 solo desbloquea — el rediseño visual y los modos Fijas/Frecuencia/
> Híbrido se abordan en **P2-05**.

---

### P0-04 🐛 Crear ruta — el botón "Publicar" del final no funciona

**Síntoma.** En `StepReview` el botón "Publicar ruta" parece pulsable pero
nada ocurre — sin snackbar, sin navegación, sin error.

**Hipótesis.**
1. Handler `onPressed: null` por validación silenciosa que ningún
   indicador visible muestra.
2. Llamada a `routeRepository.publish(...)` que lanza excepción y se
   captura sin mostrar nada al usuario.
3. Conflicto con el flujo nuevo de "ruta oficial vs comunidad" (ver
   P1.5-07).

**Σ archivos.**
- `lib/features/driver/route_editor/steps/step_review.dart`
- `lib/features/driver/route_editor/editor_controller.dart`
- `lib/data/route/route_repository_provider.dart`
- `lib/data/route/remote/route_remote_repository.dart`

**CA.**
- [ ] El botón está deshabilitado si la validación global falla y muestra
      tooltip con el motivo.
- [ ] Al pulsar con validación OK se llama a `publish()` y se muestra
      `SnackBar` de éxito → navega a `/driver`.
- [ ] Errores de red se muestran con `SnackBar` rojo + botón "Reintentar".
- [ ] Sentry captura excepciones, PostHog evento `route.publish.attempt`.

---

### P0-05 🐛 Al salir y entrar a la app se pierden los ajustes de apariencia/accesibilidad

**Síntoma.** Cambias tema, paleta, fuente, alto contraste — cierras la
app — al abrir vuelve a los valores por defecto.

**Hipótesis.**
1. `UserPreferencesLocalRepository` no abre el `Hive.box` antes del
   primer `read()`, devolviendo defaults.
2. Las llamadas a `save()` no son `await`-eadas y se pierden al cerrar.
3. El provider de tema lee de una fuente que se reinicializa por bootstrap
   antes de cargar Hive.

**Σ archivos.**
- `lib/data/user_preferences/local/user_preferences_local_repository.dart`
- `lib/data/user_preferences/user_preferences_repository_provider.dart`
- `lib/main.dart` (orden de inicialización)
- `lib/core/theme/theme_controller.dart` (o similar)

**CA.**
- [ ] Cambiar paleta + fuente + alto contraste + cerrar y reabrir: todos
      los ajustes se mantienen.
- [ ] Test de integración `prefs_persistence_test.dart` verifica
      round-trip Hive.
- [ ] El bootstrap espera explícitamente a que el box esté abierto antes
      de renderizar la primera frame (con `FlutterNativeSplash.preserve`).

> **Recordatorio.** Persistencia es **solo Hive local** — no sincronizar en
> `user_preferences` de Supabase para esta fase. Si en el futuro se quiere
> sync entre dispositivos, será una feature opcional (out of scope V16).

---

### P0-06 🐛 Perfil sin nombre ni imagen — solo aparece icono de interrogación

**Síntoma.** Al abrir el perfil del usuario logueado, el avatar es un
círculo gris con "?" y el nombre está vacío o dice "Usuario".

**Hipótesis.**
1. El widget de perfil lee de un provider que devuelve `User?` y muestra
   placeholder si es null — pero el `User` está cargado en
   `Supabase.auth.currentUser`, solo falta cablear.
2. `user_metadata.full_name` y `user_metadata.avatar_url` no se leen
   (Google Sign-In los rellena pero el código solo mira `email`).

**Σ archivos.**
- `lib/features/home/tabs/profile_tab.dart` (o `lib/features/home/widgets/profile_*`)
- `lib/data/auth/auth_repository.dart` (o equivalente)
- `lib/features/profile/widgets/profile_header.dart` (nuevo si no existe)

**Diseño avatar/nombre.**
- **Nombre**: `user_metadata.full_name` → fallback `user_metadata.name` →
  fallback parte antes de `@` del email → fallback "Usuario".
- **Avatar**: `user_metadata.avatar_url` → si existe, `Image.network` con
  placeholder shimmer y fallback a iniciales si falla la carga.
- **Iniciales**: primeras letras de cada palabra del nombre (máx 2),
  sobre `CircleAvatar` con `backgroundColor = scheme.primaryContainer`.

**CA.**
- [ ] Login con Google: nombre y foto aparecen instantáneamente.
- [ ] Login con email/password: nombre del metadata, iniciales como avatar.
- [ ] Si la foto falla de red: degrada a iniciales sin romper el layout.
- [ ] El componente se reutiliza en navbar (P0-07), header de perfil y
      cualquier comentario/feedback del usuario.

---

### P0-07 🐛 El botón perfil del navbar inferior tiene una zona táctil minúscula

**Síntoma.** Hay que pulsar exactamente sobre el icono del perfil en el
navbar — el resto de la pestaña no responde.

**Hipótesis.**
1. El `BottomNavigationBarItem` envuelve el icono en un `Padding` muy
   pequeño y el `InkWell` solo cubre eso.
2. Versión custom del navbar (`home_side_nav.dart`) sin `GestureDetector`
   en el contenedor padre.

**Σ archivos.**
- `lib/features/home/widgets/home_tab_item.dart`
- `lib/features/home/widgets/home_side_nav.dart`
- Cualquier `BottomNavigationBar` o sustituto en `home_screen.dart`.

**CA.**
- [ ] Toda la pestaña (icono + label + padding) es hitbox del botón.
- [ ] El hitbox mínimo es 48×48 dp (WCAG 2.5.5 target size).
- [ ] Se aplica también al resto de pestañas del navbar (consistencia).

---

### P0-08 🐛 "Seleccionar zona principal" da error de operador

**Síntoma.** En el flujo de elegir zona principal/ciudad/operador, salta un
error en pantalla o se queda en blanco. Probablemente null check missing.

**Hipótesis.**
1. `currentLocationProvider` accede a `activeOperator!` cuando aún no se
   ha cargado el provider de operadores.
2. `CityPickerScreen` asume que `operatorRepository.getActive()` devuelve
   no-null y revienta en la rama "primer arranque sin operador".

**Σ archivos.**
- `lib/features/city_picker/city_picker_screen.dart`
- `lib/data/operator/operator_repository_provider.dart`
- `lib/data/geo/geo_providers.dart`

**CA.**
- [ ] Flujo en primer arranque sin operador seleccionado: la pantalla
      "Elige tu zona" muestra la lista de operadores disponibles sin
      excepción.
- [ ] Al pulsar un operador se guarda en `shared_preferences` y se navega
      al home.
- [ ] Cambiar de zona desde perfil funciona sin reiniciar la app.
- [ ] Test de widget que cubre el caso "ningún operador activo".

---

### P0-09 🐛 El historial de saldo de la tarjeta NFC no aparece al iniciar sesión

**Síntoma.** Al hacer login, la tarjeta muestra saldo "—" y la pestaña de
historial está vacía aunque haya lecturas previas.

**Decisión arquitectónica.** Historial **local-only en Hive** bajo clave
`nfc_card_history:<userId>`. No se sube a Supabase. Privado y rápido.

**Σ archivos.**
- `lib/data/nfc/nfc_card_service.dart`
- `lib/features/home/tabs/card_tab.dart`
- `lib/data/cache/hive_adapters.dart` (registrar `NfcCardScanAdapter` si
  aún no está)

**CA.**
- [ ] Al iniciar sesión, el `card_tab` hidrata el historial desde Hive
      sin esperar red.
- [ ] Una lectura NFC añade entrada con timestamp y persiste en Hive.
- [ ] Cerrar sesión limpia la caché del usuario actual (no la de otros
      perfiles si los hubiera en multi-cuenta).
- [ ] El widget "Saldo" del home_widget (P1-04) consume la misma fuente
      Hive.

---

## Fase P1 — Funcionalidad rota (8 ítems)

Pantallas/flujos que aparecen reales pero no hacen nada o están a medias.

### P1-01 ✅ Privacidad — cablear todo a Supabase

> **Cerrado 2026-06-05** en branch `fix/p1-sub-e-privacidad-accesibilidad`
> commit `c7efa0f9`. El wiring Supabase ya estaba completo (consents,
> exports, deletion + edge functions); lo que faltaba era UX:
> `SmokeBackground` + spinner inline durante el await + snackbars con
> duración explícita (4-6s) y color rojo en errores.

**Síntoma.** La pantalla de privacidad no tiene fondo, los consentimientos
no se persisten, "Mis datos" y "Solicitar borrado" son falsos, los
enlaces legales no funcionan.

**Estado backend.** La infraestructura ya existe:
- Migración `001_init.sql` define `privacy_consents`, `data_exports`,
  `data_deletion_requests`.
- Migración `002_rls.sql` aplica RLS por usuario.
- Migración `004_storage.sql` crea el bucket `data-exports`.
- Migración `016_data_exports.sql` define funciones
  `request_data_export()` y `request_data_deletion()`.

→ El plan **solo arregla el wiring Flutter**, no añade migraciones.

**Σ archivos.**
- `lib/features/privacy/privacy_screen.dart`
- `lib/data/privacy_consent/privacy_consent_repository.dart`
- `lib/data/privacy_consent/local/...` (nuevo)
- `lib/data/privacy_consent/remote/...` (nuevo)
- `lib/features/privacy/widgets/consent_card.dart` (nuevo)
- `lib/features/privacy/widgets/data_export_card.dart` (nuevo)
- `lib/features/privacy/widgets/data_deletion_card.dart` (nuevo)
- `lib/features/privacy/widgets/legal_links_card.dart` (nuevo)
- `assets/legal/aviso_legal.pdf`, `politica_privacidad.pdf`,
  `politica_cookies.pdf` (nuevos)

**Sub-tareas.**
1. **Fondo del tema.** Envolver con `TransitScaffold` o equivalente.
2. **Consentimientos reales.** Read/write desde `privacy_consents` con
   tres switches: telemetría (PostHog), errores (Sentry), notificaciones
   push. Cada toggle hace un `upsert` y refleja el último estado del
   servidor.
3. **Mis datos.** Botón "Solicitar exportación" llama a
   `supabase.rpc('request_data_export')`. La UI muestra estado
   (`queued`/`processing`/`ready`) y, cuando esté `ready`, un botón
   "Descargar" que abre la URL firmada del bucket `data-exports`.
4. **Solicitar borrado.** Botón "Solicitar borrado de mis datos" llama a
   `supabase.rpc('request_data_deletion')`. UI muestra `requested_at` y
   `scheduled_at` (+30 días) con texto claro. Botón "Cancelar solicitud"
   solo si `status='requested'`.
5. **Legal.** Tres entradas que abren PDFs locales en assets con
   `url_launcher` o un visor in-app simple.

**CA.**
- [x] Pantalla con fondo de paleta (SmokeBackground).
- [x] Cambiar un consentimiento + recargar mantiene el cambio
      (wiring pre-existente).
- [x] "Solicitar exportación" inserta fila + invoca edge function +
      spinner + snackbar 4s.
- [x] "Solicitar borrado" inserta fila con `scheduled_at = NOW() + 30d`
      + spinner + snackbar 5s.
- [pending-P1.5-04] El admin lo ve en su bandeja cuando se construya.
- [partial] Legal abre `Env.tosUrl` y `Env.privacyUrl` con
      `url_launcher` (no PDFs en assets — decisión simplificada).

---

### P1-02 ✅ Accesibilidad — siempre sale "modo ninguno" + mover dislexia/daltonismo

> **Cerrado 2026-06-05** en branch `fix/p1-sub-e-privacidad-accesibilidad`
> commits `5d117df6` (label dinámico) + `f5e26c2a` (mover dislexia/daltonismo).

**Síntoma.**
- En la pestaña Accesibilidad del perfil aparece siempre "modo: ninguno"
  aunque haya selecciones.
- Dislexia (fuente OpenDyslexic) y daltonismo (paletas alternativas) están
  metidos en Apariencia cuando son ajustes de accesibilidad.

**Σ archivos.**
- `lib/features/profile/accessibility_settings_screen.dart`
- `lib/features/home/widgets/profile_accessibility_section.dart`
- `lib/features/home/widgets/profile_appearance_section.dart`
- `lib/features/appearance/widgets/font_section.dart` (mover dislexia
  fuera de aquí o hacer alias)
- `lib/core/theme/accessibility_matrix.dart`

**Plan.**
1. Mover el selector de fuente "OpenDyslexic" de `font_section` a
   `accessibility_settings_screen` como ajuste "Apoyo a dislexia".
2. Mover el selector de daltonismo (protanopia/deuteranopia/tritanopia)
   desde Apariencia a Accesibilidad como "Filtros de daltonismo".
3. Arreglar el resumen "modo: X" leyendo del controller real
   (probablemente está cableado a un provider obsoleto).
4. En Apariencia dejar solo: paleta, tema (claro/oscuro/auto),
   fuente "general" (DM Sans / Atkinson / IBM Plex), alto contraste,
   shaders de fondo.

**CA.**
- [x] La sección Accesibilidad muestra estado real vía
      `buildAccessibilitySummary` ("Daltonismo: deuteranopia · Dislexia
      activa · Contraste alto"); tests cubren los combos.
- [x] Dislexia y daltonismo desaparecen de Apariencia (font_section,
      appearance/accessibility_section).
- [x] Cambiar dislexia desde Accesibilidad cambia la fuente global
      (mismo setter ThemeNotifier que antes).
- [x] Persistencia: misma sesión Hive guest_theme_prefs (sin cambios).

---

### P1-03 ✅ Apariencia — bug "alto contraste" + "mantener color de paleta"

> **Cerrado 2026-06-05** en branch `fix/p1-sub-e-privacidad-accesibilidad`
> commit `f5e26c2a`. Causa raíz: el sub-Switch "Conservar acento" estaba
> añadido como TERCER hijo del Row del Switch padre — el `if (highContrast)
> Padding(...)` quedó dentro del Row mismo. Fix: Column wrapping con dos
> Rows hermanas, sub-row indentada con icono y descripción extra. La
> versión Off/AA/AAA del plan V16 queda como follow-up (requiere
> convertir `bool` en enum + adaptar `HighContrastTheme.apply`).

**Síntoma.** Hay dos toggles ("Alto contraste" + "Mantener color de la
paleta") con relación rota — el segundo solo se activa si desactivas el
primero y a veces ambos quedan en estado inconsistente. En modo claro el
texto se ve mal.

**Diseño nuevo.**

```
Sección "Contraste"
├── Selector segmentado:  [ Off | AA | AAA ]
│   └── "Off" desactiva el realce de contraste.
│       "AA" cumple WCAG 2.2 AA (4.5:1 texto normal, 3:1 grande).
│       "AAA" cumple WCAG 2.2 AAA (7:1 texto normal, 4.5:1 grande).
│
└── Toggle: "Conservar acento de la paleta"
    └── Habilitado solo si Contraste ≠ Off.
    └── Si está activo, el acento (botones, links) mantiene el color de la
        paleta seleccionada, ajustando solo backgrounds y textos para
        cumplir el ratio.
    └── Si está inactivo, se aplica una paleta monocroma B/N estricta
        (máximo contraste) en todos los elementos.
```

**Σ archivos.**
- `lib/features/appearance/widgets/brightness_section.dart` (o donde
  esté el toggle actual)
- `lib/core/theme/contrast_utils.dart`
- `lib/core/theme/accessibility_matrix.dart`

**CA.**
- [ ] Selector AA/AAA aplica contraste correctamente medido (test
      unitario con `contrast_utils.computeRatio`).
- [ ] "Conservar acento" sólo se puede tocar cuando AA o AAA activos.
- [ ] Modo claro + AA: el texto secundario sigue siendo legible (no gris
      claro sobre blanco).
- [ ] Persistencia: ambos valores sobreviven cierre de app.

---

### P1-04 ✨ Widgets — rediseño completo de la configuración

**Síntoma.** Los widgets (Android `home_widget`):
- No se actualizan una vez puestos en la home del móvil.
- El buscador de "parada favorita" y "línea favorita" no muestra
  paradas/líneas reales.
- Faltan opciones de personalización.

**Capacidades nuevas.**
1. **Preview en vivo** dentro de la app, en la pantalla de configuración
   del widget. Render fiel a cómo se verá en la home del móvil. Se
   recalcula al cambiar cualquier ajuste.
2. **Selector de parada/línea** con buscador real conectado a
   `stopRepository`/`routeRepository`. Lista virtualizada, filtro por
   nombre y código, agrupado por línea.
3. **Tamaño S / M / L.** S = solo próxima salida. M = lista 3 próximas.
   L = lista 5 + saldo de tarjeta + botón refrescar.
4. **Tema independiente.** Selector: Auto (sigue el del sistema) /
   Claro / Oscuro / "Color de marca" (paleta primaria de Transitly).
5. **Frecuencia de refresco + refresh manual.** Selector 15 / 30 / 60
   min para `WorkManager`. Botón "Refrescar ahora" llama directamente a
   `HomeWidget.updateWidget(...)`. **Arregla el bug "no se actualizan"**:
   el `WorkManager` no se cableó (ver `pubspec.yaml:51-54` — workmanager
   está marcado eliminado por un crash de build, hay que volver a
   integrarlo con la versión actual o usar alternativa
   `flutter_background_service`/Android JobScheduler nativo).

**Σ archivos.**
- `lib/features/profile/widgets/widget_settings_section.dart` (nuevo)
- `lib/features/profile/widgets/widget_preview.dart` (nuevo)
- `lib/features/profile/widgets/widget_stop_picker_sheet.dart` (nuevo)
- `lib/features/profile/widgets/widget_route_picker_sheet.dart` (nuevo)
- `android/app/src/main/res/layout/widget_small.xml` (revisar tres
  layouts S/M/L)
- `android/app/src/main/kotlin/.../HomeWidgetProvider.kt`
- `pubspec.yaml` (re-evaluar `workmanager` o alternativa)

**Decisión pendiente — refresco periódico.** Tres opciones:
- **A. `workmanager` actualizado**: si la 0.6+ ya resolvió el embedding
  v1 issue, volver a integrar. Investigar antes de implementar.
- **B. AlarmManager nativo Kotlin**: Service nativo Android que pinchea
  cada N min vía `HomeWidget.updateWidget`. Más manual, fiable.
- **C. Solo refresh on-resume + manual**: el widget se refresca cuando
  abres la app y cuando el usuario pulsa "Refrescar". Más simple,
  menos "vivo". Aceptable para TFG.

> Recomendación: **C** para esta fase + plan futuro de **B** si el TFG
> requiere widget realmente vivo. Documentar la decisión en `docs/
> HOME_WIDGETS.md`.

**CA.**
- [ ] La pantalla de configuración muestra preview en vivo del widget.
- [ ] Buscador encuentra paradas y líneas reales (con autocompletado).
- [ ] Cambiar de tamaño actualiza el preview.
- [ ] Cambiar de tema actualiza el preview.
- [ ] "Refrescar ahora" recarga el widget en la home Android en < 2 s.
- [ ] Tras seleccionar una parada favorita, el widget en la home muestra
      sus próximas salidas y se mantiene tras cerrar la app.

---

### P1-05 🧱 Eliminar "Gestionar mis filtros" (FilterPresets)

**Síntoma.** La pantalla `filter_presets_screen.dart` es un placeholder
sin valor; está desde la fase F19 sin cerrar.

**Plan.**
1. Eliminar el archivo `lib/features/profile/filter_presets_screen.dart`.
2. Eliminar la ruta `/profile/filters` del `go_router`.
3. Eliminar el ítem "Gestionar mis filtros" de la sección Perfil →
   Acciones avanzadas.
4. Eliminar el item correspondiente de `docs/PENDIENTES.md` (mejora
   `1.10a`).

**CA.**
- [ ] La opción ya no aparece en el perfil.
- [ ] `flutter analyze`: 0 issues (no imports rotos).
- [ ] `flutter test`: pasa todos los tests existentes (si alguno cubría
      esa pantalla, eliminarlo).

---

### P1-06 ✨ Datos offline — hacer funcional con OfflineRegions

**Síntoma.** La sección "Datos offline" del perfil es un placeholder.

**Plan.**
- Cablear la pantalla `offline_regions_screen.dart` (ya existe) a
  `offline_region_repository`. Usar `flutter_map_tile_caching` (ya en
  pubspec) para descargas reales.
- Permitir: crear región (selección de área en mapa), descargar, ver
  progreso, ver tamaño, borrar.
- Persistencia local en Hive (no Supabase).

**Σ archivos.**
- `lib/features/offline/offline_regions_screen.dart`
- `lib/features/offline/widgets/region_progress_card.dart`
- `lib/features/offline/widgets/region_status_badge.dart`
- `lib/features/profile/offline_data_screen.dart` (probablemente solo
  redirige a `/offline/regions`)
- `lib/data/offline_region/local/offline_region_local_repository.dart`

**CA.**
- [ ] Crear región: el usuario dibuja un rectángulo en el mapa, da
      nombre, confirma. La región aparece en la lista en estado
      "descargando".
- [ ] El progreso avanza visualmente; al terminar, queda "descargado" y
      muestra tamaño en MB.
- [ ] Borrar región libera el espacio en disco (verificable via
      DevTools/`du`).
- [ ] Modo avión + región descargada: los tiles se muestran offline en
      el mapa.

---

### P1-07 ✨ Fusionar "zonas" + "mostrar líneas" en el dropdown del mapa

**Síntoma.** El sheet de ajustes del mapa tiene dos secciones que
muestran prácticamente la misma información.

**Plan.**
- Una sola sección "Líneas y zonas" en `map_filter_sheet.dart` con la
  jerarquía: Zona → Operador → Línea. Implementado como
  `ExpansionTile` agrupado (puede aprovechar `zone_company_line_tree.dart`).
- Toggle global "Mostrar líneas" arriba.
- Eliminar el modelo `MapFilterState.showZones` si solo se usaba para
  pintar círculos redundantes. Mover su lógica a una visualización
  contextual (solo se pintan zonas en zoom-out > 14).

**Σ archivos.**
- `lib/features/map/widgets/map_filter_sheet.dart`
- `lib/features/map/widgets/zone_company_line_tree.dart`
- `lib/features/map/map_filter_state.dart`
- `lib/features/map/map_filter_controller.dart`

**CA.**
- [ ] El sheet de ajustes del mapa tiene solo una sección "Líneas y
      zonas".
- [ ] Marcar/desmarcar una línea afecta el mapa instantáneamente.
- [ ] Las zonas aparecen como capa visual contextual sin requerir
      ajuste separado.
- [ ] Persistencia del filtro en Hive entre sesiones.

---

### P1-08 ✨ Botón cerrar al clickar una línea — rediseño

**Síntoma.** El botón cerrar del bottom-sheet de detalle de línea queda
mal posicionado e incómodo.

**Diseño nuevo.**
- Sustituir botón "X" por **handle bar** estándar (4px alto, 36px ancho,
  centrado, color `scheme.outlineVariant`).
- Gesto **swipe-down** para cerrar (ya viene gratis con
  `DraggableScrollableSheet`).
- **Tap fuera** del sheet también cierra.
- Opcional: botón "Ver línea completa" en el sheet que navega a
  `/route/:id` para detalles extendidos.

**Σ archivos.**
- `lib/features/map/sheets/trip_info_sheet.dart`
- `lib/features/route_detail/widgets/route_detail_header.dart` (si se
  reusa)

**CA.**
- [ ] El sheet tiene handle bar visible.
- [ ] Swipe down cierra el sheet con animación natural.
- [ ] Tap fuera cierra también.
- [ ] No hay botón "X" sobresaliendo en una esquina.
- [ ] Funciona idéntico en portrait y landscape.

---

## Fase P1.5 — Sistema admin/operator/conductor (7 ítems)

Bloque coherente con jerarquía estricta:

```
Admin ──crea──> Operador ──crea código──> Usuario ──canjea código──> Conductor
                                          │
                                          └──> Conductor crea: rutas y paradas oficiales
                                          
Admin también ve: solicitudes RGPD, sugerencias, alta operador/conductor,
                  incidencias y feedback escalado
```

### P1.5-01 ✨ Bootstrap admin vía SQL

Ver **Anexo B**. Resumen:
- El usuario hace login normal con email/Google.
- En Supabase SQL Editor el dueño del proyecto ejecuta:
  ```sql
  UPDATE profiles SET role = 'admin' WHERE email = 'tu@email.com';
  ```
- El próximo login refresca el JWT y el cliente Flutter lee el rol.

**Σ archivos.**
- `lib/data/auth/auth_repository.dart` (cachear rol)
- `lib/core/router/redirect_guards.dart` (guard `requireAdmin`)

**CA.**
- [ ] Tras el UPDATE manual, la próxima sesión del usuario ve el botón
      "Panel admin" en perfil.
- [ ] El guard de `/admin/*` rechaza usuarios no admin con redirect a
      `/`.

---

### P1.5-02 ✨ Esquema Supabase — campos faltantes y RLS

**Estado.** Base ya existe (`profiles.role`, `invitation_codes`,
`driver_assignments`). Lo que falta:

- Campo `operators.is_active BOOLEAN DEFAULT true` (si no existe).
- Tabla `operator_route_proposals` (rutas/paradas oficiales pendientes
  de aprobar por admin si las crea un conductor).
- Flags `is_official BOOLEAN DEFAULT false` en `routes` y `stops` para
  diferenciar oficial vs comunidad.
- RLS para admin (acceso total) y operator (acceso a sus operadores/
  conductores).

Ver **Anexo A** para la migración SQL `021_admin_extras.sql` propuesta.

**CA.**
- [ ] La migración aplica sin errores en local y remoto.
- [ ] Tests SQL: admin ve todo, operator_admin solo lo suyo, driver
      solo lo suyo, user nada de admin.

---

### P1.5-03 ✨ Pantalla admin — Operadores (CRUD)

**Ya existe** parcialmente `admin_operators_screen.dart`. Cerrar:

- Lista de operadores con buscador.
- Crear/editar/eliminar (modal `operator_form_dialog.dart`).
- Ver conductores de cada operador.
- Ver rutas oficiales de cada operador.
- Generar código de invitación maestro tipo `operator_admin` (solo
  admin puede).

**Σ archivos.**
- `lib/features/admin/admin_operators_screen.dart`
- `lib/features/admin/widgets/operator_form_dialog.dart`
- `lib/features/admin/widgets/operator_drivers_list.dart` (nuevo)

**CA.**
- [ ] CRUD funcional sobre la tabla `operators`.
- [ ] Al crear un operador se pide nombre, slug, color, contacto.
- [ ] Eliminar operador con confirmación + cascade lógico (los
      conductores quedan revocados, las rutas se preservan marcadas como
      "operador eliminado").

---

### P1.5-04 ✨ Pantalla admin — Solicitudes (bandeja unificada)

Nueva pantalla `admin_requests_screen.dart` con tabs:

1. **Borrado RGPD** — `data_deletion_requests` con `status='requested'`.
   Acciones: aprobar (ejecuta el borrado vía Edge Function), cancelar
   (status='rejected').
2. **Sugerencias de rutas** — `route_suggestions` pendientes. Acciones:
   aprobar (queda visible como `is_official=true` si viene de operator),
   rechazar.
3. **Alta de operador/conductor** — tabla nueva `operator_applications`
   y `driver_applications` (ver Anexo A). Admin aprueba alta operador,
   operator aprueba alta conductor.
4. **Incidencias/feedback escalado** — `incidents` y `route_feedback`
   con flag `escalated_to_admin=true`. Acciones: marcar resuelto,
   responder.

**Σ archivos.**
- `lib/features/admin/admin_requests_screen.dart` (nuevo)
- `lib/features/admin/widgets/requests_tab_*.dart` (4 widgets de tab)
- `lib/data/admin/admin_requests_repository.dart` (nuevo)

**CA.**
- [ ] El admin abre la bandeja y ve los 4 tabs con badge de count.
- [ ] Acciones de aprobar/rechazar actualizan la fila en Supabase con
      `actioned_by = auth.uid()` y `actioned_at = NOW()`.
- [ ] Sentry log del cambio para auditoría.

---

### P1.5-05 ✨ Pantalla operator — Códigos de invitación

**Estado.** Ya existe `invitation_codes_screen.dart`. Cerrar:

- Generar código con N usos configurables (1, 5, 10, ilimitado) y
  fecha de expiración (default +30 días).
- Lista de códigos activos con `used_count / max_uses`.
- Botón "Compartir" (vía `share_plus`).
- Botón "Revocar" (`expires_at = NOW()`).

**Σ archivos.**
- `lib/features/operator_admin/invitation_codes_screen.dart`
- `lib/data/operator/operator_helpers.dart`

**CA.**
- [ ] El operator_admin genera código → ve formato `XXX-XXXX-XX`.
- [ ] El código compartido por WhatsApp es texto plano canjeable.
- [ ] Revocar un código impide nuevos usos sin tocar los pasados.

---

### P1.5-06 ✨ Activación conductor — `/driver/activate`

**Estado.** Pantalla `activate_driver_screen.dart` existe. Verificar:

- Input de código con máscara.
- Llamada a `supabase.rpc('claim_invitation_code', code)`.
- Tras éxito: refrescar sesión, navegar a `/driver` con rol conductor.
- Errores: código expirado / agotado / inválido con UI clara.

**CA.**
- [ ] Canjear código válido → entra en panel de conductor.
- [ ] Código expirado muestra mensaje + sugerencia "Pide otro al
      operador".

---

### P1.5-07 ✨ Rutas y paradas oficiales vs comunidad

**Plan.**
- Añadir flag `is_official BOOLEAN` en `routes` y `stops` (Anexo A).
- Operator y driver crean rutas como `is_official=true` por defecto.
- Usuarios normales crean rutas como `is_official=false` (sugerencias
  comunitarias).
- En la UI del mapa y listados:
  - Rutas oficiales: badge dorado "Oficial · Operador X".
  - Rutas comunitarias: badge gris "Comunidad · Usuario Y".
- Filtro en el mapa: "Mostrar comunitarias" (toggle, off por defecto).

**Σ archivos.**
- `lib/features/route_detail/widgets/route_detail_header.dart` (badge)
- `lib/features/map/transit_map.dart` (filtro)
- `lib/features/driver/route_editor/editor_controller.dart` (set flag)

**CA.**
- [ ] Una ruta creada por un conductor sale marcada oficial.
- [ ] Una ruta creada por usuario común sale marcada comunidad.
- [ ] El filtro del mapa oculta/muestra comunidad sin tocar oficiales.

---

## Fase P2 — Crear ruta (rediseño UX) (6 ítems)

Bloque coherente del editor del conductor. Toda la fase tras tener P0
estable (porque P0-03 y P0-04 desbloquean el editor en general).

### P2-01 🐛 Quitar selector de color duplicado en paso Info

**Síntoma.** En el paso Info aparecen dos pickers de color seguidos que
hacen lo mismo.

**Plan.** Borrar el segundo. Probablemente residuo de un refactor.

**Σ archivos.**
- `lib/features/driver/route_editor/steps/step_info.dart`

**CA.**
- [ ] Solo un selector de color en el paso Info.
- [ ] El color elegido se propaga a `step_review` correctamente.

---

### P2-02 ✨ Mejorar dropdown de tipos de servicio

**Síntoma.** El dropdown de tipo es incómodo (probablemente
`DropdownButton` con texto plano).

**Diseño nuevo.** Sustituir por **ChoiceChips** horizontales scrollables
con icono + label:
- 🚌 Urbano
- 🚎 Metropolitano
- 🚍 Especial
- 🎟️ Bonobús

Cada chip pintado con el color del tipo (definir paleta en
`route_service_type_colors.dart`).

**Σ archivos.**
- `lib/features/driver/route_editor/steps/step_info.dart`
- `lib/core/theme/route_service_type_colors.dart` (nuevo)

**CA.**
- [ ] Chips visibles con icono + label.
- [ ] Selección reflejada con `MaterialState.selected`.
- [ ] Mobile portrait: scroll horizontal si no caben.

---

### P2-03 🐛 Validación bloqueante del color en paso Siguiente

**Síntoma.** A veces hay que cambiar el color para activar "Siguiente"
aunque toda la info esté rellena. Bug del listener.

**Plan.** Auditar `editor_controller.dart` — probablemente
`canProceedToNext` depende de un campo que no notifica `notifyListeners()`
cuando se rellena por primera vez. Cablear bien.

**Σ archivos.**
- `lib/features/driver/route_editor/editor_controller.dart`

**CA.**
- [ ] Rellenar todos los campos requeridos del paso → "Siguiente" se
      habilita sin tocar el color.
- [ ] Test unitario `editor_controller_test.dart` verifica el listener.

---

### P2-04 ✨ Selección de paradas — buscador + ordenable por orden de paso

**Síntoma.** El paso de paradas no permite buscar por nombre y el orden
en que pasa el bus es difícil de definir.

**Diseño nuevo.**
- Cabecera con `SearchBar` que filtra la lista (por nombre, código).
- Lista `ReorderableListView` con drag handles visibles.
- Cada item: número de orden (1, 2, 3…), nombre, código, distancia
  desde anterior (calculada con haversine), botón eliminar.
- Botón "Añadir parada" abre un sheet con buscador + selección múltiple.
- Botón "Invertir orden" (útil si grabaste la vuelta).

**Σ archivos.**
- `lib/features/driver/route_editor/steps/step_stops.dart`
- `lib/features/driver/route_editor/widgets/stop_picker_sheet.dart` (nuevo)

**CA.**
- [ ] Buscador filtra en tiempo real.
- [ ] Drag&drop reordena con feedback visual.
- [ ] El orden se mantiene al guardar y se refleja en el mapa.
- [ ] Botón "Invertir orden" funciona.

---

### P2-05 ✨ Trazar el camino — editor de polilínea agrandado y usable

**Síntoma.** El recuadro de "Trazar el camino" es minúsculo y los
gestos no van bien.

**Plan.**
- Hacer el editor del mismo tamaño que el paso de paradas (full screen
  menos cabecera de pasos y botones).
- Gestos:
  - **Tap simple** → añade vértice al final.
  - **Long-press sobre un vértice** → modo arrastrar.
  - **Tap sobre un vértice + botón "Eliminar"** → borra ese vértice.
  - **Doble tap** → cierra el polígono (vuelve al primero) para rutas
    circulares.
- Modos:
  - **Manual** (lo de ahora).
  - **Sugerido** — sigue las calles del routing local (futuro, fuera
    de scope V16).
- Mostrar la lista de paradas como marcadores sobre el mapa de fondo
  para guiar el trazado.

**Σ archivos.**
- `lib/features/driver/route_editor/steps/step_trace.dart`
- `lib/features/driver/route_editor/widgets/polyline_editor.dart` (nuevo)

**CA.**
- [ ] El editor ocupa el alto del paso de paradas.
- [ ] Tap añade vértice; el trazado se redibuja al instante.
- [ ] Long-press + drag mueve un vértice existente.
- [ ] Las paradas son visibles como referencia.
- [ ] El total de km del trazado se calcula y muestra.

---

### P2-06 ✨ Horarios — sistema mixto por parada (Fijas / Frecuencia / Híbrido)

**Síntoma.** Horarios poco claros, visualmente feos, no permiten varios
por día.

**Diseño nuevo.**

```
Paso "Horarios"
├── Por cada parada del listado:
│   ├── Card con nombre + segmented control: [ Fijas | Frecuencia | Híbrido ]
│   │
│   ├── Modo "Fijas":
│   │   ├── Lista de horas (chips de TimeOfDay) ordenadas.
│   │   ├── Botón "+ Añadir hora" → abre selector mixto:
│   │   │   ┌──────────────────────────────┐
│   │   │   │  [ Reloj ]    [ Escribir ]   │
│   │   │   │  ─────────    ─────────       │
│   │   │   │  showTimePicker  HH:MM input  │
│   │   │   └──────────────────────────────┘
│   │   └── Las horas se ordenan automáticamente al añadir.
│   │
│   ├── Modo "Frecuencia":
│   │   ├── Inicio: HH:MM
│   │   ├── Fin: HH:MM
│   │   ├── Intervalo: dropdown (5, 10, 15, 20, 30, 60 min)
│   │   ├── Preview: "Genera 27 horas: 07:00, 07:15, 07:30, ..., 13:30"
│   │   └── Botón "Ver todas" → expandible.
│   │
│   └── Modo "Híbrido":
│       ├── Plantilla Frecuencia (igual que arriba).
│       ├── Sub-sección "Horas extra" (lista).
│       ├── Sub-sección "Horas excluidas" (lista).
│       └── Preview de la combinación.
│
└── Días de la semana:
    ├── Selector de días aplicables (L M X J V S D).
    └── Botón "Aplicar a otros días" para copiar la config.
```

**Σ archivos.**
- `lib/features/driver/route_editor/steps/step_schedules.dart`
- `lib/features/driver/route_editor/widgets/schedule_mode_selector.dart` (nuevo)
- `lib/features/driver/route_editor/widgets/schedule_fixed_editor.dart` (nuevo)
- `lib/features/driver/route_editor/widgets/schedule_frequency_editor.dart` (nuevo)
- `lib/features/driver/route_editor/widgets/schedule_hybrid_editor.dart` (nuevo)
- `lib/features/driver/route_editor/widgets/time_picker_dual.dart` (nuevo,
  combina reloj + escribir)
- `lib/data/schedule/domain/schedule_repository.dart` (modelo extendido)

**Modelo de datos (en cliente — el formato Supabase ya soporta esto).**
```dart
sealed class ScheduleConfig {
  const ScheduleConfig();
}
class FixedSchedule extends ScheduleConfig {
  final List<TimeOfDay> times;
  ...
}
class FrequencySchedule extends ScheduleConfig {
  final TimeOfDay start, end;
  final Duration interval;
  ...
  List<TimeOfDay> generate() { ... }
}
class HybridSchedule extends ScheduleConfig {
  final FrequencySchedule base;
  final List<TimeOfDay> extras;
  final List<TimeOfDay> exclusions;
  ...
  List<TimeOfDay> resolve() { ... }
}
```

**CA.**
- [ ] El segmented control cambia entre los 3 modos sin perder datos
      cuando se vuelve.
- [ ] Modo Fijas: añadir hora con reloj o tecleando funciona.
- [ ] Modo Frecuencia: el preview muestra correctamente las horas
      generadas.
- [ ] Modo Híbrido: extras se añaden, exclusiones se quitan, preview
      las refleja.
- [ ] Selector de días de la semana persiste.
- [ ] Tests unitarios para `FrequencySchedule.generate()` y
      `HybridSchedule.resolve()`.

---

## Fase P2.5 — Responsive multiplataforma (4 ítems)

Adaptación a Web + tablet + landscape. Se aborda al final cuando todo
lo demás está estable.

### P2.5-01 ✨ Sistema de breakpoints

Crear `lib/core/responsive/breakpoints.dart`:

```dart
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
  static const double desktop = 1440;
  
  static bool isMobile(BuildContext c) =>
      MediaQuery.sizeOf(c).width < mobile;
  static bool isTablet(BuildContext c) {
    final w = MediaQuery.sizeOf(c).width;
    return w >= mobile && w < tablet;
  }
  static bool isDesktop(BuildContext c) =>
      MediaQuery.sizeOf(c).width >= tablet;
}
```

Más un `ResponsiveBuilder` helper para layouts adaptativos.

**Σ archivos.**
- `lib/core/responsive/breakpoints.dart` (nuevo)
- `lib/core/responsive/responsive_builder.dart` (nuevo)

**CA.**
- [ ] Helpers disponibles para todo el código.
- [ ] Tests de widget verifican los breakpoints en distintas
      `MediaQuery.size`.

---

### P2.5-02 ✨ Navbar landscape / tablet / desktop → NavigationRail

**Síntoma.** El navbar inferior en landscape se ve mal.

**Plan.**
- En `home_screen.dart`, usar `ResponsiveBuilder`:
  - Mobile portrait → `BottomNavigationBar` actual.
  - Mobile landscape + tablet + desktop → `NavigationRail` lateral.
- El `home_side_nav.dart` ya existe — probablemente solo falta
  cablearlo al breakpoint.

**Σ archivos.**
- `lib/features/home/screens/home_screen.dart` (o equivalente)
- `lib/features/home/widgets/home_side_nav.dart`

**CA.**
- [ ] Rotar móvil → cambia a side nav sin perder estado.
- [ ] Tablet portrait → side nav.
- [ ] Web desktop → side nav extendido con labels.

---

### P2.5-03 ✨ Pantallas con max-width en desktop

**Plan.** Todas las pantallas tipo listado/formulario en desktop se
centran con `maxWidth: 800` (excepto el mapa que es full-bleed).

Crear helper `ResponsivePageWrapper` que envuelve el body.

**Σ archivos.**
- `lib/core/responsive/responsive_page_wrapper.dart` (nuevo)
- Aplicar selectivamente: perfil, accesibilidad, privacidad, notifications,
  feedback, contributions, driver dashboard, admin screens.

**CA.**
- [ ] Web desktop 1920×1080: las pantallas listado/form están centradas
      y no estiradas a todo el ancho.
- [ ] Web mobile 360 wide: el wrapper no introduce padding extra.

---

### P2.5-04 🧱 Verificar build web

**Plan.**
- `flutter build web --release` debe pasar.
- Verificar que `flutter_map_tile_caching` funciona en web (puede
  requerir fallback a tiles sin caché si la API no está soportada).
- Verificar que `home_widget` no rompe el build (puede necesitar guard
  `if (!kIsWeb)`).
- Verificar que `nfc_manager` está guardado tras `if (!kIsWeb)`.
- Verificar que Hive funciona en web (usa IndexedDB).

**CA.**
- [ ] `flutter build web --release` termina sin errores.
- [ ] La app abre en Chrome y se navega Home → Mapa → Perfil → Admin
      sin runtime exceptions.
- [ ] El mapa muestra tiles (con o sin caché según soporte).

---

## Anexo A — Migraciones SQL necesarias

> Una sola migración nueva: `021_v16_admin_extras.sql`. El grueso del
> backend GDPR/invitations ya existe en 001–020.

```sql
-- 021_v16_admin_extras.sql
-- V16: flags is_official + applications para admin

-- ── Flags is_official en routes/stops ────────────────────────────
ALTER TABLE public.routes
  ADD COLUMN IF NOT EXISTS is_official BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE public.stops
  ADD COLUMN IF NOT EXISTS is_official BOOLEAN NOT NULL DEFAULT false;

CREATE INDEX IF NOT EXISTS idx_routes_official
  ON public.routes (is_official);

CREATE INDEX IF NOT EXISTS idx_stops_official
  ON public.stops (is_official);

-- ── Tabla operator_applications ──────────────────────────────────
CREATE TABLE IF NOT EXISTS public.operator_applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  requested_operator_name TEXT NOT NULL,
  requested_slug TEXT NOT NULL,
  notes TEXT,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'rejected')),
  actioned_by UUID REFERENCES auth.users(id),
  actioned_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Tabla driver_applications ────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.driver_applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  operator_id UUID NOT NULL REFERENCES public.operators(id) ON DELETE CASCADE,
  notes TEXT,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'rejected')),
  actioned_by UUID REFERENCES auth.users(id),
  actioned_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Tabla operator_route_proposals (rutas pendientes de oficializar)
CREATE TABLE IF NOT EXISTS public.operator_route_proposals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id UUID NOT NULL REFERENCES public.routes(id) ON DELETE CASCADE,
  proposed_by UUID NOT NULL REFERENCES auth.users(id),
  operator_id UUID NOT NULL REFERENCES public.operators(id),
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'rejected')),
  actioned_by UUID REFERENCES auth.users(id),
  actioned_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Flag escalated en incidents y route_feedback ─────────────────
ALTER TABLE public.incidents
  ADD COLUMN IF NOT EXISTS escalated_to_admin BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE public.route_feedback
  ADD COLUMN IF NOT EXISTS escalated_to_admin BOOLEAN NOT NULL DEFAULT false;

-- ── RLS para las nuevas tablas ───────────────────────────────────
ALTER TABLE public.operator_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driver_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.operator_route_proposals ENABLE ROW LEVEL SECURITY;

-- Usuarios ven sus propias solicitudes.
CREATE POLICY user_sees_own_operator_apps ON public.operator_applications
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY user_sees_own_driver_apps ON public.driver_applications
  FOR SELECT USING (auth.uid() = user_id);

-- Usuarios crean sus propias solicitudes.
CREATE POLICY user_creates_operator_app ON public.operator_applications
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY user_creates_driver_app ON public.driver_applications
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Admin ve y actualiza todo.
CREATE POLICY admin_all_operator_apps ON public.operator_applications
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY admin_all_driver_apps ON public.driver_applications
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY admin_all_proposals ON public.operator_route_proposals
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Operator_admin ve solicitudes de su operador.
CREATE POLICY operator_sees_driver_apps ON public.driver_applications
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM driver_assignments da
      JOIN profiles p ON p.id = auth.uid()
      WHERE da.driver_id = auth.uid()
        AND da.operator_id = driver_applications.operator_id
        AND p.role = 'operator_admin'
        AND da.revoked_at IS NULL
    )
  );

CREATE POLICY operator_updates_driver_apps ON public.driver_applications
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM driver_assignments da
      JOIN profiles p ON p.id = auth.uid()
      WHERE da.driver_id = auth.uid()
        AND da.operator_id = driver_applications.operator_id
        AND p.role = 'operator_admin'
        AND da.revoked_at IS NULL
    )
  );
```

> **Antes de aplicar.** Ejecutar `list_tables` y `list_extensions` para
> verificar que `profiles.role`, `operators.id` y `driver_assignments`
> existen tal como asume esta migración. Si los nombres difieren,
> ajustar la migración.

---

## Anexo B — Bootstrap admin (SQL manual)

Pasos para crear la primera cuenta admin:

1. El usuario hace login normal en la app (email/password o Google).
2. El dueño del proyecto Supabase entra en SQL Editor.
3. Ejecuta:
   ```sql
   -- Asume que profiles tiene una columna role enum/text.
   UPDATE public.profiles
   SET role = 'admin'
   WHERE email = 'tu_email@gmail.com';
   ```
4. El usuario cierra sesión en la app y vuelve a abrir.
5. El JWT refresca y el cliente Flutter lee `role='admin'`.
6. El botón "Panel admin" aparece en perfil y la ruta `/admin/*` queda
   accesible.

> **Verificar** que `profiles.role` está en `auth.users.app_metadata`
> también (lo añade un trigger). Si no, añadir:
> ```sql
> UPDATE auth.users
> SET raw_app_meta_data = raw_app_meta_data || jsonb_build_object('role', 'admin')
> WHERE email = 'tu_email@gmail.com';
> ```

---

## Anexo C — Matriz de testing manual

Smoke test por fase. El implementador debe ejecutarlo manualmente en
cada plataforma objetivo (Android, iOS si está disponible, Web).

### Fase P0
| # | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| P0-01 | Líneas visibles | Abrir mapa | Polilíneas de todas las líneas activas |
| P0-02 | Mapa estable | Mapa → Perfil → Mapa × 10 | Tiles siguen cargando |
| P0-03 | Añadir horario | Editor → Horarios → Añadir | Sheet visible, cancelable |
| P0-04 | Publicar ruta | Editor → Review → Publicar | Snackbar éxito + navegación |
| P0-05 | Prefs persisten | Cambiar paleta → cerrar → abrir | Paleta mantenida |
| P0-06 | Perfil con datos | Login Google → Perfil | Nombre + foto visibles |
| P0-07 | Tap navbar | Pulsar zona externa al icono | Pestaña cambia |
| P0-08 | Zona principal | Perfil → Cambiar zona | Sin error de operador |
| P0-09 | Saldo NFC | Login | Historial visible inmediato |

### Fase P1
| # | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| P1-01 | Consentimientos | Privacidad → toggle → recargar | Mantenido |
| P1-01 | Solicitud borrado | Privacidad → Solicitar borrado | Fila en `data_deletion_requests` |
| P1-02 | Accesibilidad modo | Accesibilidad | Modo correctamente reflejado |
| P1-03 | Contraste AA | Apariencia → Contraste AA | Texto cumple ratio |
| P1-04 | Widget Android | Configurar widget → Refrescar ahora | Widget actualizado en home |
| P1-05 | FilterPresets fuera | Perfil | No aparece la opción |
| P1-06 | Región offline | Crear región → Modo avión → Mapa | Tiles offline |
| P1-07 | Filtro mapa fusionado | Mapa → Filtros | Una sola sección |
| P1-08 | Cerrar sheet línea | Mapa → tap línea → swipe down | Sheet cierra |

### Fase P1.5
| # | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| P1.5-01 | Admin login | Login admin → Perfil | Botón "Panel admin" visible |
| P1.5-03 | Crear operador | Admin → Operadores → Crear | Operador en la lista |
| P1.5-04 | Bandeja admin | Admin → Solicitudes | 4 tabs con badges |
| P1.5-05 | Código invitación | Operator → Códigos → Crear | Código compartible |
| P1.5-06 | Activar conductor | User → Canjear código | Rol conductor activo |
| P1.5-07 | Ruta oficial | Conductor → Crear ruta | Badge "Oficial" |

### Fase P2
| # | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| P2-01 | Color único | Editor → Info | Un solo picker |
| P2-02 | Chips tipo | Editor → Info → Tipo | Chips con icono |
| P2-03 | Siguiente | Rellenar todo | Siguiente activo |
| P2-04 | Buscar parada | Editor → Paradas → Buscar | Filtro en vivo |
| P2-05 | Trazar | Editor → Trazar | Editor grande, gestos OK |
| P2-06 | Horarios Frecuencia | Editor → Horarios → Frecuencia 07:00–22:00/15min | Preview con 60 horas |

### Fase P2.5
| # | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| P2.5-02 | Landscape | Rotar móvil | NavigationRail lateral |
| P2.5-03 | Web desktop | Abrir en Chrome 1920w | Pantallas centradas max 800 |
| P2.5-04 | Web build | `flutter build web --release` | Sin errores |

---

## Anexo D — Eventos PostHog/Sentry nuevos

Añadir a `lib/data/analytics/posthog_service.dart`:

| Evento | Cuándo | Properties |
|---|---|---|
| `map.tiles.failed_after_resume` | P0-02 diagnóstico | `seconds_since_background`, `tile_url_failed` |
| `route.publish.attempt` | P0-04 | `route_id`, `is_official`, `stops_count` |
| `route.publish.success` | P0-04 | `route_id`, `latency_ms` |
| `route.publish.error` | P0-04 | `route_id`, `error_type`, `error_message` |
| `widget.refresh.manual` | P1-04 | `widget_size`, `widget_type` |
| `widget.refresh.scheduled` | P1-04 | `widget_size`, `interval_min` |
| `privacy.consent.changed` | P1-01 | `consent_type`, `enabled` |
| `privacy.export.requested` | P1-01 | – |
| `privacy.deletion.requested` | P1-01 | – |
| `admin.request.actioned` | P1.5-04 | `request_type`, `action` |
| `operator.invitation.created` | P1.5-05 | `max_uses`, `kind` |
| `driver.invitation.claimed` | P1.5-06 | `code`, `operator_id` |
| `schedule.mode.changed` | P2-06 | `mode_from`, `mode_to` |

Breadcrumbs Sentry adicionales para P0-02:
- `map.init` en `TransitMap.initState`.
- `map.dispose` en `TransitMap.dispose`.
- `map.tile.load.start` con `template`, `coords`.
- `map.tile.load.error` con `template`, `coords`, `error`.

---

## Resumen ejecutivo

| Fase | Ítems | Riesgo | Pre-requisitos |
|---|---|---|---|
| P0 | 9 blockers | Medio (bug del mapa requiere diagnóstico) | – |
| P1 | 8 funcionalidades rotas | Bajo (mayoría es wiring) | P0-05 (prefs persisten) |
| P1.5 | 7 admin/operator/conductor | Alto (RLS + nueva UI) | Migración 021 aplicada |
| P2 | 6 rediseño editor ruta | Medio (Horarios es lo más complejo) | P0-03 y P0-04 |
| P2.5 | 4 responsive | Bajo (mayoría reutiliza widgets existentes) | Todo lo demás estable |

**Orden de ejecución sugerido:** P0 → P1 → P1.5 → P2 → P2.5.

**Total estimado:** 34 ítems. Sin plazo fijo — entregar fase a fase con
PRs independientes mergeables a `master`.

---

## Cambios respecto a V15

V15 cerró P36 (presentación web + descarga APK). V16 abre una nueva
línea: **reparación funcional post-testeo manual**. No hay overlap.

Las únicas dependencias con V15:
- La pantalla web del TFG sigue intacta (no se toca en V16).
- Los assets de `docs/historico/PLAN_REPARACION_*` se preservan como
  referencia.

V16 se cierra cuando todas las CA marcadas estén verificadas. El
siguiente plan (V17 o nombre nuevo) puede:
- Recoger lo que quede pendiente.
- Empezar el sistema "tracking GPS en tiempo real" (próxima feature
  grande).
