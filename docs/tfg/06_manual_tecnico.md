# 06 — Manual Técnico

**Proyecto:** Transitly
**Versión:** 2.2
**Fecha:** 2026-05-14

---

## 1. Requisitos del sistema

### Desarrollo
- **SO:** Windows 10/11, macOS 12+, Linux (Ubuntu 20.04+)
- **Flutter SDK:** 3.x (stable channel)
- **Dart SDK:** 3.x
- **Android Studio:** Hedgehog+ (con Android SDK 34+)
- **Xcode:** 15+ (solo macOS, para iOS)
- **Supabase CLI:** 1.x (para migraciones locales)
- **Git:** 2.40+

### Producción
- **Android:** API 24+ (Android 7.0 Nougat)
- **iOS:** 16+
- **Web:** Cualquier navegador moderno (híbrido Astro + Flutter Web)

---

## 2. Instalación y configuración

### 2.1 Clonar repositorio

```bash
git clone https://github.com/astralk9999/Transitly.git
cd Transitly
```

### 2.2 Configurar variables de entorno

```bash
cp .env.example .env
```

Editar `.env` con las credenciales de Supabase:
```
SUPABASE_URL=https://mmzahxtiaurkgtmtehxk.supabase.co
SUPABASE_ANON_KEY=eyJh...
```

### 2.3 Instalar dependencias

```bash
flutter pub get
```

### 2.4 Generar localizaciones

```bash
flutter gen-l10n
```

### 2.5 Generar código (freezed + json_serializable)

```bash
tool/build.sh
```

### 2.6 Verificar el entorno

```bash
flutter analyze
flutter test
```

### 2.7 Ejecutar en dispositivo

```bash
flutter run
```

---

## 3. Estructura del proyecto

```
Transitly/
├── lib/                        # Código fuente Dart
│   ├── main.dart               # Punto de entrada
│   ├── app.dart                # MaterialApp.router
│   ├── core/
│   │   ├── router/             # go_router (app_router.dart)
│   │   ├── theme/              # Design tokens
│   │   └── utils/              # AppLogger, uuid
│   ├── data/                   # Capa de datos
│   │   ├── cache/              # Hive (boxes + adapters)
│   │   ├── mock/               # MockDataService (modo invitado)
│   │   ├── nfc/                # Lector NFC
│   │   ├── sync/               # Cola offline
│   │   └── <entity>/           # Repositorios (12 entidades)
│   ├── features/               # Pantallas por dominio
│   ├── l10n/                   # Internacionalización
│   └── shared/                 # Modelos, providers, widgets
├── assets/
│   └── mock/                   # Datos semilla (JSON)
├── docs/                       # Documentación
│   ├── ARCHITECTURE.md         # Reglas de arquitectura
│   ├── historico/PLAN_TRANSITLY_V2.md    # Plan de 27 fases
│   ├── PENDIENTES.md           # Incidencias y mejoras
│   └── tfg/                    # Documentación académica
├── multiagent/                 # Sistema multiagente
├── supabase/
│   └── migrations/             # SQL migrations (001-007)
├── test/                       # Tests
├── tools/                      # Scripts auxiliares
├── pubspec.yaml                # Dependencias Dart
├── build.yaml                  # Config codegen
├── l10n.yaml                   # Config i18n
└── .env.example                # Plantilla de variables
```

---

## 4. Base de datos (Supabase)

### 4.1 Tablas principales

| Tabla | Registros | Descripción |
|-------|-----------|-------------|
| `profiles` | ~10 | Perfiles de usuario (1:1 con auth.users) |
| `operators` | ~10 | Operadores de transporte |
| `routes` | ~500+ | Rutas de autobús |
| `stops` | ~3000+ | Paradas |
| `schedules` | ~15000+ | Horarios |
| `incidents` | variable | Incidencias reportadas |
| `route_feedback` | variable | Feedback de rutas |
| `route_suggestions` | variable | Sugerencias de rutas |
| `bus_positions` | variable | Posiciones GPS de buses |
| `driver_assignments` | variable | Asignaciones conductor-operador |

### 4.2 Migraciones

```bash
# Aplicar migraciones a Supabase remoto
supabase db push

# Ver estado de migraciones
supabase migration list
```

### 4.3 Row-Level Security

- 25 tablas con RLS activo
- 102 policies granulares
- Roles: `anon`, `authenticated`, políticas por `user_role`
- Admin bypass para operaciones de gestión

---

## 5. APIs y servicios externos

| Servicio | Uso | Endpoint/Clave |
|----------|-----|---------------|
| Supabase | Backend principal | `.env` (`SUPABASE_URL`) |
| Supabase Realtime | Activo en notificaciones (`notification_stream_provider`). **El streaming de `bus_positions` es trabajo futuro (F13)**: los repos `remote` emiten snapshot + refresh manual, no suscripción en vivo. | Canal `public:notifications` (activo) / `public:bus_positions` (pendiente) |
| Supabase Storage | Avatares, adjuntos | 5 buckets |
| MapTiler | Tiles de mapa | `maptiler_api_key` (planificado F20) |
| Google Fonts | Fuentes (dmSans, ibmPlexMono) | Runtime fetch → bundle F17 |
| Sentry | Crash reporting | Planificado F22 |
| PostHog | Analytics | Planificado F22 |
| FCM | Push notifications | Planificado F21 |

---

## 6. Despliegue

### Android (APK)

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### iOS (IPA)

```bash
flutter build ios --release
# Archivo en Xcode: Product → Archive → Distribute
```

### Web (híbrido Astro + Flutter)

```bash
flutter build web --release
# Output: build/web/
# Integrar con landing Astro (planificado F23)
```

---

## 7. Mantenimiento

### Actualizar dependencias

```bash
flutter pub outdated
flutter pub upgrade
tool/build.sh  # Regenerar código tras cambios en modelos
```

### Añadir nuevo operador

1. Añadir entrada en `data/seed/spanish_gtfs_feeds.yaml`
2. Ejecutar `dart tools/seed_operators.dart`
3. Ejecutar Edge Function `import_gtfs` con el slug del operador

### Añadir nueva entidad con repositorio

Seguir el patrón canónico de `lib/data/operator/`:
1. `domain/` — interfaz abstracta
2. `remote/` — implementación Supabase
3. `local/` — implementación Hive
4. `mock/` — fallback invitado
5. Provider Riverpod con SWR

---

**Última actualización:** 2026-05-14 · Documentation Agent
