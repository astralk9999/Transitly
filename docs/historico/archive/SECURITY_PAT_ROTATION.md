# Seguridad: Rotación del PAT de Supabase (P0-1)

## Verificación actual
El PAT (`sbp_...`) en `.mcp.json` (gitignored) está potencialmente
comprometido por haber estado en disco durante el desarrollo. 

## Proceso de rotación

1. Ve a https://supabase.com/dashboard/account/tokens
2. Revoca el token viejo (el que empieza por `sbp_`)
3. Genera un token nuevo con alcance mínimo
4. Actualiza `.mcp.json` local:
   ```json
   {
     "mcpServers": {
       "supabase": {
         "command": "npx",
         "args": [
           "-y",
           "@supabase/mcp-server-supabase@latest",
           "--project-ref=mmzahxtiaurkgtmtehxk"
         ],
         "env": {
           "SUPABASE_ACCESS_TOKEN": "sbp_NUEVO_TOKEN"
         }
       }
     }
   }
   ```
5. Reinicia el servidor MCP

## Estado
- `.mcp.json` está en `.gitignore` ✅
- `.mcp.json.example` tiene placeholder `sbp_REPLACE_WITH_YOUR_PAT` ✅
- El token viejo NO está commiteado en el repositorio ✅
- **Acción pendiente:** rotar manualmente en el dashboard de Supabase
