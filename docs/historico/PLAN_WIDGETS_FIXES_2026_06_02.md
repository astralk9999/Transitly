# Plan de acción — Fixes de widgets Android (preview, descripción, deep links)

**Fecha del plan:** 2026-06-02
**Autor:** Claude Code (Opus 4.7)
**Estado:** propuesto, pendiente de aprobación del usuario
**Continuación de:** `PLAN_WIDGETS_ANDROID_2026_06_01.md` (waves 0.5–7 ya implementadas parcialmente; los widgets aparecen en el launcher pero con 3 defectos).
**Alcance:** 3 fixes acotados, sin tocar la arquitectura ya entregada.

---

## 1. Estado actual auditado (2026-06-02)

He leído el código en disco y confirmado los 3 problemas que reportas. Aquí está la causa raíz de cada uno con archivo:línea.

### 1.1. Preview vacío (solo aparece el icono)

**Síntoma:** al abrir la pestaña "Widgets" del launcher y elegir Transitly, los 3 widgets se ven como el icono cuadrado de la app, no como una mini-vista del widget real.

**Causa:**
- `android/app/src/main/res/xml/widget_next_bus_info.xml:7` → `android:previewImage="@mipmap/ic_launcher"`
- `android/app/src/main/res/xml/widget_my_line_info.xml:7` → mismo
- `android/app/src/main/res/xml/widget_nfc_balance_info.xml:7` → mismo

Los 3 XML apuntan al icono de launcher como preview. **No existe** ningún PNG real de preview en `res/drawable*/`. El único drawable de widget es `widget_bg.xml` (fondo).

Falta también `android:previewLayout` (introducido en Android 12). Sin él, en Android 12+ el sistema sigue mostrando el `previewImage`, que es el icono.

### 1.2. Falta descripción al seleccionar el widget

**Síntoma:** al pulsar el widget en el picker, no aparece la línea descriptiva ("Próximo bus en tu parada habitual", etc.) que sí muestran otras apps.

**Causa:**
- Ninguno de los 3 XML tiene `android:description="@string/..."`.
- No existe ningún `android/app/src/main/res/values*/strings.xml` con cadenas de widget (verificado con `Glob`).
- Por tanto: cero metadata legible, el picker muestra solo el nombre de la clase del provider.

### 1.3. Error 404 al hacer click en cualquier widget

**Síntoma:** tocas el widget, la app abre, te lleva a una pantalla "404 página no encontrada".

**Causa raíz (la más importante):** **el lado Flutter no procesa los deep links que envía el widget**.

Cadena de eventos actual:
1. **Widget Kotlin** lanza `HomeWidgetLaunchIntent.getActivity(..., Uri.parse("transitly://home/inicio"))` (`NextBusWidgetProvider.kt:60`) o `"transitly://home/tarjeta"` (`NfcBalanceWidgetProvider.kt:62`).
2. **AndroidManifest.xml:36-41** tiene un `intent-filter` para el scheme `transitly`, así que el sistema operativo entrega ese Intent a `MainActivity`.
3. **MainActivity.kt:1-5** es la implementación mínima: `class MainActivity : FlutterActivity()`. **No hace nada con el Intent recibido.**
4. **Flutter no escucha deep links** — verificado con `Grep`: ni `app_links`, ni `uni_links`, ni `HomeWidget.initialUri()`, ni `HomeWidget.widgetClicked` aparecen en `lib/`.
5. **GoRouter** se monta con su ruta inicial (probablemente `/` o el último estado en memoria) y, como el deep link nunca se le pasa, navega por defecto. En el `redirect_guards.dart:55,64` el fallback al final cae en `/home/inicio`. Pero si el camino lo lleva al `errorBuilder` de GoRouter primero, sale el "404".

**Causa secundaria:** el formato del URI es ambiguo.
- `transitly://home/inicio` se parsea como `scheme=transitly`, `host=home`, `path=/inicio`.
- Para que GoRouter resuelva esto a `/home/inicio` hay que concatenar `host + path` manualmente; no es automático.

---

## 2. Objetivos de este plan

1. **Mostrar preview real** de cada widget en el picker del launcher (Android ≤ 11 con PNG estático; Android 12+ con `previewLayout` dinámico).
2. **Añadir descripción** localizada (es/en/ar) que se vea al seleccionar cada widget.
3. **Resolver el 404**: que tocar cada widget abra la pestaña/pantalla correcta de la app.

Cero refactor de la arquitectura existente. Solo añadir lo que falta.

---

## 3. Plan de fix dividido en 3 tareas pequeñas

### Tarea A — Preview de los 3 widgets (1.5 h)

#### A.1. Generar PNGs de preview
Tres PNGs estáticos, uno por widget, simulando cómo se ve el widget con datos de ejemplo.

| Widget | Tamaño recomendado | Datos de ejemplo a renderizar |
|--------|--------------------|--------------------------------|
| `widget_next_bus_preview.png` | 250×80 dp → ~750×240 px @ xxhdpi | "L8 · 4 min · Plaza del Caballo" |
| `widget_my_line_preview.png` | 250×80 dp → ~750×240 px @ xxhdpi | "L15 · próximos: 3, 18, 27 min" |
| `widget_nfc_balance_preview.png` | 110×80 dp → ~330×240 px @ xxhdpi | "💳 12,40 € · Actualizado: hace 2 h" |

Dos opciones para generarlos:
- **Opción 1 (recomendada):** capturar el widget renderizado en el emulador (`adb shell screencap`) con datos mock fijos, recortar y guardar como PNG. **Coste: 20 min.**
- **Opción 2:** diseñarlos manualmente en Figma o equivalente con los colores oficiales de la app. **Coste: 40 min, pero mayor calidad visual.**

Ubicación: `android/app/src/main/res/drawable-xxhdpi/widget_*_preview.png`. Android escala desde xxhdpi a otras densidades.

#### A.2. Apuntar el `previewImage` al PNG real
En cada XML cambiar:
```xml
android:previewImage="@mipmap/ic_launcher"
```
por:
```xml
android:previewImage="@drawable/widget_next_bus_preview"
```
(idem para los otros 2).

#### A.3. Añadir `previewLayout` para Android 12+
En cada XML, añadir:
```xml
android:previewLayout="@layout/widget_next_bus"
```

En Android 12+ esto se prioriza sobre `previewImage` y muestra el layout real (vacío de datos, pero con la estructura visual). Combinado con `tools:` en el XML del layout, podemos meter datos de ejemplo solo para el preview, sin afectar el runtime.

Edit del layout `res/layout/widget_next_bus.xml`: añadir en los `TextView`:
```xml
android:text="L8"
tools:text="L8"
android:text="4 min"
tools:text="4 min"
```
Los `android:text` se sobrescriben en runtime por el provider Kotlin; solo se ven en el preview.

#### A.4. Verificación manual
- `flutter build apk --release` + instalar
- Mantener pulsado en el launcher → "Widgets" → buscar Transitly
- Confirmar que los 3 widgets se ven con sus mini-vistas de ejemplo, no con el icono cuadrado

---

### Tarea B — Descripción localizada de los 3 widgets (1 h)

#### B.1. Crear `res/values/strings.xml`
Nuevo archivo. Contenido:
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Widget labels (nombre que aparece en el picker) -->
    <string name="widget_next_bus_label">Transitly · Próximo bus</string>
    <string name="widget_my_line_label">Transitly · Mi línea</string>
    <string name="widget_nfc_balance_label">Transitly · Saldo bonobús</string>

    <!-- Widget descriptions (texto que aparece al seleccionar) -->
    <string name="widget_next_bus_description">Muestra el próximo bus en tu parada habitual con minutos restantes.</string>
    <string name="widget_my_line_description">Próximas salidas de tu línea favorita ordenadas por tiempo.</string>
    <string name="widget_nfc_balance_description">Último saldo del bonobús leído por NFC.</string>
</resources>
```

#### B.2. Crear `res/values-en/strings.xml` y `res/values-ar/strings.xml`
Mismas claves, traducidas. El sistema elige según el idioma del dispositivo, no el de la app (en Android no se puede forzar idioma del widget desde Flutter sin recrearlo).

| Clave | es | en | ar |
|-------|-----|-----|-----|
| `widget_next_bus_label` | "Transitly · Próximo bus" | "Transitly · Next bus" | "ترانزيتلي · الحافلة التالية" |
| `widget_my_line_label` | "Transitly · Mi línea" | "Transitly · My line" | "ترانزيتلي · خطي" |
| `widget_nfc_balance_label` | "Transitly · Saldo bonobús" | "Transitly · NFC balance" | "ترانزيتلي · رصيد البطاقة" |
| `widget_next_bus_description` | "Muestra el próximo bus en tu parada habitual con minutos restantes." | "Shows the next bus at your usual stop with minutes remaining." | "يعرض الحافلة التالية في محطتك المعتادة مع الوقت المتبقي." |
| `widget_my_line_description` | "Próximas salidas de tu línea favorita ordenadas por tiempo." | "Upcoming departures of your favourite line sorted by time." | "الرحلات القادمة لخطك المفضل مرتبة حسب الوقت." |
| `widget_nfc_balance_description` | "Último saldo del bonobús leído por NFC." | "Latest NFC-read travel card balance." | "آخر رصيد لبطاقة السفر تمت قراءته عبر NFC." |

#### B.3. Editar los 3 XML `widget_*_info.xml`
Añadir 2 atributos a cada `appwidget-provider`:
```xml
android:label="@string/widget_next_bus_label"
android:description="@string/widget_next_bus_description"
```
(idem para los otros 2 con sus claves).

#### B.4. Verificación
- Build + install
- Abrir el picker del launcher → seleccionar un widget de Transitly
- Confirmar que aparece la línea descriptiva debajo del nombre

---

### Tarea C — Resolver el error 404 al hacer click (2.5 h)

**Esta es la tarea más importante y compleja.** Hay que añadir el handler de deep links en Flutter y rutearlos a GoRouter.

#### C.1. Decidir mecanismo de captura de deep link

| Opción | Pros | Contras | Recomendación |
|--------|------|---------|----------------|
| `HomeWidget.initialUri()` + `HomeWidget.widgetClicked` stream | Ya tienes el plugin instalado; ZERO dependencias nuevas | Solo funciona para URIs lanzadas desde `HomeWidgetLaunchIntent` | **Recomendada** — es exactamente nuestro caso de uso |
| Plugin `app_links: ^6.3.2` | Genérico, sirve también para deep links web del futuro | Una dependencia más; algo de boilerplate extra | Alternativa si más adelante queremos universal links |
| MethodChannel custom | Cero deps | Reescribir gestión de Intent en MainActivity.kt | Innecesario |

**Voy a recomendar `HomeWidget.widgetClicked`** porque el plugin ya está integrado y este caso es 100% de widgets (no necesitas universal links todavía).

#### C.2. Crear `lib/shared/services/widget_deep_link_service.dart` (NUEVO)

API propuesta:
```dart
class WidgetDeepLinkService {
  WidgetDeepLinkService(this._goRouter);
  final GoRouter _goRouter;

  static const _validRoutes = <String>{
    '/home/inicio',
    '/home/mapa',
    '/home/tarjeta',
    '/home/perfil',
  };

  /// Llama una vez al arrancar la app: procesa el URI con el que se abrió
  /// el proceso (cold start desde widget).
  Future<void> handleColdStart() async {
    final uri = await HomeWidget.initialUri;
    if (uri != null) _route(uri);
  }

  /// Escucha continua: se activa cuando el usuario hace click en un widget
  /// mientras la app está en background (warm start).
  StreamSubscription<Uri?> listen() {
    return HomeWidget.widgetClicked.listen((uri) {
      if (uri != null) _route(uri);
    });
  }

  void _route(Uri uri) {
    // transitly://home/inicio → /home/inicio
    final path = '/${uri.host}${uri.path}';
    if (_validRoutes.contains(path)) {
      _goRouter.go(path);
    } else {
      // Fallback seguro: nunca dejamos al usuario en 404.
      _goRouter.go('/home/inicio');
    }
  }
}
```

Notas clave:
- **Fallback a `/home/inicio` siempre.** Si llega un URI desconocido (por bug futuro o widget viejo), va a inicio en vez de 404. Esto **mata el síntoma del 404 inmediatamente**, sin esperar al fix de las 3 rutas correctas.
- El set `_validRoutes` es explícito y minimalista — solo las rutas que efectivamente queremos exponer al widget.

#### C.3. Engancharlo en `lib/main.dart`

Después de `runApp(...)`, en el `initState` del widget raíz (o donde sea más limpio):
```dart
final goRouter = ref.read(routerProvider);  // o cómo se llame
final deepLinkService = WidgetDeepLinkService(goRouter);
await deepLinkService.handleColdStart();
_widgetClickSub = deepLinkService.listen();
```

Y cancelar el `StreamSubscription` en `dispose()`.

**Cuidado con el orden:** GoRouter debe estar montado antes de hacer `go()`. El plugin `home_widget` permite leer `initialUri` antes del primer frame; el listener `widgetClicked` se procesa en cada evento. La integración debe ocurrir en el `WidgetsBindingObserver` que ya existe en `_TransitlyAppWithLifecycle` (lo veo en `main.dart:196-201`).

#### C.4. Verificar (y posiblemente corregir) los URIs que envían los providers Kotlin

Actualmente:
- `NextBusWidgetProvider.kt:60` → `transitly://home/inicio`
- `NfcBalanceWidgetProvider.kt:62` → `transitly://home/tarjeta`
- `MyLineWidgetProvider.kt` → revisar (no lo he leído aún en esta auditoría, posiblemente `transitly://home/inicio` también).

Recomendación de URIs por widget:
- **Próximo bus** (Next bus): `transitly://home/inicio` (la sección "Tu próximo bus" del home). ✅ ya está correcto.
- **Mi línea** (My line): `transitly://home/inicio` también (las tarjetas "Mis líneas" del home). Si en el futuro quieres llevar directamente a `/route/{id}`, esto requiere meter `routeId` en el URI: `transitly://route?id=L8`. Decidir.
- **Saldo NFC**: `transitly://home/tarjeta` (la pestaña Tarjeta del bottom nav). ✅ ya está correcto.

Una vez `WidgetDeepLinkService` esté funcionando con esos URIs, el 404 desaparece.

#### C.5. Test manual exhaustivo
- Cold start: cerrar app completamente, tocar el widget Next bus → debe abrir directamente en `/home/inicio`.
- Warm start: dejar app en background, tocar widget NFC → debe traer la app y navegar a `/home/tarjeta` sin pasar por inicio.
- Cold start con usuario no autenticado: tocar widget → debe respetar `redirect_guards` (probablemente lo manda a `/auth/signin` primero, y tras login a `/home/inicio`). Verificar que no rompe la auth.
- URI inválido (simular con un widget mal configurado): debe ir a `/home/inicio` sin 404.

---

## 4. Archivos a crear/modificar (resumen final)

### Nuevos
- `android/app/src/main/res/drawable-xxhdpi/widget_next_bus_preview.png`
- `android/app/src/main/res/drawable-xxhdpi/widget_my_line_preview.png`
- `android/app/src/main/res/drawable-xxhdpi/widget_nfc_balance_preview.png`
- `android/app/src/main/res/values/strings.xml`
- `android/app/src/main/res/values-en/strings.xml`
- `android/app/src/main/res/values-ar/strings.xml`
- `lib/shared/services/widget_deep_link_service.dart`

### Modificados
- `android/app/src/main/res/xml/widget_next_bus_info.xml` (+`previewImage` real, +`previewLayout`, +`label`, +`description`)
- `android/app/src/main/res/xml/widget_my_line_info.xml` (idem)
- `android/app/src/main/res/xml/widget_nfc_balance_info.xml` (idem)
- `android/app/src/main/res/layout/widget_next_bus.xml` (+`tools:text` para preview Android 12+)
- `android/app/src/main/res/layout/widget_my_line.xml` (idem)
- `android/app/src/main/res/layout/widget_nfc_balance.xml` (idem)
- `lib/main.dart` (registro del `WidgetDeepLinkService` después de `runApp`)
- `lib/app.dart` o `_TransitlyAppWithLifecycle` (suscripción al stream + cancelación en dispose)

### Sin tocar
- Providers Kotlin (`NextBusWidgetProvider.kt`, `MyLineWidgetProvider.kt`, `NfcBalanceWidgetProvider.kt`)
- AndroidManifest.xml (los receivers ya están bien)
- GoRouter / rutas existentes
- Toda la capa de datos (`widget_data_writer.dart`, etc.)

---

## 5. Estimación de tiempo

| Tarea | Tiempo | Acumulado |
|-------|--------|-----------|
| A — Preview de los 3 widgets | 1.5 h | 1.5 h |
| B — Descripción localizada | 1 h | 2.5 h |
| C — Resolver 404 (deep link service) | 2.5 h | 5.0 h |
| **Total** | **~5 h** | una sola sesión |

Si solo hay tiempo para 1 cosa: hacer **Tarea C primero** porque es la única que rompe funcionalmente la app (las otras 2 son estéticas/descubribilidad).

---

## 6. Orden de ejecución recomendado

1. **Tarea C primero** (fix del 404) — 2.5 h. Quita el bug bloqueante.
2. **Build APK + smoke test** del fix C — 15 min.
3. **Tarea B** (descripciones) — 1 h. Cambios solo en XML/strings, bajo riesgo.
4. **Tarea A** (previews) — 1.5 h. Necesita generar PNGs (más laborioso pero no técnico).
5. **Build APK final + smoke test completo** — 30 min.

---

## 7. Riesgos identificados

- **R1: `HomeWidget.widgetClicked` no emite en cold start en algunos OEMs.** El plugin a veces tiene comportamiento inconsistente al arrancar la app desde cerrada. **Mitigación:** llamar siempre `HomeWidget.initialUri` en `handleColdStart()` y dejar el listener para warm starts. Las dos vías cubren los dos casos.
- **R2: GoRouter no acepta `go()` antes de su primer build.** Si lanzamos el `_route()` demasiado pronto, puede fallar silenciosamente. **Mitigación:** envolver la llamada en `WidgetsBinding.instance.addPostFrameCallback`.
- **R3: Race condition entre auth state y deep link.** Si el widget se toca antes de que `authStateProvider` haya leído la sesión, el `redirect_guards` puede mandar al usuario a `/auth/signin` por error. **Mitigación:** esperar al primer estado no-loading del provider antes de aplicar el deep link.
- **R4: PNGs preview demasiado grandes inflan el APK.** 3 PNGs de 750×240 px @ xxhdpi son ~150-300 KB cada uno. **Mitigación:** comprimir con `pngquant --quality 70-85` o usar WebP si el launcher lo soporta (Android 4.0+ sí).
- **R5: Strings árabe rompen la dirección de texto en el widget.** Si el RemoteViews no fuerza `layoutDirection="locale"`, los chars árabes pueden salir invertidos. **Mitigación:** añadir `android:layoutDirection="locale"` al layout raíz de cada widget.
- **R6: `android:previewLayout` solo funciona Android 12+.** En Android 11 y anteriores, el sistema cae a `previewImage`. Por eso necesitamos AMBOS atributos. **Mitigación:** ambos atributos siempre presentes (los hacemos en A.2 y A.3 a la vez).

---

## 8. Criterios de aceptación (smoke test final)

Cuando las 3 tareas estén terminadas:

1. **Preview visible:** abro launcher → mantengo pulsado → "Widgets" → Transitly. Los 3 widgets aparecen con sus mini-vistas reales, no con el icono cuadrado.
2. **Descripción visible:** toco un widget en el picker. Aparece una línea descriptiva debajo del nombre del widget (en el idioma del sistema).
3. **404 resuelto - cold start:** cierro Transitly completamente. Toco widget Próximo bus en el launcher. La app se abre y va directamente a la pestaña "Inicio" (no a 404).
4. **404 resuelto - warm start:** Transitly en background. Toco widget NFC. La app pasa a primer plano y navega a la pestaña "Tarjeta".
5. **Idioma sistema:** cambio idioma del móvil a inglés. Reabro el picker. Los nombres y descripciones de los 3 widgets aparecen en inglés.
6. **No rompe nada existente:** los widgets siguen actualizándose con los datos correctos; los providers Kotlin no han cambiado.

---

## 9. Próximos pasos

Cuando apruebes el plan:

- **Opción rápida:** "arranca tarea C" — solo arreglo el 404 (~2.5 h, fix bloqueante).
- **Opción completa:** "arranca las 3 tareas" — fixes completos en una sesión (~5 h).

Si prefieres ajustar algo antes (p.ej. cambiar URIs por widget para que cada uno vaya a una pantalla más específica que "/home/inicio"), dímelo y revisamos la Tarea C antes de implementar.

---

## Changelog

- **2026-06-02** — Plan inicial creado tras auditoría del estado actual:
  - Confirmado preview vacío (`previewImage="@mipmap/ic_launcher"` en los 3 XML).
  - Confirmado sin descripción (no hay `strings.xml`, no hay `android:description` en XML).
  - Confirmado 404 raíz: `MainActivity.kt` mínima + Flutter sin handler de deep link + URIs `transitly://...` ignorados.
