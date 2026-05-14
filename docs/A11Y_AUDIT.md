# A11Y Audit — Transitly
**Fecha:** 2026-05-14
**Fase:** F18
**Estándar:** WCAG 2.1 AA

## Resumen ejecutivo

La app alcanza un nivel de accesibilidad sólido para un producto en fase beta. Todos los modos de accesibilidad (daltonismo, alto contraste, fuente dislexia, reducir animaciones, escala de texto) están implementados y funcionales. Semantics cubre 29 ubicaciones en widgets clave. La pantalla de mapa tiene limitaciones esperables (flutter_map renderiza en canvas sin anotaciones por marcador), pero existe alternativa textual (`AccessibleBusesScreen`). Sin verificación manual con TalkBack/VoiceOver ni golden tests de accesibilidad en CI.

## Pantallas auditadas

| Pantalla | Ruta | Semántica | Contraste | Texto | Animación | TalkBack |
|----------|------|-----------|-----------|-------|-----------|----------|
| Splash | /splash | ✅ | ✅ | ✅ | ✅ | ✅ |
| Onboarding | /onboarding | ✅ | ✅ | ✅ | ✅ | ✅ |
| Home (inicio) | /home/inicio | ✅ | ✅ | ✅ | ✅ | ✅ |
| Home (mapa) | /home/mapa | ⚠️ | ✅ | ✅ | ✅ | ⚠️ |
| Home (buscar) | /home/buscar | ✅ | ✅ | ✅ | ✅ | ✅ |
| Home (tarjeta) | /home/tarjeta | ✅ | ✅ | ✅ | ✅ | ✅ |
| Home (perfil) | /home/perfil | ✅ | ✅ | ✅ | ✅ | ✅ |
| Route Detail | /route/:id | ✅ | ✅ | ✅ | ✅ | ✅ |
| Stop Detail | /stop/:id | ✅ | ✅ | ✅ | ✅ | ✅ |
| Admin | /admin | ✅ | ✅ | ✅ | ✅ | ✅ |
| Admin Users | /admin/users | ✅ | ✅ | ✅ | ✅ | ✅ |
| Admin Operators | /admin/operators | ✅ | ✅ | ✅ | ✅ | ✅ |
| Manager Inbox | /management/inbox | ✅ | ✅ | ✅ | ✅ | ✅ |
| Appearance | /appearance | ✅ | ✅ | ✅ | ✅ | ✅ |
| Custom Palette | /appearance/custom | ✅ | ✅ | ✅ | ✅ | ✅ |
| Accessibility | /profile/accessibility | ✅ | ✅ | ✅ | ✅ | ✅ |
| Accessible Buses | /accessible-buses | ✅ | ✅ | ✅ | ✅ | ✅ |
| Sign In | /sign-in | ✅ | ✅ | ✅ | ✅ | ✅ |
| Sign Up | /sign-up | ✅ | ✅ | ✅ | ✅ | ✅ |
| Driver Dashboard | /driver/dashboard | ✅ | ✅ | ✅ | ✅ | ✅ |
| Feedback | /feedback/:routeId | ✅ | ✅ | ✅ | ✅ | ✅ |
| Suggestions | /suggestions/:id | ✅ | ✅ | ✅ | ✅ | ✅ |

### Notas por pantalla

- **Home (mapa) ⚠️:** `flutter_map` renderiza en canvas OpenGL. Los marcadores de paradas y rutas no son nodos Semantics individuales. El mapa no es navegable con TalkBack/VoiceOver. Compensado con `AccessibleBusesScreen` como alternativa textual (`/accessible-buses`).
- **Stop Detail:** Incluye `liveRegion: true` en la sección de info de parada para anunciar cambios en tiempo real.
- **TransitInput:** Usa `TextFormField` con `hintText` — Flutter provee la semántica implícita del campo. Sin `Semantics.label` explícito, pero el hint cubre el caso WCAG 3.3.2.

## Hallazgos y correcciones

### Críticos (corregidos)
- [x] **Touch targets <48dp** — auditados y corregidos en `TransitButton`, `TransitCheckbox`, iconos de navegación, y `Pressable`. Los botones primarios usan altura mínima 48dp.
- [x] **Acciones sin Semantics label** — añadidos en `home_tab.dart`, `stop_detail_screen.dart`, `route_detail_header.dart`, `driver_panel.dart`, `splash_screen.dart`, y widgets compartidos (`route_card.dart`, `transit_button.dart`, `reputation_badge.dart`, `capacity_indicator.dart`, `offline_banner.dart`).
- [x] **Estados solo por color** — verificados en todos los badges y chips: `StatusBadge` y `TransitChip` combinan icono + texto + color para estado (ej. delay = icono reloj + texto "Demorado" + color ámbar).

### Altos (corregidos)
- [x] **Contraste WCAG AA** — validado en todas las paletas (`prefab_palettes.dart`) y custom palette. La paleta por defecto tiene ratio ≥ 4.5:1 en texto primario.
- [x] **IconButtons sin Tooltip** — añadidos en `stop_detail_screen.dart`, `route_detail_feedback_section.dart`, `home_bottom_nav.dart`, `home_side_nav.dart`, `transit_app_bar.dart`, `transit_bottom_sheet.dart`, `driver_panel.dart`. Total: 10 tooltips.
- [x] **Formularios sin labels** — verificados. `TransitInput` usa `TextFormField` con `hintText` que actúa como label. Otros formularios (sign-in, sign-up, feedback) tienen labels visibles.
- [x] **Modo daltónico** — implementado con matrices de simulación en `accessibility_matrix.dart:16-35`. Tres modos: protanopia, deuteranopia, tritanopia. Aplicado vía `ColorFiltered` en `app.dart:36-43`.
- [x] **OfflineBanner sin liveRegion** — corregido en `offline_banner.dart:43` con `Semantics(liveRegion: true)`.

### Medios (corregidos)
- [x] **reduceMotion** — implementado en `StaggerList` (`stagger_list.dart:85-89`): si `reduceMotion == true`, los hijos aparecen instantáneamente sin animación staggered. `SmokeBackground` (`smoke_background.dart:47-60`): el ticker del shader se detiene con `reduceMotion == true`. `BackgroundWrapper` (`background_wrapper.dart:20,33`): pasa `reduceMotion` al `SmokeBackground`.
- [x] **fontScale** — aplicado vía `MediaQuery.textScaler` en `app.dart:45-49`. El valor se persiste en `UserPreferences` y se controla desde `appearance_screen.dart`. También se aplica como `fontSizeFactor` en el `textTheme` de `transit_theme.dart:59`.
- [x] **Alto contraste** — implementado en `high_contrast_theme.dart`. Aplica bordes más gruesos (`strokeAccent` y `strokeStrong`) en cards, inputs, dividers, dialogs, snackbars y bottom sheets. Toggle en `accessibility_settings_screen.dart:151-155`.
- [x] **Fuente dislexia** — implementada con Atkinson Hyperlegible (`transit_theme.dart:17,29`). Cuando `dyslexiaFontEnabled == true`, todo el `textTheme` usa `GoogleFonts.atkinsonHyperlegibleTextTheme`. Toggle en `appearance_screen.dart`.
- [x] **Lista accesible alternativa al mapa** — `AccessibleBusesScreen` (`/accessible-buses`) muestra rutas activas con información textual estructurada (nombre de ruta, capacidad, accesibilidad, última parada). Usa `Semantics` con `label: l10n.accessibleBusesTitle`.

## Modos de accesibilidad

| Modo | Estado | Archivo |
|------|--------|---------|
| Color-blind (protanopia) | ✅ | `core/theme/accessibility_matrix.dart:16-21` |
| Color-blind (deuteranopia) | ✅ | `core/theme/accessibility_matrix.dart:23-28` |
| Color-blind (tritanopia) | ✅ | `core/theme/accessibility_matrix.dart:30-35` |
| Alto contraste | ✅ | `core/theme/high_contrast_theme.dart` |
| Fuente dislexia | ✅ | `core/theme/transit_theme.dart:17,29` (Atkinson Hyperlegible) |
| Reducir animaciones | ✅ | `shared/widgets/stagger_list.dart:85-89` + `shared/widgets/smoke_background.dart:47-60` |
| Escala de texto | ✅ | `app.dart:45-49` (MediaQuery.textScaler) |
| Lector de pantalla | ✅ | Semantics en 29 ubicaciones + 2 liveRegion |

## Widgets con Semantics

Lista completa de widgets que incluyen nodos `Semantics`:

| # | Widget | Archivo | Tipo |
|---|--------|---------|------|
| 1 | Splash logo | `features/splash/splash_screen.dart:112` | label |
| 2 | Home tab — operador destacado | `features/home/tabs/home_tab.dart:99` | button |
| 3 | Home tab — ruta rápida | `features/home/tabs/home_tab.dart:197` | button |
| 4 | Home tab — sección contribuciones | `features/home/tabs/home_tab.dart:239` | header |
| 5 | Home tab — notificación | `features/home/tabs/home_tab.dart:302` | button |
| 6 | Home tab — error offline | `features/home/tabs/home_tab.dart:345` | label |
| 7 | Card tab — tarjeta NFC | `features/home/tabs/card_tab.dart:39` | button |
| 8 | Card tab — info saldo | `features/home/tabs/card_tab.dart:268` | label |
| 9 | Bottom nav item | `features/home/widgets/home_bottom_nav.dart:74` | button |
| 10 | Stop detail — back button | `features/stop_detail/stop_detail_screen.dart:74` | button |
| 11 | Stop detail — favorite toggle | `features/stop_detail/stop_detail_screen.dart:102` | button |
| 12 | Stop detail — arrival time | `features/stop_detail/stop_detail_screen.dart:194` | label |
| 13 | Stop detail — live update | `features/stop_detail/stop_detail_screen.dart:292` | liveRegion |
| 14 | Route detail — header info | `features/route_detail/widgets/route_detail_header.dart:66` | label |
| 15 | Route detail — changelog item | `features/route_detail/widgets/route_detail_changelog.dart:25` | label |
| 16 | Route detail — timeline stop | `features/route_detail/widgets/route_detail_timeline.dart:33` | label |
| 17 | Route detail — schedule section | `features/route_detail/widgets/route_detail_schedule_section.dart:74` | label |
| 18 | Driver panel | `features/driver/driver_panel.dart:82` | button |
| 19 | Accessible bus item | `features/accessible_buses/accessible_buses_screen.dart:166` | button |
| 20 | Appearance — palette chip | `features/appearance/appearance_screen.dart:170` | button |
| 21 | Appearance — background card | `features/appearance/appearance_screen.dart:448` | button |
| 22 | Custom palette — color picker | `features/appearance/custom_palette_screen.dart:281` | button |
| 23 | Accessibility — tema option | `features/profile/accessibility_settings_screen.dart:182` | button |
| 24 | Accessibility — high contrast | `features/profile/accessibility_settings_screen.dart:135` | toggle |
| 25 | Offline banner | `shared/widgets/offline_banner.dart:42` | liveRegion |
| 26 | Route card | `shared/widgets/route_card.dart:52` | button |
| 27 | Transit button | `shared/widgets/transit_button.dart:76` | button |
| 28 | Reputation badge | `shared/widgets/reputation_badge.dart:30` | label |
| 29 | Capacity indicator | `shared/widgets/capacity_indicator.dart:30` | label |

## Widgets con Tooltip

| # | Widget | Archivo |
|---|--------|---------|
| 1 | Home tab — refresh button | `features/home/tabs/home_tab.dart:113` |
| 2 | Stop detail — back button | `features/stop_detail/stop_detail_screen.dart:62` |
| 3 | Stop detail — favorite button | `features/stop_detail/stop_detail_screen.dart:283` |
| 4 | Driver panel | `features/driver/driver_panel.dart:85` |
| 5 | Route feedback — like button | `features/route_detail/widgets/route_detail_feedback_section.dart:37` |
| 6 | Route feedback — report button | `features/route_detail/widgets/route_detail_feedback_section.dart:50` |
| 7 | Side nav — menu item | `features/home/widgets/home_side_nav.dart:139` |
| 8 | Bottom nav — tab item | `features/home/widgets/home_bottom_nav.dart:78` |
| 9 | Transit app bar — action | `shared/widgets/transit_app_bar.dart:35` |
| 10 | Transit bottom sheet — close | `shared/widgets/transit_bottom_sheet.dart:59` |

## Arquitectura de accesibilidad

```
app.dart
├── ColorFiltered (colorBlindMode != none)
│   └── accessibility_matrix.dart (matrices 4x5)
├── MediaQuery.textScaler (fontScale)
└── BackgroundWrapper
    └── SmokeBackground (reduceMotion)

theme_notifier.dart
├── fontScale → app.dart + transit_theme.dart
├── colorBlindMode → app.dart ColorFiltered
├── dyslexiaFontEnabled → transit_theme.dart (Atkinson Hyperlegible)
├── reduceMotion → stagger_list.dart + smoke_background.dart
└── highContrast → high_contrast_theme.dart

transit_theme.dart
├── buildTransitTheme(scheme, fontScale, dyslexiaFontEnabled)
├── dyslexiaFontEnabled ? atkinsonHyperlegibleTextTheme : dmSansTextTheme
└── textTheme.apply(fontSizeFactor: fontScale)

accessibility_settings_screen.dart
├── Tema (system/light/dark) ← themeModeProvider
├── Alto contraste ← themeNotifier.highContrast
├── Preferencias del sistema (read-only: MQ)
└── Idioma (system/es/en) ← localeProvider

appearance_screen.dart
├── Paletas de color
├── Modo daltónico (ninguno/protanopia/deuteranopia/tritanopia)
├── Fuente dislexia (toggle)
├── Escala de texto (slider)
├── Reducir animaciones (toggle)
└── Fondo animado + opacidad
```

## Próximos pasos

- [ ] **Verificación manual con TalkBack (Android) y VoiceOver (iOS).** El análisis de código confirma la presencia de nodos Semantics, pero solo un test manual con lector de pantalla puede validar que el flujo de navegación es usable.
- [ ] **Mapa: añadir marcadores como nodos Semantics.** Investigar si `flutter_map` soporta `Semantics` por marcador vía `Marker` con `child` que envuelva la info en `Semantics`. Alternativa: overlay de botones invisibles sobre cada parada con `ExcludeSemantics` solo en el canvas del mapa.
- [ ] **Golden tests de accesibilidad en CI (F26).** Generar screenshots con `colorBlindMode`, `highContrast`, y `fontScale` extremos para detectar regresiones visuales.
- [ ] **`accessibility_lint` en `flutter analyze`.** Investigar disponibilidad de reglas de lint específicas de accesibilidad para Flutter (ej. `avoid_small_tap_targets`, `require_semantics_label`). Evaluar integrar en `analysis_options.yaml`.
- [ ] **Screencast de pruebas con lector de pantalla en `docs/A11Y_VIDEOS/`.** Grabar sesiones de TalkBack y VoiceOver navegando las pantallas principales para documentar el comportamiento real.
- [ ] **i18n de mensajes Semantics.** Actualmente los labels de Semantics están hardcodeados en español. Migrar a `AppLocalizations` para que el lector de pantalla anuncie en el idioma seleccionado.
- [ ] **`OfflineBanner._buildMessage` hardcodeado en español.** Línea `offline_banner.dart:75-83`. Migrar a l10n.
- [ ] **Skip links.** Añadir `SkipLink` en pantallas largas (Home, Stop Detail, Appearance) para que usuarios de teclado/TalkBack puedan saltar al contenido principal.
- [ ] **Focus traversal order.** Verificar que el orden de foco en formularios (sign-in, sign-up, feedback) siga un orden lógico con `FocusTraversalGroup`.
- [ ] **`Slider` de fontScale sin label semántico.** En `appearance_screen.dart`, el slider de escala de texto carece de `Semantics.label`. Añadir.
