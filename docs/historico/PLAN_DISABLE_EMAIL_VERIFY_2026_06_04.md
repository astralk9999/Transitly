# Plan de acción — Desactivar verificación de email (Supabase sin SMTP)

**Fecha:** 2026-06-04
**Autor:** Claude Code (Opus 4.7)
**Estado:** propuesto
**Goal:** Permitir signup directo sin verificación de email mientras no haya SMTP configurado. Sesión activa inmediata tras crear cuenta. Mantener la infraestructura dormida para reactivarla cuando se configure SMTP.
**Arquitectura:** Cambio de 1 toggle en Supabase Dashboard + auto-login defensivo en el cliente + limpieza de dead code opcional. **Tiempo total: ~40 min**.

---

## 1. Estado actual (auditado)

| # | Aspecto | Estado |
|---|---------|--------|
| **a** | Listener `onAuthStateChange` bypassa check `emailConfirmedAt` | ✅ Ya implementado (`auth_repository_supabase.dart:44-51`) |
| **b** | `signup_screen.dart` redirige a `/home/inicio` tras success | ✅ Ya implementado (línea 114-115) |
| **c** | Clase `AuthEmailVerificationPending` | ⚠️ Definida pero 0 usos en código vivo |
| **d** | `EmailVerifyPendingScreen` + ruta `/verify-email` | ⚠️ Existe pero ningún flujo navega allí |
| **e** | Toggle "Confirm email" en Supabase Dashboard | ❌ **Hay que desactivarlo manualmente** |
| **f** | `signUp()` con confirm-email ON → user pero no session | ❌ Bloquea la entrada directa al home |

**Causa raíz del bloqueo**: con el toggle "Confirm email" activo, `_client.auth.signUp(...)` retorna `User` pero `currentSession == null`. El bypass del listener no se dispara porque no hay evento `signedIn`. El usuario aterriza en `/home/inicio` sin sesión → `authStateProvider` emite `AuthUnauthenticated` → redirect a `/sign-in`.

---

## 2. Plan de tareas

### Tarea A — Desactivar verificación en Supabase Dashboard (5 min) ⭐ BLOQUEANTE

**Goal:** quitar el requisito de confirmar email para crear cuenta.

**Pasos manuales:**

- [ ] **Paso 1**: Abrir https://supabase.com/dashboard/project/mmzahxtiaurkgtmtehxk/auth/providers
- [ ] **Paso 2**: En la sección **Email** → desplegar configuración.
- [ ] **Paso 3**: Buscar **"Confirm email"** (o **"Enable email confirmations"**).
- [ ] **Paso 4**: Cambiar a **OFF / Disabled**.
- [ ] **Paso 5**: Guardar.

**Verificación:**
- Probar `signUp` desde la app con un email nuevo.
- En logs: `signed in uid=… (verification bypassed)` debe aparecer **inmediatamente tras el signUp**, no requerir click en email.

**Notas:**
- Las cuentas YA creadas pero no verificadas **deberían quedar usables automáticamente** una vez se desactive el toggle. Verificar con una cuenta de prueba.
- Si el SMTP NUNCA se configuró, el dashboard puede no permitir activar "Confirm email" sin SMTP configurado. En ese caso este paso es no-op (ya está OFF).

---

### Tarea B — Auto-login defensivo tras signUp (15 min)

**Goal:** garantizar que tras `signUp()` haya una sesión activa, independientemente de cómo se comporte Supabase con el toggle.

**Justificación:**
- Con toggle OFF, `signUp()` **debería** crear session automáticamente (comportamiento estándar).
- **Pero** si por algún flag del proyecto, o por una versión de Supabase, no la crea, el usuario queda sin sesión.
- Hacer un `signInWithPassword` tras `signUp` **es defensivo y barato** — usa las credenciales que el usuario acaba de introducir.

**Archivos:**
- Modify: `lib/data/auth/auth_repository_supabase.dart` método `signUpWithEmail`

**Steps:**

- [ ] **Paso 1**: Modificar el método para hacer auto-login si no hay session activa:

```dart
@override
Future<void> signUpWithEmail(
  String email,
  String password,
  String displayName,
) async {
  _stateController.add(AuthLoading());
  try {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: <String, dynamic>{'display_name': displayName},
    );

    // Si Supabase ya creó session (toggle "Confirm email" OFF), perfecto.
    // Si no (toggle ON o configuración legacy), forzamos login con las
    // credenciales recién introducidas para garantizar sesión activa.
    if (response.session == null && response.user != null) {
      AppLogger.info(_logTag,
          'signUp returned no session, attempting auto-login');
      try {
        await _client.auth.signInWithPassword(
          email: email.trim(),
          password: password,
        );
      } catch (e) {
        AppLogger.warn(_logTag,
            'auto-login after signup failed (email confirm still required?)', e);
        // No re-lanzar: el signup fue OK. La UI puede mostrar al usuario
        // un mensaje si quiere, pero el listener ya gestiona el state.
      }
    }
  } catch (e, st) {
    if (e is Exception) {
      throw mapAuthError(e);
    }
    AppLogger.error(_logTag, 'signUpWithEmail failed', e, st);
    throw const AuthRepoException(AuthError.unknown, 'Error inesperado');
  }
}
```

- [ ] **Paso 2**: Smoke test:
  1. Signup con email nuevo + password.
  2. Logs esperados: `signUp returned no session, attempting auto-login` (si hace falta) + `signed in uid=…`.
  3. App muestra home con sesión activa, sin pasar por verify-email.

**Criterio**: signup siempre acaba en home autenticado.

---

### Tarea C — Limpieza dead code (15 min, OPCIONAL)

**Goal:** decidir si eliminar o conservar la infraestructura de verificación dormida.

**Recomendación:** **CONSERVAR** todo. El usuario lo reactivará cuando configure SMTP. Eliminar y volver a crear es más trabajo.

Si aún así prefieres limpiar:

**Archivos:**
- Audit: `lib/features/auth/email_verify_pending_screen.dart`
- Audit: `lib/data/auth/auth_repository.dart:41-46` (`AuthEmailVerificationPending`)
- Audit: `lib/core/router/app_router.dart:124-127` (ruta `/verify-email`)
- Audit: `lib/core/router/redirect_guards.dart:19` (`isAuthRoute` incluye `/verify-email`)

**Steps:**

- [ ] **Paso 1**: Confirmar con `grep` exhaustivo que nadie navega a `/verify-email`:
```bash
grep -rn "verify-email\|VerifyEmail\|AuthEmailVerificationPending" lib/ --include="*.dart"
```

- [ ] **Paso 2**: Si el resultado solo incluye declaraciones (no usos), eliminar:
  - Borrar `lib/features/auth/email_verify_pending_screen.dart`.
  - Quitar import + ruta en `app_router.dart:124-127`.
  - Quitar `/verify-email` de `redirect_guards.dart:19`.
  - Quitar clase `AuthEmailVerificationPending` de `auth_repository.dart:41-46`.

- [ ] **Paso 3**: `flutter analyze` debe seguir verde.

**Criterio**: si CONSERVAS, salta a Tarea D. Si LIMPIAS, smoke test build OK.

---

### Tarea D — Actualizar documentación (10 min)

**Goal:** dejar registro del estado actual + cómo reactivar cuando se configure SMTP.

**Archivos:**
- Modify: `docs/SUPABASE_SETUP.md`

**Steps:**

- [ ] **Paso 1**: Añadir sección al inicio del doc:

```markdown
## Estado actual (2026-06-04)

**Verificación de email DESACTIVADA** mientras no se configure SMTP propio.

- Toggle "Confirm email" en Supabase Dashboard → OFF.
- Los usuarios autentican inmediatamente tras signup.
- El código bypassa el check `emailConfirmedAt` en el listener.
- La pantalla `/verify-email` queda dormida (infraestructura conservada).

### Reactivar verificación cuando se configure SMTP

1. **Supabase Dashboard**:
   - Authentication → Providers → Email → "Confirm email" → ON.
   - Authentication → SMTP Settings → configurar SMTP propio
     (Resend, SendGrid, Postmark, etc.).
   - Authentication → URL Configuration → Site URL: `transitly://auth/verified`.
   - Email Templates → Confirm signup → personalizar plantilla.

2. **Código**:
   - Quitar el comentario "verification bypassed" en
     `auth_repository_supabase.dart:44-51` y restaurar el check
     `emailConfirmedAt`.
   - Activar navegación a `/verify-email` tras signup en `signup_screen.dart`
     (en lugar de `/home/inicio` directo).
   - Volver a usar `AuthEmailVerificationPending` en el listener.

3. **Test**:
   - Crear cuenta → recibir email → click link → app verifica → sesión activa.
```

- [ ] **Paso 2**: Verificar que el documento es coherente.

**Criterio**: futuro contributor sabe el estado y cómo cambiarlo.

---

## 3. Archivos modificados (resumen)

### Modificados (1)
- `lib/data/auth/auth_repository_supabase.dart` (Tarea B — auto-login defensivo)

### Docs (1)
- `docs/SUPABASE_SETUP.md` (Tarea D — estado + reactivación)

### Manual (Supabase Dashboard)
- Toggle "Confirm email" → OFF (Tarea A)

### Sin tocar
- Listener, signup_screen, redirect_guards, router, pantallas auth.

### Conservado (dormido para futuro)
- `EmailVerifyPendingScreen`, clase `AuthEmailVerificationPending`, ruta `/verify-email`.

---

## 4. Estimación de tiempo

| Tarea | Tiempo | Tipo |
|-------|--------|------|
| A — Toggle Supabase Dashboard | 5 min | Manual |
| B — Auto-login defensivo | 15 min | Código |
| C — Limpieza dead code (opcional) | 15 min | Código |
| D — Actualizar SUPABASE_SETUP.md | 10 min | Doc |
| Build + smoke | 5 min | Test |
| **Total** | **~40 min** | sin C: 35 min |

---

## 5. Orden de ejecución

1. **A primero** (Dashboard) — es el bloqueo real. Sin esto B no sirve.
2. **B** — defensivo, garantiza session aunque A se haya hecho mal.
3. **D** — registro para el futuro.
4. **C** — solo si quieres reducir ruido visual; recomendado SKIP.

---

## 6. Decisiones tomadas

| # | Decisión | Razón |
|---|----------|-------|
| D1 | Conservar infraestructura `/verify-email` | Se reactivará con SMTP; eliminar y recrear es más trabajo |
| D2 | Auto-login defensivo tras signUp | Garantiza session aunque el toggle se quede ON o haya bug |
| D3 | Doc explícita del estado actual | Próximo contributor entiende qué pasa |
| D4 | NO mostrar mensaje "verifica tu correo" al usuario | Sin SMTP el mensaje sería confuso (correo nunca llega) |

---

## 7. Riesgos

- **R1: Toggle "Confirm email" no aparece en Dashboard si nunca se configuró.** Mitigación: si está OFF por defecto, la Tarea A es no-op; el bug original era otra cosa (revisar logs).
- **R2: Auto-login con password recién creado puede fallar si el password tiene caracteres especiales mal escapados.** Mitigación: Supabase ya maneja la sanitización; `password` se pasa tal cual desde el TextField.
- **R3: Si el usuario hace signup con un email YA registrado, `signUp` falla con `emailTaken` antes del auto-login.** Esto es comportamiento correcto (no crear cuenta duplicada). Mitigación: ninguna, es el flujo esperado.
- **R4: Eliminar dead code (Tarea C) y luego reactivarlo es más trabajo.** Mitigación: NO ejecutar C — conservar todo.
- **R5: Las cuentas creadas antes con verificación pendiente pueden quedar bloqueadas.** Mitigación: en Supabase Dashboard → Users → seleccionar usuarios → "Confirm email" manual desde la UI, o ejecutar SQL: `UPDATE auth.users SET email_confirmed_at = now() WHERE email_confirmed_at IS NULL;`.

---

## 8. Criterios de aceptación

1. Crear cuenta nueva con email + password → entra DIRECTO a `/home/inicio` con sesión activa.
2. Logs muestran `signed in uid=…` inmediatamente tras signUp (no requiere click en email).
3. Las cuentas creadas durante el período "limbo" (pendientes verificación) ahora se pueden usar para login sin nada extra.
4. `docs/SUPABASE_SETUP.md` documenta el estado actual + cómo revertir.

---

## 9. Próximos pasos

Cuando apruebes:
- **"arranca todo"** → A + B + D (~30 min, recomendado).
- **"solo A"** → manual Dashboard, prueba si el código actual ya basta (~5 min).
- **"limpieza también"** → A + B + C + D (~50 min, elimina dead code).

Recomendado **"arranca todo"** — el código + doc en 30 min, y mantienes la infraestructura dormida para cuando configures SMTP.

---

## Changelog

- **2026-06-04** — Plan creado tras auditoría. Diagnóstico: el código ya bypassa email verification, el bloqueo real es el toggle de Supabase Dashboard. Auto-login defensivo añadido como red de seguridad.
