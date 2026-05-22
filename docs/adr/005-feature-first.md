# ADR-005: Arquitectura feature-first

## Estado
Aceptado

## Contexto
El proyecto crece con ~20 features y necesita una organización de carpetas que:
- Escale linealmente con nuevas features (cada feature no toca otras)
- Separe claramente UI de datos
- Permita encontrar código rápido (feature → archivo → línea)
- Facilite onboarding de nuevos desarrolladores

## Decisión
Usamos arquitectura **feature-first** con carpetas transversales `core/`, `shared/`, `data/`.

## Estructura
```
lib/
├── main.dart              # bootstrap
├── app.dart               # MaterialApp.router
├── core/                  # router, theme, utils (NO lógica de negocio)
├── data/                  # repos, mock, cache, nfc, sync (no depende de features/)
├── features/              # una carpeta por dominio funcional
│   └── <feature>/
│       ├── *_screen.dart
│       ├── widgets/
│       └── *_controller.dart
├── l10n/                  # ARB sources + generated
└── shared/                # models, providers, widgets (usados en ≥2 features)
```

## Alternativas consideradas

### Layer-first (MVC, Clean Architecture)
Descartado. Con ~20 features, layer-first dispersa el código de una misma feature en 3-4 carpetas. Cambiar una pantalla requiere tocar 4 archivos en 4 ubicaciones distintas.

### Package-first (cada feature un paquete Dart)
Descartado. Overkill para un proyecto de este tamaño. La boundary de paquete añade fricción en imports sin beneficio hasta que el equipo crezca a ≥5 desarrolladores.

## Reglas de oro

1. **Una pantalla = un `*_screen.dart`** dentro de su feature. Si >300 LoC → descomponer en `widgets/` o `steps/` de la misma feature.
2. **`shared/widgets/` solo si se usa en ≥2 features.** Si solo una feature lo usa, vive dentro de ella.
3. **`shared/providers/` solo para estado global.** Estado local → `*_controller.dart` en la propia feature.
4. **`data/` no depende de `features/`.** La UI consume datos a través de providers Riverpod.
5. **Tokens de diseño se consumen, no se duplican.** `transit_colors`, `transit_typography`, `transit_spacing`, `transit_animations`.

## Consecuencias

### Positivas
- Cada feature es autocontenida → navegación directa feature → archivo
- Bajo acoplamiento entre features (solo comparten `shared/`)
- Fácil de eliminar/renombrar features sin efectos laterales
- Clara separación UI (`features/`) vs datos (`data/`)

### Negativas
- Riesgo de duplicar widgets en features (mitigado con regla 2)
- Riesgo de que `shared/widgets/` crezca descontrolado (mitigado con regla 2)
- Riesgo de que `data/` importe `features/` (mitigado con test de arquitectura de capas, PRO-QA-14)

## Referencias
- `docs/ARCHITECTURE.md` — documento completo de arquitectura
- `lib/` — implementación actual
