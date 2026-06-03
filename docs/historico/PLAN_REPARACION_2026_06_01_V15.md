# Plan v15 — 10 fondos react-bits adaptados a Flutter

**Fecha:** 2026-06-01
**Autor:** Claude Code (Opus 4.7)
**Plan anterior:** `PLAN_REPARACION_2026_06_01_V14.md`

---

## TL;DR

10 fondos de react-bits convertidos a Flutter siguiendo el mismo patrón
que `shaders/smoke.frag` + `SmokeBackground`. Los que usan WebGL/Three.js
se convierten a **`FragmentProgram` GLSL ES 1.00** (renderiza en GPU
sobre `CustomPainter`); los que usan Canvas2D se convierten a
**`CustomPainter` Dart puro**.

| # | Nombre react-bits | Tipo origen | Adaptación Flutter | Dificultad |
|---|---|---|---|---|
| 1 | **Aurora** | OGL + GLSL | FragmentShader `aurora.frag` | Media |
| 2 | **Balatro** | OGL + GLSL | FragmentShader `balatro.frag` | Media |
| 3 | **ColorBends** | Three.js + GLSL | FragmentShader `color_bends.frag` | Alta |
| 4 | **DarkVeil** | OGL + GLSL (CPPN neural) | FragmentShader `dark_veil.frag` | Alta |
| 5 | **Dither** | R3F + postprocessing | 2-pass shader (waves + dither) | Muy alta |
| 6 | **DotField** | Canvas2D | `CustomPainter` Dart | Baja |
| 7 | **DotGrid** | Canvas2D + GSAP | `CustomPainter` Dart + tween | Media |
| 8 | **FaultyTerminal** | OGL + GLSL | FragmentShader `faulty_terminal.frag` | Alta |
| 9 | **FloatingLines** | Three.js + GLSL | FragmentShader `floating_lines.frag` | Media |
| 10 | **LightRays** | OGL + GLSL | FragmentShader `light_rays.frag` | Media |

**Estimado total**: 8 horas de desarrollo + 2h pulido + 1h integración.

---

## Patrón de adaptación

### Para shaders GLSL (Aurora, Balatro, ColorBends, etc.)

**Diferencias clave WebGL → Flutter GLSL ES 1.00:**

| WebGL (origen) | Flutter |
|---|---|
| `#version 300 es` | Sin pragma de versión |
| `in vec2 position;` | (no input attributes — Flutter pasa quad full-screen) |
| `out vec4 fragColor;` | `out vec4 fragColor;` (con `flutter/runtime_effect.glsl`) |
| `gl_FragCoord` | `FlutterFragCoord()` |
| `gl_FragColor` | Asignar a `fragColor` out variable |
| `vec3 uColorStops[3]` | Aplanado a `uColor1`, `uColor2`, `uColor3` (cada uno vec3) |
| `texture(sampler, uv)` | `texture(sampler, uv)` (igual) |

**Plantilla Flutter `.frag`:**

```glsl
#version 460 core
#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform float uTime;          // index 0
uniform vec2  uResolution;    // indices 1,2
uniform vec3  uColor1;        // indices 3,4,5
uniform vec3  uColor2;        // indices 6,7,8
uniform vec3  uColor3;        // indices 9,10,11
uniform float uAmplitude;     // index 12
uniform float uBlend;         // index 13

out vec4 fragColor;

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / uResolution;
    // ... lógica del shader original ...
    fragColor = vec4(rgb, alpha);
}
```

**Carga en Dart (mismo patrón que `SmokeBackground`):**

```dart
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({
    super.key,
    this.colorStops = const [
      Color(0xFF7CFF67),
      Color(0xFFB497CF),
      Color(0xFF5227FF),
    ],
    this.amplitude = 1.0,
    this.blend = 0.5,
    this.speed = 1.0,
    this.opacity = 1.0,
    this.reduceMotion = false,
    this.child,
  });

  // ... fields ...

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  ui.FragmentShader? _shader;
  late final Ticker _ticker;
  final ValueNotifier<double> _time = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) {
      _time.value = d.inMilliseconds / 1000.0;
    });
    if (!widget.reduceMotion) _ticker.start();
    _loadShader();
  }

  Future<void> _loadShader() async {
    final program = await ui.FragmentProgram.fromAsset('shaders/aurora.frag');
    if (mounted) setState(() => _shader = program.fragmentShader());
  }

  @override
  Widget build(BuildContext context) {
    if (_shader == null) return widget.child ?? const SizedBox.expand();
    return CustomPaint(
      painter: _AuroraPainter(
        shader: _shader!,
        time: _time,
        colorStops: widget.colorStops,
        amplitude: widget.amplitude,
        blend: widget.blend,
        speed: widget.speed,
      ),
      child: widget.child ?? const SizedBox.expand(),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  // ... constructor ...

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, time.value * speed);
    shader.setFloat(1, size.width);
    shader.setFloat(2, size.height);
    shader.setFloat(3, colorStops[0].r); // r
    shader.setFloat(4, colorStops[0].g);
    shader.setFloat(5, colorStops[0].b);
    shader.setFloat(6, colorStops[1].r);
    shader.setFloat(7, colorStops[1].g);
    shader.setFloat(8, colorStops[1].b);
    shader.setFloat(9, colorStops[2].r);
    shader.setFloat(10, colorStops[2].g);
    shader.setFloat(11, colorStops[2].b);
    shader.setFloat(12, amplitude);
    shader.setFloat(13, blend);

    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }
}
```

### Para Canvas2D (DotField, DotGrid)

CustomPainter directo en Dart, sin shader. Idéntico al patrón de
`SoftGridPainter` / `TopoLinesPainter` que ya tenemos.

---

## Estructura

```
WAVE 1 (shaders GLSL principales — 4 agentes paralelos)
├── A1  Aurora + LightRays (más simples)
├── A2  Balatro + FloatingLines
├── A3  ColorBends + FaultyTerminal
└── A4  DarkVeil

WAVE 2 (Canvas2D — 1 agente)
└── A5  DotField + DotGrid

WAVE 3 (Multi-pass — 1 agente)
└── A6  Dither (waves + post-process dither = 2 shaders + texture)

WAVE 4 (integración — 1 agente)
└── A7  Registrar en pubspec.yaml shaders:, app_background.dart enum,
        prefab_backgrounds.dart, background_wrapper.dart switch,
        actualizar background_selector.dart con previews

WAVE 5 (coordinador)
└── flutter clean + pub get + build APK + install
```

### Archivos NUEVOS

```
shaders/
  aurora.frag
  balatro.frag
  color_bends.frag
  dark_veil.frag
  dither_waves.frag          (pass 1 de Dither)
  dither_dither.frag         (pass 2 de Dither)
  faulty_terminal.frag
  floating_lines.frag
  light_rays.frag

lib/shared/widgets/backgrounds/
  aurora_background.dart
  balatro_background.dart
  color_bends_background.dart
  dark_veil_background.dart
  dither_background.dart
  dot_field_background.dart
  dot_grid_background.dart
  faulty_terminal_background.dart
  floating_lines_background.dart
  light_rays_background.dart

lib/core/theme/backgrounds/
  (modificar app_background.dart, prefab_backgrounds.dart)
```

### Archivos a MODIFICAR

```
pubspec.yaml  (añadir 9 shaders nuevos a sección `shaders:`)
lib/core/theme/backgrounds/app_background.dart  (enum + clases)
lib/core/theme/backgrounds/prefab_backgrounds.dart  (registrar)
lib/shared/widgets/background_wrapper.dart  (switch para cada uno)
lib/features/appearance/widgets/background_selector.dart  (iconos+previews)
```

---

## WAVE 1 — Briefs

### A1 — Aurora + LightRays

```text
ROL: Engineer Flutter, FragmentShader.

OBJETIVO:
Adaptar Aurora.tsx y LightRays.tsx a Flutter:
- shaders/aurora.frag (con noise FBM, color ramp, snoise)
- shaders/light_rays.frag (con rayStrength, dist falloff)
- lib/shared/widgets/backgrounds/aurora_background.dart
- lib/shared/widgets/backgrounds/light_rays_background.dart

DETALLES TÉCNICOS AURORA:
- 3 color stops aplanados a 9 uniforms float (vec3 × 3)
- uniforms: uTime, uResolution (vec2), uColor1/2/3 (vec3), uAmplitude, uBlend
- Default colors: ["#7cff67","#B497CF","#5227FF"]
- Función snoise (simplex noise 2D) — copiar tal cual del original
- COLOR_RAMP macro — convertir a función inline porque Flutter GLSL
  ES 1.00 puede no soportar macros complejas
- Output: vec4 con alpha basado en `auroraAlpha`

DETALLES TÉCNICOS LIGHT RAYS:
- uniforms: iTime, iResolution, rayPos, rayDir, raysColor, raysSpeed,
  lightSpread, rayLength, pulsating, fadeDistance, saturation, mousePos,
  mouseInfluence, noiseAmount, distortion
- Función rayStrength compleja con spread + falloff + pulse + noise
- Soporta 8 orígenes (top-center, top-left, ... bottom-right) calculados
  en Dart antes de pasar al shader
- mousePos: en runtime, leer GestureDetector + ValueNotifier; en Apariencia
  se desactiva mouseInfluence (uMouseInfluence = 0)

INTEGRACIÓN:
- Constructor del widget acepta props del react-bits Usage
- Asignar valores razonables por defecto si el contexto es "fondo de app"
  (no hay mouse, pulsating=false, etc.)
- mismo patrón State con Ticker + ValueNotifier que SmokeBackground

VERIFICACIÓN:
- App → Apariencia → Fondo → "Aurora" → render correcto
- App → Apariencia → Fondo → "Light Rays" → render correcto
```

### A2 — Balatro + FloatingLines

```text
ROL: Engineer Flutter, FragmentShader.

DETALLES TÉCNICOS BALATRO:
- uniforms: iTime, iResolution, uSpinRotation, uSpinSpeed, uOffset,
  uColor1/2/3 (vec4), uContrast, uLighting, uSpinAmount, uPixelFilter,
  uSpinEase, uIsRotate (bool→float 0/1), uMouse
- Loop con 5 iteraciones de pattern
- En reposo: uIsRotate = false, uMouse fijado a (0.5, 0.5)
- Vec4 colors → 12 uniforms float

DETALLES TÉCNICOS FLOATING LINES:
- 3 ondas (top/middle/bottom) con counts y distances configurables
- Función wave + getLineColor con gradient sampling
- Loop interno con MAX 8 líneas por onda (limitado por GLSL ES 1.00)
- enabledTop/Middle/Bottom como bool → float
- linesGradient: array de hasta 8 vec3 (aplanado a 24 floats)
- linesGradientCount: int → float
- En reposo: interactive=false, mouse fijo

INTEGRACIÓN:
- Defaults: BalatroBackground muestra el efecto sin interacción mouse
- FloatingLinesBackground respeta accent de paleta como uno de los colores
```

### A3 — ColorBends + FaultyTerminal

```text
ROL: Engineer Flutter, FragmentShader avanzado.

DETALLES TÉCNICOS COLORBENDS:
- Shader compacto pero con muchos uniforms
- uColors[8] → 24 uniforms vec3 aplanados (probable necesidad de
  reescribir el loop para acceder por nombre a cada color)
- uIterations: loop con `break` cuando i >= uIterations
- Default colors: ["#ff5c7a","#8a5cff","#00ffd1"]
- Mouse y rotation: pasar valores fijos en background

DETALLES TÉCNICOS FAULTY TERMINAL:
- Shader pesado: nested arithmetic, hueShift, scanlines, glitch
- 16 uniforms (scale, gridMul, digitSize, timeScale, scanlineIntensity,
  glitchAmount, flickerAmount, noiseAmp, chromaticAberration, dither,
  curvature, tint, mousePos, mouseStrength, useMouse, pageLoadProgress,
  brightness)
- pageLoadAnimation: en runtime con clock; en Apariencia siempre 1.0
- Tint: del accent de la paleta activa

INTEGRACIÓN:
- ColorBendsBackground.defaultColors usa accent + variantes shifted hue
- FaultyTerminalBackground tint = c.accent del scheme activo
```

### A4 — DarkVeil (CPPN neural)

```text
ROL: Engineer Flutter, FragmentShader pesado.

DETALLES TÉCNICOS:
- El shader es enorme: ~80 líneas de matrices 4×4 hardcoded (es un
  Compositional Pattern-Producing Network entrenado)
- 8 buffers vec4 (`buf[0..7]`) con operaciones matriciales
- Pesados cálculos en cada frame → posible problema de performance
  en dispositivos móviles bajos
- Funciones: hueShiftRGB, sigmoid, rand, cppn_fn (mainImage)
- uniforms: uHueShift, uNoise (intensity), uScan (intensity),
  uScanFreq, uWarp, uTime, uResolution

PERFORMANCE:
- Probar en A142P real
- Si baja de 30 FPS, añadir uniform `uQuality` con escala de resolución
- Renderizar a half-res y upscale con FilterQuality.medium

INTEGRACIÓN:
- DarkVeilBackground (con uniform `quality: double`)
- Defaults conservadores: noiseIntensity=0, scanlineIntensity=0, warpAmount=0
```

---

## WAVE 2 — Brief

### A5 — DotField + DotGrid (Canvas2D)

```text
ROL: Engineer Flutter, CustomPainter Dart.

DOTFIELD:
- Grid de puntos con bulge interactivo cuando mouse cerca
- ELIMINAR interactividad mouse (apps móvil) — usar wave amplitude
  como reemplazo o glow centrado pulsante
- Props: dotRadius, dotSpacing, gradientFrom/To (linear gradient),
  glowColor, glowRadius
- Implementar con CustomPainter (no shader)
- Ticker para animar el wave/glow

DOTGRID:
- Similar pero con animación inertia (originalmente con GSAP)
- En Flutter: AnimationController con elasticOut tween al click
- Mouse desactivado en Apariencia → solo grid estático con baseColor

INTEGRACIÓN:
- Dos clases:
  lib/shared/widgets/backgrounds/dot_field_background.dart
  lib/shared/widgets/backgrounds/dot_grid_background.dart
```

---

## WAVE 3 — Brief

### A6 — Dither (multi-pass)

```text
ROL: Engineer Flutter, multi-pass rendering.

PROBLEMA:
Dither es 2 shaders en cadena:
1. waveFragmentShader genera ruido FBM en una textura
2. ditherFragmentShader aplica Bayer matrix dithering sobre esa textura

En Flutter el multi-pass se hace con `Layer` + `ui.PictureRecorder`
+ `ui.Image` intermediate:
1. Renderiza wave shader a un ui.Image off-screen
2. Pasa ese ui.Image como sampler2D al dither shader
3. Renderiza dither shader al canvas final

IMPLEMENTACIÓN:
- shaders/dither_waves.frag (pass 1)
- shaders/dither_dither.frag (pass 2, uniform `sampler2D inputBuffer`)
- En el painter:
  1. Crear FragmentShader para waves
  2. drawRect a un PictureRecorder
  3. picture.toImage() → ui.Image intermediate
  4. dither.setImageSampler(0, intermediate)
  5. dither.setFloat(...) los uniforms restantes
  6. drawRect del dither al canvas final

PERFORMANCE:
- 2 passes = ~2× lento. Aceptable a 30 FPS en móvil moderno.
- Si lento, reducir resolución del intermediate buffer (half-res)

INTEGRACIÓN:
- DitherBackground con defaults razonables
- waveColor del accent de la paleta
```

---

## WAVE 4 — Brief

### A7 — Integración completa

```text
ROL: Engineer Flutter, sistema de fondos.

ARCHIVOS:
- pubspec.yaml
- lib/core/theme/backgrounds/app_background.dart
- lib/core/theme/backgrounds/prefab_backgrounds.dart
- lib/shared/widgets/background_wrapper.dart
- lib/features/appearance/widgets/background_selector.dart

TAREAS:

T1. pubspec.yaml — añadir 9 shaders nuevos:

    shaders:
      - shaders/smoke.frag
      - shaders/aurora.frag
      - shaders/balatro.frag
      - shaders/color_bends.frag
      - shaders/dark_veil.frag
      - shaders/dither_waves.frag
      - shaders/dither_dither.frag
      - shaders/faulty_terminal.frag
      - shaders/floating_lines.frag
      - shaders/light_rays.frag

T2. app_background.dart — añadir nuevos tipos:
   - Crear clase `ShaderBackground` extendida o nuevas subclases por
     cada fondo: AuroraBackground, BalatroBackground, ..., LightRaysBackground
   - Cada uno con su `id` único y constructor con defaults

T3. prefab_backgrounds.dart — registrar los 10 nuevos en `prefabBackgrounds`:
   ```dart
   final prefabBackgrounds = <AppBackground>[
     const NoneBackground(),
     const ShaderBackground('shaders/smoke.frag', Colors.purple),
     // ... existentes ...
     const AuroraBgConfig(),
     const BalatroBgConfig(),
     const ColorBendsBgConfig(),
     const DarkVeilBgConfig(),
     const DitherBgConfig(),
     const DotFieldBgConfig(),
     const DotGridBgConfig(),
     const FaultyTerminalBgConfig(),
     const FloatingLinesBgConfig(),
     const LightRaysBgConfig(),
   ];
   ```

T4. background_wrapper.dart — switch ampliado:
   ```dart
   return switch (bg) {
     NoneBackground() => ...,
     ShaderBackground() => ...,
     GradientBackground() => ...,
     ImageBackground() => ...,
     ProceduralBackground() => ...,
     AuroraBgConfig() => AuroraBackground(...),
     BalatroBgConfig() => BalatroBackground(...),
     // etc.
   };
   ```

T5. background_selector.dart — icono y label por cada uno:
   ```dart
   String _bgName(String id) => switch (id) {
     'aurora' => 'Aurora',
     'balatro' => 'Balatro',
     'color-bends' => 'Color Bends',
     'dark-veil' => 'Dark Veil',
     'dither' => 'Dither',
     'dot-field' => 'Dot Field',
     'dot-grid' => 'Dot Grid',
     'faulty-terminal' => 'Faulty Terminal',
     'floating-lines' => 'Floating Lines',
     'light-rays' => 'Light Rays',
     // ...
   };

   IconData _bgIcon(String id) => switch (id) {
     'aurora' => Icons.gradient,
     'balatro' => Icons.spa,
     'color-bends' => Icons.water,
     'dark-veil' => Icons.dark_mode,
     'dither' => Icons.grid_3x3,
     'dot-field' => Icons.grain,
     'dot-grid' => Icons.apps,
     'faulty-terminal' => Icons.terminal,
     'floating-lines' => Icons.waves,
     'light-rays' => Icons.flare,
     // ...
   };
   ```

T6. (Opcional) Pre-cargar shaders en startup:
   En main.dart, antes de runApp, await
   `FragmentProgram.fromAsset(...)` para los 10 para evitar lag al
   seleccionar el primero.
```

---

## Implementación demo: Aurora

Como prueba de concepto voy a implementar Aurora ahora mismo para
validar el patrón. Si funciona bien, los otros 9 siguen exactamente la
misma estructura.

**Archivo `shaders/aurora.frag`** (a crear):

```glsl
#version 460 core
#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform float uTime;
uniform vec2  uResolution;
uniform vec3  uColor1;
uniform vec3  uColor2;
uniform vec3  uColor3;
uniform float uAmplitude;
uniform float uBlend;

out vec4 fragColor;

vec3 permute(vec3 x) {
    return mod(((x * 34.0) + 1.0) * x, 289.0);
}

float snoise(vec2 v){
    const vec4 C = vec4(
        0.211324865405187, 0.366025403784439,
        -0.577350269189626, 0.024390243902439
    );
    vec2 i  = floor(v + dot(v, C.yy));
    vec2 x0 = v - i + dot(i, C.xx);
    vec2 i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    i = mod(i, 289.0);

    vec3 p = permute(
        permute(i.y + vec3(0.0, i1.y, 1.0))
      + i.x + vec3(0.0, i1.x, 1.0)
    );

    vec3 m = max(
        0.5 - vec3(
            dot(x0, x0),
            dot(x12.xy, x12.xy),
            dot(x12.zw, x12.zw)
        ),
        0.0
    );
    m = m * m;
    m = m * m;

    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * (a0*a0 + h*h);

    vec3 g;
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

vec3 colorRamp(float t) {
    if (t <= 0.5) {
        return mix(uColor1, uColor2, t * 2.0);
    } else {
        return mix(uColor2, uColor3, (t - 0.5) * 2.0);
    }
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / uResolution;

    vec3 rampColor = colorRamp(uv.x);

    float height = snoise(vec2(uv.x * 2.0 + uTime * 0.1, uTime * 0.25))
        * 0.5 * uAmplitude;
    height = exp(height);
    height = (uv.y * 2.0 - height + 0.2);
    float intensity = 0.6 * height;

    float midPoint = 0.20;
    float auroraAlpha = smoothstep(
        midPoint - uBlend * 0.5,
        midPoint + uBlend * 0.5,
        intensity
    );

    vec3 auroraColor = intensity * rampColor;
    fragColor = vec4(auroraColor * auroraAlpha, auroraAlpha);
}
```

**Archivo `lib/shared/widgets/backgrounds/aurora_background.dart`** (a crear):

(Ver código completo en sección "Patrón de adaptación" arriba — sigue la
misma estructura que `SmokeBackground`.)

---

## Roadmap de ejecución

| Fase | Items | Tiempo |
|------|-------|--------|
| **Fase 1** | Implementar Aurora como demo + validación | 1h |
| **Fase 2** | Implementar shaders simples (LightRays, Balatro, FloatingLines) | 3h |
| **Fase 3** | Implementar shaders complejos (ColorBends, FaultyTerminal, DarkVeil) | 3h |
| **Fase 4** | Implementar Canvas2D (DotField, DotGrid) | 1h |
| **Fase 5** | Implementar multi-pass (Dither) | 1.5h |
| **Fase 6** | Integración + testing en A142P + ajustes performance | 2h |
| **TOTAL** | | **~11h** |

---

## Riesgos y mitigaciones

| Riesgo | Mitigación |
|--------|------------|
| Performance baja en A142P con DarkVeil/FaultyTerminal | Renderizar a half-res, upscale con FilterQuality.medium |
| GLSL ES 1.00 no soporta ciertas funciones | Polyfill manual (ej. tanh, atanh con fórmulas) |
| Macros GLSL no portables (COLOR_RAMP de Aurora) | Convertir a función inline |
| Arrays grandes (uColorStops[3] de Aurora) | Aplanar a uniforms individuales (uColor1, uColor2, uColor3) |
| Multi-pass Dither con ui.Image lento | Cache de 1 frame con OffscreenLayer |
| Texturas / samplers no funcionan | Documentar limitación y simplificar |
| Mouse interaction (DotField/DotGrid) en móvil | Reemplazar por animación automática (wave, pulsing) |

---

## Decisión

Empiezo implementando **Aurora** ahora mismo para validar todo el flujo
(shader + widget + integración). Si en el dispositivo se ve bien, los
otros 9 son aplicar el mismo patrón.

Si quieres que los haga TODOS de una en sesiones largas, dímelo y
empiezo en orden de dificultad ascendente:
LightRays → Aurora → FloatingLines → Balatro → ColorBends →
FaultyTerminal → DarkVeil → DotField → DotGrid → Dither.
