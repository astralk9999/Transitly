-- P1.5 (plan post-TFG): los buckets públicos `avatars` y `operator-assets`
-- permitían LISTAR todos los objetos a cualquiera (lint
-- public_bucket_allows_listing). La descarga pública por URL directa NO
-- pasa por RLS en buckets public=true, así que quitar la policy de SELECT
-- elimina el listado/enumeración sin romper la entrega de imágenes.
-- Verificado: ni la app Flutter ni la web usan el cliente de Storage sobre
-- estos buckets (solo generate_data_export usa storage, con service_role y
-- sobre data-exports).
--
-- NOTA: aplicada al remoto el 2026-06-12 vía MCP (`p1_5_no_public_bucket_listing`).
DROP POLICY IF EXISTS "avatars_select_public" ON storage.objects;
DROP POLICY IF EXISTS "operator_assets_select_public" ON storage.objects;
