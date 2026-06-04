# Setup Supabase Dashboard — Transitly

## Estado actual (2026-06-04)

**Verificación de email DESACTIVADA** mientras no se configure SMTP propio.

- Toggle "Confirm email" en Supabase Dashboard → **OFF**.
- Los usuarios autentican inmediatamente tras signup.
- El código bypassa el check `emailConfirmedAt` en el listener
  (`auth_repository_supabase.dart:44-51`).
- Red de seguridad adicional: `signUpWithEmail` hace auto-login con las
  credenciales si Supabase no devuelve session
  (`auth_repository_supabase.dart` método `signUpWithEmail`).
- La pantalla `/verify-email` queda dormida (infraestructura conservada
  para reactivar sin reescribir nada).

### Desactivar verificación (pasos manuales)

1. Abrir https://supabase.com/dashboard/project/mmzahxtiaurkgtmtehxk/auth/providers
2. En la sección **Email** → desplegar configuración.
3. Buscar **"Confirm email"** (o "Enable email confirmations").
4. Cambiar a **OFF / Disabled** y guardar.

### Desbloquear cuentas creadas durante el limbo

Si hay usuarios creados ANTES con `email_confirmed_at = null` que no
pueden iniciar sesión, ejecutar en SQL Editor de Supabase Dashboard:

```sql
UPDATE auth.users
SET email_confirmed_at = now()
WHERE email_confirmed_at IS NULL;
```

### Reactivar verificación cuando se configure SMTP

1. **Supabase Dashboard**:
   - Authentication → SMTP Settings → configurar SMTP propio
     (Resend, SendGrid, Postmark, etc.).
   - Authentication → Providers → Email → "Confirm email" → **ON**.
   - Authentication → URL Configuration → Site URL: `transitly://auth/verified`.
   - Authentication → Email Templates → Confirm signup → personalizar plantilla.

2. **Código**:
   - Restaurar check `emailConfirmedAt` en el listener
     (`auth_repository_supabase.dart:44-51`). Hoy es bypass total; añadir
     branch a `AuthEmailVerificationPending` cuando email no confirmado.
   - En `signUpWithEmail`, eliminar el bloque auto-login y en su lugar
     navegar a `/verify-email` desde la UI.
   - En `signup_screen.dart`, cambiar `context.go('/home/inicio')` por
     navegación a la pantalla de verificación pendiente.

3. **Test**:
   - Crear cuenta → recibir email → click link → app verifica → sesión activa.

---

## 1. URL Configuration
Authentication → URL Configuration:
- Site URL: `https://transitly-app.web.app/auth/verify`
- Redirect URLs: añadir `transitly://auth/verified`

## 2. Email Templates
Authentication → Email Templates → Confirm signup:
- Subject: "Verifica tu cuenta de Transitly"
- Body: usar `{{ .ConfirmationURL }}`

## 3. Google OAuth Provider
Authentication → Providers → Google:
- Client ID (Web): configurar en Google Cloud Console
- Authorized redirect URIs: `https://<project>.supabase.co/auth/v1/callback`

## 4. Verificación
- Crear cuenta de prueba
- Verificar email recibido tiene link correcto (no `localhost`)
- Tap en el link en móvil → app abre verificada

---

## RLS Policies — gotchas conocidos

### `route_shares` ↔ `routes` — recursión 42P17 (resuelto 2026-06-04)

**Síntoma:** `PostgrestException: infinite recursion detected in policy for
relation "route_shares", code: 42P17`. Bloqueaba `getMyStats()` en el perfil.

**Causa:** ciclo cerrado entre dos policies:

- `route_shares.route_shares_select_owner` hacía `EXISTS (SELECT FROM routes WHERE owner_id = auth.uid())`.
- `routes.routes_select_visible` hacía `EXISTS (SELECT FROM route_shares WHERE shared_with_id = auth.uid())`.

Cuando PostgreSQL evaluaba SELECT sobre cualquiera de las dos, necesitaba evaluar la otra, que necesitaba evaluar la primera → recursión → 42P17.

**Fix aplicado:** migration `fix_route_shares_rls_recursion`. Crea la función
`public.is_route_owner(p_route_id uuid)` con `SECURITY DEFINER` que bypassa
RLS para hacer el lookup. Las 3 policies de `route_shares` que consultaban
`routes` (SELECT, DELETE, INSERT del owner) ahora llaman la función — misma
semántica, sin recursión.

**Por si vuelve a aparecer:**

1. `SELECT * FROM pg_policies WHERE tablename IN ('route_shares', 'routes', 'user_routes');`
2. Buscar policies que hagan `EXISTS (SELECT FROM <otra_tabla>)` cuando la otra tabla también referencia a la primera en su `qual`.
3. Encapsular el lookup en una función `SECURITY DEFINER STABLE` que bypassa RLS.
4. Sustituir el `EXISTS` por la llamada a la función.
