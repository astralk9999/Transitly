# Inflesz Legibility Audit — Transitly

> **Version:** 1.0 · **Tool:** Inflesz (https://legible.es) · **Standard:** WCAG 2.2

## Overview

Inflesz analyzes text readability using the Flesch-Szigriszt index adapted for
Spanish. Scores range from 0 (very difficult) to 100 (very easy).

**Target for public-facing text:** ≥ 60 ("Normal" or easier).

---

## Audit Results

### Home screen

| Text | Score | Level | Status |
|------|:-----:|-------|:------:|
| "TRANSITLY" header | 100 | Muy fácil | ✅ |
| Route descriptions | 55 | Algo difícil | ⚠️ |
| Nearby stops label | 70 | Normal | ✅ |

### Error messages

| Text | Score | Level | Status |
|------|:-----:|-------|:------:|
| "NFC no disponible" | 65 | Normal | ✅ |
| "Error al leer la tarjeta" | 72 | Bastante fácil | ✅ |
| "Credenciales inválidas" | 48 | Difícil | ⚠️ |

### Onboarding

| Text | Score | Level | Status |
|------|:-----:|-------|:------:|
| "Bienvenido a Transitly" | 85 | Bastante fácil | ✅ |
| Step descriptions | 60 | Normal | ✅ |

---

## Recommendations

### Priority 1 (score < 50)

1. **"Credenciales inválidas"** → "El email o la contraseña no son correctos. Inténtalo de nuevo."
2. **Error genérico** → "Algo salió mal. Vuelve a intentarlo en unos segundos."

### Priority 2 (score 50-60)

3. Route descriptions → Add context: "L1 conecta el centro con la periferia. Pasa cada 15 minutos."

### Easy Reading Mode (PRO-A11Y-6)

A toggleable "Lectura Fácil" mode that:
- Shortens sentences to ≤ 15 words
- Replaces complex words with simpler synonyms
- Uses active voice instead of passive
- Adds emoji/icon indicators for key concepts

Implementation: `UserPreferences.easyReadingMode` boolean + ARB keys with
`_easy` suffix for simplified versions of complex strings.

```dart
// In app_es.arb
"nfcErrorAuthFailed": "No se pudo autenticar la tarjeta",
"nfcErrorAuthFailed_easy": "No se pudo leer la tarjeta. Inténtalo otra vez.",
```

---

## Re-audit Schedule

Quarterly, or when new user-facing text is added.
