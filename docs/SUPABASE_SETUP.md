# Setup Supabase Dashboard — Transitly

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
