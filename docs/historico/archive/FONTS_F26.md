# F26 — Empaquetar fuentes localmente (cerrar el fetch por red)

## Estado actual

`google_fonts` resuelve **DM Sans** e **IBM Plex Mono** por red en el primer
arranque (con caché posterior). Implicaciones:

- **Privacidad:** la primera carga envía IP + User-Agent a `fonts.gstatic.com`.
- **Offline:** sin red en el primer arranque, la tipografía cae a la del sistema.

El código ya tiene el *seam* listo: la constante `_fontsBundled` en
`lib/main.dart`. Mientras es `false`, se mantiene el comportamiento actual
(precarga en segundo plano, sin bloquear el arranque). Esta tarea queda como
deuda técnica documentada porque requiere binarios `.ttf` que no se generan
desde el entorno de desarrollo automatizado.

## Pasos para cerrar F26

1. **Descargar las familias** (mismos pesos que usa la app):
   - DM Sans — <https://fonts.google.com/specimen/DM+Sans>
     (al menos `Regular 400`, `Medium 500`, `Bold 700`).
   - IBM Plex Mono — <https://fonts.google.com/specimen/IBM+Plex+Mono>
     (al menos `Regular 400`, `Medium 500`, `Bold 700`).

2. **Copiar los `.ttf`** a:
   - `assets/fonts/dm_sans/DMSans-Regular.ttf` (etc.)
   - `assets/fonts/ibm_plex_mono/IBMPlexMono-Regular.ttf` (etc.)

3. **Declarar las fuentes en `pubspec.yaml`** bajo `flutter:` (usar la
   sección `fonts:`, no `assets:`), por ejemplo:

   ```yaml
   fonts:
     - family: DM Sans
       fonts:
         - asset: assets/fonts/dm_sans/DMSans-Regular.ttf
         - asset: assets/fonts/dm_sans/DMSans-Medium.ttf
           weight: 500
         - asset: assets/fonts/dm_sans/DMSans-Bold.ttf
           weight: 700
     - family: IBM Plex Mono
       fonts:
         - asset: assets/fonts/ibm_plex_mono/IBMPlexMono-Regular.ttf
         - asset: assets/fonts/ibm_plex_mono/IBMPlexMono-Medium.ttf
           weight: 500
         - asset: assets/fonts/ibm_plex_mono/IBMPlexMono-Bold.ttf
           weight: 700
   ```

4. **Activar el switch**: en `lib/main.dart`, poner
   `const bool _fontsBundled = true;`. Esto llama a
   `GoogleFonts.config.allowRuntimeFetching = false;`, de modo que
   `google_fonts` usa exclusivamente las fuentes empaquetadas (los helpers
   `GoogleFonts.dmSans()` / `GoogleFonts.ibmPlexMono()` siguen funcionando
   porque resuelven contra la familia registrada por Flutter).

5. **Verificar**:
   - `flutter pub get` y `flutter run` **sin red** → la tipografía debe ser
     la correcta desde el primer frame.
   - `flutter analyze` y `flutter test` en verde.
   - Comprobar el tamaño del APK/IPA (los `.ttf` añaden ~1–2 MB).

## Notas

- No commitear `.ttf` con licencias incompatibles: DM Sans e IBM Plex Mono
  son **SIL OFL 1.1**, redistribuibles; incluir el `OFL.txt` de cada familia
  en su carpeta.
- El `OFL` permite el bundling; mantener el texto de licencia junto a los
  ficheros.
