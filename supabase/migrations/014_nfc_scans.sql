-- =============================================================
-- 014_nfc_scans.sql — Persistencia de escaneos NFC
-- =============================================================
--
-- Tabla para guardar los escaneos NFC de tarjetas de transporte
-- en Supabase cuando el usuario está autenticado. La cache local
-- Hive actúa como fuente primaria (offline-first); esta tabla
-- replica los escaneos exitosos.
--
-- Idempotente: usa IF NOT EXISTS y DO blocks.
-- Aplicación: supabase db push  o  copia/pega en SQL Editor.

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'nfc_scans'
    ) THEN
        CREATE TABLE nfc_scans (
            id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            card_id text NOT NULL,
            balance numeric(10,2) NOT NULL,
            scanned_at timestamptz NOT NULL,
            created_at timestamptz DEFAULT now(),
            UNIQUE(user_id, card_id, scanned_at)
        );

        CREATE INDEX nfc_scans_user_id_idx ON nfc_scans(user_id);

        ALTER TABLE nfc_scans ENABLE ROW LEVEL SECURITY;

        CREATE POLICY "users read own scans"
            ON nfc_scans FOR SELECT
            USING (auth.uid() = user_id);

        CREATE POLICY "users insert own scans"
            ON nfc_scans FOR INSERT
            WITH CHECK (auth.uid() = user_id);
    END IF;
END $$;
